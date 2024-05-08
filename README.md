# Lab2
Lab modulo 2 

# Flask Store API

This repository contains a Flask application implementing a simple Store API.

## Dockerfile

This Dockerfile sets up a Python 3.10 environment with Flask installed and exposes port 5000. It then copies the application files into the container and specifies the command to run the Flask application.

```Dockerfile
FROM python:3.10
EXPOSE 5000
WORKDIR /app
RUN pip install flask
COPY . .
CMD ["flask", "run", "--host", "0.0.0.0"]

### App.py

This file contains the main code for the Flask application. It defines routes for handling store data.


from flask import Flask, request

app = Flask(__name__)

stores = [
    {
        "name": "My Store",
        "items": [
            {
                "name": "Chair",
                "price": 15.99
            }
        ]
        
    }
]

@app.get('/store')
def get_stores():
    return {"stores": stores}


## Running the Application

To run this application using Docker, make sure you have Docker installed on your system. Then, build the Docker image using the provided Dockerfile, and run the container. The Flask application will be accessible at http://localhost:5000/store.

docker build -t flask-store .
docker run -p 5000:5000 flask-store

After running the container, you can access the API endpoint at http://localhost:5000/store.

