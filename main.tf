terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.54.0"
    }
  }
}

resource "aws_vpc" "vpc" {
  cidr_block      = var.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "test-stg-vpc"
  }
}
 
resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet_a
  map_public_ip_on_launch = true
  tags = {
    Name = "test-stg-public-a"
  }
}
 
resource "aws_subnet" "public_subnet_c" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet_c
  map_public_ip_on_launch = true
  tags = {
    Name = "test-stg-public-c"
  }
}
 
resource "aws_subnet" "private_web_a" {
  cidr_block = var.private_subnet_a
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "test-stg-web-a"
  }
}
 
resource "aws_subnet" "private_web_c" {
  cidr_block = var.private_subnet_c
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "test-stg-web-c"
  }
}
 
resource "aws_subnet" "private_db_2a" {
  cidr_block = var.private_subnet_2a
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "test-stg-db-a"
  }
}
 
resource "aws_subnet" "private_db_2c" {
  cidr_block = var.private_subnet_2c
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "test-stg-db-c"
  }
}
resource "aws_security_group" "allow_ssh" {
  name        = "test-stg-sg-bastion"
  description = "Allow SSH inbound connections"
  vpc_id = aws_vpc.vpc.id
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["45.122.253.2/32"]
  }
 
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "test-stg-sg-bastion"
  }
}

resource "aws_instance" "bastion_public_a" {
  ami           = "ami-0ffac3e16de16665e"
  instance_type = "t2.micro"
  key_name = "zero one"
  vpc_security_group_ids = [ aws_security_group.allow_ssh.id ]
  subnet_id = aws_subnet.public_subnet_a.id
  associate_public_ip_address = true
  root_block_device {
    volume_size = "20"
    volume_type = "gp3"
    encrypted = true
    delete_on_termination = true
    }
  tags = {
    Name = "test-stg-bastion"
    }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
 
  tags = {
    Name = "internet-gateway"
  }
}

resource "aws_route_table" "public_subnet_a" {
  vpc_id = aws_vpc.vpc.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}
 
resource "aws_instance" "bastion_private_web_a" {
  ami           = "ami-0ffac3e16de16665e" 
  instance_type = "t2.micro"
  key_name = "zero one"
  subnet_id = aws_subnet.private_web_a.id
  vpc_security_group_ids = [ aws_security_group.allow_ssh.id ]
  associate_public_ip_address = true

# root disk
  root_block_device {
    volume_size = "10"
    volume_type = "gp3"
    encrypted = true
    delete_on_termination = true
  }

  tags = {
    Name = "test-stg-web-1"    
  }
}

resource "aws_instance" "bastion_private_web_c" {
  ami           = "ami-0ffac3e16de16665e"
  instance_type = "t2.micro"
  key_name = "zero one"
  subnet_id = aws_subnet.private_web_c.id
  vpc_security_group_ids = [ aws_security_group.allow_ssh.id ]
  associate_public_ip_address = true

# root disk
  root_block_device {
    volume_size = "20"
    volume_type = "gp3"
    encrypted = true
    delete_on_termination = true
  }

  tags = {
    Name = "test-stg-web-n"
  }
}


resource "aws_elb" "web_elb" {
  name = "web-elb"
   security_groups = [
    "${aws_security_group.allow_ssh.id}"
  ]  

  subnets = [
    "${aws_subnet.private_web_a.id}",
    "${aws_subnet.private_web_c.id}"
  ]
  cross_zone_load_balancing   = true
  
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
}

resource "aws_launch_configuration" "web" {
  name_prefix = "web"
  image_id = "ami-0ffac3e16de16665e" 
  instance_type = "t2.micro"
  key_name = "zero one"
  associate_public_ip_address = true
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name = "zero-one"
 
  desired_capacity     = 1
  min_size             = 1
  max_size             = 3
  
  health_check_type    = "ELB"
  load_balancers = [
    "${aws_elb.web_elb.id}"
  ]
  launch_configuration = "${aws_launch_configuration.web.name}"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity = "1Minute"
  vpc_zone_identifier  = [
    "${aws_subnet.private_web_a.id}",
    "${aws_subnet.private_web_c.id}"
  ]
# Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }
tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
}

resource "aws_db_instance" "private_db_2a" {
  allocated_storage    = 20
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}
