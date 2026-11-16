import json
import re
import urllib.error
import urllib.request

from django.utils import timezone

from empresas.checklist import ITENS


class CnpjNaoEncontrado(Exception):
    pass


class ErroConsulta(Exception):
    pass


def somente_digitos(valor) -> str:
    return re.sub(r"\D", "", valor or "")


def formatar_cnpj(valor) -> str:
    digitos = somente_digitos(valor)
    if len(digitos) != 14:
        return digitos
    return f"{digitos[:2]}.{digitos[2:5]}.{digitos[5:8]}/{digitos[8:12]}-{digitos[12:]}"


def _digito(base: str) -> str:
    pesos = list(range(len(base) - 7, 1, -1)) + list(range(9, 1, -1))
    soma = sum(int(digito) * peso for digito, peso in zip(base, pesos))
    resto = soma % 11
    return "0" if resto < 2 else str(11 - resto)


def cnpj_valido(valor) -> bool:
    digitos = somente_digitos(valor)
    if len(digitos) != 14 or digitos == digitos[0] * 14:
        return False
    primeiro = _digito(digitos[:12])
    segundo = _digito(digitos[:12] + primeiro)
    return digitos[-2:] == primeiro + segundo


def gerar_cnpj(base12: str) -> str:
    base = somente_digitos(base12)
    if len(base) != 12:
        raise ValueError("A base do CNPJ precisa ter 12 dígitos.")
    primeiro = _digito(base)
    segundo = _digito(base + primeiro)
    return base + primeiro + segundo


def consultar_brasilapi(cnpj: str) -> dict:
    digitos = somente_digitos(cnpj)
    url = f"https://brasilapi.com.br/api/cnpj/v1/{digitos}"
    requisicao = urllib.request.Request(url, headers={"User-Agent": "mercado-futuro/1.0", "Accept": "application/json"})
    try:
        with urllib.request.urlopen(requisicao, timeout=12) as resposta:
            return json.loads(resposta.read().decode())
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            raise CnpjNaoEncontrado() from exc
        raise ErroConsulta(f"A consulta pública respondeu com erro {exc.code}.") from exc
    except urllib.error.URLError as exc:
        raise ErroConsulta("Não foi possível alcançar o serviço público de CNPJ.") from exc


def _normalizar(texto) -> str:
    return re.sub(r"\s+", " ", (texto or "").strip()).casefold()


def _marcar(empresa, codigo, status, observacao, evidencia, usuario):
    from empresas.models import ItemChecklist

    item = empresa.checklist.get(codigo=codigo)
    item.status = status
    item.observacao = (observacao or "")[:500]
    item.evidencia = evidencia or ""
    item.marcado_por = usuario
    item.marcado_em = timezone.now()
    item.save()
    return item


def registrar_cnpj_nao_encontrado(empresa, usuario):
    return _marcar(
        empresa,
        "cnpj_ativo",
        "falha",
        "CNPJ não encontrado na base pública.",
        "",
        usuario,
    )


def aplicar_consulta_cnpj(empresa, dados: dict, usuario):
    from empresas.models import ItemChecklist

    situacao = (dados.get("descricao_situacao_cadastral") or "").strip()
    ativa = "ATIVA" in situacao.upper()
    evidencia = json.dumps(dados, ensure_ascii=False)[:15000]
    _marcar(
        empresa,
        "cnpj_ativo",
        ItemChecklist.OK if ativa else ItemChecklist.FALHA,
        "Consulta pública: situação cadastral ativa." if ativa else f"Situação cadastral: {situacao or 'não informada'}.",
        evidencia,
        usuario,
    )
    _marcar(
        empresa,
        "situacao_cadastral",
        ItemChecklist.OK if ativa else ItemChecklist.FALHA,
        situacao or "Situação não informada pela consulta.",
        evidencia,
        usuario,
    )
    razao_api = _normalizar(dados.get("razao_social"))
    razao_local = _normalizar(empresa.razao_social)
    confere = bool(razao_api) and (razao_api == razao_local or razao_local in razao_api or razao_api in razao_local)
    _marcar(
        empresa,
        "razao_social",
        ItemChecklist.OK if confere else ItemChecklist.FALHA,
        "Razão social confere com a consulta." if confere else f"Consulta pública: {dados.get('razao_social') or 'não informada'}.",
        evidencia,
        usuario,
    )
    descricao_cnae = dados.get("cnae_fiscal_descricao") or ""
    item_cnae = empresa.checklist.get(codigo="cnae")
    if item_cnae.status == ItemChecklist.PENDENTE and descricao_cnae:
        item_cnae.observacao = descricao_cnae[:500]
        item_cnae.evidencia = evidencia
        item_cnae.marcado_por = usuario
        item_cnae.marcado_em = timezone.now()
        item_cnae.save()
    return [codigo for codigo, _titulo in ITENS]
