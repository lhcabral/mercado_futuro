from django.conf import settings
from django.db import models

from catalogo.models import Produto
from empresas.models import Empresa


class Negociacao(models.Model):
    ABERTA = "aberta"
    OPCOES_ENVIADAS = "opcoes_enviadas"
    ACEITA = "aceita"
    RECUSADA = "recusada"
    ENCERRADA = "encerrada"
    STATUS = [
        (ABERTA, "Aberta"),
        (OPCOES_ENVIADAS, "Opções enviadas"),
        (ACEITA, "Aceita"),
        (RECUSADA, "Recusada"),
        (ENCERRADA, "Encerrada"),
    ]
    ATIVAS = {ABERTA, OPCOES_ENVIADAS, ACEITA}

    produto = models.ForeignKey(Produto, on_delete=models.CASCADE, related_name="negociacoes")
    cliente = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="negociacoes",
    )
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name="negociacoes")
    status = models.CharField(max_length=20, choices=STATUS, default=ABERTA)
    criada_em = models.DateTimeField(auto_now_add=True)
    atualizada_em = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "negociação"
        verbose_name_plural = "negociações"
        ordering = ["-atualizada_em"]

    def __str__(self):
        return f"{self.cliente} · {self.produto}"


class Mensagem(models.Model):
    negociacao = models.ForeignKey(Negociacao, on_delete=models.CASCADE, related_name="mensagens")
    autor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="mensagens",
    )
    texto = models.TextField()
    criada_em = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["criada_em"]

    def __str__(self):
        return self.texto[:40]


class OpcaoNegociacao(models.Model):
    RETIRADA = "retirada"
    ENVIO = "envio"
    COMBINAR = "combinar"
    ENTREGAS = [
        (RETIRADA, "Retirada"),
        (ENVIO, "Envio"),
        (COMBINAR, "A combinar"),
    ]
    FORMAS = [
        ("pix", "PIX"),
        ("boleto", "Boleto"),
        ("cartao", "Cartão"),
        ("dinheiro", "Dinheiro"),
    ]

    negociacao = models.ForeignKey(Negociacao, on_delete=models.CASCADE, related_name="opcoes")
    preco = models.DecimalField("preço", max_digits=12, decimal_places=2)
    prazo_dias = models.PositiveIntegerField(null=True, blank=True)
    tipo_entrega = models.CharField(max_length=20, choices=ENTREGAS)
    formas_pagamento = models.JSONField(default=list)
    observacao = models.TextField(blank=True)
    validade = models.DateField(null=True, blank=True)
    escolhida = models.BooleanField(default=False)
    criada_em = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "opção de negociação"
        verbose_name_plural = "opções de negociação"
        ordering = ["criada_em"]

    def __str__(self):
        return f"R$ {self.preco} · {self.get_tipo_entrega_display()}"
