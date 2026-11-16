from django.urls import path

from negociacoes.views import (
    AceitarOpcaoView,
    EncerrarNegociacaoView,
    MensagemView,
    NegociacaoDetalheView,
    NegociacaoListaView,
    OpcaoView,
)

urlpatterns = [
    path("negociacoes/", NegociacaoListaView.as_view(), name="negociacoes"),
    path("negociacoes/<int:negociacao_id>/", NegociacaoDetalheView.as_view(), name="negociacao"),
    path("negociacoes/<int:negociacao_id>/mensagens/", MensagemView.as_view(), name="mensagens"),
    path("negociacoes/<int:negociacao_id>/opcoes/", OpcaoView.as_view(), name="opcoes"),
    path(
        "negociacoes/<int:negociacao_id>/opcoes/<int:opcao_id>/aceitar/",
        AceitarOpcaoView.as_view(),
        name="aceitar-opcao",
    ),
    path("negociacoes/<int:negociacao_id>/encerrar/", EncerrarNegociacaoView.as_view(), name="encerrar"),
]
