resource "aws_subnet" "mgmt" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, 2)
  vpc_id            = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-mgmt"
    purpose     = "management"
    environment = var.environment
  }
}

resource "aws_route_table_association" "mgmt" {
  route_table_id = aws_route_table.internet.id
  subnet_id      = aws_subnet.mgmt.id
}

module "bastion" {
  source            = "github.com/jetbrains-infra/terraform-aws-bastion-host"

  allowed_hosts     = ["0.0.0.0/0"]
  disk_size         = 10
  instance_type     = "t2.micro"
  internal_networks = [var.vpc_cidr_block]
  project           = "${var.environment}-processor"
  ssh_key           = "processor"
  subnet_id         = aws_subnet.mgmt.id
}

resource "aws_security_group" "management" {
  vpc_id = aws_vpc.main.id

    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${module.bastion.private_ip}/32"]
    }

    tags = {
      Name        = "${var.environment}-management"
      environment = var.environment
      purpose     = "management"
    }
}