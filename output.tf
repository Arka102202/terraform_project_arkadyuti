output "elb_dns" {
  value = aws_lb.web-lb.dns_name
}
