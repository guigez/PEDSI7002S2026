# Mural da Turma (Flutter + BLoC) — SOLUÇÃO DO PROFESSOR

App de referência da prática: lê, cria, apaga e curte recados numa API serverless na AWS
(API Gateway → Lambda → DynamoDB). Os alunos fazem o próprio app do zero; este serve para
tirar dúvidas, testar a API antes da aula e projetar trechos quando uma dupla travar.

## Rodar

```bash
flutter create . --platforms=web,android   # só na 1ª vez: gera web/ e android/
flutter pub get
flutter run -d chrome
```

Depois do `flutter create .`, apague `test/widget_test.dart` (ele usa o `MyApp` do template
e quebra o `flutter analyze`).

## Configurar a API

A URL fica em `lib/provider/mural_api.dart`, na constante `apiUrl`, **sem barra no final**.

| API | URL |
|---|---|
| Ao vivo (criada no console na aula) | Invoke URL do API Gateway, copiada na hora |
| Reserva (Terraform, plano B) | `https://nk5fiyaei9.execute-api.us-east-2.amazonaws.com` |

## Arquivos

| Arquivo | Papel |
|---|---|
| `lib/main.dart` | Cria o `MuralBloc` (já carregando a lista) e abre a tela |
| `lib/models/recado.dart` | Modelo `Recado` (id, autor, texto, curtidas) e `fromJson` |
| `lib/provider/mural_api.dart` | Única parte que fala com a internet: um método por rota |
| `lib/bloc/mural_bloc.dart` | Eventos → estado (lista, carregando, erro) |
| `lib/view/mural_page.dart` | Tela: formulário, lista, curtir e apagar |

O código está comentado linha a linha, com as dúvidas mais comuns de cada camada.

## Rotas usadas

| Nível do enunciado | Provider | BLoC (evento) | Rota | Sucesso |
|---|---|---|---|---|
| 1 · Ler | `listar()` | `CarregarRecados` | `GET /recados` | 200 |
| 2 · Escrever | `criar(autor, texto)` | `EnviarRecado` | `POST /recados` | 201 |
| 3 · Apagar | `apagar(id)` | `ApagarRecado` | `DELETE /recados/{id}` | 204 |
| Desafio · Curtir | `curtir(id)` | `CurtirRecado` | `POST /recados/{id}/curtir` | 200 |

Todo evento que altera dados chama a API e depois dispara `CarregarRecados`, para a lista
mostrar também o que as outras duplas fizeram.

## Checklist antes da aula

- [ ] `flutter analyze` sem erros
- [ ] Com a URL da reserva: lista carrega, enviar, curtir e apagar funcionam no Chrome
- [ ] Nenhum erro de CORS no console do Chrome (F12)
