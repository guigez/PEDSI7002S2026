// =============================================================================
// main.dart — ponto de entrada do app
// =============================================================================
// Aqui as camadas são montadas e ligadas umas às outras:
//
//   view (MuralPage)  --eventos-->  bloc (MuralBloc)  --chama-->  provider (MuralApi)  --HTTP-->  AWS
//   view (MuralPage)  <--estados--  bloc (MuralBloc)  <--dados--  provider (MuralApi)  <--JSON--  AWS
//
// A tela nunca fala direto com a API: ela só dispara eventos e desenha estados.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'provider/mural_api.dart';
import 'bloc/mural_bloc.dart';
import 'view/mural_page.dart';

void main() {
  runApp(
    // BlocProvider (do pacote flutter_bloc, NÃO confundir com a nossa pasta
    // provider/) cria o MuralBloc e o deixa disponível para todos os widgets
    // abaixo dele na árvore. Qualquer widget filho consegue pegá-lo com
    // context.read<MuralBloc>() ou ouvi-lo com BlocBuilder.
    // Ele também chama bloc.close() sozinho quando o widget sai da tela.
    BlocProvider(
      // MuralApi() é passada pelo construtor (injeção de dependência):
      // o bloc não sabe COMO a API funciona, só que ela tem listar/criar/apagar.
      // Isso permite, por exemplo, trocar por uma API falsa num teste.
      //
      // O operador ".." (cascade) chama add() no bloc recém-criado e devolve
      // o próprio bloc. É o mesmo que:
      //   final bloc = MuralBloc(MuralApi());
      //   bloc.add(CarregarRecados());
      //   return bloc;
      // Ou seja: assim que o app abre, a lista já começa a ser carregada.
      create: (_) => MuralBloc(MuralApi())..add(CarregarRecados()),
      child: const MaterialApp(home: MuralPage()),
    ),
  );
}
