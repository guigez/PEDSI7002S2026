# API reserva do Mural da Turma: DynamoDB <- Lambda <- API Gateway (HTTP API).
# Mesma arquitetura que será montada ao vivo no console, só que com outros nomes.

# ---------------------------------------------------------------- DynamoDB
resource "aws_dynamodb_table" "recados" {
  name         = "${var.prefixo}-recados"
  billing_mode = "PAY_PER_REQUEST" # on-demand: sem uso, quase sem custo
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# ---------------------------------------------------------------- IAM
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.prefixo}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

# Logs no CloudWatch
resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Privilégio mínimo: só as 4 ações que a função usa, só nesta tabela
data "aws_iam_policy_document" "tabela" {
  statement {
    actions = [
      "dynamodb:Scan",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
    ]
    resources = [aws_dynamodb_table.recados.arn]
  }
}

resource "aws_iam_role_policy" "tabela" {
  name   = "AcessoRecados"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.tabela.json
}

# ---------------------------------------------------------------- Lambda
# Empacota o mesmo lambda_function.py usado na aula (pasta backend/)
data "archive_file" "codigo" {
  type        = "zip"
  source_file = "${path.module}/../lambda_function.py"
  output_path = "${path.module}/build/lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.prefixo}-recados"
  retention_in_days = 7
}

resource "aws_lambda_function" "recados" {
  function_name    = "${var.prefixo}-recados"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.13"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.codigo.output_path
  source_code_hash = data.archive_file.codigo.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.recados.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.logs,
    aws_cloudwatch_log_group.lambda,
  ]
}

# ---------------------------------------------------------------- API Gateway (HTTP API)
resource "aws_apigatewayv2_api" "mural" {
  name          = "${var.prefixo}-api"
  protocol_type = "HTTP"

  # O API Gateway responde sozinho ao preflight (OPTIONS) do navegador
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.mural.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.recados.invoke_arn
  payload_format_version = "2.0"
}

locals {
  rotas = [
    "GET /recados",
    "POST /recados",
    "DELETE /recados/{id}",
    "POST /recados/{id}/curtir",
  ]
}

resource "aws_apigatewayv2_route" "rotas" {
  for_each  = toset(local.rotas)
  api_id    = aws_apigatewayv2_api.mural.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "padrao" {
  api_id      = aws_apigatewayv2_api.mural.id
  name        = "$default"
  auto_deploy = true

  # Evita abuso da API pública durante a aula
  default_route_settings {
    throttling_rate_limit  = 50
    throttling_burst_limit = 100
  }
}

# Permite que o API Gateway chame a Lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "PermitirApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recados.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.mural.execution_arn}/*/*"
}
