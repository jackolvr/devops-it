variable "region" {
  type    = string
  default = "sa-east-1"
}

variable "project" {
  type    = string
  default = "devops-it"
}

variable "ssh_key_name" {
  type        = string
  description = "Nome da chave SSH na AWS"
  default     = ""
}

variable "my_ip_cidr" {
  type        = string
  description = "Seu IP público em formato CIDR (ex: 203.0.113.1/32)"
  default     = "0.0.0.0/0"  # ATENÇÃO: Muito permissivo, use seu IP real!
}

# EC2
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# AMI
variable "ami_id" {
  type        = string
  description = "AMI (se vazio, usa AL2023 mais recente)"
  default     = ""
}


# RDS
variable "db_engine" {
  type    = string
  default = "postgres"
}

variable "db_engine_version" {
  type    = string
  default = "16"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_name" {
  type    = string
  default = "uTqdCnYkvYfFA8HF"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type      = string
  sensitive = true # injetado por secret
}
