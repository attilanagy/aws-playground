resource "aws_subnet" "efs" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, 30)
  vpc_id            = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-efs"
    purpose     = "efs"
    environment = var.environment
  }
}

resource "aws_security_group" "efs" {
    vpc_id = aws_vpc.main.id

    ingress {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = [
        for instance in aws_instance.sftp: "${instance.private_ip}/32"
      ]
    }

    egress {
      from_port       = 0
      to_port         = 65535
      protocol        = "TCP"
      cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
      Name        = "${var.environment}-efs"
      environment = var.environment
      purpose     = "efs"
    }
}

resource "aws_efs_file_system" "sftp" {
  creation_token   = "${var.environment}-sftp"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name        = "${var.environment}-sftp"
    environment = var.environment
    purpose     = "sftp"
  }
}

resource "aws_efs_mount_target" "sftp" {
  file_system_id  = aws_efs_file_system.sftp.id
  security_groups = [aws_security_group.efs.id]
  subnet_id       = aws_subnet.efs.id
}

data "template_cloudinit_config" "sftp" {
  base64_encode = true
  
  part {
    content_type = "text/x-shellscript"
    content      = <<EOF
      #!/bin/bash

      sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.sftp.dns_name}:/ /mnt
    EOF
  }
}

resource "aws_security_group" "sftp_internet" {
    vpc_id = aws_vpc.main.id

    ingress {
      from_port   = 220
      to_port     = 220
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
      Name        = "${var.environment}-sftp"
      environment = var.environment
      purpose     = "sftp"
    }
}

resource "aws_security_group" "sftp_internal" {
    vpc_id = aws_vpc.main.id

    ingress {
      from_port   = 1220
      to_port     = 1220
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr_block]
    }

    egress {
      from_port       = 0
      to_port         = 65535
      protocol        = "TCP"
      cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
      Name        = "${var.environment}-sftp"
      environment = var.environment
      purpose     = "sftp"
    }
}

resource "aws_instance" "sftp" {
    ami                         = var.sftp_ami_id
    associate_public_ip_address = true
    instance_type               = var.sftp_instance_type
    key_name                    = var.ec2_keypair_name
    subnet_id                   = aws_subnet.dmz[count.index].id
    user_data_base64            = data.template_cloudinit_config.sftp.rendered
    vpc_security_group_ids      = [aws_security_group.management.id, aws_security_group.sftp_internet.id, aws_security_group.sftp_internal.id]

    count                       = 2

    tags = {
      Name        = "${var.environment}-sftp${count.index}"
      environment = var.environment
      purpose     = "sftp"
    }
}

resource "aws_elb" "sftp_internet" {
  instances       = aws_instance.sftp[*].id
  name            = "${var.environment}-sftp-elb-public"
  security_groups = [aws_security_group.sftp_internet.id]
  subnets         = aws_subnet.dmz[*].id

  listener {
    instance_port     = 220
    instance_protocol = "tcp"
    lb_port           = 220
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:220"
    interval            = 30
  }

  tags = {
    Name        = "${var.environment}-sftp-elb-internet"
    environment = var.environment
    purpose     = "sftp"
  }
}

resource "aws_elb" "sftp_internal" {
  instances       = aws_instance.sftp[*].id
  internal        = true
  name            = "${var.environment}-sftp-elb-private"
  security_groups = [aws_security_group.sftp_internal.id]
  subnets         = aws_subnet.dmz[*].id

  listener {
    instance_port     = 1220
    instance_protocol = "tcp"
    lb_port           = 1220
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:1220"
    interval            = 30
  }

  tags = {
    Name        = "${var.environment}-sftp-elb-internal"
    environment = var.environment
    purpose     = "sftp"
  }
}