resource "aws_security_group" "rds_sg" {
  name        = "${var.project}-rds"
  description = "Allow Postgres from app subnets"
  vpc_id      = var.vpc_id

  ingress {
    description = "Postgres from app subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.app_cidr_allow_list
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-rds-subnets"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.project}-rds-subnets"
  }
}

resource "aws_db_instance" "this" {
  identifier              = "${var.project}-db"
  allocated_storage       = 20
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  port                    = 5432
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = false
  multi_az                = false
  storage_encrypted       = true
  deletion_protection     = false
  skip_final_snapshot     = true
  apply_immediately       = true
  backup_retention_period = 0

  tags = {
    Name = "${var.project}-rds"
  }
}
