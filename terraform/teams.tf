locals {
  platform_teams = {
    admin = {
      users = concat(
        [data.aws_caller_identity.current.arn]
        # ,
        # [
        #   "${your admin user arn here}"
        # ]
      )
    }
  }

  application_teams = {
    platform-services = {
      "labels" = {
        "project" = "platform-services"
      }
      "quota" = {
        "requests.cpu"    = "16000m",
        "requests.memory" = "64Gi",
        "limits.cpu"      = "16000m",
        "limits.memory"   = "64Gi",
        "pods"            = "100",
        "secrets"         = "500",
        "services"        = "100"
      }
      users = concat(
        [data.aws_caller_identity.current.arn]
        # ,
        # [
        #   "${your admin user arn here}"
          
        # ]
      )
    }
  }
}


resource "kubernetes_role" "application_teams_admin" {
  for_each = module.eks_blueprints.teams[0].application_teams_iam_role_arn
  metadata {
    name      = "${each.key}-admin-role"
    namespace = each.key
  }
  rule {
    api_groups = ["*"]
    resources  = ["configmaps", "pods", "podtemplates", "secrets", "serviceaccounts", "services", "deployments", "horizontalpodautoscalers", "networkpolicies", "statefulsets", "replicasets", "ingresses", "jobs", "cronjobs"]
    verbs      = ["create", "update", "delete", "get", "list", "patch"]
  }
  rule {
    api_groups = ["*"]
    resources  = ["resourcequotas"]
    verbs      = ["create", "update", "delete"]
  }
}

resource "kubernetes_role_binding" "application_teams_admin" {
  for_each = module.eks_blueprints.teams[0].application_teams_iam_role_arn
  metadata {
    name      = "${each.key}-admin-role-binding"
    namespace = each.key
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "${each.key}-admin-role"
  }
  subject {
    kind      = "Group"
    name      = "${each.key}-group"
    api_group = "rbac.authorization.k8s.io"
    namespace = each.key
  }
}
