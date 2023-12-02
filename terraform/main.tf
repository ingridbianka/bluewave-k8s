provider "aws" {
  region = var.region
  # access_key = var.aws_acces_key
  # secret_key = var.aws_secret_access_key

  # assume_role {
  #   role_arn     = local.platform_build_role_arn
  #   session_name = "terraform"
  #   external_id  = "terraform"
  # }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  ####Exec plugins
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  ####Exec plugins
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  }
}

provider "tls" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks_blueprints.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_blueprints.eks_cluster_id
}

locals {
  vpc_cidr = var.vpc_cidr
  vpc_name = join("-", [var.cluster_name, "vpc"])
  azs      = slice(data.aws_availability_zones.available.names, 0, 4)

  tags = {
    ManagedBy = "Terraform"
    Project   = var.product
    sys_level = var.sys_level 
  }
}

resource "aws_security_group_rule" "allow_all_vpc_traffic_egress" {
  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = [local.vpc_cidr]
  security_group_id = module.vpc.default_security_group_id
}

resource "aws_security_group_rule" "allow_all_vpc_traffic_ingress" {
  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = [local.vpc_cidr]
  security_group_id = module.vpc.default_security_group_id
}

resource "aws_security_group" "private_security_group" {
  name_prefix = "observsmart-eks-${var.subdomain}-private-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow TCP traffic from the cluster to Redis Cache"
    from_port   = var.ec_redis_port
    to_port     = var.ec_redis_port
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    description = "Allow TCP traffic from Redis Cache back to the cluster"
    from_port   = var.ec_redis_port
    to_port     = var.ec_redis_port
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  ingress {
    description = "Allow TCP traffic from the cluster to the database"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    description = "Allow TCP traffic from the database back to the cluster"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  ingress {
    description      = "Allow all TCP traffic from the security group itself"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    self             = true
  }

  egress {
    description      = "Allow all TCP traffic to the security group itself"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    self             = true
  }
  tags = local.tags
  
}


resource "aws_elasticache_subnet_group" "cache_subnets" {
  name       = "${var.cluster_name}-caches"
  subnet_ids = module.vpc.private_subnets
  tags = local.tags
}

resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.cluster_name}-databases"
  subnet_ids = module.vpc.private_subnets
  tags = local.tags
}

resource "aws_vpc_peering_connection" "foo" {
  for_each = toset(var.peer_vpc_ids)

  peer_vpc_id   = module.vpc.vpc_id
  vpc_id        = each.value
  auto_accept   = true
  tags = local.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.14.0"

  name = local.vpc_name
  cidr = local.vpc_cidr
  azs  = local.azs

  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  single_nat_gateway   = true
  create_igw           = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.vpc_name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.vpc_name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.vpc_name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    "public"                                    = "true"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    "private"                                   = "true"
  }

  tags = local.tags
}

data "aws_subnet_ids" "private_subnets_az_1" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "${var.cluster_name}-vpc-private-us-*-*a"
  }
  depends_on = [
    module.vpc
  ]
}

data "aws_subnet_ids" "private_subnets_az_2" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "${var.cluster_name}-vpc-private-us-*-*b"
  }
  depends_on = [
    module.vpc
  ]
}

data "aws_subnet_ids" "private_subnets_az_3" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "${var.cluster_name}-vpc-private-us-*-*c"
  }
  depends_on = [
    module.vpc
  ]
}

module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.12.2"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_kms_key_additional_admin_arns = var.cluster_admin_arns

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids = module.vpc.public_subnets


  managed_node_groups = {
    t3a_large_az_1 = {
      node_group_name = "${var.region}a-managed-ondemand-r6al"
      instance_types  = ["r6a.large"]
      desired_size    = 1
      min_size        = 1
      max_size        = 2
      max_unavailable = 1 
      disk_size       = 128
      update_config = [{
        max_unavailable_percentage = 75
      }]
      subnet_ids      = data.aws_subnet_ids.private_subnets_az_1.ids 
      additional_tags = {
        ExtraTag    = "r6al-on-demand"
        Name        = "${var.cluster_name}-${var.region}a"
        subnet_type = "private"
        sys_level   = var.sys_level
      }
    }
    t3a_large_az_2 = {
      node_group_name = "${var.region}b-managed-ondemand-r6al"
      instance_types  = ["r6a.large"]
      desired_size    = 1
      min_size        = 1
      max_size        = 2
      max_unavailable = 1 
      disk_size       = 128
      update_config = [{
        max_unavailable_percentage = 75
      }]
      subnet_ids      = data.aws_subnet_ids.private_subnets_az_2.ids
      public_ip              = false 
      additional_tags = {
        ExtraTag    = "r6al-on-demand"
        Name        = "${var.cluster_name}-${var.region}b"
        subnet_type = "private"
        sys_level   = var.sys_level
      }
    }
    t3a_large_az_3 = {
      node_group_name = "${var.region}c-managed-ondemand-r6al"
      instance_types  = ["r6a.large"]
      desired_size    = 1
      min_size        = 1
      max_size        = 2
      max_unavailable = 1 
      disk_size       = 128
      update_config = [{
        max_unavailable_percentage = 75
      }]
      subnet_ids      = data.aws_subnet_ids.private_subnets_az_3.ids
      additional_tags = {
        ExtraTag    = "r6al-on-demand"
        Name        = "${var.cluster_name}-${var.region}c"
        subnet_type = "private"
        sys_level   = var.sys_level
      }
    }
  }

  platform_teams = local.platform_teams

  application_teams = local.application_teams

  tags = local.tags
}

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.32.1"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  enable_amazon_eks_vpc_cni    = true
  enable_amazon_eks_coredns    = true
  enable_amazon_eks_kube_proxy = true

  enable_aws_load_balancer_controller = true
  enable_metrics_server               = true
  enable_cluster_autoscaler           = true

  enable_amazon_eks_aws_ebs_csi_driver  = true
  enable_aws_efs_csi_driver = true

  tags = local.tags

  depends_on = [ module.eks_blueprints ]
}



data "aws_iam_role" "existing_role" {
  name = "${var.cluster_name}-aws-load-balancer-controller-sa-irsa"

  depends_on = [ module.eks_blueprints_kubernetes_addons ]
}
data "aws_iam_policy_document" "add_tags_policy_doc" {
  statement {
    actions = ["elasticloadbalancing:AddTags"]
    resources = ["*"]  
  }
}

resource "aws_iam_policy" "add_tags_policy" {
  name   = "AddTagsPolicy"
  policy = data.aws_iam_policy_document.add_tags_policy_doc.json
}
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = data.aws_iam_role.existing_role.name
  policy_arn = aws_iam_policy.add_tags_policy.arn
  depends_on = [ module.eks_blueprints_kubernetes_addons ]
}




