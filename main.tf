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

resource "aws_lambda_function" "lambda" {
  function_name    = "${var.project}-lambda"
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "hello_lambda.lambda_handler"
  runtime          = "python3.6"

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
