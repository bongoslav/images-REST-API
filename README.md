# MYX Backend Challenge

# Dependencies
- express
- redis
- sqlite3
- multer
- exif-parser
- image-thumbnail

# Starting the app
- Clone the repository
```
git clone https://github.com/bongoslav/myx-backend-challenge.git
```
- Install dependencies
```
cd <project_name>
npm install
```
- start redis-server by running:
```
redis-server
```

- Build and run the project
```
npm start
```
# Endpoints
- Get all images' info from the DB:
```
GET /all-images-info
```
- Get all images in a lat/long bounding box example:
```
GET /images?minLat=50&maxLat=52&minLong=0&maxLong=10
```
- GET single image details:
```
GET /images/:id
```
- Get the thumbnail of an image with an id in the DB:
```
GET /images/:id/thumbnail
```
- Add an image:
```
POST /upload
```
- Delete an image:
```
DELETE /images/:id
```
# Additional info
- All logic is in single file as per requirements.
- Successful tests have been made in Postman and CURL.
- Thumbnails are not stored in DB, they are being generated per request.
- when running the first test all of the data will be initially cached. However the tests include a POST request which flushes the Redis DB, to avoid that feel free to edit the example routes in the bash file.
- to test the app run:
```
cd ./tests
bash test.sh
```
# Problem description
Your task is to design a service that:

1) Allows clients to upload / delete JPEG images through a REST API
2) Can be queried to return all images inside a geographical bounding box, that is defined by min
and max latitude/longitude. You can trust the EXIF information inside the JPEG.
3) Can be queried to return the original image and thumbnail (256x256) version of it.

## Goals
Simplicity. Couple hundred lines of code, one or two files, few dependencies. No
need for fancy OOP hierarchy or something like that. Bare minimum that works
reliably.

Testing.

Efficiency.