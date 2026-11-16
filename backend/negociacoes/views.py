from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from contas.models import User
from negociacoes.models import Mensagem, Negociacao, OpcaoNegociacao
from negociacoes.serializers import (
    AbrirNegociacaoSerializer,
    MensagemSerializer,
    NegociacaoDetalheSerializer,
    NegociacaoListaSerializer,
    OpcaoNegociacaoSerializer,
)


def _visiveis(usuario):
    consulta = Negociacao.objects.select_related("produto", "empresa", "cliente")
    if usuario.papel == User.PAPEL_STAFF:
        return consulta
    if usuario.papel == User.PAPEL_EMPRESA:
        return consulta.filter(empresa__usuario=usuario)
    return consulta.filter(cliente=usuario)


def _obter(usuario, negociacao_id):
    return get_object_or_404(_visiveis(usuario), pk=negociacao_id)


def _exigir_participante(negociacao, usuario):
    if negociacao.cliente_id == usuario.id or negociacao.empresa.usuario_id == usuario.id:
        return
    raise PermissionDenied("Você não participa desta negociação.")


class NegociacaoListaView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        consulta = _visiveis(request.user).order_by("-atualizada_em")[:100]
        return Response(NegociacaoListaSerializer(consulta, many=True).data)

    def post(self, request):
        if request.user.papel != User.PAPEL_CLIENTE:
            raise PermissionDenied("A mesa é aberta por um cliente.")
        serial = AbrirNegociacaoSerializer(data=request.data)
        serial.is_valid(raise_exception=True)
        produto = serial.validated_data["produto"]
        if produto.empresa.usuario_id == request.user.id:
            raise ValidationError({"detail": "Você não negocia o próprio produto."})
        existente = (
            Negociacao.objects.filter(produto=produto, cliente=request.user)
            .exclude(status__in=[Negociacao.RECUSADA, Negociacao.ENCERRADA])
            .first()
        )
        if existente:
            return Response(NegociacaoDetalheSerializer(existente, context={"request": request}).data)
        negociacao = Negociacao.objects.create(
            produto=produto,
            cliente=request.user,
            empresa=produto.empresa,
        )
        texto = (serial.validated_data.get("mensagem") or "").strip()
        if texto:
            Mensagem.objects.create(negociacao=negociacao, autor=request.user, texto=texto)
        return Response(
            NegociacaoDetalheSerializer(negociacao, context={"request": request}).data,
            status=201,
        )


class NegociacaoDetalheView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, negociacao_id):
        negociacao = _obter(request.user, negociacao_id)
        return Response(NegociacaoDetalheSerializer(negociacao, context={"request": request}).data)


class MensagemView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, negociacao_id):
        negociacao = _obter(request.user, negociacao_id)
        _exigir_participante(negociacao, request.user)
        if negociacao.status == Negociacao.ENCERRADA:
            raise ValidationError({"detail": "Esta negociação está encerrada."})
        serial = MensagemSerializer(data=request.data, context={"request": request})
        serial.is_valid(raise_exception=True)
        mensagem = serial.save(negociacao=negociacao, autor=request.user)
        Negociacao.objects.filter(pk=negociacao.pk).update(atualizada_em=timezone.now())
        return Response(MensagemSerializer(mensagem, context={"request": request}).data, status=201)


class OpcaoView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, negociacao_id):
        negociacao = _obter(request.user, negociacao_id)
        if negociacao.empresa.usuario_id != request.user.id:
            raise PermissionDenied("Somente o vendedor envia opções.")
        if negociacao.status not in {Negociacao.ABERTA, Negociacao.OPCOES_ENVIADAS}:
            raise ValidationError({"detail": "Esta negociação não aceita novas opções."})
        serial = OpcaoNegociacaoSerializer(data=request.data)
        serial.is_valid(raise_exception=True)
        opcao = serial.save(negociacao=negociacao)
        if negociacao.status == Negociacao.ABERTA:
            negociacao.status = Negociacao.OPCOES_ENVIADAS
        negociacao.save(update_fields=["status", "atualizada_em"])
        return Response(OpcaoNegociacaoSerializer(opcao).data, status=201)


class AceitarOpcaoView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, negociacao_id, opcao_id):
        negociacao = _obter(request.user, negociacao_id)
        if negociacao.cliente_id != request.user.id:
            raise PermissionDenied("Somente o cliente aceita uma opção.")
        if negociacao.status not in {Negociacao.ABERTA, Negociacao.OPCOES_ENVIADAS}:
            raise ValidationError({"detail": "Esta negociação não está aberta para aceite."})
        opcao = get_object_or_404(OpcaoNegociacao, pk=opcao_id, negociacao=negociacao)
        negociacao.opcoes.update(escolhida=False)
        opcao.escolhida = True
        opcao.save(update_fields=["escolhida"])
        negociacao.status = Negociacao.ACEITA
        negociacao.save(update_fields=["status", "atualizada_em"])
        Mensagem.objects.create(
            negociacao=negociacao,
            autor=request.user,
            texto=f"Opção aceita: R$ {opcao.preco} · {opcao.get_tipo_entrega_display()}.",
        )
        negociacao.refresh_from_db()
        return Response(NegociacaoDetalheSerializer(negociacao, context={"request": request}).data)


class EncerrarNegociacaoView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, negociacao_id):
        negociacao = _obter(request.user, negociacao_id)
        _exigir_participante(negociacao, request.user)
        if negociacao.status == Negociacao.ENCERRADA:
            return Response(NegociacaoDetalheSerializer(negociacao, context={"request": request}).data)
        negociacao.status = Negociacao.ENCERRADA
        negociacao.save(update_fields=["status", "atualizada_em"])
        return Response(NegociacaoDetalheSerializer(negociacao, context={"request": request}).data)
