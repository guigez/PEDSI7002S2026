output "api_url" {
  description = "Cole esta URL no TODO 0 (apiUrl), sem barra no final."
  value       = aws_apigatewayv2_api.mural.api_endpoint
}

output "teste" {
  description = "Abra no navegador: deve devolver [] (ou os recados)."
  value       = "${aws_apigatewayv2_api.mural.api_endpoint}/recados"
}
