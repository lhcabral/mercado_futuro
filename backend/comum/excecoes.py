from rest_framework.views import exception_handler

TRADUCOES = {
    "Authentication credentials were not provided.": "Entre na sua conta para continuar.",
    "Given token not valid for any token type": "Sessão expirada. Entre novamente.",
    "Token is invalid": "Sessão expirada. Entre novamente.",
    "Token is expired": "Sessão expirada. Entre novamente.",
    "Not found.": "Não encontrado.",
    "You do not have permission to perform this action.": "Você não tem permissão para esta ação.",
}


def traduzir_excecao(exc, context):
    resposta = exception_handler(exc, context)
    if resposta is None or not isinstance(resposta.data, dict):
        return resposta
    detalhe = resposta.data.get("detail")
    if isinstance(detalhe, str) and detalhe in TRADUCOES:
        resposta.data["detail"] = TRADUCOES[detalhe]
    return resposta
