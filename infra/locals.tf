locals {
  name          = "${var.name_prefix}-${var.env}"
  desired_count = var.env == "prod" ? 2 : 1
}
