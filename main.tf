terraform {
  required_version = ">=1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 1.0.4"
    }
  }
}

provider "aws" {
  profile = "terraform"
  region  = "ap-northeast-1"
}

provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "hello_lambda.py"
  output_path = "hello_lambda.zip"
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "${var.project}-iam-role"
  assume_role_policy = data.aws_iam_policy_document.policy.json

  tags = {
    Name        = "${var.project}-${var.environment}-iam-role"
    Project     = var.project
    Environment = var.environment
  }
}

# =============================================================================
# VPC
# =============================================================================

resource "aws_vpc" "vpc" {
  cidr_block                       = "192.168.0.0/20"
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Project     = var.project
    Environment = var.environment
  }
}


# =============================================================================
# SUBNET 
# =============================================================================

resource "aws_subnet" "private_subnet_1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-1a"
  cidr_block              = "192.168.3.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name        = "${var.project}-${var.environment}-private-subnet-1a"
    Project     = var.project
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_subnet" "private_subnet_1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-1c"
  cidr_block              = "192.168.4.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name        = "${var.project}-${var.environment}-private-subnet-1c"
    Project     = var.project
    Environment = var.environment
    Type        = "private"
  }
}

# =============================================================================
# SECURITY GROUP
# =============================================================================

resource "aws_security_group" "lambda_sg" {
  name        = "${var.project}-${var.environment}-lambda-sg"
  description = "lambda security group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name        = "${var.project}-${var.environment}-lambda-sg"
    Project     = var.project
    Environment = var.environment
  }
}


# =============================================================================
# LAMBDA 
# =============================================================================

resource "aws_lambda_function" "lambda" {
  function_name    = "${var.project}-lambda"
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "hello_lambda.lambda_handler"
  runtime          = "python3.6"


  vpc_config {
    security_group_ids = [
      aws_security_group.lambda_sg.id
    ]
    subnet_ids = [
      aws_subnet.private_subnet_1a.id,
      aws_subnet.private_subnet_1c.id
    ]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-lambda-function"
    Project     = var.project
    Environment = var.environment
  }

  environment {
    variables = {
      greeting = "Hello"
    }
  }
}
