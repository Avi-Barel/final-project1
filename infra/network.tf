data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  selected_azs = slice(data.aws_availability_zones.available.names, 0, 2)

  subnets_config = {
    public-0 = {
      cidr_block  = cidrsubnet(var.vpc_cidr, 8, 0)
      az          = local.selected_azs[0]
      is_public   = true
      name_suffix = "public-${local.selected_azs[0]}"
    }
    public-1 = {
      cidr_block  = cidrsubnet(var.vpc_cidr, 8, 1)
      az          = local.selected_azs[1]
      is_public   = true
      name_suffix = "public-${local.selected_azs[1]}"
    }
    private-0 = {
      cidr_block  = cidrsubnet(var.vpc_cidr, 8, 10)
      az          = local.selected_azs[0]
      is_public   = false
      name_suffix = "private-${local.selected_azs[0]}"
    }
    private-1 = {
      cidr_block  = cidrsubnet(var.vpc_cidr, 8, 11)
      az          = local.selected_azs[1]
      is_public   = false
      name_suffix = "private-${local.selected_azs[1]}"
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name}-igw"
  }
}

resource "aws_subnet" "all" {
  for_each = local.subnets_config

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.is_public

  tags = {
    Name = "${local.name}-${each.value.name_suffix}"
  }
}

locals {
  public_subnet_ids  = [aws_subnet.all["public-0"].id, aws_subnet.all["public-1"].id]
  private_subnet_ids = [aws_subnet.all["private-0"].id, aws_subnet.all["private-1"].id]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = { for k, v in local.subnets_config : k => aws_subnet.all[k].id if v.is_public }
  subnet_id      = each.value
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = { for k, v in local.subnets_config : k => aws_subnet.all[k].id if !v.is_public }
  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}

# --- Security Groups (N5) ---

resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP on port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound to anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-alb-sg"
  }
}

resource "aws_security_group" "ecs" {
  name        = "${local.name}-ecs-sg"
  description = "ECS tasks security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Port 80 from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Outbound to anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-ecs-sg"
  }
}

resource "aws_security_group" "redis" {
  name        = "${local.name}-redis-sg"
  description = "Redis security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Port 6379 from ECS tasks only"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-redis-sg"
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "RDS Postgres security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Port 5432 from ECS tasks only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-rds-sg"
  }
}

# --- Application Load Balancer & Target Groups (L1, L2) ---

resource "aws_lb" "this" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.public_subnet_ids

  tags = {
    Name = "${local.name}-alb"
  }
}

resource "aws_lb_target_group" "vote" {
  name        = "${local.name}-vote"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${local.name}-vote"
  }
}

resource "aws_lb_target_group" "result" {
  name        = "${local.name}-result"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${local.name}-result"
  }
}

resource "aws_lb_listener" "vote" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vote.arn
  }
}

resource "aws_lb_listener" "result" {
  load_balancer_arn = aws_lb.this.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.result.arn
  }
}
