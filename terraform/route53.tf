resource "aws_route53_zone" "bluewave_app" {
  name = "ledoux-bluewave.com"

  force_destroy = true
}
