variable "region" {
      default = "us-east-1"
}

variable "public_subnet_cidr" {
      default = "10.0.1.0/24"
}

variable "ssh_key"{
    description = "Each Key is generated for each instance provisioned"
    type = string
    default = "terrec2"
}