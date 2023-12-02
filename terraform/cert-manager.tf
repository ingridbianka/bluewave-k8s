locals {
  letsencrypt_prod_name    = "letsencrypt-prod"
  letsencrypt_staging_name = "letsencrypt-staging"
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.8.0"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = true
  }

  set {
    name  = "prometheus.enabled"
    value = false
  }

  depends_on = [ module.eks_blueprints_kubernetes_addons ]
}

resource "kubectl_manifest" "issuer_letsencrypt_staging" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${local.letsencrypt_staging_name}
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: ${var.contact_email}
    privateKeySecretRef:
      name: ${local.letsencrypt_staging_name}
    solvers:
      - http01:
          ingress:
            class: nginx
YAML

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "issuer_letsencrypt_prod" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${local.letsencrypt_prod_name}
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${var.contact_email}
    privateKeySecretRef:
      name: ${local.letsencrypt_prod_name}
    solvers:
      - http01:
          ingress:
            class: nginx
YAML
  depends_on = [
    helm_release.cert_manager
  ]
}
