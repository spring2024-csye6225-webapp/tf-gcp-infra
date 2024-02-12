provider "google" {
  credentials = file(var.service_key_route)
  project     = var.project_id
  region      = var.region
}

resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name          = var.webapp_subnet_name
  ip_cidr_range = var.webapp_subnet_cidr
  network       = google_compute_network.vpc_network.self_link
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = var.db_subnet_name
  ip_cidr_range = var.db_subnet_cidr
  network       = google_compute_network.vpc_network.self_link
}

resource "google_compute_route" "webapp_route" {
  name             = var.webapp_route_name
  dest_range       = var.webapp_destination_route
  network          = google_compute_network.vpc_network.self_link
  next_hop_gateway = var.hop_gateway_value
  priority         = var.webapp_route_priority
}

