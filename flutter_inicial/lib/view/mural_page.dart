import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/mural_bloc.dart';

class MuralPage extends StatefulWidget {
  const MuralPage({super.key});

  @override
  State<MuralPage> createState() => _MuralPageState();
}

class _MuralPageState extends State<MuralPage> {
  final _autor = TextEditingController();
  final _texto = TextEditingController();

  @override
  void dispose() {
    _autor.dispose();
    _texto.dispose();
    super.dispose();
  }

  void _enviar() {
    final autor = _autor.text.trim();
    final texto = _texto.text.trim();
    if (autor.isEmpty || texto.isEmpty) return;
    context.read<MuralBloc>().add(EnviarRecado(autor, texto));
    _texto.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mural da Turma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MuralBloc>().add(CarregarRecados()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _autor,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _texto,
                    decoration: const InputDecoration(labelText: 'Recado'),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _enviar),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<MuralBloc, MuralState>(
              builder: (context, state) {
                if (state.carregando && state.recados.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.erro != null) {
                  return Center(child: Text(state.erro!));
                }
                return ListView(
                  children: [
                    for (final r in state.recados)
                      ListTile(
                        title: Text(r.texto),
                        subtitle: Text(r.autor),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
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
