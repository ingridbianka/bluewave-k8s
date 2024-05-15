resource "aws_route53_zone" "bluewave_app" {
  name = "ingrid-bluewave.com"

  force_destroy = true
}
