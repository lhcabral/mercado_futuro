from django.urls import path

from empresas.views import (
    ChecklistItemView,
    ConsultarCnpjView,
    DecidirEmpresaView,
    DocumentosEmpresaView,
    EmpresaEquipeView,
    EnviarAnaliseView,
    FilaEmpresasView,
    MinhaEmpresaView,
)

urlpatterns = [
    path("empresas/minha/", MinhaEmpresaView.as_view(), name="minha-empresa"),
    path("empresas/minha/documentos/", DocumentosEmpresaView.as_view(), name="documentos-empresa"),
    path("empresas/minha/enviar-analise/", EnviarAnaliseView.as_view(), name="enviar-analise"),
    path("admin/empresas/", FilaEmpresasView.as_view(), name="fila-empresas"),
    path("admin/empresas/<int:empresa_id>/", EmpresaEquipeView.as_view(), name="empresa-equipe"),
    path(
        "admin/empresas/<int:empresa_id>/checklist/<slug:codigo>/",
        ChecklistItemView.as_view(),
        name="checklist-item",
    ),
    path(
        "admin/empresas/<int:empresa_id>/consultar-cnpj/",
        ConsultarCnpjView.as_view(),
        name="consultar-cnpj",
    ),
    path("admin/empresas/<int:empresa_id>/decidir/", DecidirEmpresaView.as_view(), name="decidir-empresa"),
]
