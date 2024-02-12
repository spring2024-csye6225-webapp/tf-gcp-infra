output "terraform_output" {
  value = "All the neccessary network resouces are now setup"
}

output "webapp_subnet_cidr" {
  value = google_compute_subnetwork.webapp_subnet.ip_cidr_range
}

output "db_subnet_cidr" {
  value = google_compute_subnetwork.db_subnet.ip_cidr_range
}
