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
      target_port = 5000
    }
    selector = {
      "type" = "backend"
      "app"  = "pythonapp"   
    }
  }
}


