output "bastion_host" {
  description = "The public IP address of the bastion host"
  value       = module.bastion.public_ip
}

output "db_endpoint" {
  description = "The MySQL database endpoint"
  value       = aws_db_instance.db.endpoint
}

output "sftp_public_elb_dns_name" {
  description = "The FQDN of the public SFTP elastic load balancer"
  value       = aws_elb.sftp_internet.dns_name
}

output "queue_url" {
  value       = aws_sqs_queue.worker.id
  description = "The URL of the worker SQS queue"
}

output "web_lb_dns_name" {
  description = "The FQDN of the Load Balancer"
  value       = aws_lb.web.dns_name
}