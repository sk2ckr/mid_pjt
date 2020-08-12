#
#
# provider creation
#
#
provider "aws" {
  region  = var.region
}

#
#
# vpc creation
#
#
resource "aws_vpc" "vpc1" {
  cidr_block       = var.vpc1-cidr

  enable_dns_hostnames = true
  enable_dns_support =true
  instance_tenancy ="default"
  tags = {
    Name = "${var.prefix}-vpc1"
  }
}

resource "aws_vpc" "vpc2" {
  cidr_block       = var.vpc2-cidr

  enable_dns_hostnames = true
  enable_dns_support =true
  instance_tenancy ="default"
  tags = {
    Name = "${var.prefix}-vpc2"
  }
}

#
#
# subnet creation
#
#
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.vpc1.id
  availability_zone = var.az-1a
  cidr_block        = var.subnet1a-cidr

  tags  = {
    Name = "${var.prefix}-public-1a"
  }
}

resource "aws_subnet" "public_1b" {
  vpc_id            = aws_vpc.vpc1.id
  availability_zone = var.az-1b
  cidr_block        = var.subnet1b-cidr

  tags  = {
    Name = "${var.prefix}-public_1b"
  }
}

resource "aws_subnet" "public_2a" {
  vpc_id            = aws_vpc.vpc2.id
  availability_zone = var.az-2a
  cidr_block        = var.subnet2a-cidr

  tags  = {
    Name = "${var.prefix}-public-2a"
  }
}

resource "aws_subnet" "public_2b" {
  vpc_id            = aws_vpc.vpc2.id
  availability_zone = var.az-2b
  cidr_block        = var.subnet2b-cidr

  tags  = {
    Name = "${var.prefix}-public_2b"
  }
}

#
#
# internet gateway creation
#
#
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "${var.prefix}-igw1"
  }
}

resource "aws_internet_gateway" "igw2" {
  vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "${var.prefix}-igw2"
  }
}

#
#
# routing table creation
#
#
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }

  tags = {
    Name = "${var.prefix}-rt1"
  }
}

resource "aws_route_table_association" "rt1_public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table_association" "rt1_public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw2.id
  }

  tags = {
    Name = "${var.prefix}-rt2"
  }
}

resource "aws_route_table_association" "rt2_public_2a" {
  subnet_id      = aws_subnet.public_2a.id
  route_table_id = aws_route_table.rt2.id
}

resource "aws_route_table_association" "rt2_public_2b" {
  subnet_id      = aws_subnet.public_2b.id
  route_table_id = aws_route_table.rt2.id
}

#
#
# default security group creation for alb
#
#
resource "aws_default_security_group" "sg1_default" {
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-sg1_default"
  }
}

resource "aws_default_security_group" "sg2_default" {
  vpc_id = aws_vpc.vpc2.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-sg2_default"
  }
}

#
#
# s3 creation for alb
#
#
resource "aws_s3_bucket" "alb1_s3" {
  bucket = "${var.prefix}-alb1-log.com"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.alb_account_id}:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.prefix}-alb1-log.com/*"
    }
  ]
}
  EOF

  lifecycle_rule {
    id      = "log_lifecycle"
    prefix  = ""
    enabled = true

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket" "alb2_s3" {
  bucket = "${var.prefix}-alb2-log.com"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.alb_account_id}:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.prefix}-alb2-log.com/*"
    }
  ]
}
  EOF

  lifecycle_rule {
    id      = "log_lifecycle"
    prefix  = ""
    enabled = true

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

#
#
# alb, alb target group, alb listener creation
#
#
resource "aws_alb" "alb1" {
    name = "${var.prefix}-alb1"
    internal = false
    security_groups = [aws_security_group.sg1_ec2.id]
    subnets = [
        aws_subnet.public_1a.id,
        aws_subnet.public_1b.id
    ]
    access_logs {
        bucket = aws_s3_bucket.alb1_s3.id
        prefix = "frontend-alb1"
        enabled = true
    }
    tags = {
        Name = "${var.prefix}-ALB1"
    }
    lifecycle { create_before_destroy = true }
}

resource "aws_alb_target_group" "frontend1" {
    name = "frontend1-target-group"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.vpc1.id
    health_check {
        interval = 30
        path = "/"
        healthy_threshold = 3
        unhealthy_threshold = 3
    }
    tags = { Name = "${var.prefix}-Frontend1 Target Group" }
}

resource "aws_alb_listener" "http1" {
    load_balancer_arn = aws_alb.alb1.arn
    port = "80"
    protocol = "HTTP"
    default_action {
        target_group_arn = aws_alb_target_group.frontend1.arn
        type = "forward"
    }
}

resource "aws_alb" "alb2" {
    name = "${var.prefix}-alb2"
    internal = false
    security_groups = [aws_security_group.sg2_ec2.id]
    subnets = [
        aws_subnet.public_2a.id,
        aws_subnet.public_2b.id
    ]
    access_logs {
        bucket = aws_s3_bucket.alb2_s3.id
        prefix = "frontend-alb2"
        enabled = true
    }
    tags = {
        Name = "${var.prefix}-ALB2"
    }
    lifecycle { create_before_destroy = true }
}

resource "aws_alb_target_group" "frontend2" {
    name = "frontend2-target-group"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.vpc2.id
    health_check {
        interval = 30
        path = "/"
        healthy_threshold = 3
        unhealthy_threshold = 3
    }
    tags = { Name = "${var.prefix}-Frontend2 Target Group" }
}

resource "aws_alb_listener" "http2" {
    load_balancer_arn = aws_alb.alb2.arn
    port = "80"
    protocol = "HTTP"
    default_action {
        target_group_arn = aws_alb_target_group.frontend2.arn
        type = "forward"
    }
}

#
#
# ec2 security group creation
#
#
resource "aws_security_group" "sg1_ec2" {
  name        = "allow_http_ssh"
  description = "Allow HTTP/SSH inbound connections"
  vpc_id = aws_vpc.vpc1.id

  //allow http 80 port from alb
  ingress { 
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //allow ssh 22 port from my_ip(cloud9)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cloud9-cidr]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP/SSH Security Group"
  }
}

resource "aws_security_group" "sg2_ec2" {
  name        = "allow_http_ssh"
  description = "Allow HTTP/SSH inbound connections"
  vpc_id = aws_vpc.vpc2.id

  //allow http 80 port from alb
  ingress { 
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //allow ssh 22 port from my_ip(cloud9)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cloud9-cidr]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP/SSH Security Group"
  }
}

#
#
# ec2 autoscaling configuration
#
#
resource "aws_launch_configuration" "web1" {
  name_prefix = "skuser22-autoscaling-web1-"

  image_id = var.amazon_linux
  instance_type = "t2.micro"
  key_name = var.keyname
  security_groups = [
    "${aws_security_group.sg1_ec2.id}",
    "${aws_default_security_group.sg1_default.id}",
  ]
  associate_public_ip_address = true
    
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "web2" {
  name_prefix = "skuser22-autoscaling-web2-"

  image_id = var.amazon_linux
  instance_type = "t2.micro"
  key_name = var.keyname
  security_groups = [
    "${aws_security_group.sg2_ec2.id}",
    "${aws_default_security_group.sg2_default.id}",
  ]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

#
#
# autoscaling group creation
#
#
resource "aws_autoscaling_group" "web1" {
  name = "${aws_launch_configuration.web1.name}-asg"

  min_size             = 1
  desired_capacity     = 2
  max_size             = 4

  health_check_type    = "ELB"
  target_group_arns   = [aws_alb_target_group.frontend1.arn]

  launch_configuration = aws_launch_configuration.web1.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity="1Minute"

  vpc_zone_identifier  = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1b.id
  ]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix}-web1-autoscaling"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg1-attachment" {
  autoscaling_group_name = aws_autoscaling_group.web1.id
  alb_target_group_arn   = aws_alb_target_group.frontend1.arn
}

resource "aws_autoscaling_group" "web2" {
  name = "${aws_launch_configuration.web2.name}-asg"

  min_size             = 1
  desired_capacity     = 2
  max_size             = 4

  health_check_type    = "ELB"
  target_group_arns   = [aws_alb_target_group.frontend2.arn]

  launch_configuration = aws_launch_configuration.web2.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity="1Minute"

  vpc_zone_identifier  = [
    aws_subnet.public_2a.id,
    aws_subnet.public_2b.id
  ]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix}-web2-autoscaling"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg2-attachment" {
  autoscaling_group_name = aws_autoscaling_group.web2.id
  alb_target_group_arn   = aws_alb_target_group.frontend2.arn
}

#
#
# autoscaling policy (up)
#
#

resource "aws_autoscaling_policy" "web1_policy_up" {
  name = "web1_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 10
  autoscaling_group_name = aws_autoscaling_group.web1.name
}

resource "aws_cloudwatch_metric_alarm" "web1_cpu_alarm_up" {
  alarm_name = "web1_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "20"

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [aws_autoscaling_policy.web1_policy_up.arn]
}


resource "aws_autoscaling_policy" "web2_policy_up" {
  name = "web2_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 10
  autoscaling_group_name = aws_autoscaling_group.web2.name
}

resource "aws_cloudwatch_metric_alarm" "web2_cpu_alarm_up" {
  alarm_name = "web2_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "20"

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [aws_autoscaling_policy.web2_policy_up.arn]
}

#
#
# autoscaling polity (down)
#
#

resource "aws_autoscaling_policy" "web1_policy_down" {
  name = "web1_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 10
  autoscaling_group_name = aws_autoscaling_group.web1.name
}

resource "aws_cloudwatch_metric_alarm" "web1_cpu_alarm_down" {
  alarm_name = "web1_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = ["${aws_autoscaling_policy.web1_policy_down.arn}"]
}

resource "aws_autoscaling_policy" "web2_policy_down" {
  name = "web2_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 10
  autoscaling_group_name = aws_autoscaling_group.web2.name
}

resource "aws_cloudwatch_metric_alarm" "web2_cpu_alarm_down" {
  alarm_name = "web2_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = ["${aws_autoscaling_policy.web2_policy_down.arn}"]
}


#
#
# vpc peering connection creation
#
#

resource "aws_vpc_peering_connection" "vpc_peer" {
  peer_vpc_id   = aws_vpc.vpc2.id
  vpc_id        = aws_vpc.vpc1.id
  auto_accept   = true
  
  tags = {
    Name = "${var.prefix} VPC Peering between vpc1 and vpc2"
  }
}

resource "aws_route" "vpc1_route" {
  route_table_id            = aws_route_table.rt1.id
  destination_cidr_block    = var.vpc2-cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peer.id
}

resource "aws_route" "vpc2_route" {
  route_table_id            = aws_route_table.rt2.id
  destination_cidr_block    = var.vpc1-cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peer.id
}

resource "aws_security_group_rule" "sg1_rule" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [aws_vpc.vpc2.cidr_block]
  security_group_id = aws_security_group.sg1_ec2.id
}

resource "aws_security_group_rule" "sg2_rule" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [aws_vpc.vpc1.cidr_block]
  security_group_id = aws_security_group.sg2_ec2.id
}

#
#
# endpoint for s3 creation
#
#

# resource "aws_vpc_endpoint" "endpoint1" {
#   vpc_id       = aws_vpc.vpc1.id
#   service_name = "com.amazonaws.${var.region}.s3"
  
#   tags = {
#     Name = "${var.prefix} VPC1 endpoint"
#   }
# }

# resource "aws_vpc_endpoint" "endpoint2" {
#   vpc_id       = aws_vpc.vpc2.id
#   service_name = "com.amazonaws.${var.region}.s3"
  
#   tags = {
#     Name = "${var.prefix} VPC2 endpoint"
#   }
# }
