# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
  required_version = ">= 1.1.0"
}

provider "aws" {
  region = "us-east-1"
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/nodejs/"
  output_path = "${path.module}/index.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "m_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_lambda_function" "myfunction" {
  function_name = "myfunction"
  handler      = "index.handler"
  runtime      = "nodejs14.x"
  filename     = data.archive_file.zip_the_python_code.output_path

  # source_code_hash = filebase64sha256("index.zip")

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_function_url" "lambda_function_url" {
  function_name      = aws_lambda_function.myfunction.arn
  authorization_type = "NONE"
}

output "function_url" {
  description = "Function URL."
  value       = aws_lambda_function_url.lambda_function_url.function_url
}
