resource "helm_release" "rancher" {
  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/latest"
  chart            = "rancher"
  version          = "2.7"
  create_namespace = true
  namespace        = "cattle-system"

  

  values = [
    "${file("rancher_values.yaml")}"
  ]

  depends_on = [ helm_release.nginx_ingress_controller]

}


resource "kubernetes_namespace" "bluewave_namespaces" {
  for_each = toset(var.k8s_namespaces)

  metadata {
    name = each.value
  }

  depends_on = [ module.eks_blueprints ]
}


resource "kubectl_manifest" "rancher_ingress" {
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bluewave-app-ingress
  namespace: cattle-system
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /rancher
        pathType: Prefix
        backend:
          service:
            name: rancher
            port:
              number: 80
    
YAML

  depends_on = [
    helm_release.cert_manager
  ]
}