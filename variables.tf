variable "region" { type = string, default = "sa-east-1" }
variable "project" { type = string, default = "devops-it" }

# EC2
variable "instance_type" { type = string, default = "t3.micro" }
variable "ami_id" { type = string, default = "ami-02482fe6c7e44373a" }

# RDS
variable "db_engine" { type = string, default = "postgres" }
variable "db_engine_version" { type = string, default = "16" }
variable "db_instance_class" { type = string, default = "db.t4g.micro" }
variable "db_name" { type = string, default = "uTqdCnYkvYfFA8HF" }
variable "db_username" { type = string, default = "appuser" }
variable "db_password" { type = string, sensitive = true } # injetado por secret
