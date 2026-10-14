/// Um recado do mural, como a API devolve em JSON:
/// {"id": "...", "autor": "...", "texto": "..."}
class Recado {
  final String id;
  final String autor;
  final String texto;

  const Recado({required this.id, required this.autor, required this.texto});

  factory Recado.fromJson(Map<String, dynamic> json) => Recado(
        id: json['id'] as String,
        autor: json['autor'] as String,
        texto: json['texto'] as String,
      );
}
