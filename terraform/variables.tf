variable "product" {
  type        = string
  description = "The product name"
  default     = "bluewave" 
}


variable "project" {
  type        = string
  description = "The product name"
  default     = "bluewave" 
}

variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
  default     = "dev" 
}

# variable "instance_type" {
#   type        = string
#   description = "The instance type"
#   default     = "r6a.large"
# }

variable "region" {
  type        = string
  description = "The region"
  default     = "us-east-1"
}

variable "github_username" {
  type        = string
  description = "Your GitHub username"
  default     = "LedouxS"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block of the VPC"
  default = "10.1.0.0/16"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "bluewave-eks-cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes Version"
  # default     = "1.25"
  default     = "1.23"
  # default     = "1.21"
}

variable "cluster_domain" {
  type        = string
  description = "Domain name to use for the cluster's primary ingress controller"
  default     = "bluewave.bluewave-ledoux.com"
}

variable "cluster_admin_arns" {
  type        = list(string)
  description = "Admin ARNs to give access to resources where applicable"
  default     = []
}

# variable "vault_csr_private_key_pem" {
#   type        = string
#   description = "Private key to use for setting up Vault TLS"
# }

variable "default_allowed_cidr_list" {
  type        = string
  description = "CIDRs to allow by default for Ingress resources without custom annotations (comma separated list)"
  default     = "0.0.0.0/0"
}

variable "contact_email" {
  type        = string
  description = "Email used whenever a contact email is required by a resource"
  default     = "ledoux.songwa@gmail.com"
}

# variable "external_dns_hosted_zone_arns" {
#   type        = list(string)
#   description = "Route53 hosted zone arns to allow external-dns to manage"
#   default     = []
# }

variable "peer_vpc_ids" {
  type = list(string)
  description = "List of VPC ids to which to peer the platform vpc"
  default = []
}



####---------rds redis and s3-------------------------

variable sys_level {
  type    = string
  default = "prod"
}


variable username {
  type    = string
  default = "bluewave"
}

variable subdomain {
  type = string
  default = "eks-bluewave"
}



variable hospitalsize {
  type    = string
  default = "small"
}

variable db_instance_size {
  type    = map
  default = {
    "small" : "db.t3.medium",
    "medium" : "db.t3.medium",
    "large" : "db.t3.medium"
  }
}

variable ec_instance_size {
  type    = map
  default = {
    "small" : "cache.t4g.micro",
    "medium" : "cache.t4g.micro",
    "large" : "cache.t4g.micro"
  }
}

variable ec_replicate {
  type    = bool
  default = false
  # default = true
}

variable ec_redis_port {
  type    = number
  default = 6379
}

variable db_username {
  type = string
  default = "postgres"
}

variable db_password {
  type = string
  default = "postgres123"
}

variable db_name {
  type    = string
  default = "postgres"
}

variable db_port {
  type    = number
  default = 5432
}

variable skip_final_snapshot {
  default = false
  type    = bool
}

variable "k8s_namespaces" {
  description = "List of namespaces to create in our k8s cluster"
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}



