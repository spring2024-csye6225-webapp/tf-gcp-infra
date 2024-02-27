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
  count                    = var.vpc_count
  name                     = "${var.webapp_subnet_name}-${count.index}"
  ip_cidr_range            = var.webapp_subnet_cidr[count.index]
  network                  = google_compute_network.vpc_network[count.index].self_link
  private_ip_google_access = true // access for private ip's
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

//googlecomputeglobaladdress  create an IP 
resource "google_compute_global_address" "instance_ip" {
  name         = "instance-ip"
  project      = var.project_id
  purpose      = "EXTERNAL"
  address_type = "EXTERNAL"
}

resource "google_service_networking_connection" "private_connection" {
  network                 = google_compute_network.vpc_network[0].name
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.instance_ip.address]
}


// output - name 
resource "google_project_service" "service_networking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
}


resource "google_sql_database_instance" "cloud_instance" {
  count               = var.vpc_count
  name                = "${var.cloudsql_instance_name}-${count.index}"
  database_version    = "POSTGRES_13"
  region              = var.region
  deletion_protection = var.deletion_protection
  project             = var.project_id


  settings {
    tier              = "db-f1-micro"
    availability_type = var.availability_type
    disk_type         = var.disk_type
    disk_size         = var.disk_size

    ip_configuration {
      ipv4_enabled    = var.ipv4_enabled
      private_network = google_compute_network.vpc_network[count.index].self_link

    }
  }

  depends_on = [
    google_compute_network.vpc_network,
    google_compute_subnetwork.db_subnet
  ]
}


resource "google_sql_database" "postgresql" {
  count     = var.vpc_count
  name      = var.database_name
  instance  = google_sql_database_instance.cloud_instance[count.index].name
  charset   = "utf8"
  collation = "utf8_general_ci"
}


resource "google_sql_user" "database_user" {
  count    = var.vpc_count
  name     = var.database_user_name
  instance = google_sql_database_instance.cloud_instance[count.index].name
  password = random_password.generated_password[count.index].result
}

resource "random_password" "generated_password" {
  count   = var.vpc_count
  length  = 16
  special = true
}




resource "google_compute_firewall" "allow_ssh" {
  count   = var.vpc_count
  name    = "allow-ssh-${count.index}"
  network = google_compute_network.vpc_network[count.index].name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webapp-subnet-0"]
}

resource "google_compute_instance" "vm_instance" {
  count        = var.vpc_count
  name         = "vm-instance-${count.index}"
  machine_type = "n1-standard-1"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image_name
      size  = 100
      type  = "pd-balanced"
    }
  }

  //
  metadata_startup_script = <<-EOF
      #!/bin/bash
      # Script to set up environment variables with database credentials

      # Database credentials
      DB_HOST="${google_sql_database_instance.cloud_instance[count.index].ip_address}"
      DB_USER="${var.database_user_name}"
      DB_PASS="${random_password.generated_password[count.index].result}"
      DB_NAME="${var.database_name}"

      # Write credentials to .env file in /tmp directory
      cat <<EOT >> /tmp/.env
      DB_HOST=\${DB_HOST}
      DB_USER=\${DB_USER}
      DB_PASS=\${DB_PASS}
      DB_NAME=\${DB_NAME}
EOT
EOF

  network_interface {
    network    = google_compute_network.vpc_network[count.index].self_link
    subnetwork = google_compute_subnetwork.webapp_subnet[count.index].self_link
    access_config {
      // Ephemeral public IP
    }
  }
  tags = ["webapp-subnet-0"]

}
