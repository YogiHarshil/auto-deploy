provider "aws" {
  region = "ap-south-1"
}

# Data block to reference an existing security group
data "aws_security_group" "existing_sg" {
  # Replace with the name or ID of your existing security group
  filter {
    name   = "group-name"
    values = ["allow_ssh_http"]  # Change this to the name of your existing security group
  }
}

# Define the Security Group only if it does not exist
resource "aws_security_group" "allow_ssh_http" {
  count       = length(data.aws_security_group.existing_sg.id) > 0 ? 0 : 1
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Now define the EC2 instance
resource "aws_instance" "nginx_server" {
  ami           = "ami-00bb6a80f01f03502" 
  instance_type = "t2.micro"
  key_name      = "my-key"
  
  # Use the existing security group if it exists, otherwise use the newly created one
  vpc_security_group_ids = [
    length(data.aws_security_group.existing_sg.id) > 0 ? data.aws_security_group.existing_sg.id : aws_security_group.allow_ssh_http[0].id
  ]

  tags = {
    Name = "nginx-server"
  }

  # Generate Ansible Inventory File
  provisioner "local-exec" {
    command = <<EOT
      echo "[web]" > ../ansible-setup/inventory
      echo "nginx-server ansible_host=${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my-key.pem " >> ../ansible-setup/inventory
    EOT
  }
}

# Output the Public IP
output "instance_ip" {
  value = aws_instance.nginx_server.public_ip
}
