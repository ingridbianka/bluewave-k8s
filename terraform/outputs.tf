
# --  VPC OUTPUT  --

output "vpc_id" {
  value = module.vpc.vpc_id
}
output "region" {
  value       = var.region
  description = "AWS region where VPC and cluster are deployed"
}

output "vpc_private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "vpc_private_subnet_cidr" {
  value = module.vpc.private_subnets_cidr_blocks
}

output "vpc_public_subnet_cidr" {
  value = module.vpc.public_subnets_cidr_blocks
}

output "vpc_default_security_group_id" {
  value = module.vpc.default_security_group_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "vpc_availability_zones" {
  value = local.azs
}

output "cache_subnet_group" {
  description = "Elasticache subnet groups each team should use to deploy caches"
  value = aws_elasticache_subnet_group.cache_subnets
}

output "db_subnet_group" {
  description = "RDS subnet groups each team should use to deploy databases"
  value = aws_db_subnet_group.db_subnets
}


# -- EKS OUTPUT --

output "eks_cluster_name" {
  value = var.cluster_name
}

output "eks_cluster_id" {
  value = module.eks_blueprints.eks_cluster_id
}

output "eks_cluster_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}

output "eks_cluster_ca_certificate" {
  value = data.aws_eks_cluster.cluster.certificate_authority.0.data
}

output "eks_managed_nodegroups" {
  value = module.eks_blueprints.managed_node_groups
}


# -- TEAMS OUPUT --

output "teams" {
  description = "EKS Blueprints raw teams output, in case we need it later"
  value       = module.eks_blueprints.teams
}

output "teams_configure_kubectl_commands" {
  description = "Command to configure kubectl to access the platform as a team"
  value       = module.eks_blueprints.teams[0].application_teams_configure_kubectl
}

output "teams_eks_cluster_access_roles" {
  description = "IAM roles for each team allowing access to cluster"
  value       = module.eks_blueprints.teams[0].application_teams_iam_role_arn
}

output "admin_configure_kubectl_command" {
  description = "Command to configure kubectl to access the platform as an admin"
  value       = module.eks_blueprints.teams[0].platform_teams_configure_kubectl.admin
}


# -- INGRESS OUTPUT --

output "cluster_domain" {
  value       = var.cluster_domain
  description = "Domain associated with the cluster's primary ingress controller"
}

output "cert_manager_cluster_issuers" {
  description = "cert-manager cluster issuers deployed on the cluster"
  value = {
    letsencrypt_staging = {
      name = local.letsencrypt_staging_name
    }
    letsencrypt_prod = {
      name = local.letsencrypt_prod_name
    }
  }
}

################################################################################
# File System
################################################################################

output "arn" {
  description = "Amazon Resource Name of the file system"
  value       = module.efs.arn
}

output "id" {
  description = "The ID that identifies the file system (e.g., `fs-ccfc0d65`)"
  value       = module.efs.id
}

output "dns_name" {
  description = "The DNS name for the filesystem per [documented convention](http://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html)"
  value       = module.efs.dns_name
}

output "size_in_bytes" {
  description = "The latest known metered size (in bytes) of data stored in the file system, the value is not the exact size that the file system was at any point in time"
  value       = module.efs.size_in_bytes
}

################################################################################
# Mount Target(s)
################################################################################

output "mount_targets" {
  description = "Map of mount targets created and their attributes"
  value       = module.efs.mount_targets
}

################################################################################
# Security Group
################################################################################

output "security_group_arn" {
  description = "ARN of the security group"
  value       = module.efs.security_group_arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.efs.security_group_id
}

################################################################################
# # Access Point(s)
# ################################################################################

# output "access_points" {
#   description = "Map of access points created and their attributes"
#   value       = module.efs.access_points
# }

################################################################################
# Replication Configuration
################################################################################

output "replication_configuration_destination_file_system_id" {
  description = "The file system ID of the replica"
  value       = module.efs.replication_configuration_destination_file_system_id
}


