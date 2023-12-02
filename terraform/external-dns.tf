locals {
  external_dns_user_name = "${var.cluster_name}-external-dns-user"
}

resource "aws_iam_user" "external_dns_user" {
  name = local.external_dns_user_name
}

resource "aws_iam_access_key" "external_dns_user" {
  user = aws_iam_user.external_dns_user.name
}

data "aws_iam_policy_document" "external_dns_access" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [ aws_route53_zone.bluewave_app.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns_access" {
  name        = "${var.cluster_name}-external-dns-route53-access"
  description = "Allows external-dns to update Route53 resources"
  policy      = data.aws_iam_policy_document.external_dns_access.json
}

data "aws_iam_policy_document" "external_dns_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.external_dns_user.arn]
    }
  }
}

resource "aws_iam_role" "external_dns_access" {
  name                = "${var.cluster_name}-external-dns-route53-access"
  description         = "Role assumed by external-dns on ${var.cluster_name}"
  assume_role_policy  = data.aws_iam_policy_document.external_dns_assume_role.json
  managed_policy_arns = [aws_iam_policy.external_dns_access.arn]
}

resource "helm_release" "external_dns_platform" {
  name             = "external-dns-platform"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "external-dns"
  version          = "6.5.6"
  namespace        = "external-dns"
  create_namespace = true

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = var.region
  }

  set {
    name  = "aws.credentials.accessKey"
    value = aws_iam_access_key.external_dns_user.id
  }

  set_sensitive {
    name  = "aws.credentials.secretKey"
    value = aws_iam_access_key.external_dns_user.secret
  }

  set {
    name  = "aws.assumeRoleArn"
    value = aws_iam_role.external_dns_access.arn
  }

  set {
    name  = "aws.roleArn"
    value = aws_iam_role.external_dns_access.arn
  }

  depends_on = [ module.eks_blueprints_kubernetes_addons ]
}
