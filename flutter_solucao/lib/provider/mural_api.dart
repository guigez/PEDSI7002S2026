// =============================================================================
// provider/mural_api.dart — a ÚNICA parte do app que fala com a internet
// =============================================================================
// Cada método corresponde a uma rota do API Gateway, que repassa a chamada
// para a Lambda, que lê/escreve no DynamoDB:
//
//   listar()  -> GET    /recados        -> 200 + lista em JSON
//   criar()   -> POST   /recados        -> 201
//   apagar()  -> DELETE /recados/{id}   -> 204 (sem corpo)
//
// Por que Future e não Stream? Cada chamada HTTP é um pedido e UMA resposta.
// Stream serve quando o dado chega sozinho, várias vezes, sem ninguém pedir.
//
// Regra adotada: se o status não for o esperado, lança Exception. Quem trata
// o erro é o BLoC (try/catch), que transforma em mensagem para a tela.
// =============================================================================

import 'dart:convert'; // jsonEncode, jsonDecode, utf8

import 'package:http/http.dart' as http; // "as http" evita conflito de nomes: http.get, http.post...

import '../models/recado.dart';

// Invoke URL do API Gateway (Console > API Gateway > sua API > Stages).
// SEM barra no final: o código já monta '$apiUrl/recados'.
// Com barra, a URL vira '...com//recados' e o API Gateway responde 404.
const apiUrl = 'https://SEU-ID.execute-api.us-east-1.amazonaws.com';

class MuralApi {
  /// GET /recados -> 200 com a lista.
  Future<List<Recado>> listar() async {
    // "await" pausa ESTA função até a resposta chegar, sem travar a tela.
    // Uri.parse transforma a String em um objeto Uri, que o pacote http exige.
    final resposta = await http.get(Uri.parse('$apiUrl/recados'));

    if (resposta.statusCode != 200) throw Exception('Erro ${resposta.statusCode}');

    // Por que utf8.decode(bodyBytes) e não resposta.body?
    //   resposta.body decodifica como Latin-1 quando o servidor não informa o
    //   charset no header. Resultado: "Olá" aparece como "OlÃ¡".
    //   Decodificando os bytes em UTF-8 na mão, os acentos ficam certos.
    //
    // jsonDecode devolve "dynamic"; "as List" diz ao Dart que é uma lista.
    final lista = jsonDecode(utf8.decode(resposta.bodyBytes)) as List;

    // Converte cada Map do JSON em um objeto Recado.
    // .map(...) devolve um Iterable "preguiçoso"; .toList() materializa a lista.
    return lista.map((json) => Recado.fromJson(json)).toList();
  }

  /// POST /recados -> 201 (Created)
  Future<void> criar(String autor, String texto) async {
    final resposta = await http.post(
      Uri.parse('$apiUrl/recados'),
      // Avisa o servidor que o corpo é JSON.
      headers: {'Content-Type': 'application/json'},
      // jsonEncode transforma o Map em String: {"autor":"Ana","texto":"Oi"}
      // A Lambda lê exatamente as chaves "autor" e "texto".
      body: jsonEncode({'autor': autor, 'texto': texto}),
    );

    // DÚVIDA COMUM: veio 400 → corpo sem autor/texto, chaves com outro nome, ou
    //                          tamanho fora do limite (autor 1-40, texto 1-280).
    //               veio 404 → rota errada (ex.: /recado, sem "s") ou rota
    //                          POST não criada no API Gateway.
    //               veio 500 → erro dentro da Lambda (ver CloudWatch Logs).
    if (resposta.statusCode != 201) throw Exception('Erro ${resposta.statusCode}');
  }

  /// DELETE /recados/{id} -> 204 (No Content)
  Future<void> apagar(String id) async {
    // O id vai na própria URL; DELETE não precisa de corpo nem de header.
    final resposta = await http.delete(Uri.parse('$apiUrl/recados/$id'));

    // DÚVIDA COMUM: "esperava 200": DELETE bem-sucedido sem corpo devolve 204.
    if (resposta.statusCode != 204) throw Exception('Erro ${resposta.statusCode}');
  }
}

// -----------------------------------------------------------------------------
// ERROS QUE NÃO VIRAM statusCode (a chamada falha antes de ter resposta)
// -----------------------------------------------------------------------------
// • "ClientException: Failed to fetch" rodando no Chrome:
//     quase sempre é CORS. O navegador bloqueia a resposta se o API Gateway
//     não tiver CORS liberado (Allow-Origin *, métodos GET/POST/DELETE,
//     header content-type). No Android/emulador CORS não existe, por isso
//     "funciona no celular e não no Chrome".
// • "Failed host lookup": URL digitada errada ou sem internet.
// • Android em build release sem internet: falta
//     <uses-permission android:name="android.permission.INTERNET"/>
//     no AndroidManifest.xml (em debug o Flutter já inclui).
// -----------------------------------------------------------------------------
