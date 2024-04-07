terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# Configure the AWS Provider
provider "aws" {
  region = "$REGION"
  access_key = "$ACCESS_KEY"
  secret_key = "$SECRET_KEY"
}

# Create a VPC
resource "aws_vpc" "NewLab_VPC" {
  cidr_block = "10.0.0.0/16" 
  tags = {
    Name = "NewLab"
  }
} 
#creating subnet 1
resource "aws_subnet" "Subnet1" {
  vpc_id     = aws_vpc.NewLab_VPC.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Subnet1"
  }
}

#creating subnet 2
resource "aws_subnet" "Subnet2" {
  vpc_id     = aws_vpc.NewLab_VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Subnet2"
  }
}
#creating internet gateway

resource "aws_internet_gateway" "IGW_NewLab" {
  vpc_id = aws_vpc.NewLab_VPC.id
  tags = {
    name   = "IGW_NewLab"
    
  }
}
#creating route table
resource "aws_route_table" "route_table_NewLab" {
  vpc_id = aws_vpc.NewLab_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW_NewLab.id
  }

  tags = {
    Name = "route_table_NewLab"
  }
}
#creating route table association for subnet1
resource "aws_route_table_association" "RTA1" {
  subnet_id      = aws_subnet.Subnet1.id
  route_table_id = aws_route_table.route_table_NewLab.id
}

#creating route table association for subnet2
resource "aws_route_table_association" "RTA2" {
  subnet_id      = aws_subnet.Subnet2.id
  route_table_id = aws_route_table.route_table_NewLab.id
}

#Create Security group for Instance1
resource "aws_security_group" "SG1" {
  name        = "SG1"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.NewLab_VPC.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG1"
  }
}


# #Create Security group for Instance2
# resource "aws_security_group" "SG2" {
#   name        = "SG2"
#   description = "Allow HTTP inbound traffic"
#   vpc_id      = aws_vpc.NewLab_VPC.id

#   ingress {
#     description      = "HTTP from VPC"
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "SG2"
#   }
# }

#create security group3 for instance3
resource "aws_security_group" "SG3" {
  name        = "SG3"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.NewLab_VPC.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

# ingress {
#     description      = "SSH from VPC"
#     from_port        = 22
#     to_port          = 22
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#   }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG3"
  }
}

#create EC2 instance for Subnet1
resource "aws_instance" "NewLabInstance1" {
  ami           = "ami-0230bd60aa48260c6"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.Subnet1.id 
  associate_public_ip_address = true
  security_groups = [aws_security_group.SG1.id]
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
  systemctl start httpd
  systemctl enable httpd
  echo "This server $(hostname -f)" > /var/www/html/index.html
  EOF

  tags = {
    Name = "NewLabInstance-1"
  }
}


# #create EC2 instance for Subnet2
# resource "aws_instance" "NewLabInstance2" {
#   ami           = "ami-0230bd60aa48260c6"
#   instance_type = "t2.micro"
#   subnet_id = aws_subnet.Subnet2.id
#   associate_public_ip_address = true 
#   security_groups = [aws_security_group.SG2.id] 
#   user_data = <<-EOF
#   #!/bin/bash
# yum update -y
# yum install -y httpd
# systemctl start httpd
# systemctl enable httpd
# echo "This server $(hostname -f)" > /var/www/html/index.html
# EOF

#   tags = {
#     Name = "NewLabInstance-2"
#   }
# }

# create new EC2Instance3 for Subnet2
resource "aws_instance" "NewLabInstance3" {
  ami           = "ami-0230bd60aa48260c6"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.Subnet2.id 
  associate_public_ip_address = true
  security_groups = [aws_security_group.SG3.id]
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
  systemctl start httpd
  systemctl enable httpd
  echo "This server $(hostname -f)" > /var/www/html/index.html
  EOF

  tags = {
    Name = "NewLabInstance-3"
  }
}

#create target group
resource "aws_lb_target_group" "TG1" {
  name        = "tf-TG1-lb-alb-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.NewLab_VPC.id
  health_check {
    enabled = true 
    healthy_threshold = 3 
    interval = 10
    matcher = 200 
    path = "/" 
    port = "traffic-port"
    protocol = "HTTP" 
    timeout = 6
    unhealthy_threshold = 3
  }
}

#Attach target group to Instance 1
resource "aws_lb_target_group_attachment" "Attach1" {
  target_group_arn = aws_lb_target_group.TG1.arn
  target_id        = aws_instance.NewLabInstance1.id
  port             = 80
}

# #Attach target group to Instance 2
# resource "aws_lb_target_group_attachment" "Attach2" {
#   target_group_arn = aws_lb_target_group.TG1.arn
#   target_id        = aws_instance.NewLabInstance2.id
#   port             = 80
# }

#Attach target group to Instance 3
resource "aws_lb_target_group_attachment" "Attach3" {
  target_group_arn = aws_lb_target_group.TG1.arn
  target_id        = aws_instance.NewLabInstance3.id
  port             = 80
}

#Create application load balancer
resource "aws_lb" "NewLabLB" {
  name               = "NewLabLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SG1.id, 
 aws_security_group.SG3.id]
  subnets            = [aws_subnet.Subnet1.id, aws_subnet.Subnet2.id]
}


#Create listener on port 80
resource "aws_lb_listener" "NewLabListener" {
  load_balancer_arn = aws_lb.NewLabLB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG1.arn
  }
}

#Creating Public Zone
resource "aws_route53_zone" "NewLabZone" {
  name = "chiomathegirl.co.uk"
}

#Create record for Route 53
resource "aws_route53_record" "www" {
  zone_id = "Z012659812VXOVC2AQIGR"
  name    = "chiomathegirl.co.uk"
  type    = "A"
  alias {
    name                   = aws_lb.NewLabLB.dns_name
    zone_id                = aws_lb.NewLabLB.zone_id
    evaluate_target_health = true
  }
}