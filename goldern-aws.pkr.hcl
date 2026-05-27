packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

# Source block: defines AMI filter and instance settings
source "amazon-ebs" "amazon-linux" {
  ami_name      = "golden-ami-${local.timestamp}"
  region        = var.aws_region
  instance_type = var.instance_type
  ssh_username  = var.ssh_username

  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["137112412989"]
    most_recent = true
  }
}

# Build block: only provisioners and post-processors
build {
  sources = ["source.amazon-ebs.amazon-linux"]

  provisioner "shell" {
    inline = [
      "echo 'Updating system...'",
      "sudo yum update -y",
      "echo 'Installing Docker...'",
      "sudo yum install -y docker",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "echo 'Checking SSM Agent...'",
      "sudo systemctl enable amazon-ssm-agent",
      "sudo systemctl start amazon-ssm-agent"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
