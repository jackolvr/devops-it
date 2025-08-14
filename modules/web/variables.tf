variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "user_data" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "my_ip_cidr" {
  type = string
}