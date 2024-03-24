provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc_network" {
  count                           = var.vpc_count
  name                            = "${var.vpc_name}-${count.index}"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp_subnet" {
  count                    = var.vpc_count
  name                     = "${var.webapp_subnet_name}-${count.index}"
  ip_cidr_range            = var.webapp_subnet_cidr[count.index]
  network                  = google_compute_network.vpc_network[count.index].self_link
  private_ip_google_access = false
}

resource "google_compute_subnetwork" "db_subnet" {
  count                    = var.vpc_count
  name                     = "${var.db_subnet_name}-${count.index}"
  ip_cidr_range            = var.db_subnet_cidr[count.index]
  network                  = google_compute_network.vpc_network[count.index].self_link
  private_ip_google_access = true
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
  name    = "allow-ssh-${0}"
  network = google_compute_network.vpc_network[0].name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webapp-subnet-0"]
}


//googlecomputeglobaladdress  create an IP 
resource "google_compute_global_address" "instance_ip" {
  name          = var.ip_instance_name
  purpose       = var.ip_instance_purpose
  address_type  = var.ip_instance_address_type
  network       = google_compute_network.vpc_network[0].self_link
  prefix_length = var.ip_instance_prefix_length
}
resource "google_project_service" "service_networking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
}

resource "google_service_networking_connection" "private_connection" {
  network                 = google_compute_network.vpc_network[0].name
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.instance_ip.name]
  deletion_policy         = var.private_connection_delete_policy
  depends_on = [
    google_project_service.service_networking,
    google_compute_network.vpc_network
  ]
}


// output - name 



resource "google_sql_database_instance" "cloud_instance" {
  name                = var.cloudsql_instance_name
  database_version    = var.posgres_version
  region              = var.region
  deletion_protection = var.deletion_protection
  project             = var.project_id
  depends_on          = [google_service_networking_connection.private_connection, google_compute_network.vpc_network]
  settings {
    tier              = var.postgres_tier
    availability_type = var.availability_type
    disk_type         = var.disk_type
    disk_size         = var.disk_size

    ip_configuration {
      ipv4_enabled                                  = var.ipv4_enabled
      private_network                               = google_compute_network.vpc_network[0].self_link
      enable_private_path_for_google_cloud_services = true
    }
  }
}

resource "google_sql_database" "cloud-database" {
  name     = var.database_name
  instance = google_sql_database_instance.cloud_instance.name

}

resource "google_sql_user" "database_user" {
  name     = var.database_user_name
  instance = google_sql_database_instance.cloud_instance.name
  password = random_password.generated_password.result
}


resource "google_compute_firewall" "firewall_postgres" {
  name      = var.postgres_firewall_name
  direction = var.postgres_firewall_direction
  network   = google_compute_network.vpc_network[0].self_link
  deny {
    protocol = var.postgres_firewall_deny_protocol
    ports    = var.postgres_firewall_deny_ports
  }
}

resource "google_compute_firewall" "firewall_postgres_allow" {
  name      = "firewall-postgres-allow"
  direction = var.postgres_firewall_direction
  network   = google_compute_network.vpc_network[0].self_link
  allow {
    protocol = var.postgres_firewall_allow_protocol
    ports    = var.postgres_firewall_allow_ports
  }
  priority    = var.postgres_firewall_priority
  target_tags = var.postgres_firewall_target_tags
}

resource "random_password" "generated_password" {
  length  = var.password_length
  special = false
}

resource "google_service_account" "vm_service_account" {
  account_id = "abhaydee-vms-1"
  display_name = "abhaydee-serviceaccount"
}


resource "google_project_iam_binding" "logging_admin_binding" {
  project = var.project_id
  role = "roles/logging.admin"
  members = [ 
     "serviceAccount:${google_service_account.vm_service_account.email}"
   ]
}

resource "google_project_iam_binding" "monitoring_metric_write_binding" {
  project = var.project_id
  role = "roles/monitoring.metricWriter"
  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}"
  ]
}



resource "google_pubsub_topic" "verify_email_topic" { 
  name = "verify_email"
}

resource "google_pubsub_subscription" "verify_email_subscription" {
  name = "verify_email_subscription"
  topic = google_pubsub_topic.verify_email_topic.name
  ack_deadline_seconds = 120
  expiration_policy {
    ttl = "604800s"
  }
}

resource "google_storage_bucket" "clouduser-bucket" {
  name = "users-bucket"
  location = "us-central1-a"
  force_destroy = true

  versioning {
    enabled = true
  }

}

resource "google_storage_bucket_object" "cloud_function_archive" {
  name = "cloud-serverless.zip"
  bucket = google_storage_bucket.clouduser-bucket.name
  source = "./.terraform.zip"
}

resource "google_cloudfunctions_function" "verify_email_subscription" {
  name = "verify_email_subscription"
  runtime = "nodejs14"
  source_archive_bucket = google_storage_bucket.clouduser-bucket.name
  source_archive_object = google_storage_bucket_object.cloud_function_archive.name
  trigger_http = true
  entry_point = "verifyEmail"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource = google_pubsub_topic.verify_email_topic.name
  }

  service_account_email = google_service_account.vm_service_account.email

  //we need to add the IAM binding here 
}


resource "google_compute_instance" "vm_instance" {
  name         = var.vm_instance_name
  machine_type = var.vm_instance_machinetype
  zone         = var.zone
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = var.image_name
      size  = var.vm_instance_size
      type  = var.vm_instance_type
    }
  }

  metadata_startup_script = <<-EOF
    cd /opt/csye6225

    # Check if .env file exists
    if [ -f .env ]; then
        # If .env file exists, remove it
        rm -f .env
    fi

    # Create a new .env file
    touch .env

    # Function to check if a key-value pair already exists in the .env file
    function key_value_exists {
        local key="$1"
        local value="$2"
        grep -q "^$key=" .env && grep -q "^$key=$value" .env
    }

    # Append unique key-value pairs to the .env file
    append_to_env() {
        local key="$1"
        local value="$2"
        if ! key_value_exists "$key" "$value"; then
            echo "$key=$value" >> .env
        fi
    }

    # Append unique key-value pairs to the .env file
    append_to_env "POSTGRES_HOST" "${google_sql_database_instance.cloud_instance.ip_address.0.ip_address}"
    append_to_env "POSTGRES_DB" "${var.database_name}"
    append_to_env "POSTGRES_USER" "${var.database_user_name}"
    append_to_env "POSTGRES_PASSWORD" "${random_password.generated_password.result}"

    # Reload systemd daemon to apply changes

    sudo sed -i 's/host    all             all             127.0.0.1\/32            ident/host    all             all             127.0.0.1\/32            password/g' /var/lib/pgsql/data/pg_hba.conf
    sudo sed -i 's/host    all             all             ::1\/128                 ident/host    all             all             ::1\/128                 password/g' /var/lib/pgsql/data/pg_hba.conf
    sudo systemctl daemon reload
EOF


  network_interface {
    network    = google_compute_network.vpc_network[0].self_link
    subnetwork = google_compute_subnetwork.webapp_subnet[0].self_link
    access_config {
      // Ephemeral public IP
    }
  }

  tags = ["webapp-subnet-0"]

  service_account {
    email = google_service_account.vm_service_account.email
    scopes = ["logging-write", "monitoring"]
  }
}


resource "google_dns_record_set" "webapp_dns_records" {
  name = var.webapp_domain_name
  type = var.webapp_dnsrecord_type
  ttl = var.webapp_dns_ttl
  managed_zone = var.managed_zone_webapp
  rrdatas = [google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip]
}

# echo "DB_HOST=${google_sql_database_instance.cloud_instance.ip_address}" >> .env


