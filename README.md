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

##############################################################################################################

**App.py**

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

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"     "You can put this "Hello, World" to avoid seeing the URL NOT FOUND message" 

@app.get('/store')
def get_stores():
    return {"stores": stores}

##############################################################################################################

#  Running the Application

Build the Docker image using the provided Dockerfile, and run the container. The Flask application will be accessible at http://localhost:5000/store.

docker build -t flask-store .
docker run -p 5000:5000 flask-store

After running the container, you can access the API endpoint at http://localhost:5000/store.


##############################################################################################################

# providers.tf   >>>>  This file has the google and kubernetes providers to implement in this project

terraform {
  required_version = ">= 0.12"
  backend "gcs" {
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
}
provider "kubernetes" {
  host  = google_container_cluster.lab-2.endpoint
  token = data.google_client_config.current.access_token
  client_certificate = base64decode(
    google_container_cluster.lab-2.master_auth[0].client_certificate,
  )
  client_key = base64decode(google_container_cluster.lab-2.master_auth[0].client_key)
  cluster_ca_certificate = base64decode(
    google_container_cluster.lab-2.master_auth[0].cluster_ca_certificate,
  )
}

##############################################################################################################

#  main.tf   >>>> This is the file to create the GKE Cluster


data "google_container_engine_versions" "lab-2" {
  location = "us-central1-c"
}
data "google_client_config" "current" {
}

resource "google_container_cluster" "lab-2" {
  name               = "my-first-cluster"
  location           = "us-central1-c"
  initial_node_count = 3
  min_master_version = data.google_container_engine_versions.default.latest_master_version

  node_config {
    machine_type = "g1-small"
    disk_size_gb = 32
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sleep 90"
  }
}

##############################################################################################################

# k8s.tf   >>>>  This file has the "deployment", "service deployment" & the load balancer service on K8s which is based on a yaml structure


resource "kubernetes_deployment" "name" {
  metadata {
    name = "pythonappdeployment"  
    labels = {
      "type" = "backend"
      "app"  = "pythonapp"      
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "type" = "backend"
        "app"  = "pythonapp"    
      }
    }
    template {
      metadata {
        name = "pythonapppod"   
        labels = {
          "type" = "backend"
          "app"  = "pythonapp"  
        }
      }
      spec {
        container {
          name  = "pythoncontainer"   
          image = var.container_image
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "google_compute_address" "lab-2" {
  name   = "ipforservice"
  region = var.region
}

resource "kubernetes_service" "appservice" {
  metadata {
    name = "pythonapp-lb-service"
  }
  spec {
    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.lab-2.address
    port {
      port        = 5000
      target_port = 80
    }
    selector = {
      "type" = "backend"
      "app"  = "pythonapp"   
    }
  }
}

##############################################################################################################

#  variables.tf    >>>  This variables are called in the files above

variable "region" {
}
variable "project_id" {
}
variable "container_image" {
}

##############################################################################################################

#  outputs.tf  >>>  This file is very useful to get the most important elements to get access to our application at the end of our terraform apply 

output "cluster_name" {
  value = google_container_cluster.lab-2.name
}
output "cluster_endpoint" {
  value = google_container_cluster.lab-2.endpoint
}
output "cluster_location" {
  value = google_container_cluster.lab-2.location
}
output "load-balancer-ip" {
  value = google_compute_address.lab-2.address
}


##############################################################################################################

                                           # Setup Github OIDC Authentication for GCP #


***  Get your GCP Project number for reference  ***

gcloud projects describe my-project-57433-labmodule2

Example:

createTime: '2024-04-23T15:12:57.012423Z'
lifecycleState: ACTIVE
name: My Project 57433 - LabModule2
projectId: my-project-57433-labmodule2
projectNumber: '436611642203'


***  Create a new workload Identity pool ***

gcloud iam workload-identity-pools create "k8s-pool" \
--project="my-project-57433-labmodule2" \
--location="global" \
--display-name="k8s Pool"


***  Create a OIDC (openID Connect) identity provider to authenticate with Github  ***

gcloud iam workload-identity-pools providers create-oidc "k8s-provider" \
--project="my-project-57433-labmodule2" \
--location="global" \
--workload-identity-pool="k8s-pool" \
--display-name="k8s provider" \
--attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
--issuer-uri="https://token.actions.githubusercontent.com"


***  Create a "service account" using the roles below in GCP  ***

roles/compute.admin
roles/container.admin
roles/container.clusterAdmin
roles/iam.serviceAccountTokenCreator
roles/iam.serviceAccountUser
roles/storage.admin


***  Add IAM Policy bindings with Github repo, Identity provider and Service account  ***

gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT_EMAIL}" \
--project="my-project-57433-labmodule2" \
--role="roles/iam.workloadIdentityUser" \
--member="principalSet://iam.googleapis.com/projects/436611642203/locations/global/workloadIdentityPools/k8s-pool/attribute.repository/kpavonhu/Lab2


***  Create a bucket in GCS to store the terraform state file. ***

Add secrets to Github Repo

    GCP_PROJECT_ID
    GCP_TF_STATE_BUCKET


##############################################################################################################

#  This is the GitHub Actions workflow for deploying the app to GKE using terraform


name: Deploy to kubernetes
on:
  push:
    branches:
      - "main"

env:
  GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  TF_STATE_BUCKET_NAME: ${{ secrets.GCP_TF_STATE_BUCKET }}
  GAR_LOCATION: us-central1

jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      IMAGE_TAG: ${{ github.sha }}

    permissions:
      contents: 'read'
      id-token: 'write'

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - id: 'auth'
      uses: 'google-github-actions/auth@v2'
      with:
        credentials_json: '${{ secrets.GCP_CREDENTIALS }}'

    - name: 'Set up Cloud SDK'
      uses: 'google-github-actions/setup-gcloud@v2'
      
    - name: Docker configuration
      ##run: gcloud auth activate-service-account github-actions@my-project-57433-labmodule2.iam.gserviceaccount.com --key-file=/Users/kpavon/Downloads/my-project-57433-labmodule2-039a9d2a2e11.json --project=my-project-57433-labmodule2
      run: gcloud auth configure-docker
    
    - name: Build and push docker image
      run: |    
        docker build -t us.gcr.io/${{ secrets.GCP_PROJECT_ID }}/pythonappimage:$IMAGE_TAG .  
        docker push us.gcr.io/${{ secrets.GCP_PROJECT_ID }}/pythonappimage:$IMAGE_TAG
      working-directory: ./pythonapp   ## Fijarme en el directorio donde esta la aplicacion

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3

    - name: Terraform init
      run: |  ## This command needs to be issued in the google CLI >>   gcloud auth activate-service-account github-actions@my-project-57433-labmodule2.iam.gserviceaccount.com --project=my-project-57433-labmodule2
        terraform init -backend-config="bucket=k8s-terraform-state-file" -backend-config="prefix=test"
      working-directory: ./Terraform

    - name: Terraform destroy
      run: |
        terraform destroy 

    - name: Terraform Plan
      run: |
        terraform plan -lock=false \
        -var="region=us-central1" \
        -var="project_id=${GCP_PROJECT_ID}" \
        -var="container_image=us.gcr.io/${GCP_PROJECT_ID}/pythonappimage:$IMAGE_TAG" \
        -out=PLAN
      working-directory: ./Terraform

    - name: Terraform apply
      run: terraform apply -lock=false PLAN
      working-directory: ./Terraform

<img width="800" alt="Captura de pantalla 2024-05-08 a la(s) 9 57 12 p  m" src="https://github.com/kpavonhu/Lab2/assets/112138880/bdb6474f-8eca-4efa-b09b-29d05a978154">

