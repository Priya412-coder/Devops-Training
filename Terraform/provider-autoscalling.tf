provider "aws" {
	region = "us-east-1"
}

#creating vpc
resource "aws_vpc" "my_vpc" {
  cidr_block       = "50.20.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "TF_VPC"
  }
}

#creating 1st public subnet
resource "aws_subnet" "pubsub1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "50.20.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "TF_PubSub1"
  }
}

#creating 2nd public subnet
resource "aws_subnet" "pubsub2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "50.20.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "TF_PubSub2"
  }
}

#creating internet Gateway
resource "aws_internet_gateway" "My_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "TF_IG"
  }
}

#creating routetable
resource "aws_route_table" "Public_RT" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.My_igw.id
    }

    tags = {
        Name = "TF_Pub_RT"
    }
}

#associating route table
resource "aws_route_table_association" "Pub_RT_ass1" {
    subnet_id = aws_subnet.pubsub1.id
    route_table_id = aws_route_table.Public_RT.id
}

resource "aws_route_table_association" "Pub_RT_ass2" {
    subnet_id = aws_subnet.pubsub2.id
    route_table_id = aws_route_table.Public_RT.id
}

#creating 1st private subnet
resource "aws_subnet" "prisub1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "50.20.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "TF_PriSub1"
  }
}

#creating 2nd private subnet
resource "aws_subnet" "prisub2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "50.20.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "TF_PriSub2"
  }
}

#creating elastic IP with NAT Gateway
resource "aws_eip" "nat_gw_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.pubsub1.id

  tags = {
    Name = "TF_NAT_GAT"
  }
}

#creating routetable
resource "aws_route_table" "Private_RT" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gw.id
    }

    tags = {
        Name = "TF_Pri_RT"
    }
}

resource "aws_route_table_association" "Pri_RT_ass1" {
    subnet_id = aws_subnet.prisub1.id
    route_table_id = aws_route_table.Private_RT.id
}

resource "aws_route_table_association" "Pri_RT_ass2" {
    subnet_id = aws_subnet.prisub2.id
    route_table_id = aws_route_table.Private_RT.id
}

#creating security group for frontend server
resource "aws_security_group" "Frontend_Security" {
  name        = "TF_Front_SG"
  description = "Allow SSH inbound connections"
  vpc_id = aws_vpc.my_vpc.id

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
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TF_Front_SG"
  }
}

#creating security group for Backend server
resource "aws_security_group" "Backend_Security" {
  name        = "TF_Back_SG"
  description = "Allow outbound connections"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TF_Back_SG"
  }
}

#creting frontend instance
resource "aws_instance" "front_instance" {
  ami           = "ami-0ae2e13c705b01af5"
  instance_type = "t2.micro"
  key_name = "Priyanka : Linux"
  vpc_security_group_ids = [ aws_security_group.Frontend_Security.id ]
  subnet_id = aws_subnet.pubsub1.id
  associate_public_ip_address = true

  tags = {
    Name = "TF_Front_Server"
  }
}

#creting backend instance
resource "aws_instance" "back_instance" {
  ami           = "ami-0e88fec7162ab2b8d"
  instance_type = "t2.micro"
  key_name = "Priyanka : Linux"
  vpc_security_group_ids = [ aws_security_group.Backend_Security.id ]
  subnet_id = aws_subnet.prisub1.id
  associate_public_ip_address = false

  tags = {
    Name = "TF_Back_Server"
  }
}

#creating RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  name = "db_subnet_group"
  subnet_ids = [aws_subnet.prisub1.id,aws_subnet.prisub2.id]

  tags = {
    Name = "TF_Back_Server"
  }
}

resource "aws_db_instance" "db-instance" {
  instance_class         = "db.t2.micro"
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.0.27"
  username               = "priya"
  password               = "priyanka"
  db_name                 = "TF_db"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.Backend_Security.id]
  skip_final_snapshot    = true
}

#creating backend target group
resource "aws_lb_target_group" "TF-backend-tgt-group" {
  name     = "TF-backend-tgt-group"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

#creating backend load balancer
resource "aws_lb" "BackendLoadbalancer" {
  name               = "TF-Backend-LB"
  internal           =  true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Backend_Security.id]
  subnets            = [aws_subnet.prisub1.id, aws_subnet.prisub2.id]
  tags = {
       Name = "TF-Backend-LB"
  }
}

#Create a Listner for Backend Load balancer
resource "aws_lb_listener" "Backend-Listner-LB" {
  load_balancer_arn = aws_lb.BackendLoadbalancer.arn
  port              = "8000"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TF-backend-tgt-group.arn
  }
}

#creating launch configuration
resource "aws_launch_configuration" "TF_Back_Launch_config" {
  name          = "TF_Back_Launch_config"
  image_id      = "ami-0e88fec7162ab2b8d"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.Backend_Security.id]
}

#Create a Backend Auto Scaling Group
resource "aws_autoscaling_group" "TF-Backend-ASG" {
  name                      = "TF-Backend-ASG"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 30
  desired_capacity          = 1
  launch_configuration      = aws_launch_configuration.TF_Back_Launch_config.id
  vpc_zone_identifier       = [aws_subnet.prisub1.id, aws_subnet.prisub2.id]
  target_group_arns         = [aws_lb_target_group.TF-backend-tgt-group.id]
  tag {
    key                 = "Name"
    value               = "TF_Backend_ASG"
    propagate_at_launch = true
  }
  
}

#Create a Backend Target Policy for Auto Scaling
resource "aws_autoscaling_policy" "Backend-TargetPolicy" {
name = "Backend-TargetPolicy"
policy_type = "TargetTrackingScaling"
autoscaling_group_name = aws_autoscaling_group.TF-Backend-ASG.id
estimated_instance_warmup = 200

target_tracking_configuration {
predefined_metric_specification {
predefined_metric_type = "ASGAverageCPUUtilization"
}

    target_value = "50"
}
}

#Create a launch_configuration For Frontend
resource "aws_launch_configuration" "TF_Front_Launch_config" {
  name          = "TF_Front_Launch_config"
  image_id      = "ami-0f45637a7fa3499a0"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.Frontend_Security.id]
}

#Create a Frontend TargetGroup
resource "aws_lb_target_group" "TF-frontend-tgt-group" {
  name     = "TF-frontend-tgt-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

#Create a Frontend Loadbalancer
resource "aws_lb" "FrontendLoadbalancer" {
  name               = "TF-Frontend-LB"
  internal           =  false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Frontend_Security.id]
  subnets            = [aws_subnet.pubsub1.id, aws_subnet.pubsub2.id]
  tags = {
       Name = "TF-Frontend-LB"
  }

}

#Create a Listner for Frontend Load balancer
resource "aws_lb_listener" "Frontend-Listner-LB" {
  load_balancer_arn = aws_lb.FrontendLoadbalancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TF-frontend-tgt-group.arn
  }
}

#Create a Frontend aws_autoscaling_group 
resource "aws_autoscaling_group" "TF-Frontend-ASG" {
  name                      = "TF-Frontend-ASG"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 30
  desired_capacity          = 1
  launch_configuration      = aws_launch_configuration.TF_Front_Launch_config.id
  vpc_zone_identifier       = [aws_subnet.pubsub1.id, aws_subnet.pubsub2.id]
  target_group_arns         = [aws_lb_target_group.TF-frontend-tgt-group.id]
  tag {
    key                 = "Name"
    value               = "TF-ASG-Frontend"
    propagate_at_launch = true
  }
  
}

#Create a Frontend-TargetPolicy 
resource "aws_autoscaling_policy" "Frontend-TargetPolicy" {
name = "Frontend-TargetPolicy"
policy_type = "TargetTrackingScaling"
autoscaling_group_name = aws_autoscaling_group.TF-Frontend-ASG.id
estimated_instance_warmup = 200

target_tracking_configuration {
predefined_metric_specification {
predefined_metric_type = "ASGAverageCPUUtilization"
}

    target_value = "60"
}
}










