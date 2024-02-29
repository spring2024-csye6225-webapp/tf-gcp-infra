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
  default     = "n1-standard-1"
  description = "vm instance machine type"
}


variable "vm_instance_size" {
  default     = 100
  description = "vm instance machine size"
}
