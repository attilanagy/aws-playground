variable "db_instance_size" {
  type        = string
  default     = "t2.micro"
  description = "DB instance class"
}

variable "db_password" {
  type        = string
  default     = "password"
  description = "The password for the MySQL database"
}

variable "db_user" {
  type        = string
  default     = "user"
  description = "The user for MySQL database"
}

variable "db_storage" {
  type        = string
  default     = 10
  description = "The storage allocated to the MySQL database"
}

variable "environment" {
  type        = string
  description = "The name of the enironment"
}

variable "ec2_keypair_name" {
  type        = string
  default     = "processor"
  description = "The EC2 SSH keypair name"
}

variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "The AWS region where the VPC is located at"
}

variable "sftp_ami_id" {
  type        = string
  default     = "ami-032449f6edfd0733f" # debian
  description = "The AMI ID for SFTP servers"
}

variable "sftp_instance_type" {
  type        = string
  default     = "t2.nano"
  description = "The instance type for SFTP servers"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "The CIDR block of the VPC"
}

variable "web_ami_id" {
  type        = string
  default     = "ami-098300699405cf362" # nginx
  description = "The AMI ID for web servers"
}

variable "web_instance_type" {
  type        = string
  default     = "t2.nano"
  description = "The instance type for web servers"
}

variable "web_max_size" {
  type        = number
  default     = 3
  description = "The maximum number of instances in web auto-scaling group"
}

variable "worker_ami_id" {
  type        = string
  default     = "ami-01eb7b0c1119f2550" # debian
  description = "The AMI ID for worker nodes"
}

variable "worker_instance_type" {
  type        = string
  default     = "t2.nano"
  description = "The instance type for worker nodes"
}

variable "worker_max_size" {
  type        = number
  default     = 3
  description = "The maximum number of instances in worker auto-scaling group"
}