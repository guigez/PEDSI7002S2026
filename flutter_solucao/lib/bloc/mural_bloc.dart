// =============================================================================
// bloc/mural_bloc.dart — a lógica do app
// =============================================================================
// O BLoC recebe EVENTOS (o que a tela pediu) e emite ESTADOS (o que a tela
// deve mostrar). Ele fica no meio: não desenha nada e não sabe montar HTTP.
//
//   Tela  --add(Evento)-->  MuralBloc  --emit(Estado)-->  BlocBuilder redesenha
//
// Por dentro, o BLoC é um Stream: entram eventos, saem estados. Por isso a
// tela não precisa de Stream próprio nem de setState para a lista.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';

import '../provider/mural_api.dart';
import '../models/recado.dart';

// -----------------------------------------------------------------------------
// EVENTOS: o que a tela pode pedir
// -----------------------------------------------------------------------------
// "sealed" (Dart 3): só as classes deste arquivo podem estender MuralEvent.
// Assim o compilador conhece TODOS os eventos possíveis.
sealed class MuralEvent {}

/// Buscar a lista no servidor (abertura do app, botão de atualizar, e depois
/// de criar/apagar).
class CarregarRecados extends MuralEvent {}

/// Usuário clicou em enviar. Carrega os dados digitados.
class EnviarRecado extends MuralEvent {
  final String autor, texto;
  EnviarRecado(this.autor, this.texto);
}

/// Usuário clicou na lixeira de um recado.
class ApagarRecado extends MuralEvent {
  final String id;
  ApagarRecado(this.id);
}

// -----------------------------------------------------------------------------
// ESTADO: tudo o que a tela precisa para se desenhar
// -----------------------------------------------------------------------------
// Uma classe só, com 3 campos, em vez de uma classe por estado
// (Loading/Loaded/Error). É mais simples para iniciantes e permite manter a
// lista antiga visível enquanto carrega de novo.
class MuralState {
  final List<Recado> recados; // o que aparece na lista
  final bool carregando;      // true = mostrar o spinner (se a lista estiver vazia)
  final String? erro;         // != null = mostrar a mensagem no lugar da lista

  // Valores padrão: lista vazia, sem carregar, sem erro (estado inicial).
  const MuralState({this.recados = const [], this.carregando = false, this.erro});
}

// -----------------------------------------------------------------------------
// O BLOC
// -----------------------------------------------------------------------------
class MuralBloc extends Bloc<MuralEvent, MuralState> {
  final MuralApi api; // recebida pronta do main.dart (injeção de dependência)

  // super(const MuralState()) define o estado inicial.
  // Cada on<Evento>(função) diz: "quando chegar este evento, rode esta função".
  MuralBloc(this.api) : super(const MuralState()) {
    on<CarregarRecados>(_carregar);
    on<EnviarRecado>(_enviar);
    on<ApagarRecado>(_apagar);
  }

  // Cada handler recebe o evento e um "emit", que publica um novo estado.
  // "state" (sem underline) é o estado atual, herdado da classe Bloc.

  Future<void> _carregar(CarregarRecados event, Emitter<MuralState> emit) async {
    // 1) Avisa que está carregando, mantendo a lista atual na tela.
    //    Note que "erro" não é repassado: um novo carregamento limpa o erro
    //    anterior. É assim que o botão de atualizar "conserta" a tela.
    emit(MuralState(recados: state.recados, carregando: true));
    try {
      // 2) Busca na nuvem e publica a lista nova (carregando volta a false).
      emit(MuralState(recados: await api.listar()));
    } catch (e) {
      // 3) Qualquer Exception lançada no provider cai aqui e vira texto.
      //    '$e' mostra, por exemplo, "Exception: Erro 404".
      emit(MuralState(recados: state.recados, erro: '$e'));
    }
  }

  Future<void> _enviar(EnviarRecado event, Emitter<MuralState> emit) async {
    try {
      // Grava no servidor...
      await api.criar(event.autor, event.texto);
      // ...e pede para recarregar. add() dispara OUTRO evento para o próprio
      // bloc; quem emite a lista nova é o _carregar.
      //
      // Por que recarregar em vez de inserir o recado na lista local?
      //   - o id é gerado pela Lambda, o app não o tem antes de recarregar;
      //   - a lista passa a mostrar também o que as outras duplas postaram.
      //   Custo: uma chamada GET a mais por envio.
      add(CarregarRecados());
    } catch (e) {
      emit(MuralState(recados: state.recados, erro: '$e'));
    }
  }

  Future<void> _apagar(ApagarRecado event, Emitter<MuralState> emit) async {
    // Mesmo padrão do _enviar, chamando apagar().
    try {
      await api.apagar(event.id);
      add(CarregarRecados());
    } catch (e) {
      emit(MuralState(recados: state.recados, erro: '$e'));
    }
  }
}

// -----------------------------------------------------------------------------
// DÚVIDAS COMUNS
// -----------------------------------------------------------------------------
// • "Por que não chamar api.listar() direto dentro do _enviar?"
//     Funcionaria, mas duplicaria a lógica de carregando/erro. Disparar o
//     evento reaproveita o _carregar.
// • "Esqueci o await no api.criar e o recado não aparece / às vezes aparece."
//     Sem await, o add(CarregarRecados()) roda antes do POST terminar e o GET
//     pode chegar ao DynamoDB antes do recado ser gravado. Além disso, um erro
//     no POST não cai no catch.
// • "Emitter was called after an event handler completed"
//     Faltou await em alguma chamada antes de um emit, então o handler já
//     tinha terminado quando o emit rodou.
// • "Apareceu o erro e a lista sumiu."
//     A tela mostra o erro NO LUGAR da lista quando erro != null. O botão de
//     atualizar dispara CarregarRecados, que limpa o erro.
// -----------------------------------------------------------------------------
