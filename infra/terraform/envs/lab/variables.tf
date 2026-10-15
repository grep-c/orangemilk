variable "region" {
  type    = string
  default = "us-east-1"
}

variable "prefix" {
  type    = string
  default = "omk"
}

variable "env" {
  type    = string
  default = "lab"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "ssh_keypair_name" {
  type        = string
  description = "Existing AWS EC2 Key Pair name (passed from CI/CD)"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "Your public IP CIDR /32 is recommended"
  default     = "0.0.0.0/0"
}
