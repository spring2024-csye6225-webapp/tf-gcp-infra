provider "google" {
  project = var.project_id
  region  = var.region
}

//testing something

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
  name    = "allow-ssh-${count.index}"
  network = google_compute_network.vpc_network[count.index].name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0" ]
  target_tags   = ["webapp-subnet-0"]
}

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
  account_id   = "abhaydee-vms-1"
  display_name = "abhaydee-serviceaccount"
}

resource "google_project_iam_binding" "logging_admin_binding" {
  project = var.project_id
  role    = "roles/logging.admin"
  members = [ 
    "serviceAccount:${google_service_account.vm_service_account.email}"
  ]
}

resource "google_project_iam_binding" "monitoring_metric_write_binding" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}"
  ]
}

resource "google_compute_firewall" "allow_load_balancer_ingress" {
  name          = var.load-balancer-ingress
  network       = google_compute_network.vpc_network[0].name
  direction = var.ingress_direction
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
 source_ranges = ["130.211.0.0/22","35.191.0.0/16", "0.0.0.0/0"]
  source_tags = ["lb-tag"]
  target_tags = ["webapp-subnet-0"]
}

resource "google_compute_firewall" "deny_external_ingress" {
  name          = "deny-external-ingress"
  network       = google_compute_network.vpc_network[0].name
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webapp-subnet-0"]
}

resource "google_compute_health_check" "webapp_health_check" {
  name                 = "webapp-health-check"
  check_interval_sec   = var.health_check_interval_sec
  timeout_sec          = var.health_check_timeout_sec
  unhealthy_threshold  = var.unhealthy_threshold
  healthy_threshold    = var.healthy_threshold

  http_health_check {
    port_name = "http"
    port = "8080"
    request_path = "/healthz"
  }
}



resource "google_compute_url_map" "url_map" {
  name            = var.url_map_name
  default_service = google_compute_backend_service.webapp-load-balancer.self_link
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name    = var.https_proxy
  url_map = google_compute_url_map.url_map.self_link
  // need to add the ssl certificates  
  ssl_certificates = [google_compute_managed_ssl_certificate.webapp-ssl-certificate.self_link]

}


resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name       = var.forwarding_rule_name
  ip_protocol = var.forwarding_rule_protocol
  load_balancing_scheme = var.load_balancing_scheme
  target     = google_compute_target_https_proxy.https_proxy.self_link  
  port_range = var.port_range
  ip_address = google_compute_global_address.forward_address.id
}


resource "google_compute_global_address" "forward_address" {
 project       = var.project_id
  name = var.global_address_name
}


resource "google_dns_record_set" "webapp_dns_records" {
  name         = var.webapp_domain_name
  type         = var.webapp_dnsrecord_type
  ttl          = var.webapp_dns_ttl
  managed_zone = var.managed_zone_webapp

  rrdatas = [google_compute_global_address.forward_address.address]
}

resource "google_compute_region_instance_group_manager" "regional_instance_group_manager" {
  name             = var.regional_instance_group_manager_name
  base_instance_name = var.base_instance_name
  region           = var.region
  description = "Terraform instance"
  target_size      = 10
  distribution_policy_zones = var.distributed_policy_zones
  distribution_policy_target_shape = "EVEN"
  version {
    name               = "version-template"
    instance_template  = google_compute_region_instance_template.regional_instance_template.self_link
  }

  named_port {
    name = "http"
    port = 8080
  }

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
  }
  auto_healing_policies {
    initial_delay_sec = 300
    health_check      = google_compute_health_check.webapp_health_check.self_link
  }

  lifecycle {
    create_before_destroy = true
  }


  depends_on = [google_compute_health_check.webapp_health_check, google_compute_region_instance_template.regional_instance_template]
}

resource "google_compute_backend_service" "webapp-load-balancer" {
  name                    = var.backend_service_name
  protocol                = "HTTP"
  timeout_sec             = 10
  port_name               = "http"
  load_balancing_scheme = "EXTERNAL"
  enable_cdn              = true
  health_checks           = [google_compute_health_check.webapp_health_check.self_link]

  backend {
    group = google_compute_region_instance_group_manager.regional_instance_group_manager.instance_group
       balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}
# resource "google_compute_target_pool" "target_pool" {
#   name             = "instance-pool"
#   region           = var.region
#   health_checks    = [google_compute_health_check.webapp_health_check.self_link]
#   session_affinity = "NONE"

#   instances = [
#     google_compute_region_instance_group_manager.regional_instance_group_manager.instance_group
#   ]
# }

resource "google_compute_region_instance_template" "regional_instance_template" {
  name        = var.regional_instance_template_name
  description = "Regional instance template for ${var.vm_instance_name}"
  
  machine_type   = var.vm_instance_machinetype
  can_ip_forward = false
  region = var.region
  tags = var.target_tags

  scheduling {
    automatic_restart   = true
    preemptible = false
  }

  disk {
    source_image = var.image_name
    auto_delete  = true
    boot         = true
    disk_type    = var.instance_template_disk_type
    disk_size_gb = var.instance_template_disk_size
  }
  reservation_affinity {
    type = "ANY_RESERVATION"
  }

 
   network_interface {
    network    = google_compute_network.vpc_network[0].self_link
    subnetwork = google_compute_subnetwork.webapp_subnet[0].self_link
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    startup-script = <<-EOF
      cd /opt/csye6225

      if [ -f .env ]; then
          rm -f .env
      fi

      touch .env

      key_value_exists() {
          local key="$1"
          local value="$2"
          grep -q "^$key=" .env && grep -q "^$key=$value" .env
      }

      append_to_env() {
          local key="$1"
          local value="$2"
          if ! key_value_exists "$key" "$value"; then
              echo "$key=$value" >> .env
          fi
      }

      append_to_env "POSTGRES_HOST" "${google_sql_database_instance.cloud_instance.ip_address.0.ip_address}"
      append_to_env "POSTGRES_DB" "${var.database_name}"
      append_to_env "POSTGRES_USER" "${var.database_user_name}"
      append_to_env "POSTGRES_PASSWORD" "${random_password.generated_password.result}"

      sudo sed -i 's/host    all             all             127.0.0.1\/32            ident/host    all             all             127.0.0.1\/32            password/g' /var/lib/pgsql/data/pg_hba.conf
      sudo sed -i 's/host    all             all             ::1\/128                 ident/host    all             all             ::1\/128                 password/g' /var/lib/pgsql/data/pg_hba.conf
      sudo systemctl daemon reload
    EOF
  }

  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["logging-write", "monitoring", "pubsub", "cloud-platform","userinfo-email", "storage-ro", "compute-ro"]
  }

  labels = {
    gce-service-proxy = "on"
  }

  depends_on = [ google_compute_subnetwork.webapp_subnet, google_pubsub_topic.verify_email_topic , google_sql_database_instance.cloud_instance ]
}

resource "google_compute_region_autoscaler" "autoscaler" {
  name   = "autoscaler-${var.region}-3"
  region = var.region
  target = google_compute_region_instance_group_manager.regional_instance_group_manager.self_link
  
  autoscaling_policy {
    min_replicas    = var.autoscaler_min_replicas
    max_replicas    = var.autoscaler_max_replicas
    cooldown_period = var.autoscaler_cool_down_period_sec

    cpu_utilization {
      target = var.autoscaler_cpu_utilization_target
    }
  }

  # depends_on = [google_compute_target_pool.target_pool]
}

resource "google_pubsub_topic" "verify_email_topic" { 
  name = var.pubsub_topic_name
}

resource "google_pubsub_topic_iam_binding" "pubsub_binding" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}"
  ]
  topic = google_pubsub_topic.verify_email_topic.name
}

resource "google_project_iam_binding" "invoker-binding" {
  project = var.project_id
  role    = "roles/run.invoker"
  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}"
  ]
}

resource "google_pubsub_subscription" "verify_email_subscription" {
  name                 = var.pubsub_subscription_name
  topic                = google_pubsub_topic.verify_email_topic.name
  ack_deadline_seconds = var.ack_deadline_seconds

  expiration_policy {
    ttl = var.subscription_ttl
  }
}

resource "google_storage_bucket" "cloud-serverless-003tx-unique-bucket-2-abc123" {
  name          = var.bucket_name
  location      = var.bucket_region
  force_destroy = true

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_object" "cloud_function_archive" {
  name   = var.bucket_object_name
  bucket = google_storage_bucket.cloud-serverless-003tx-unique-bucket-2-abc123.name
  source = var.serverless_code_path
}

resource "google_vpc_access_connector" "vpc-serverless-0003tx-unique-connector-2-xyz789" {
  name          = var.vpc_connector_name
  network       = google_compute_network.vpc_network[0].self_link
  ip_cidr_range = var.vpc_connector_cidr 
}

resource "google_cloudfunctions_function" "verify_email_subscription" {
  name                  = var.cloud_function_name
  description           = "function to test user verification"
  runtime               = var.nodejs_version
  source_archive_bucket = google_storage_bucket.cloud-serverless-003tx-unique-bucket-2-abc123.name
  source_archive_object = google_storage_bucket_object.cloud_function_archive.name
  entry_point           = var.entryPointTrigger

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.verify_email_topic.name
  }         
  
  available_memory_mb = var.available_memory
  timeout             = 540
  ingress_settings    = "ALLOW_ALL"

  environment_variables = {
    MAINGUN_API_KEY   = var.maingun_api_key
    POSTGRES_HOST     = google_sql_database_instance.cloud_instance.ip_address.0.ip_address # Fetching the IP address dynamically
    POSTGRES_DB       = var.database_name
    POSTGRES_USER     = var.database_user_name
    POSTGRES_PASSWORD = random_password.generated_password.result
  }

  vpc_connector        = google_vpc_access_connector.vpc-serverless-0003tx-unique-connector-2-xyz789.name
  service_account_email = google_service_account.vm_service_account.email
}

resource "google_compute_managed_ssl_certificate" "webapp-ssl-certificate" {
  name = var.ssl_certificate_name
  
  managed {
    domains = var.ssl_domain
  }

  description = var.ssl_description
}

resource "google_compute_ssl_policy" "webapp-ssl-policy" {
  name    = var.ssl_policy_name
  profile = var.ssl_profile
}

module "gce-lb-https" {
  source  = "terraform-google-modules/lb-http/google"
  version = "~> 10.0"
  name    = var.network_prefix
  project = var.project_id

  target_tags       = var.target_tags
  backends          = {
    default = {
      protocol          = "HTTPS"
      port              = 443
      port_name         = "https"
      timeout_sec       = 10
      enable_cdn        = false

      health_check = {
        request_path = "/healthz"
        port         = 443
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
        group = google_compute_region_instance_group_manager.regional_instance_group_manager.instance_group
        }
      ]

      iap_config = {
        enable = false
      }
      disable_http_to_https_redirection = true
    }
  }

  ssl_policy       = google_compute_ssl_policy.webapp-ssl-policy.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.webapp-ssl-certificate.self_link]
}