// =============================================================================
// models/recado.dart — o formato do dado
// =============================================================================
// Um model é só a "forma" do dado dentro do app. Ele não sabe de tela, de
// BLoC nem de internet. Sua única responsabilidade extra é saber se montar a
// partir do JSON que a API devolve.
//
// A Lambda devolve cada recado assim:
//   {"id": "3f2a...", "autor": "Ana", "texto": "Olá turma!", "curtidas": 0, ...}
// Campos que o app não usa (ex.: criadoEm) são simplesmente ignorados.
// =============================================================================

class Recado {
  // "final": depois de criado, o recado não muda (objeto imutável).
  // Se algo mudar no servidor, o app busca a lista de novo e cria objetos novos.
  final String id; // gerado pela Lambda (uuid); usado no DELETE /recados/{id}
  final String autor;
  final String texto;
  final int curtidas; // contador do desafio; a Lambda começa em 0

  const Recado({
    required this.id,
    required this.autor,
    required this.texto,
    this.curtidas = 0,
  });

  // "factory" é um construtor que pode fazer trabalho antes de criar o objeto.
  // Recebe o Map que o jsonDecode produziu e lê cada chave.
  //
  // DÚVIDA COMUM: "type 'Null' is not a subtype of type 'String'"
  //   → o JSON veio sem uma dessas chaves (ex.: a Lambda grava "nome" em vez
  //     de "autor"). Os nomes aqui precisam bater com os da Lambda.
  factory Recado.fromJson(Map<String, dynamic> json) => Recado(
        id: json['id'] as String,
        autor: json['autor'] as String,
        texto: json['texto'] as String,
        // curtidas é NÚMERO no JSON. Ler como String dá
        // "type 'int' is not a subtype of type 'String'".
        // "as num?" + "?? 0" aceita int, double ou campo ausente sem quebrar.
        curtidas: (json['curtidas'] as num? ?? 0).toInt(),
      );
}
