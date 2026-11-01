data "aws_ecr_repository" "vote" {
  name = "${var.name_prefix}-vote"
}

data "aws_ecr_repository" "result" {
  name = "${var.name_prefix}-result"
}

data "aws_ecr_repository" "worker" {
  name = "${var.name_prefix}-worker"
}
