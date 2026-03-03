provider "aws" {
  region = "us-east-1"
}
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_instance" "ansible" {
    ami                     = "ami-0030e4319cbf4dbf2"
    instance_type           = "t3.micro"
    key_name                = "taxiapp"
    vpc_security_group_ids  = [aws_security_group.demo-sg.id]
    //subnet_id               = "subnet-077471d3c705ea769"
    tags                    = {
        Name      = "ansible"
    }
}
    


resource "aws_instance" "jenkins_master" {
  ami                        = "ami-0030e4319cbf4dbf2"
  instance_type              = "c7i-flex.large"
  key_name                   = "taxiapp"
  vpc_security_group_ids     = [aws_security_group.demo-sg.id]
  
  tags                       = {
    Name = "jenkins-master"
  }
  

}

resource "aws_instance" "jenkins_slave" {
  ami                        = "ami-0030e4319cbf4dbf2"
  instance_type              = "c7i-flex.large"
  key_name                   = "taxiapp"
  vpc_security_group_ids     = [aws_security_group.demo-sg.id]
  
  tags                       = {
    Name = "jenkins-slave"
  }
  
}


resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "SSH Access"

  
  ingress {
    description      = "SHH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
    description      = "Jenkins port"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
    description      = "Container  port"
    from_port        = 8000
    to_port          = 8000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
    description      = "https  port"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
    description      = "http  port"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
    description      = "Prometheus  port"
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh-port"

  }
}
