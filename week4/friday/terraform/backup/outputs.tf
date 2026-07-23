# Server IP outputs for Ansible inventory
output "api_server_ip" {
  description = "Public IP of the API server"
  value       = module.api_server.server_ip
}

output "payments_server_ip" {
  description = "Public IP of the Payments server"
  value       = module.payments_server.server_ip
}

output "logs_server_ip" {
  description = "Public IP of the Logs server"
  value       = module.logs_server.server_ip
}

# SSH command outputs for easy access
output "ssh_api_cmd" {
  description = "SSH command for API server"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.api_server.server_ip}"
}

output "ssh_payments_cmd" {
  description = "SSH command for Payments server"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.payments_server.server_ip}"
}

output "ssh_logs_cmd" {
  description = "SSH command for Logs server"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.logs_server.server_ip}"
}

# For Terraform plan validation
output "server_ips" {
  description = "Map of all server IPs"
  value = {
    api      = module.api_server.server_ip
    payments = module.payments_server.server_ip
    logs     = module.logs_server.server_ip
  }
}
