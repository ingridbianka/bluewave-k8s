
resource random_string random {
  length           = 8
  special          = true
  override_special = "-"
}

resource random_password password {
  length           = 16
  special          = true
  override_special = "/@\" "
}

resource random_uuid uuid {}



resource aws_elasticache_replication_group cache-replication-group {
  count                         = var.ec_replicate ? 1 : 0
  automatic_failover_enabled    = true
  replication_group_id          = var.sys_level == "prod" ?  "${var.subdomain}-${random_string.random.result}" : "${var.sys_level}${var.subdomain}-${random_string.random.result}"
  replication_group_description = "Redis cache group for ${var.subdomain}"
  transit_encryption_enabled    = true
  auth_token                    = random_password.password.result
  maintenance_window            = "Sat:23:00-Sun:01:00"
  subnet_group_name             = aws_elasticache_subnet_group.cache_subnets.name
  security_group_ids            = ["${aws_security_group.private_security_group.id}"]
  port                          = var.ec_redis_port
  engine                        = "redis"
  engine_version                = "3.2.10"
  node_type                     = var.ec_instance_size[var.hospitalsize]
  parameter_group_name          = "default.redis3.2.cluster.on"
  
  cluster_mode {
    num_node_groups         = 1
    replicas_per_node_group = 2
  }

  tags = local.common_tags
}

//Either one of cache replication group or cache cluster will be created based on ec_replicate variable
resource aws_elasticache_cluster cache-cluster {
  count                = var.ec_replicate ? 0 : 1 //if replicate = false then it creates cache cluster group
  cluster_id           = "observsmart-eks-${var.subdomain}-redis-cache"
  subnet_group_name    = aws_elasticache_subnet_group.cache_subnets.name
  maintenance_window   = "Sat:23:00-Sun:01:00"
  security_group_ids   = ["${aws_security_group.private_security_group.id}"]
  engine               = "redis"
  # engine_version       = "3.2.10"
  engine_version       = "7.0"

  node_type            = var.ec_instance_size[var.hospitalsize]
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = var.ec_redis_port

  tags = local.common_tags
}