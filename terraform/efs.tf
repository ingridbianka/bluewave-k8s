
locals {
  region = var.region
  name   = "${var.subdomain}-efs-storage"
}



################################################################################
# EFS Module
################################################################################

module "efs" {
  source = "terraform-aws-modules/efs/aws"

  # File system
  name           = local.name
  creation_token = local.name
  encrypted      = true
  kms_key_arn    = module.kms.key_arn

  performance_mode                = "generalPurpose"
  throughput_mode                 = "elastic"
#   provisioned_throughput_in_mibps = 256

  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  # File system policy
  attach_policy                      = false


  # Mount targets / security group
  mount_targets              = { for k, v in zipmap(local.azs, module.vpc.public_subnets) : k => { subnet_id = v } }
  security_group_description = "${var.subdomain} EFS security group"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provdied for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC public subnets"
      cidr_blocks = module.vpc.public_subnets_cidr_blocks
    }
  }


  # Backup policy
  enable_backup_policy = true

  # Replication configuration
  create_replication_configuration = true
  replication_configuration_destination = {
    region = "us-east-1"
  }

  tags = local.tags
}


module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.0"

  aliases               = ["efs/${local.name}"]
  description           = "EFS customer managed key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}