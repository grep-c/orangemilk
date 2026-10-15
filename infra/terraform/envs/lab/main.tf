provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = "orangemilk"
      Prefix  = var.prefix
      Env     = var.env
      Managed = "terraform"
    }
  }
}

module "k3s_node" {
  source = "../../modules/ec2_k3s_node"

  name             = "${var.prefix}-ec2-${var.env}"
  instance_type    = var.instance_type
  ssh_keypair_name = var.ssh_keypair_name
  allowed_ssh_cidr = var.allowed_ssh_cidr

  tags = {
    Component = "k3s-node"
  }
}
