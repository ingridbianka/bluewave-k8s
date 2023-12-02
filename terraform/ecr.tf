resource "aws_ecr_repository" "bluewave_app" {
  name                 = "bluewave-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true

  tags = {
    Name = "${var.product}-ecr-repo-${var.environment}"
  }
}