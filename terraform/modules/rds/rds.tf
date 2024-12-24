# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = var.PRIVATE_SUBNET_IDS

  tags = {
    Name = "main-db-subnet-group"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres14"
  name   = "custom-postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier        = "main-db"
  engine            = "postgres"
  engine_version    = "14"
  instance_class    = "db.t2.micro" # Free tier eligible
  allocated_storage = 10
  storage_type      = "gp2" # Free tier eligible

  db_name  = "appdb"
  username = var.DB_USERNAME
  password = var.DB_PASSWORD

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [var.RDS_SECURITY_GROUP_ID]

  skip_final_snapshot = true
  publicly_accessible = false
  multi_az            = false # Set to false for free tier

  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  tags = {
    Name = "main-db"
  }
}
