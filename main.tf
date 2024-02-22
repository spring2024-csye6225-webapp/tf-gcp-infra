provider "google" {
  credentials = file(var.service_key_route)
  project     = var.project_id
  region      = var.region
}

resource "google_compute_network" "vpc_network" {
  count                   = var.vpc_count
  name                    = "${var.vpc_name}-${count.index}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "webapp_subnet" {
  count         = var.vpc_count
  name          = "${var.webapp_subnet_name}-${count.index}"
  ip_cidr_range = var.webapp_subnet_cidr[count.index]
  network       = google_compute_network.vpc_network[count.index].self_link
}

resource "google_compute_subnetwork" "db_subnet" {
  count         = var.vpc_count
  name          = "${var.db_subnet_name}-${count.index}"
  ip_cidr_range = var.db_subnet_cidr[count.index]
  network       = google_compute_network.vpc_network[count.index].self_link
}

resource "google_compute_route" "webapp_route" {
  count            = var.vpc_count
  name             = "${var.webapp_route_name}-${count.index}"
  dest_range       = var.webapp_destination_route
  network          = google_compute_network.vpc_network[count.index].self_link
  next_hop_gateway = var.hop_gateway_value
  priority         = var.webapp_route_priority
}


locals {
  webapp_subnet_cidr = [
    for i in range(var.vpc_count) : cidrsubnet("10.0.${i}.0/24", 8, 1)
  ]

  db_subnet_cidr = [
    for i in range(var.vpc_count) : cidrsubnet("10.1.${i}.0/24", 8, 1)
  ]
}

variable "webapp_subnet_cidr" {
  description = "CIDR address range for webapp subnets"
  type        = list(string)
}

variable "db_subnet_cidr" {
  description = "CIDR address range for db subnets"
  type        = list(string)
}

resource "google_compute_firewall" "allow_ssh" {
  count   = var.vpc_count
  name    = "allow-ssh-${count.index}"
  network = google_compute_network.vpc_network[count.index].name
 
  allow {
    protocol = "tcp"
    ports    = ["8080", "22"]
  }
 
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["webapp-subnet-0"]
}

resource "google_compute_instance" "vm_instance" {
  count         = var.vpc_count
  name          = "vm-instance-${count.index}"
  machine_type  = "n1-standard-1"
  zone          = var.zone
 
  boot_disk {
    initialize_params {
      image = var.image_name
      size  = 100
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network[count.index].self_link
    subnetwork = google_compute_subnetwork.webapp_subnet[count.index].self_link
    access_config {
      // Ephemeral public IP
    }
  }
  tags = ["webapp-subnet-0"]

}