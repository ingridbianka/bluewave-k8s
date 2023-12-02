resource "helm_release" "nginx_ingress_controller" {
  name             = "ingress-nginx-platform"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.0.17"
  create_namespace = true
  namespace        = "ingress-nginx"

  

  values = [
    "${file("nginx_values.yaml")}"
  ]

  set {
    name  = "controller.service.annotations.external-dns.alpha.kubernetes.io/hostname"
    value = var.cluster_domain
  }

  set {
    name  = "controller.config.whitelist-source-range"
    value = var.default_allowed_cidr_list
  }

  set {
    name  = "controller.config.proxy-real-ip-cidr"
    value = local.vpc_cidr
  }

  depends_on = [ module.eks_blueprints_kubernetes_addons ]
}

resource "null_resource" "wait_for_lb" {
  provisioner "local-exec" {
    command = "sleep 1"
  }

  depends_on = [
    helm_release.nginx_ingress_controller
  ]
}



