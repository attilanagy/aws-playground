resource "aws_subnet" "worker" {
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, 20 + count.index)
  vpc_id            = aws_vpc.main.id

  count             = length(data.aws_availability_zones.available.names)

  tags = {
    Name        = "${var.environment}-worker${count.index}"
    environment = var.environment
    purpose     = "worker"
  }
}

resource "aws_security_group" "worker" {
    vpc_id = aws_vpc.main.id

    ingress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
      Name        = "${var.environment}-worker"
      environment = var.environment
      purpose     = "worker"
    }
}

resource "aws_eip" "worker_nat_gateway" {
  count = length(aws_subnet.worker[*])
  vpc   = true

  tags = {
    Name        = "${var.environment}-worker${count.index}"
    environment = var.environment
    purpose     = "worker"
  }
}

resource "aws_nat_gateway" "worker" {
  allocation_id = aws_eip.worker_nat_gateway[count.index].id
  subnet_id     = aws_subnet.dmz[count.index].id

  count         = length(data.aws_availability_zones.available.names)

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name        = "${var.environment}-worker-nat${count.index}"
    environment = var.environment
    purpose     = "worker"
  }
}

resource "aws_route_table" "worker" {
  vpc_id = aws_vpc.main.id

  count  = length(aws_subnet.worker[*])

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.worker[count.index].id
  }

  tags = {
    Name        = "${var.environment}-worker-nat${count.index}"
    environment = var.environment
  }
}

resource "aws_route_table_association" "worker" {
  route_table_id = aws_route_table.worker[count.index].id
  subnet_id      = aws_subnet.worker[count.index].id

  count          = length(aws_subnet.worker[*])
}

resource "aws_launch_configuration" "worker" {
  associate_public_ip_address = false
  image_id                    = var.worker_ami_id
  instance_type               = var.worker_instance_type
  key_name                    = var.ec2_keypair_name
  name                        = "${var.environment}-worker"
  security_groups             = [aws_security_group.management.id, aws_security_group.worker.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "worker" {
  launch_configuration = aws_launch_configuration.worker.name
  min_size             = 1
  max_size             = var.worker_max_size
  vpc_zone_identifier  = aws_subnet.worker[*].id

  tag {
    key                 = "environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "purpose"
    value               = "worker"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "worker_target_tracking_policy" {
  autoscaling_group_name    = aws_autoscaling_group.worker.name
  estimated_instance_warmup = 120
  name                      = "${var.environment}-worker-target-tracking-policy"
  policy_type               = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = "60"
  }
}