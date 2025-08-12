terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
  backend "s3" {} # parâmetros via backend.hcl
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project   = "devops-it"
      ManagedBy = "terraform"
    }
  }
}

