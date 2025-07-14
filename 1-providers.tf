provider "aws" {
  region = local.region
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.53"
    }
  }

# Configure the backend to use s3 for state storage
    backend "s3" {
    bucket = "berlin-41"
    key    = "tool/terraform.tfstate"
    region = "us-east-1"
  }
}
