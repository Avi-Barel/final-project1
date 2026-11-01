resource "aws_ecs_cluster" "this" {
  name = "${local.name}-cluster"

  tags = {
    Name = "${local.name}-cluster"
  }
}

# --- Service: Vote ---
module "vote" {
  source = "./modules/service"

  name               = "${local.name}-vote"
  cluster_id         = aws_ecs_cluster.this.id
  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn
  image              = "${data.aws_ecr_repository.vote.repository_url}:${var.image_tag}"
  subnets            = local.public_subnet_ids
  security_groups    = [aws_security_group.ecs.id]
  desired_count      = local.desired_count
  target_group_arn   = aws_lb_target_group.vote.arn
  container_port     = 80

  environment = {
    REDIS_HOST = aws_elasticache_cluster.this.cache_nodes[0].address
    OPTION_A   = var.option_a
    OPTION_B   = var.option_b
  }
}

# --- Service: Result ---
module "result" {
  source = "./modules/service"

  name               = "${local.name}-result"
  cluster_id         = aws_ecs_cluster.this.id
  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn
  image              = "${data.aws_ecr_repository.result.repository_url}:${var.image_tag}"
  subnets            = local.public_subnet_ids
  security_groups    = [aws_security_group.ecs.id]
  desired_count      = local.desired_count
  target_group_arn   = aws_lb_target_group.result.arn
  container_port     = 80

  environment = {
    DB_HOST = aws_db_instance.this.address
    DB_PORT = tostring(aws_db_instance.this.port)
    DB_USER = aws_db_instance.this.username
    DB_NAME = aws_db_instance.this.db_name
    DB_SSL  = "true"
  }

  secrets = {
    DB_PASSWORD = aws_secretsmanager_secret.db_password.arn
  }
}

# --- Service: Worker ---
module "worker" {
  source = "./modules/service"

  name               = "${local.name}-worker"
  cluster_id         = aws_ecs_cluster.this.id
  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn
  image              = "${data.aws_ecr_repository.worker.repository_url}:${var.image_tag}"
  subnets            = local.public_subnet_ids
  security_groups    = [aws_security_group.ecs.id]
  desired_count      = local.desired_count

  environment = {
    REDIS_HOST = aws_elasticache_cluster.this.cache_nodes[0].address
    DB_HOST    = aws_db_instance.this.address
    DB_PORT    = tostring(aws_db_instance.this.port)
    DB_USER    = aws_db_instance.this.username
    DB_NAME    = aws_db_instance.this.db_name
    DB_SSL     = "true"
  }

  secrets = {
    DB_PASSWORD = aws_secretsmanager_secret.db_password.arn
  }
}
