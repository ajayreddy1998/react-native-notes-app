provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "my-terraform-backend-bucket"
    key            = "react-notes-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

data "aws_key_pair" "existing_key" {
  key_name = "my-existing-keypair"  
}

resource "aws_instance" "react_notes_app" {
  ami                    = "ami-0abcdef1234567890" 
  instance_type          = "t3.micro"
  key_name               = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "ReactNotesApp-EC2"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "curl -fsSL https://deb.nodesource.com/setup_18.x | bash -",
      "apt-get install -y nodejs",
      "npm install pm2 -g",
      "git clone https://github.com/your-repo/react-native-notes-app.git /home/ubuntu/app",
      "cd /home/ubuntu/app",
      "npm install",
      "pm2 start npm -- start"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/my-existing-keypair.pem")
      host        = self.public_ip
    }
  }
}

resource "aws_security_group" "sg" {
  name        = "react_notes_sg"
  description = "Allow HTTP and SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
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

output "instance_ip" {
  value = aws_instance.react_notes_app.public_ip
}
