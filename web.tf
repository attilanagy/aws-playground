resource "aws_security_group" "web" {
    vpc_id = aws_vpc.main.id

    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port       = 0
      to_port         = 65535
      protocol        = "TCP"
      cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
      Name        = "${var.environment}-web"
      environment = var.environment
      purpose     = "web"
    }
}

resource "aws_lb" "web" {
  internal           = false
  load_balancer_type = "application"
  name               = "${var.environment}-web"
  security_groups    = [aws_security_group.web.id, aws_security_group.management.id]
  subnets            = aws_subnet.dmz[*].id

  tags = {
    Name = "${var.environment}-web-lb"
    environment = var.environment
    purpose     = "web"
  }
}

resource "aws_lb_target_group" "web-http" {
  name     = "${var.environment}-web-http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "web-http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-http.arn
  }
}

resource "aws_launch_configuration" "web" {
  associate_public_ip_address = true
  image_id                    = var.web_ami_id
  instance_type               = var.web_instance_type
  key_name                    = var.ec2_keypair_name
  name                        = "${var.environment}-web"
  security_groups             = [aws_security_group.management.id, aws_security_group.web.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  launch_configuration = aws_launch_configuration.web.name
  min_size             = 1
  max_size             = var.web_max_size
  target_group_arns    = [aws_lb_target_group.web-http.arn]
  vpc_zone_identifier  = aws_subnet.dmz[*].id

  tag {
    key = "environment"
    value = var.environment
    propagate_at_launch = true
  }

  tag {
    key = "purpose"
    value = "web"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web_target_tracking_policy" {
  autoscaling_group_name    = aws_autoscaling_group.web.name
  estimated_instance_warmup = 120
  name                      = "${var.environment}-web-target-tracking-policy"
  policy_type               = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = "60"
  }
}