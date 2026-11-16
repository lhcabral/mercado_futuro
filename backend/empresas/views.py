from django.shortcuts import get_object_or_404
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from contas.models import User
from empresas.cnpj import (
    CnpjNaoEncontrado,
    ErroConsulta,
    aplicar_consulta_cnpj,
    consultar_brasilapi,
    registrar_cnpj_nao_encontrado,
)
from empresas.models import Empresa
from empresas.serializers import (
    DocumentoEmpresaSerializer,
    DocumentoEnvioSerializer,
    EmpresaDetalheSerializer,
    EmpresaEscritaSerializer,
    EmpresaResumoSerializer,
)
from empresas.servicos import decidir_empresa, enviar_para_analise, empresa_do_usuario, marcar_item


class EhEquipe(IsAuthenticated):
    message = "Apenas a equipe do aplicativo acessa esta área."

    def has_permission(self, request, view):
        return super().has_permission(request, view) and request.user.papel == User.PAPEL_STAFF


class MinhaEmpresaView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        empresa = empresa_do_usuario(request.user)
        if empresa is None:
            return Response({"detail": "Nenhuma empresa cadastrada."}, status=404)
        return Response(EmpresaDetalheSerializer(empresa, context={"request": request}).data)

    def post(self, request):
        serial = EmpresaEscritaSerializer(data=request.data, context={"request": request})
        serial.is_valid(raise_exception=True)
        empresa = serial.save()
        return Response(EmpresaDetalheSerializer(empresa, context={"request": request}).data, status=201)

    def patch(self, request):
        empresa = empresa_do_usuario(request.user)
        if empresa is None:
            return Response({"detail": "Nenhuma empresa cadastrada."}, status=404)
        serial = EmpresaEscritaSerializer(
            empresa,
            data=request.data,
            partial=True,
            context={"request": request},
        )
        serial.is_valid(raise_exception=True)
        empresa = serial.save()
        return Response(EmpresaDetalheSerializer(empresa, context={"request": request}).data)


class DocumentosEmpresaView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        empresa = empresa_do_usuario(request.user)
        if empresa is None:
            return Response({"detail": "Nenhuma empresa cadastrada."}, status=404)
        serial = DocumentoEnvioSerializer(data=request.data)
        serial.is_valid(raise_exception=True)
        documento = serial.save(empresa=empresa)
        return Response(DocumentoEmpresaSerializer(documento, context={"request": request}).data, status=201)


class EnviarAnaliseView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        empresa = empresa_do_usuario(request.user)
        if empresa is None:
            return Response({"detail": "Nenhuma empresa cadastrada."}, status=404)
        empresa = enviar_para_analise(empresa)
        return Response(EmpresaDetalheSerializer(empresa, context={"request": request}).data)


class FilaEmpresasView(APIView):
    permission_classes = [EhEquipe]

    def get(self, request):
        consulta = Empresa.objects.all().order_by("-atualizada_em")
        status = request.query_params.get("status")
        if status:
            consulta = consulta.filter(status=status)
        return Response(EmpresaResumoSerializer(consulta, many=True, context={"request": request}).data)


class EmpresaEquipeView(APIView):
    permission_classes = [EhEquipe]

    def get(self, request, empresa_id):
        empresa = get_object_or_404(Empresa, pk=empresa_id)
        return Response(EmpresaDetalheSerializer(empresa, context={"request": request}).data)


class ChecklistItemView(APIView):
    permission_classes = [EhEquipe]

    def post(self, request, empresa_id, codigo):
        empresa = get_object_or_404(Empresa, pk=empresa_id)
        item = marcar_item(
            empresa,
            codigo,
            request.data.get("status"),
            request.data.get("observacao", ""),
            request.user,
        )
        from empresas.serializers import ItemChecklistSerializer

        return Response(ItemChecklistSerializer(item).data)


class ConsultarCnpjView(APIView):
    permission_classes = [EhEquipe]

    def post(self, request, empresa_id):
        empresa = get_object_or_404(Empresa, pk=empresa_id)
        try:
            dados = consultar_brasilapi(empresa.cnpj)
        except CnpjNaoEncontrado:
            registrar_cnpj_nao_encontrado(empresa, request.user)
            empresa.refresh_from_db()
            return Response(EmpresaDetalheSerializer(empresa, context={"request": request}).data)
        except ErroConsulta as exc:
            return Response({"detail": str(exc)}, status=502)
        aplicar_consulta_cnpj(empresa, dados, request.user)
        empresa.refresh_from_db()
        return Response(EmpresaDetalheSerializer(empresa, context={"request": request}).data)


class DecidirEmpresaView(APIView):
    permission_classes = [EhEquipe]

    def post(self, request, empresa_id):
        empresa = get_object_or_404(Empresa, pk=empresa_id)
        empresa = decidir_empresa(
            empresa,
            request.data.get("decisao"),
            request.data.get("motivo", ""),
            request.user,
        )
        return Response(EmpresaDetalheSerializer(empresa, context={"request": request}).data)
