resource "aws_api_gateway_rest_api" "key_test" {
  name        = "Serverlesskey_test"
  description = "Terraform Serverless Application key_test"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.key_test.invoke_url}"
}