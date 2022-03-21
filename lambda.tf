terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "key-test-kml"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    
  }
}

resource "aws_ssm_parameter" "key_test" {
  name  = "key_test"
  type  = "String"
  value = "${var.key_test}"
}

resource "aws_lambda_function" "key_test" {
  function_name = "key_test2"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "key-test-kml"
  s3_key    = "v1.0.0/key_test.zip"

  # "key_test" is the filename within the zip file (key_test.py) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "key_test.handler"
  runtime = "python3.7"

  role = "${aws_iam_role.lambda_exec.arn}"
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_key_test_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.key_test.id}"
  parent_id   = "${aws_api_gateway_rest_api.key_test.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.key_test.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.key_test.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.key_test.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.key_test.id}"
  resource_id   = "${aws_api_gateway_rest_api.key_test.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.key_test.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.key_test.invoke_arn}"
}

resource "aws_api_gateway_deployment" "key_test" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.key_test.id}"
  stage_name  = "test"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.key_test.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.key_test.execution_arn}/*/*"
}