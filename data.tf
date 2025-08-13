data "aws_ami" "al2023_x86_64" {
  most_recent = true
  owners      = ["137112412989"] # AWS oficial

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  chosen_ami = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023_x86_64.id
}
