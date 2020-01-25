resource "aws_vpc" "main" {
  cidr_block            = var.vpc_cidr_block
  enable_dns_hostnames  = true
  enable_dns_support    = true

  tags = {
    Name        = "processor-${var.environment}"
    environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "processor-${var.environment}.gw"
    environment = var.environment
  }
}

resource "aws_route_table" "internet" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-internet"
    environment = var.environment
  }
}

resource "aws_subnet" "dmz" {
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, 10 + count.index)
  vpc_id            = aws_vpc.main.id

  count             = length(data.aws_availability_zones.available.names)

  tags = {
    Name        = "${var.environment}-dmz${count.index}"
    purpose     = "dmz"
    environment = var.environment
  }
}

resource "aws_route_table_association" "dmz" {
  route_table_id = aws_route_table.internet.id
  subnet_id      = aws_subnet.dmz[count.index].id

  count          = length(aws_subnet.dmz[*])
}


