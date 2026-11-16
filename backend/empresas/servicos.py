from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from empresas.checklist import OBRIGATORIOS
from empresas.models import Empresa, ItemChecklist

STATUS_ITEM = {chave for chave, _rotulo in ItemChecklist.STATUS}


def empresa_do_usuario(usuario):
    try:
        return usuario.empresa
    except Empresa.DoesNotExist:
        return None


def pendencias_para_aprovacao(empresa):
    return list(
        empresa.checklist.filter(codigo__in=OBRIGATORIOS)
        .exclude(status=ItemChecklist.OK)
        .order_by("ordem")
        .values_list("titulo", flat=True)
    )


def exigir_cadastro_completo(empresa):
    faltando = []
    if not empresa.razao_social:
        faltando.append("razão social")
    if not empresa.cnpj:
        faltando.append("CNPJ")
    if not empresa.nome_fantasia:
        faltando.append("nome fantasia")
    if not empresa.cidade or not empresa.uf:
        faltando.append("cidade e UF")
    if not empresa.logo:
        faltando.append("logomarca")
    if not empresa.documentos.exists():
        faltando.append("documento do responsável")
    if faltando:
        raise ValidationError(
            {"detail": "Complete o cadastro antes de enviar para análise.", "faltando": faltando}
        )


def enviar_para_analise(empresa):
    if empresa.status not in {Empresa.RASCUNHO, Empresa.RECUSADA}:
        raise ValidationError({"detail": "Este cadastro não pode ser reenviado para análise."})
    exigir_cadastro_completo(empresa)
    empresa.status = Empresa.EM_ANALISE
    empresa.motivo_recusa = ""
    empresa.save(update_fields=["status", "motivo_recusa", "atualizada_em"])
    return empresa


def marcar_item(empresa, codigo, status, observacao, usuario):
    if status not in STATUS_ITEM:
        raise ValidationError({"status": "Status de checklist inválido."})
    item = get_object_or_404(ItemChecklist, empresa=empresa, codigo=codigo)
    item.status = status
    item.observacao = (observacao or "").strip()
    item.marcado_por = usuario
    item.marcado_em = timezone.now()
    item.save()
    return item


def decidir_empresa(empresa, decisao, motivo, usuario):
    del usuario
    motivo = (motivo or "").strip()
    if decisao == Empresa.APROVADA:
        pendencias = pendencias_para_aprovacao(empresa)
        if pendencias:
            raise ValidationError({"detail": "Checklist incompleto.", "pendencias": pendencias})
        empresa.status = Empresa.APROVADA
        empresa.motivo_recusa = ""
    elif decisao in {Empresa.RECUSADA, Empresa.SUSPENSA}:
        if decisao == Empresa.RECUSADA and not motivo:
            raise ValidationError({"motivo": "Informe o motivo da recusa."})
        empresa.status = decisao
        empresa.motivo_recusa = motivo
    else:
        raise ValidationError({"decisao": "Decisão inválida."})
    empresa.save(update_fields=["status", "motivo_recusa", "atualizada_em"])
    return empresa
