resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name}-redis-subnet-group"
  subnet_ids = local.private_subnet_ids

  tags = {
    Name = "${local.name}-redis-subnet-group"
  }
}

resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${local.name}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.redis.id]

  tags = {
    Name = "${local.name}-redis"
  }
}
