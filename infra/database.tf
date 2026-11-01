resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${local.name}-db-password"
  recovery_window_in_days = 0

  tags = {
    Name = "${local.name}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-db-subnet-group"
  subnet_ids = local.private_subnet_ids

  tags = {
    Name = "${local.name}-db-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier             = "${local.name}-db"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  db_name                = "votes"
  username               = "voteadmin"
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "${local.name}-db"
  }
}
