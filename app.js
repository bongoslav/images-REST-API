const express = require("express");
const multer = require("multer");
const ExifParser = require("exif-parser");
const sqlite3 = require("sqlite3").verbose();
const redis = require("redis");
const fs = require("fs");
const path = require("path");
const imageThumbnail = require("image-thumbnail");

const app = express();

app.use(express.urlencoded({ extended: true }));

const port = 3000;

// connecting to db
const db = new sqlite3.Database("database.sqlite");
db.serialize(() => {
  db.run(
    `CREATE TABLE IF NOT EXISTS images_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
          originalName TEXT NOT NULL,
          latitude FLOAT,
          longitude FLOAT,
          image TEXT
          )`,
    (err) => {
      if (err) {
        throw err;
      }
    }
  );
});

// setup multer configuration
const storage = multer.memoryStorage();
const upload = multer({ storage });

// Initiate and connect to the Redis client
const redisClient = redis.createClient();
(async () => {
  redisClient.on("error", (error) => console.error(`Ups : ${error}`));
  await redisClient.connect();
})();

async function getOrSetCache(cacheKey, cb) {
  // First attempt to retrieve data from the cache
  try {
    const cachedResult = await redisClient.get(cacheKey);
    if (cachedResult) {
      console.log("Data from cache.");
      return JSON.parse(cachedResult);
    }
  } catch (error) {
    throw new Error("Something happened to Redis", error);
  }

  try {
    // if no cachedResult
    const result = await cb();
    // Finally, if you got any results, save the data back to the cache
    if (result != null) {
      try {
        await redisClient.set(cacheKey, JSON.stringify(result));
      } catch (error) {
        throw new Error("Error occurred while fetching data.");
      }
    }
    console.log("Data outside cache.");
    return result;
  } catch (error) {
    throw new Error(error);
  }
}

// routes
app.get("/images", async (req, res) => {
  const maxLat = req.query.maxLat;
  const minLat = req.query.minLat;
  const maxLong = req.query.maxLong;
  const minLong = req.query.minLong;

  const query = `SELECT
  id, originalName, latitude, longitude
  FROM images_info WHERE
  latitude BETWEEN ? AND ? AND
  longitude BETWEEN ? AND ? ;`;

  const cachedKey = `${minLat}:${maxLat}:${minLong}:${maxLong}`;
  const data = await getOrSetCache(cachedKey, async () => {
    const rows = await new Promise((resolve, reject) => {
      db.all(query, [minLat, maxLat, minLong, maxLong], (err, rows) => {
        if (err) {
          reject(err);
        }
        resolve(rows);
      });
    });
    if (rows.length === 0) {
      return JSON.stringify("No images found");
    }
    return rows;
  });
  if (data.length === 0) {
    res.status(404).json(data);
  } else {
    res.status(200).json(data);
  }
});

app.get("/images/:id/:thumbnail?", async (req, res) => {
  const id = req.params.id;
  let thumbnail;
  let cachedKey;
  const thumbnailOptions = { width: 256, height: 256 };
  const query =
    "SELECT id, originalName, latitude, longitude, image FROM images_info WHERE id = ?";

  if (req.params.thumbnail) {
    cachedKey = `${id}:thumbnail`;
  } else {
    cachedKey = `${id}`;
  }

  const data = await getOrSetCache(cachedKey, async () => {
    const row = await new Promise((resolve, reject) => {
      db.get(query, id, (err, currentRow) => {
        if (err) {
          reject(err);
        }
        resolve(currentRow);
      });
    });
    if (row === undefined) {
      return `No image found with id: ${id}`;
    }
    return row;
  });
  // checking in order to set the correct response code
  if (data === `No image found with id: ${id}`) {
    res.status(404).json(data);
  } else {
    if (req.params.thumbnail) {
      if (!data.id) {
      }
      try {
        thumbnail = await imageThumbnail(data.image, thumbnailOptions);
      } catch (err) {
        throw new Error(err);
      }
      return res.header("Content-Type", "image/jpeg").send(thumbnail);
    }
    res.status(200).json(data);
  }
});

app.post("/upload", upload.single("image"), async (req, res) => {
  const { originalname, buffer } = req.file;
  let latitude = null;
  let longitude = null;

  // const fileName = `${Date.now()}_${originalname}`;
  const imagePath = path.join("images", originalname);

  fs.writeFile(imagePath, buffer, (err) => {
    if (err) {
      console.error(err);
      return res.status(500).send("Error uploading image");
    }
  });

  // get lat/long
  const parser = ExifParser.create(buffer);
  try {
    exifData = parser.parse();
    latitude = exifData["tags"]["GPSLatitude"];
    longitude = exifData["tags"]["GPSLongitude"];
  } catch (err) {
    console.log("exif parse error: " + err.message);
  }

  const query =
    "INSERT INTO images_info (originalName, latitude, longitude, image) VALUES(?, ?, ?, ?);";

  db.run(
    query,
    [originalname, latitude, longitude, imagePath],
    async (err, row) => {
      if (err) {
        throw err;
      }
      // cleaning the cache because we have new data!
      redisClient.flushAll("ASYNC", (err, succeeded) => {
        if (err) {
          throw new Error(err);
        } else {
          console.log("Successful Redis flush.");
        }
      });
      res
        .status(201)
        .json({ message: `Image ${originalname} has been uploaded` });
    }
  );
});

app.delete("/images/:id", (req, res) => {
  const id = req.params.id;

  const query = "DELETE FROM images_info WHERE id = ?";
  db.run(query, id, (err) => {
    if (err) {
      throw err;
    }
  });
  return res
    .status(200)
    .json(`Image with id: ${id} has been deleted if such ID exists.`);
});

app.get("/all-images-info", async (req, res) => {
  let resStatus;
  const data = await getOrSetCache("all-images", async () => {
    const rows = await new Promise((resolve, reject) => {
      db.all(
        "SELECT id, originalName, latitude, longitude FROM images_info;",
        (err, rows) => {
          if (err) {
            reject(err);
          }
          resolve(rows);
        }
      );
    });
    if (rows.length === 0) {
      return "No images found";
    }
    return rows;
  });
  if (data.length === 0) {
    resStatus = 404;
  } else {
    resStatus = 200;
  }
  res.status(resStatus).json(data);
});

app.listen(port, () => {
  console.log(`Listening on port ${port}...`);
});

// closing the db after termination
process.on("SIGINT", () => {
  db.close((err) => {
    if (err) {
      console.log("DB CLOSE ERROR: " + err);
    } else {
      console.log("Closed database connection");
    }
    process.exit(0);
  });
});
