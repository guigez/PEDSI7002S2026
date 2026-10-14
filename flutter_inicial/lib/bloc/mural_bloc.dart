import 'package:flutter_bloc/flutter_bloc.dart';

import '../provider/mural_api.dart';
import '../models/recado.dart';

// Eventos: o que a tela pede.
sealed class MuralEvent {}

class CarregarRecados extends MuralEvent {}

class EnviarRecado extends MuralEvent {
  final String autor, texto;
  EnviarRecado(this.autor, this.texto);
}

class ApagarRecado extends MuralEvent {
  final String id;
  ApagarRecado(this.id);
}

// Estado: o que a tela mostra.
class MuralState {
  final List<Recado> recados;
  final bool carregando;
  final String? erro;
  const MuralState({this.recados = const [], this.carregando = false, this.erro});
}

class MuralBloc extends Bloc<MuralEvent, MuralState> {
  final MuralApi api;

  MuralBloc(this.api) : super(const MuralState()) {
    on<CarregarRecados>(_carregar);
    on<EnviarRecado>(_enviar);
    on<ApagarRecado>(_apagar);
  }

  /// PRONTO: use como exemplo.
  Future<void> _carregar(CarregarRecados event, Emitter<MuralState> emit) async {
    emit(MuralState(recados: state.recados, carregando: true));
    try {
      emit(MuralState(recados: await api.listar()));
    } catch (e) {
      emit(MuralState(recados: state.recados, erro: '$e'));
    }
  }

  Future<void> _enviar(EnviarRecado event, Emitter<MuralState> emit) async {
    // TODO 3: chame api.criar(event.autor, event.texto) e, se der certo,
    // recarregue a lista com add(CarregarRecados()).
    // Se der erro, emita MuralState(recados: state.recados, erro: '$e').
    emit(MuralState(recados: state.recados, erro: 'TODO 3: implemente _enviar em lib/bloc/mural_bloc.dart'));
  }

  Future<void> _apagar(ApagarRecado event, Emitter<MuralState> emit) async {
    // TODO 4: igual ao TODO 3, mas chamando api.apagar(event.id).
    emit(MuralState(recados: state.recados, erro: 'TODO 4: implemente _apagar em lib/bloc/mural_bloc.dart'));
  }
}
