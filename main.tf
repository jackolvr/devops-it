################
# Networking
################
resource "aws_vpc" "this" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "sa-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "sa-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public-b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.10.101.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "${var.project}-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.10.102.0/24"
  availability_zone = "sa-east-1b"

  tags = {
    Name = "${var.project}-private-b"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

################
# Security
################
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project}-ec2"
  description = "Allow HTTP from ALB and SSH(optional)"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-alb"
  description = "Allow HTTP from internet"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project}-rds"
  description = "Allow Postgres from EC2 subnets"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Postgres from private subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.private_a.cidr_block,
      aws_subnet.private_b.cidr_block,
      aws_subnet.public_a.cidr_block,
      aws_subnet.public_b.cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################
# EC2 + ALB
################
resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

####################
# USER_DATA + NGINX
####################
user_data = <<-EOF
  #!/bin/bash
  set -euxo pipefail

  # Detecta gerenciador de pacotes
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
    WEBROOT="/var/www/html"
  elif command -v dnf >/dev/null 2>&1; then
    # Amazon Linux 2023
    dnf -y update
    dnf -y install nginx
    WEBROOT="/usr/share/nginx/html"
  elif command -v yum >/dev/null 2>&1; then
    # Amazon Linux 2
    yum -y update
    amazon-linux-extras enable nginx1 || true
    yum -y install nginx
    WEBROOT="/usr/share/nginx/html"
  else
    echo "Gerenciador de pacotes não suportado" >&2
    exit 1
  fi

  mkdir -p "${WEBROOT}"
  echo "OK - devops-it" > "${WEBROOT}/index.html"

  systemctl enable nginx
  systemctl restart nginx

  # Garante que está escutando em 0.0.0.0:80
  ss -ltn | grep ':80' || (echo "Nginx não está escutando na porta 80" >&2; exit 1)
EOF


  tags = {
    Name = "${var.project}-ec2"
  }
}

resource "aws_lb" "app" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "${var.project}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200-399"
    interval            = 15
    timeout             = 6
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 80
}

################
# RDS Postgres
################
resource "aws_db_subnet_group" "rds" {
  name       = "${var.project}-rds-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "this" {
  identifier              = "${var.project}-db"
  allocated_storage       = 20
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false
  deletion_protection     = false
  storage_encrypted       = true
  apply_immediately       = true
  backup_retention_period = 0

  tags = {
    Name = "${var.project}-rds"
  }
}
