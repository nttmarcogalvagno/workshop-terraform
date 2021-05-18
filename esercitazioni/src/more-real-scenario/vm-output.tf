# Virtual machine output | vm-output.tf
output "webserver-name" {
  value = google_compute_instance_template.web_server.name
}
output "webserver-internal-ip" {
  value = google_compute_instance_template.web_server.network_interface[0].network_ip
}
