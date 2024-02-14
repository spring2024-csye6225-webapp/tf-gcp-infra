output "terraform_output" {
  value = "All the necessary network resources are now set up"
}

output "webapp_subnet_cidr" {
  value = {
    for idx, subnet in google_compute_subnetwork.webapp_subnet : idx => subnet.ip_cidr_range
  }
}

output "db_subnet_cidr" {
  value = {
    for idx, subnet in google_compute_subnetwork.db_subnet : idx => subnet.ip_cidr_range
  }
}
