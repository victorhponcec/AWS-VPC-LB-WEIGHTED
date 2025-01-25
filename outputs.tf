#Retrieve AWS AZ Information
data "aws_region" "current" {}

output "current_region" {
  value = data.aws_region.current.name
}

output "instance_ip" {
  value = aws_instance.amazon_linux.public_ip
}

output "instance_LB2" {
  value = aws_instance.amazon_linux_lb2.private_ip
}

output "lb_ip" {
  value = aws_lb.lb.dns_name
}

