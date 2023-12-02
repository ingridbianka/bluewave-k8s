locals {
  user_data = templatefile("${path.module}./templates/user-data.sh.tmpl", {
    region          = var.region
    repository_name = aws_ecr_repository.bluewave_app.registry_id
  })
}