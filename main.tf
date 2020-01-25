provider "aws" {
    version = "~> 2.0"
    region  = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}