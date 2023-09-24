resource "aws_vpc" "demo-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.demo-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    name = "public-subnet"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id = aws_vpc.demo-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    name = "public-subnet2"
  }
}

resource "aws_internet_gateway" "vpc-igw" {
  vpc_id = aws_vpc.demo-vpc.id
}

resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.demo-vpc.id

  subnet_ids = [ aws_subnet.public_subnet.id, aws_subnet.public_subnet2.id ]

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 200
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    rule_no    = 300
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    rule_no    = 200
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 300
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  tags = {
    Name = "demo-nacl"
  }
}

resource "aws_security_group" "swbserver-sg" {
  name = "WebDMZ"
  description = "Secruity group for my web server"
  vpc_id = aws_vpc.demo-vpc.id

  ingress {
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }

  ingress {
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }
}

resource "aws_security_group" "lb-sg" {
  name = "LoadBalancerSg"
  description = "Secruity group for load balancer"
  vpc_id = aws_vpc.demo-vpc.id

  ingress {
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }
}

resource "aws_instance" "web-server1" {
  ami = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [ "${aws_security_group.swbserver-sg.id}" ]
  subnet_id = aws_subnet.public_subnet.id
  key_name = "provider-rsa"
  user_data = "${file("userdata.sh")}"
}

resource "aws_instance" "web-server2" {
  ami = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [ "${aws_security_group.swbserver-sg.id}" ]
  subnet_id = aws_subnet.public_subnet2.id
  key_name = "provider-rsa"
  user_data = "${file("userdata.sh")}"
}

resource "aws_lb" "web-lb" {
  name = "web-lb"
  internal = "false"
  load_balancer_type = "application"
  subnets = ["${aws_subnet.public_subnet.id}", "${aws_subnet.public_subnet2.id}"]
  security_groups = ["${aws_security_group.lb-sg.id}"]
}

resource "aws_lb_listener" "web-lb-listener" {
  load_balancer_arn = aws_lb.web-lb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web-tg.id
  }
}

resource "aws_lb_target_group" "web-tg" {
  name = "web-tg"
  protocol = "HTTP"
  port = "80"
  vpc_id = aws_vpc.demo-vpc.id
}

resource "aws_lb_target_group_attachment" "web-tg-attach" {
  target_group_arn = aws_lb_target_group.web-tg.arn
  target_id = aws_instance.web-server1.id
  port = "80"
}

resource "aws_lb_target_group_attachment" "web-tg-attach2" {
  target_group_arn = aws_lb_target_group.web-tg.arn
  target_id = aws_instance.web-server2.id
  port = "80"
}

resource "aws_launch_configuration" "nginx_lc" {
  name_prefix          = "nginx-lc-"
  image_id             = var.ami_id  # Replace with your desired AMI ID.
  instance_type        = var.instance_type
  security_groups = ["${aws_security_group.lb-sg.id}"]

  lifecycle {
    create_before_destroy = true
  }
  }

resource "aws_autoscaling_group" "nginx_asg" {
  name                = "nginx-asg"
  launch_configuration = aws_launch_configuration.nginx_lc.name
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = [aws_subnet.public_subnet.id, aws_subnet.public_subnet2.id]  # Replace with your subnet IDs.

  tag {
    key                 = "Name"
    value               = "nginx-instance"
    propagate_at_launch = true
  }
}