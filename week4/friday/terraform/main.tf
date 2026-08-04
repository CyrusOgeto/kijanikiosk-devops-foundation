# Remote backend using MinIO
terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "~> 3.2"
    }
    external = {
      source = "hashicorp/external"
      version = "~> 2.3"
    }
  }
  
  backend "s3" {
    bucket                      = "kijanikiosk-tfstate"
    key                         = "terraform.tfstate"
    region                      = "us-east-1"
    endpoints = {
      s3 = "http://localhost:9000"
    }
    access_key                  = "minioadmin"
    secret_key                  = "minioadmin"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
}

# No provider configuration needed - we're not using AWS!

# Local variables for server names
locals {
  server_names = ["api", "payments", "logs"]
}

# Create Multipass VMs using null_resource with local-exec
resource "null_resource" "multipass_vms" {
  for_each = toset(local.server_names)
  
  triggers = {
    server_name = each.key
    timestamp   = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      if ! multipass list 2>/dev/null | grep -q "kijanikiosk-${each.key}"; then
        echo "Creating VM: kijanikiosk-${each.key}"
        multipass launch 22.04 --name kijanikiosk-${each.key} --cpus 2 --memory 2G --disk 10G
      else
        echo "VM kijanikiosk-${each.key} already exists"
      fi
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      echo "Destroying VM: kijanikiosk-${each.key}"
      multipass delete kijanikiosk-${each.key} 2>/dev/null || true
      multipass purge 2>/dev/null || true
    EOT
  }
}

# Get IPs from Multipass VMs
data "external" "multipass_ips" {
  depends_on = [null_resource.multipass_vms]
  
  program = ["bash", "-c", <<-EOT
    echo '{
      "api": "'$(multipass info kijanikiosk-api 2>/dev/null | grep IPv4 | awk '{print $2}')'",
      "payments": "'$(multipass info kijanikiosk-payments 2>/dev/null | grep IPv4 | awk '{print $2}')'",
      "logs": "'$(multipass info kijanikiosk-logs 2>/dev/null | grep IPv4 | awk '{print $2}')'"
    }'
  EOT
  ]
}
