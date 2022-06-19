terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-southeast-1"
}

resource "aws_security_group" "tf_security" {
    name = "tf-security"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "tf_gitea_instance" {
  ami             = "ami-0c802847a7dd848c0"
  instance_type   = "t2.micro"
  key_name        = "ec2_user"
  security_groups = ["tf-security"] 

  tags = {
    Name = "tf-gitea"
  }

  connection {
    user = "ec2-user"
    private_key = "${file("./ec2-user.pem")}"
    host = self.public_ip
  }

  provisioner "file" {
    source = "./docker-compose.yml"
    destination = "/home/ec2-user/docker-compose.yml"
  } 

  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo /usr/local/bin/docker-compose -f /home/ec2-user/docker-compose.yml up -d",
    ]
  }

}


resource "aws_lb_target_group" "tf_lb_tg_gitea" {
  name        = "tf-lb-tg-gitea"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "vpc-0bdf55ff403d7ce74"
}

resource "aws_lb_target_group_attachment" "tf_reg_instance" {
  target_group_arn = aws_lb_target_group.tf_lb_tg_gitea.arn
  target_id        = aws_instance.tf_gitea_instance.id
  port             = 80
}

resource "aws_lb" "tf_lb_gitea" {
  name               = "tf-lb-gitea"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf_security.id]
  subnets            = ["subnet-0cf43bf8f4d946a0b", "subnet-0fe1092f53c72b91d", "subnet-088d5ffd85b26b01b"]
}

resource "aws_lb_listener" "tf_lb_listener_gitea" {
  load_balancer_arn = aws_lb.tf_lb_gitea.arn
  #port              = "80"
  #protocol          = "HTTP"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-southeast-1:883219204833:certificate/bd1e11b8-28ad-4a1b-864a-31deeae7b483"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf_lb_tg_gitea.arn
  }
}

