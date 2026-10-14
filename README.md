# Aula Cloud (AWS) + Flutter: material de referência

Prática: **Mural da Turma**. Um app Flutter que lê e grava recados numa API serverless na AWS.

```
App Flutter  --HTTP/JSON-->  API Gateway (HTTP API)  -->  Lambda (Python 3.13)  -->  DynamoDB (tabela Recados)
```

## Estrutura

| Pasta | Para quê |
|---|---|
| `backend/lambda_function.py` | Código da Lambda (os alunos colam no console). |
| `backend/tests/` | Testes locais com DynamoDB simulado: `pip install boto3 moto pytest` e depois `pytest backend/tests` |
| `backend/template-plano-b.yaml` | CloudFormation que sobe tudo de uma vez: a **API compartilhada do professor** (plano B). |
| `app_flutter_inicial/` | O que os alunos recebem: app pronto, com TODOs só em `lib/services/mural_api.dart`. |
| `app_flutter_solucao/` | Gabarito, com `flutter test` cobrindo a camada de API. |

## Rodando um app

Os projetos trazem só `lib/` e `test/`. As pastas de plataforma são geradas na primeira vez:

```bash
cd app_flutter_inicial          # ou app_flutter_solucao
flutter create . --platforms=web,android
flutter pub get
# edite lib/config.dart com a URL da API
flutter run -d chrome
```

> Android: o `flutter create` já cuida da permissão de INTERNET no modo debug. Para build *release*, confira se
> `<uses-permission android:name="android.permission.INTERNET"/>` está em `android/app/src/main/AndroidManifest.xml`.

## Plano B (API compartilhada)

1. Console AWS → **CloudFormation** → *Create stack* → *Upload a template file* → `backend/template-plano-b.yaml`.
2. Na sua conta, deixe `RoleArnExistente` vazio. No Learner Lab, informe o ARN da `LabRole`.
3. Na aba **Outputs**, copie `ApiUrl` e distribua para a turma.
4. Depois da aula: **Delete stack** (apaga tabela, função e API).

Teste rápido: `curl <ApiUrl>/recados` deve devolver `[]`.
