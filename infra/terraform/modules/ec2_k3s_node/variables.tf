variable "name" {
  type        = string
  description = "Base name for resources, e.g. omk-ec2-lab"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "ssh_keypair_name" {
  type        = string
  description = "Existing AWS EC2 Key Pair name to attach to the instance"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH to the instance (e.g. your home public IP /32)."
  default     = "0.0.0.0/0"
}

variable "tags" {
  type        = map(string)
  description = "Extra tags to apply"
  default     = {}
}
