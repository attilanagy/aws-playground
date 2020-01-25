resource "aws_sqs_queue" "worker" {
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  name                      = "${var.environment}-worker-queue"
  receive_wait_time_seconds = 10

  tags = {
    environment = var.environment
    purpose     = "worker"
  }
}

# https://github.com/terraform-providers/terraform-provider-aws/issues/3550
resource "aws_sqs_queue_policy" "worker_node" {
  queue_url = aws_sqs_queue.worker.id
  policy    = jsonencode({
    Version   = "2012-10-17"
    Id        = "sqspolicy"
    Statement = [
      {
        Sid       = "${var.environment}_worker_node_receive"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["sqs:ReceiveMessage","sqs:DeleteMessage"]
        Resource  = aws_sqs_queue.worker.arn
        Condition = {
          IpAddress = {
            "aws:SourceIp" = [for workernet in aws_subnet.worker[*]: workernet.cidr_block]
          }
        }
      },
      {
        Sid       = "${var.environment}_web_node_send"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.worker.arn
        Condition = {
          IpAddress = {
            "aws:SourceIp" = [for dmznet in aws_subnet.dmz[*]: dmznet.cidr_block]
          }
        }
      }
    ]
  })
}