import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'provider/mural_api.dart';
import 'bloc/mural_bloc.dart';
import 'view/mural_page.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => MuralBloc(MuralApi())..add(CarregarRecados()),
      child: const MaterialApp(home: MuralPage()),
    ),
  );
}
