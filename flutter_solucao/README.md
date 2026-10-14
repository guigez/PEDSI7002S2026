# Mural da Turma (Flutter + BLoC) — SOLUÇÃO

```bash
flutter create . --platforms=web,android   # gera as pastas de plataforma
flutter pub get
flutter run -d chrome
```

## Arquivos

| Arquivo | Papel |
|---|---|
| `lib/main.dart` | Cria o `MuralBloc` e abre a tela |
| `lib/models/recado.dart` | Modelo: JSON → `Recado` |
| `lib/provider/mural_api.dart` | Conversa com a nuvem (HTTP) |
| `lib/bloc/mural_bloc.dart` | Eventos → estado |
| `lib/view/mural_page.dart` | Tela (só lê o estado e dispara eventos) |

## Lacunas

| TODO | Arquivo | O que fazer |
|---|---|---|
| 0 | `provider/mural_api.dart` | Colar a URL da sua API |
| 1 | `provider/mural_api.dart` | `criar()`: POST `/recados`, espera 201 |
| 2 | `provider/mural_api.dart` | `apagar()`: DELETE `/recados/{id}`, espera 204 |
| 3 | `bloc/mural_bloc.dart` | `_enviar`: chamar `api.criar` e recarregar |
| 4 | `bloc/mural_bloc.dart` | `_apagar`: chamar `api.apagar` e recarregar |

`listar()` e `_carregar` já estão prontos: use-os como modelo.
