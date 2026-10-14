// =============================================================================
// view/mural_page.dart — a tela
// =============================================================================
// A tela faz só duas coisas:
//   1) DISPARA eventos para o BLoC  -> context.read<MuralBloc>().add(...)
//   2) DESENHA o estado atual        -> BlocBuilder<MuralBloc, MuralState>
// Ela não chama a API e não guarda a lista. Quem tem a lista é o BLoC.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/mural_bloc.dart';

// Por que StatefulWidget se o estado está no BLoC?
//   Os TextEditingController (o texto dos campos) precisam ser criados uma vez
//   e descartados no dispose(). Isso é estado de TELA, não do app, e não faz
//   sentido colocar no BLoC.
class MuralPage extends StatefulWidget {
  const MuralPage({super.key});

  @override
  State<MuralPage> createState() => _MuralPageState();
}

class _MuralPageState extends State<MuralPage> {
  // Controladores: guardam e permitem ler/limpar o texto de cada TextField.
  final _autor = TextEditingController();
  final _texto = TextEditingController();

  @override
  void dispose() {
    // Libera os controladores quando a tela é destruída (evita vazamento).
    _autor.dispose();
    _texto.dispose();
    super.dispose();
  }

  void _enviar() {
    final autor = _autor.text.trim(); // trim() tira espaços das pontas
    final texto = _texto.text.trim();
    if (autor.isEmpty || texto.isEmpty) return; // não envia campo vazio

    // context.read: pega o bloc UMA vez, sem se inscrever para redesenhar.
    // É o certo para callbacks (onPressed, onSubmitted).
    // (context.watch seria para dentro do build, e redesenharia a cada estado.)
    context.read<MuralBloc>().add(EnviarRecado(autor, texto));

    // Limpa só o recado; o nome fica para o próximo envio.
    _texto.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mural da Turma'),
        actions: [
          // Recarrega a lista e também limpa uma mensagem de erro.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MuralBloc>().add(CarregarRecados()),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------------- Formulário: Nome | Recado | Enviar ----------------
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 140, // largura fixa para o nome
                  child: TextField(
                    controller: _autor,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                ),
                const SizedBox(width: 8),
                // Expanded: o campo do recado ocupa o espaço que sobrar na Row.
                Expanded(
                  child: TextField(
                    controller: _texto,
                    decoration: const InputDecoration(labelText: 'Recado'),
                    onSubmitted: (_) => _enviar(), // Enter também envia
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _enviar),
              ],
            ),
          ),

          // ---------------- Lista: depende do estado do BLoC ------------------
          // Expanded é obrigatório: um ListView dentro de Column sem altura
          // definida gera "Vertical viewport was given unbounded height".
          Expanded(
            // BlocBuilder escuta o MuralBloc e chama builder() a cada estado
            // novo. Só ESTE trecho é redesenhado, não a tela toda.
            child: BlocBuilder<MuralBloc, MuralState>(
              builder: (context, state) {
                // Spinner só na primeira carga (lista vazia). Nas recargas a
                // lista antiga continua na tela, sem "piscar".
                if (state.carregando && state.recados.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Erro tem prioridade sobre a lista. O "!" diz ao Dart que
                // erro não é null aqui (acabamos de checar).
                if (state.erro != null) {
                  return Center(child: Text(state.erro!));
                }
                // "for" dentro de lista (collection for): cria um ListTile por
                // recado. Para listas grandes, ListView.builder seria melhor
                // (só constrói o que está visível); aqui a lista é pequena.
                return ListView(
                  children: [
                    for (final r in state.recados)
                      ListTile(
                        title: Text(r.texto),
                        subtitle: Text(r.autor),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          // Manda o id do recado; a API usa no DELETE.
                          onPressed: () =>
                              context.read<MuralBloc>().add(ApagarRecado(r.id)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
