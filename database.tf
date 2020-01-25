resource "aws_subnet" "db" {
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, 40 + count.index)
  vpc_id            = aws_vpc.main.id

  count             = length(data.aws_availability_zones.available.names)

  tags = {
    Name        = "${var.environment}-db${count.index}"
    environment = var.environment
    purpose     = "db"
  }
}

resource "aws_db_subnet_group" "db" {
  name       = "db"
  subnet_ids = aws_subnet.db[*].id

  tags = {
    Name        = "${var.environment}-db"
    environment = var.environment
    purpose     = "db"
  }
}

resource "aws_security_group" "db" {
  vpc_id = aws_vpc.main.id

  ingress {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = [for workernet in aws_subnet.worker[*]: workernet.cidr_block]
  }

  ingress {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = [for dmznet in aws_subnet.dmz[*]: dmznet.cidr_block]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
      Name        = "${var.environment}-db"
      environment = var.environment
      purpose     = "db"
  }
}

resource "aws_db_instance" "db" {
  allocated_storage      = var.db_storage
  db_subnet_group_name   = aws_db_subnet_group.db.name
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.${var.db_instance_size}"
  name                   = "processor${var.environment}"
  multi_az               = true
  username               = var.db_user
  password               = var.db_password
  skip_final_snapshot    = true
  parameter_group_name   = "default.mysql5.7"
  vpc_security_group_ids = [aws_security_group.db.id]
}