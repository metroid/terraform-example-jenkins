
####Jenkins

resource "kubernetes_deployment" "jenkins" {
  metadata {
    name = "jenkins"
    labels = {
      app  = "jenkins"
    }
  }
  spec {
    replicas = 1
      selector {
        match_labels = {
          app  = "jenkins"
        }
      }
    template {
      metadata {
        labels = {
          app  = "jenkins"
        }
      }
      spec {
        container {
          image = "jenkins/jenkins"
          name  = "jenkins"
          port {
            container_port = 8080
         }
        }
      }
    }
  }
}

resource "kubernetes_service" "jenkins" {
  depends_on = [kubernetes_deployment.jenkins]
  metadata {
    name = "jenkins"
  }
  spec {
    selector = {
      app = "jenkins"
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}