output "vote_url" {
  description = "URL for the voting service"
  value       = "http://${aws_lb.this.dns_name}"
}

output "result_url" {
  description = "URL for the results service"
  value       = "http://${aws_lb.this.dns_name}:8080"
}

output "redis_endpoint" {
  description = "Redis endpoint address"
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
}

output "db_endpoint" {
  description = "Postgres DB endpoint address"
  value       = aws_db_instance.this.address
}
