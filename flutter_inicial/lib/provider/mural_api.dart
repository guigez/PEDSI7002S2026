import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recado.dart';

// TODO 0: cole aqui a URL da sua API (Invoke URL do API Gateway), sem barra no final.
const apiUrl = 'https://SEU-ID.execute-api.us-east-1.amazonaws.com';

/// Única parte do app que conversa com a nuvem.
class MuralApi {
  /// GET /recados -> 200 com a lista.  PRONTO: use como exemplo.
  Future<List<Recado>> listar() async {
    final resposta = await http.get(Uri.parse('$apiUrl/recados'));
    if (resposta.statusCode != 200) throw Exception('Erro ${resposta.statusCode}');
    final lista = jsonDecode(utf8.decode(resposta.bodyBytes)) as List;
    return lista.map((json) => Recado.fromJson(json)).toList();
  }

  /// POST /recados -> 201
  Future<void> criar(String autor, String texto) async {
    // TODO 1: envie um POST para '$apiUrl/recados' com
    //   headers: {'Content-Type': 'application/json'}
    //   body: jsonEncode({'autor': autor, 'texto': texto})
    // Lance uma Exception se o status for diferente de 201.
    throw UnimplementedError('TODO 1: criar()');
  }

  /// DELETE /recados/{id} -> 204
  Future<void> apagar(String id) async {
    // TODO 2: envie um DELETE para '$apiUrl/recados/$id'.
    // Lance uma Exception se o status for diferente de 204.
    throw UnimplementedError('TODO 2: apagar()');
  }
}
