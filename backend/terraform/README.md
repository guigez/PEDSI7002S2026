# API reserva (Terraform)

Cria a mesma arquitetura da aula, com nomes `mural-backup-*`, para usar se a demonstração ao vivo falhar.

| Recurso | Nome |
|---|---|
| Tabela DynamoDB (on-demand, chave `id`) | `mural-backup-recados` |
| Role IAM (logs + 4 ações na tabela) | `mural-backup-lambda-role` |
| Função Lambda (Python 3.13, `../lambda_function.py`) | `mural-backup-recados` |
| HTTP API com CORS e 4 rotas, stage `$default` | `mural-backup-api` |

## Subir

```powershell
aws sts get-caller-identity   # confere a credencial (não use a root)
terraform init
terraform apply               # responda yes; ~1 min
terraform output -raw api_url # cole no TODO 0, sem barra no final
```

## Testar

```powershell
$url = terraform output -raw api_url
Invoke-RestMethod "$url/recados"
Invoke-RestMethod -Method Post -Uri "$url/recados" -ContentType 'application/json' -Body '{"autor":"Gui","texto":"teste"}'
```

## Apagar tudo depois da aula

```powershell
terraform destroy
```

Custo esperado: centavos de dólar (tudo é cobrado por uso; parado, ~zero).
A API tem limite de 50 req/s (rajada de 100) para evitar abuso, já que não tem autenticação.
