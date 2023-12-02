


resource aws_db_instance postgresql {
  identifier                 = "observsmart-eks-${var.subdomain}-master-database"
  instance_class             = var.db_instance_size[var.hospitalsize]
  allocated_storage          = "20"
  max_allocated_storage      = "100"
  engine                     = "postgres"
  engine_version             = "15.4"
  name                       = var.db_name
  password                   = var.db_password
  username                   = var.db_username
  backup_retention_period    = "30"
  backup_window              = "20:00-22:00"
  maintenance_window         = "Sat:23:00-Sun:01:00"
  auto_minor_version_upgrade = false
  copy_tags_to_snapshot      = true
  port                       = var.db_port
  vpc_security_group_ids     = ["${aws_security_group.private_security_group.id}"]
  db_subnet_group_name       = aws_db_subnet_group.db_subnets.name
  final_snapshot_identifier  = ! var.skip_final_snapshot ? "${local.name_template}-database-finalsnapshot" : null
  storage_encrypted          = true
  skip_final_snapshot        = var.skip_final_snapshot


  tags = merge(
    {
      Name : "${local.name_template}-postgres"
    },
    local.common_tags,
  )
}