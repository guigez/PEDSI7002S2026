"""Mural da Turma - backend serverless (API Gateway HTTP API -> Lambda -> DynamoDB).

Rotas (configuradas no API Gateway):
  GET    /recados               -> lista os recados (mais recentes primeiro)
  POST   /recados               -> cria um recado  {"autor": "...", "texto": "..."}
  DELETE /recados/{id}          -> apaga um recado
  POST   /recados/{id}/curtir   -> soma 1 curtida (desafio extra)

Variavel de ambiente: TABLE_NAME (padrao "Recados"). Chave de particao: id (String).
"""
import json
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal

import boto3

TABELA = boto3.resource("dynamodb").Table(os.environ.get("TABLE_NAME", "Recados"))

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}


def resposta(status, corpo=None):
    def converte(o):  # DynamoDB devolve numeros como Decimal
        if isinstance(o, Decimal):
            return int(o)
        raise TypeError
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json", **CORS},
        "body": "" if corpo is None else json.dumps(corpo, default=converte, ensure_ascii=False),
    }


MAX_RECADOS = 300


def listar():
    # Scan devolve os itens em ordem arbitraria e no maximo 1 MB por pagina:
    # le todas as paginas antes de ordenar, senao os recados novos podem sumir.
    itens, kwargs = [], {}
    while True:
        pagina = TABELA.scan(**kwargs)
        itens.extend(pagina.get("Items", []))
        if "LastEvaluatedKey" not in pagina:
            break
        kwargs["ExclusiveStartKey"] = pagina["LastEvaluatedKey"]
    itens.sort(key=lambda r: r.get("criadoEm", ""), reverse=True)
    return resposta(200, itens[:MAX_RECADOS])


def criar(evento):
    try:
        dados = json.loads(evento.get("body") or "{}")
    except json.JSONDecodeError:
        return resposta(400, {"erro": "JSON invalido"})
    autor = str(dados.get("autor", "")).strip()
    texto = str(dados.get("texto", "")).strip()
    if not (1 <= len(autor) <= 40) or not (1 <= len(texto) <= 280):
        return resposta(400, {"erro": "autor (1-40) e texto (1-280) sao obrigatorios"})
    recado = {
        "id": str(uuid.uuid4()),
        "autor": autor,
        "texto": texto,
        "curtidas": 0,
        "criadoEm": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    TABELA.put_item(Item=recado)
    return resposta(201, recado)


def apagar(rid):
    TABELA.delete_item(Key={"id": rid})
    return resposta(204)


def curtir(rid):
    try:
        r = TABELA.update_item(
            Key={"id": rid},
            UpdateExpression="ADD curtidas :um",
            ConditionExpression="attribute_exists(id)",
            ExpressionAttributeValues={":um": 1},
            ReturnValues="ALL_NEW",
        )
    except TABELA.meta.client.exceptions.ConditionalCheckFailedException:
        return resposta(404, {"erro": "recado nao encontrado"})
    return resposta(200, r["Attributes"])


def lambda_handler(evento, contexto):
    metodo = evento["requestContext"]["http"]["method"]
    partes = [p for p in evento.get("rawPath", "/").split("/") if p]
    # Com stage nomeado (ex.: /prod/recados) ignoramos o prefixo
    if partes and partes[0] != "recados":
        partes = partes[1:]

    if metodo == "OPTIONS":
        return resposta(204)
    if partes == ["recados"] and metodo == "GET":
        return listar()
    if partes == ["recados"] and metodo == "POST":
        return criar(evento)
    if len(partes) == 2 and partes[0] == "recados" and metodo == "DELETE":
        return apagar(partes[1])
    if len(partes) == 3 and partes[0] == "recados" and partes[2] == "curtir" and metodo == "POST":
        return curtir(partes[1])
    return resposta(404, {"erro": f"rota nao encontrada: {metodo} /{'/'.join(partes)}"})
