# Server IP outputs for Ansible inventory
output "api_server_ip" {
  description = "Public IP of the API server"
  value       = data.external.multipass_ips.result.api
}

output "payments_server_ip" {
  description = "Public IP of the Payments server"
  value       = data.external.multipass_ips.result.payments
}

output "logs_server_ip" {
  description = "Public IP of the Logs server"
  value       = data.external.multipass_ips.result.logs
}

# SSH command outputs
output "ssh_api_cmd" {
  description = "SSH command for API server"
  value       = "ssh ubuntu@${data.external.multipass_ips.result.api}"
}

output "ssh_payments_cmd" {
  description = "SSH command for Payments server"
  value       = "ssh ubuntu@${data.external.multipass_ips.result.payments}"
}

output "ssh_logs_cmd" {
  description = "SSH command for Logs server"
  value       = "ssh ubuntu@${data.external.multipass_ips.result.logs}"
}

# For Terraform plan validation
output "server_ips" {
  description = "Map of all server IPs"
  value       = data.external.multipass_ips.result
}

# For the pipeline script
output "inventory_content" {
  value = <<-EOT
    [kijanikiosk]
    api ansible_host=${data.external.multipass_ips.result.api}
    payments ansible_host=${data.external.multipass_ips.result.payments}
    logs ansible_host=${data.external.multipass_ips.result.logs}
    
    [all:vars]
    ansible_user=ubuntu
    ansible_python_interpreter=/usr/bin/python3
  EOT
}
