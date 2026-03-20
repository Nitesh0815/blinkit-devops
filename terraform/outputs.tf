output "ec2_public_ip" {
  value       = aws_instance.blinkit_server.public_ip
  description = "SSH and Jenkins access IP"
}