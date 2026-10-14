"""Testes locais da Lambda com DynamoDB simulado (moto).  Rode: pytest backend/tests"""
import importlib
import json
import os
import sys

import boto3
import pytest
from moto import mock_aws

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


def evento(metodo, caminho, corpo=None):
    return {
        "rawPath": caminho,
        "requestContext": {"http": {"method": metodo}},
        "body": None if corpo is None else json.dumps(corpo),
    }


@pytest.fixture
def lf():
    os.environ.update(AWS_DEFAULT_REGION="us-east-1", AWS_ACCESS_KEY_ID="x",
                      AWS_SECRET_ACCESS_KEY="x", TABLE_NAME="Recados")
    with mock_aws():
        boto3.resource("dynamodb").create_table(
            TableName="Recados",
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        import lambda_function
        yield importlib.reload(lambda_function)


def test_fluxo_completo(lf):
    r = lf.lambda_handler(evento("POST", "/recados", {"autor": "Ana", "texto": "Olá, nuvem!"}), None)
    assert r["statusCode"] == 201
    criado = json.loads(r["body"])
    assert criado["texto"] == "Olá, nuvem!" and criado["curtidas"] == 0
    assert r["headers"]["Access-Control-Allow-Origin"] == "*"

    lista = json.loads(lf.lambda_handler(evento("GET", "/recados"), None)["body"])
    assert [x["id"] for x in lista] == [criado["id"]]

    r = lf.lambda_handler(evento("POST", f"/recados/{criado['id']}/curtir"), None)
    assert r["statusCode"] == 200 and json.loads(r["body"])["curtidas"] == 1

    assert lf.lambda_handler(evento("DELETE", f"/recados/{criado['id']}"), None)["statusCode"] == 204
    assert json.loads(lf.lambda_handler(evento("GET", "/recados"), None)["body"]) == []


def test_validacao_e_erros(lf):
    assert lf.lambda_handler(evento("POST", "/recados", {"autor": "", "texto": "x"}), None)["statusCode"] == 400
    assert lf.lambda_handler(evento("POST", "/recados", {"autor": "A", "texto": "x" * 281}), None)["statusCode"] == 400
    ruim = evento("POST", "/recados"); ruim["body"] = "{nao é json"
    assert lf.lambda_handler(ruim, None)["statusCode"] == 400
    assert lf.lambda_handler(evento("POST", "/recados/naoexiste/curtir"), None)["statusCode"] == 404
    assert lf.lambda_handler(evento("PUT", "/recados"), None)["statusCode"] == 404
    assert lf.lambda_handler(evento("OPTIONS", "/recados"), None)["statusCode"] == 204


def test_stage_nomeado_e_ordem(lf):
    lf.lambda_handler(evento("POST", "/prod/recados", {"autor": "A", "texto": "1"}), None)
    lf.lambda_handler(evento("POST", "/prod/recados", {"autor": "B", "texto": "2"}), None)
    lista = json.loads(lf.lambda_handler(evento("GET", "/prod/recados"), None)["body"])
    assert len(lista) == 2
    assert lista[0]["criadoEm"] >= lista[1]["criadoEm"]


def test_lista_mais_recentes_primeiro_com_muitos_itens(lf):
    with lf.TABELA.batch_writer() as b:
        for i in range(350):
            b.put_item(Item={"id": f"antigo-{i}", "autor": "x", "texto": "y" * 250,
                             "curtidas": 0, "criadoEm": f"2026-01-01T00:{i // 60:02d}:{i % 60:02d}+00:00"})
    novo = json.loads(lf.lambda_handler(evento("POST", "/recados", {"autor": "Bia", "texto": "novo"}), None)["body"])
    lista = json.loads(lf.lambda_handler(evento("GET", "/recados"), None)["body"])
    assert len(lista) == lf.MAX_RECADOS
    assert lista[0]["id"] == novo["id"]
