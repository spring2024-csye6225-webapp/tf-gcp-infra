

variable "project_id" {
  description = "ID of the Google Cloud project"
}

variable "region" {
  description = "Region where the resources will be deployed"
}

variable "webapp_destination_route" {
  description = "Destination range for the webapp route"
}

variable "webapp_route_priority" {
  description = "Priority value for the webapp route"
}

variable "vpc_name" {
  description = "Name of the VPC network"
}

variable "webapp_subnet_name" {
  description = "Name of the subnet for the web application"
}

variable "db_subnet_name" {
  description = "Name of the subnet for the database"
}

variable "webapp_route_name" {
  description = "Name of the route for the web application"
}

variable "hop_gateway_value" {
  description = "Next hop gateway value for the route"
}

variable "service_key_route" {
  description = "File route for the Google Cloud service account key"
}

variable "vpc_count" {
  description = "Number of VPCs to be created"
  type        = number
}

variable "zone" {
  description = "Zone where the instances will be created"
}

variable "image_name" {
  description = "Name of the image to be used for boot disk"
}


variable "database_name" {
  description = "Name of the database"
  default     = "webapp"
}

variable "database_user_name" {
  description = "Name of the database user"
  default     = "webapp"
}


variable "cloudsql_instance_name" {
  description = "Name of cloud sql instance"
  default     = "custom-cloud-instance-test"
}


variable "deletion_protection" {
  default     = "false"
  description = "Deletion protection toggle for the cloud sql instance"
}

variable "availability_type" {
  default     = "REGIONAL"
  description = "regional or global location from the google cloud sql instance can be accessed"
}

variable "disk_type" {
  default     = "pd-ssd"
  description = "Type of disk to be used for the database"
}

variable "disk_size" {
  default     = 10
  description = "Size of the disk to be used"
}

variable "ipv4_enabled" {
  default     = false
  description = "ipv4 enablement toggle"
}


variable "ip_instance_name" {
  default     = "instance-ip"
  description = "ip instance name"
}

variable "ip_instance_purpose" {
  default     = "VPC_PEERING"
  description = "ip instance purpose"
}

variable "ip_instance_address_type" {
  default     = "INTERNAL"
  description = "ip instance address type"
}


variable "ip_instance_prefix_length" {
  default     = 16
  description = "ip instance prefix length"
}


variable "private_connection_delete_policy" {
  default     = "ABANDON"
  description = "delete policy status"
}


variable "posgres_version" {
  default     = "POSTGRES_14"
  description = "postgresql version"
}


variable "postgres_tier" {
  default     = "db-f1-micro"
  description = "postgres instance tier"
}


variable "password_length" {
  default     = 16
  description = "length of the password"
}


variable "vm_instance_type" {
  default     = "pd-balanced"
  description = "type of the vm instance"
}

variable "vm_instance_name" {
  default     = "vm-instance"
  description = "name of the vm instance"
}


variable "vm_instance_machinetype" {
  default     = "e2-standard-2"
  description = "vm instance machine type"
}


variable "vm_instance_size" {
  default     = 100
  description = "vm instance machine size"
}

variable "postgres_firewall_name" {

}

variable "postgres_firewall_direction" {

}

variable "postgres_firewall_deny_protocol" {

}


variable "postgres_firewall_deny_ports" {

}


variable "postgres_firewall_allow_protocol" {

}


variable "postgres_firewall_allow_ports" {

}

variable "postgres_firewall_priority" {

}


variable "postgres_firewall_target_tags" {

}


variable "webapp_domain_name" {
  description = "Webapp domain name description"
}

variable "webapp_dnsrecord_type" {
  description = "Type of dns record to update"
}

variable "webapp_dns_ttl" {
  description = "Time to Live of webapp domain"
}

variable "managed_zone_webapp" {
  description = "Managed cloud dns zone for webapp"
}

variable "vpc_connector_name" {
  description = "vpc connector name"
}

variable "vpc_connector_cidr" {
  description = "vpc connector cidr"
}

variable "maingun_api_key" {
  description = "api key for mailgun"
}

variable "entryPointTrigger" {
  description = "entry point for the cloud function"
}


variable "available_memory" {
  description = "available memory for the cloud function"
}


variable "nodejs_version" {
  description = "nodejs version for cloud function"
}

variable "bucket_name" {
  description = "bucket name"
}

variable "bucket_region" {
  description = "region of bucket"
}

variable "bucket_object_name" {
  description = "bucket object name"
}

variable "serverless_code_path" {
  description = "location of the serverless code"
}

variable "cloud_function_name" {
  description = "name of the cloud function"
}


variable "pubsub_topic_name" {
  description = "name of the pubsub topic"
}

variable "pubsub_subscription_name" {
  description = "name of the pubsub subscription"
}

variable "subscription_ttl" {
  description = "ttl value of the subscription"
}

variable "ack_deadline_seconds" {
  
}

variable "autoscaler_min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 3
}

variable "autoscaler_max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 6
}

variable "autoscaler_cool_down_period_sec" {
  description = "Cooldown period for autoscaler"
  type        = number
  default     = 60
}

variable "autoscaler_cpu_utilization_target" {
  description = "Target CPU utilization for autoscaler"
  type        = number
  default     = 0.15
}


variable "network_prefix" {
  description = "load balancer name"
}


variable "ssl_certificate_name" {
  description = "ssl certificate name"
}

variable "ssl_domain" {
  description = "domain for ssl config"
}

variable "ssl_description" {
  description = "Managed SSl certificate for abhaydee.com"
}

variable "ssl_policy_name" {
  description = "name of the ssl policy"
}

variable "ssl_profile" {
  description = "profile for ssl config"
}

variable "target_tags" {
  description = "target tags for resources"
}

variable "load-balancer-ingress" {
  description = "load balance ingress name"
}


variable "ingress_direction" {
  description = "ingress direction"
}


variable "health_check_name" {
  description = "health checker name"
}


variable "health_check_interval_sec" {
  description = "Check interval second for health checker"
}

variable "health_check_timeout_sec" {
  description = "timeout second for health check"
}

variable "unhealthy_threshold" {
  description = "unhealthy threshold value"
}

variable "healthy_threshold" {
  description = "healthy threshold value"
}

variable "url_map_name" {
  description = "url map name"
}

variable "https_proxy" {
  description = "proxy name for https"
}

variable "forwarding_rule_name" {
  description = "forwarding rule name "
}

variable "forwarding_rule_protocol" {
  description = "forwarding rule protocol"
}

variable "load_balancing_scheme" {
  description = "load balancing scheme"
}

variable "port_range" {
  description = "port range for forwarding to https"
}

variable "global_address_name" {
  description = "global address name"
}

variable "regional_instance_group_manager_name" {
  description = "regional instance group manager name"
}


variable "distributed_policy_zones" {
  description = "zones for distribution"
}


variable "base_instance_name" {
  description = "base_instance_name"
}

variable "backend_service_name" {
  description = "backend service name"
}


variable "regional_instance_template_name" {
  description = "regional instance template name"
}

variable "instance_template_disk_type" {
  description = "disk type"
}

variable "instance_template_disk_size" {
  description = "disk size"
}

variable "terraform_key_ring_name" {
  
}

variable "vm_crypto_key" {
  
}

variable "rotation_period" {
  
}

variable "cloudsql-crypto-key" {
  
}

variable "bucket-crypto-key" {
  
}