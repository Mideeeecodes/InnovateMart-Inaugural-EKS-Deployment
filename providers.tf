terraform {
  backend "s3" {
    bucket = "my-state-lock-bucket006"
    region = "us-east-1"
    key = "InnovateMart/s3/terraform.tfstate"
  }
#    required_providers {
#     aws = {
#       source = "hashicorp/aws"
#       version = "6.13.0"
#     }
#   }
}

provider "aws" {
  region = "us-east-1"
}

