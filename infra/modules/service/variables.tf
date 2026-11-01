variable "name" {
  description = "Full service name, e.g. avi-vapp-dev-vote"
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID or ARN"
  type        = string
}

variable "cpu" {
  description = "Fargate CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate memory in MiB"
  type        = number
  default     = 512
}

variable "execution_role_arn" {
  description = "Task execution IAM role ARN"
  type        = string
}

variable "image" {
  description = "ECR image URI with tag"
  type        = string
}

variable "environment" {
  description = "Container environment variables"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Container secrets from Secrets Manager"
  type        = map(string)
  default     = {}
}

variable "subnets" {
  description = "Subnet IDs for the service tasks"
  type        = list(string)
}

variable "security_groups" {
  description = "Security group IDs for the service tasks"
  type        = list(string)
}

variable "desired_count" {
  description = "Number of running tasks"
  type        = number
  default     = 1
}

variable "target_group_arn" {
  description = "Optional target group ARN for ALB integration"
  type        = string
  default     = null
}

variable "container_port" {
  description = "Optional container port for ALB integration"
  type        = number
  default     = null
}
