locals {
  user_data = templatefile("${path.module}./templates/user-data.sh.tmpl", {
    region          = var.region
    repository_name = aws_ecr_repository.bluewave_app.registry_id
  })
  github_actions_assume_role_session_user_arn = "arn:aws:sts::${var.aws_account_id}:assumed-role/${aws_iam_role.github_actions.name}/github-actions_bluewave"
}