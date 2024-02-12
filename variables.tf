variable "project_id" {
  description = "ID of the google cloud project"
}

variable "region" {
  description = "Region to run the project"
}


# variable "webapp_subnet_cidr" {
#   description = "CIDR address range for webapp subnet"
# }

# variable "db_subnet_cidr" {
#   description = "CIDR address range for db subnet"
# }


variable "webapp_destination_route" {
  description = "Destination range"
}

variable "webapp_route_priority" {
  description = "priority value"
}

variable "vpc_name" {
  description = "VPC network name"
}


variable "webapp_subnet_name" {
  description = "webapp subnet name"
}


variable "db_subnet_name" {
  description = "db subnet name"
}


variable "webapp_route_name" {
  description = "webapp route name"
}

variable "hop_gateway_value" {
  description = "hop gateway value"
}


variable "service_key_route" {
  description = "service key file route"
}


variable "vpc_count" {
  description = "No of VPC's that has to be created"
  type        = number
}


variable "zone" {
  description ="zone"
}

variable "image_name" { 
  description = "image name"
}
