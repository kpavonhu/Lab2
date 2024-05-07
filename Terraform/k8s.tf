resource "kubernetes_deployment" "name" {
  metadata {
    name = "pythonappdeployment"  ## Cambiar el nombre de la aplicacion "nodeapp"
    labels = {
      "type" = "backend"
      "app"  = "pythonapp"      ## Cambiar el nombre de la aplicacion "nodeapp"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "type" = "backend"
        "app"  = "pythonapp"    ## Cambiar el nombre de la aplicacion "nodeapp"
      }
    }
    template {
      metadata {
        name = "pythonapppod"   ## Cambiar el nombre de la aplicacion "nodeapp"
        labels = {
          "type" = "backend"
          "app"  = "pythonapp"  ## Cambiar el nombre de la aplicacion "nodeapp"
        }
      }
      spec {
        container {
          name  = "pythoncontainer"   ## Cambiar el nombre del container
          image = var.container_image
          port {
            container_port = 5000
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
    name = "pythonapp-lb-service"   ## Cambiar el nombre de la aplicacion "nodeapp"
  }
  spec {
    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.lab-2.address
    port {
      port        = 80
      target_port = 5000
    }
    selector = {
      "type" = "backend"
      "app"  = "pythonapp"   ## Cambiar el nombre de la aplicacion "nodeapp"
    }
  }
}


