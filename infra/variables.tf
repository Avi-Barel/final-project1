variable "name_prefix" {
  description = "Prefix for all resources (lowercase letters, digits, hyphens, up to 12 chars)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,12}$", var.name_prefix))
    error_message = "name_prefix must be lowercase letters, digits and hyphens, up to 12 characters."
  }
}

variable "env" {
  description = "Environment name (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "env must be either 'dev' or 'prod'."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block with no default"
  type        = string
}

variable "image_tag" {
  description = "ECR image tag with no default"
  type        = string
}

variable "option_a" {
  description = "Voting option A"
  type        = string
  default     = "חתולים"
}

variable "option_b" {
  description = "Voting option B"
  type        = string
  default     = "כלבים"
}
