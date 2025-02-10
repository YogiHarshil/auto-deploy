provider "aws" {
  region = "ap-south-1"
}

# Define the Security Group first
resource "aws_security_group" "allow_ssh_http" {
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
  
  # Use `vpc_security_group_ids` instead of `security_groups`
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  tags = {
    Name = "nginx-server"
  }

  # Generate Ansible Inventory File
  provisioner "local-exec" {
    command = <<EOT
      echo "[web]" > ../ansible-setup/inventory
      echo "nginx-server ansible_host=${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my-key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> ../ansible-setup/inventory
    EOT
  }
}

# Output the Public IP
output "instance_ip" {
  value = aws_instance.nginx_server.public_ip
}
