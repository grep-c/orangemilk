output "public_ip" {
  value = module.k3s_node.public_ip
}

output "public_dns" {
  value = module.k3s_node.public_dns
}

output "ssh_user" {
  value = module.k3s_node.ssh_user
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/omk_lab ubuntu@${module.k3s_node.public_ip}"
}
