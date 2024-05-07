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
