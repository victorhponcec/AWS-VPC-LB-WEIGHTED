# DNS Hosted Zone
/*
resource "aws_route53_zone" "victor" {
  name = "victorponce.com"
}

# DNS Record = Alias
resource "aws_route53_record" "lb" {
  zone_id = aws_route53_zone.victor.zone_id
  name    = "victorponce.com"
  type    = "A"
  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}
*/