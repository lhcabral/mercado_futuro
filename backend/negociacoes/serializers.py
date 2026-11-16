from rest_framework import serializers

from catalogo.models import Produto
from negociacoes.models import Mensagem, Negociacao, OpcaoNegociacao

FORMAS_VALIDAS = {chave for chave, _rotulo in OpcaoNegociacao.FORMAS}


class MensagemSerializer(serializers.ModelSerializer):
    autor_nome = serializers.CharField(source="autor.nome", read_only=True)
    meu = serializers.SerializerMethodField()

    class Meta:
        model = Mensagem
        fields = ("id", "autor_nome", "texto", "criada_em", "meu")
        read_only_fields = ("id", "autor_nome", "criada_em", "meu")

    def get_meu(self, obj):
        usuario = self.context["request"].user
        return usuario.is_authenticated and obj.autor_id == usuario.id

    def validate_texto(self, value):
        texto = value.strip()
        if not texto:
            raise serializers.ValidationError("Escreva uma mensagem.")
        return texto


class OpcaoNegociacaoSerializer(serializers.ModelSerializer):
    class Meta:
        model = OpcaoNegociacao
        fields = (
            "id",
            "preco",
            "prazo_dias",
            "tipo_entrega",
            "formas_pagamento",
            "observacao",
            "validade",
            "escolhida",
            "criada_em",
        )
        read_only_fields = ("id", "escolhida", "criada_em")

    def validate_preco(self, value):
        if value < 0:
            raise serializers.ValidationError("O preço não pode ser negativo.")
        return value

    def validate_formas_pagamento(self, value):
        if not isinstance(value, list) or not value:
            raise serializers.ValidationError("Informe ao menos uma forma de pagamento.")
        invalidas = [item for item in value if item not in FORMAS_VALIDAS]
        if invalidas:
            raise serializers.ValidationError("Forma de pagamento inválida.")
        return list(dict.fromkeys(value))


class NegociacaoListaSerializer(serializers.ModelSerializer):
    produto_titulo = serializers.CharField(source="produto.titulo", read_only=True)
    produto_id = serializers.IntegerField(source="produto.id", read_only=True)
    fornecedor_nome = serializers.CharField(source="empresa.nome_fantasia", read_only=True)
    cliente_nome = serializers.CharField(source="cliente.nome", read_only=True)

    class Meta:
        model = Negociacao
        fields = (
            "id",
            "status",
            "produto_id",
            "produto_titulo",
            "fornecedor_nome",
            "cliente_nome",
            "atualizada_em",
        )


class NegociacaoDetalheSerializer(serializers.ModelSerializer):
    mensagens = MensagemSerializer(many=True, read_only=True)
    opcoes = OpcaoNegociacaoSerializer(many=True, read_only=True)
    produto_titulo = serializers.CharField(source="produto.titulo", read_only=True)
    produto_id = serializers.IntegerField(source="produto.id", read_only=True)
    fornecedor_nome = serializers.CharField(source="empresa.nome_fantasia", read_only=True)
    fornecedor_telefone = serializers.CharField(source="empresa.telefone", read_only=True)
    cliente_nome = serializers.CharField(source="cliente.nome", read_only=True)
    cliente_telefone = serializers.CharField(source="cliente.telefone", read_only=True)
    cliente_cidade = serializers.CharField(source="cliente.cidade", read_only=True)
    pode_enviar_opcao = serializers.SerializerMethodField()
    pode_aceitar = serializers.SerializerMethodField()
    pode_mensagem = serializers.SerializerMethodField()

    class Meta:
        model = Negociacao
        fields = (
            "id",
            "status",
            "produto_id",
            "produto_titulo",
            "fornecedor_nome",
            "fornecedor_telefone",
            "cliente_nome",
            "cliente_telefone",
            "cliente_cidade",
            "mensagens",
            "opcoes",
            "pode_enviar_opcao",
            "pode_aceitar",
            "pode_mensagem",
            "criada_em",
            "atualizada_em",
        )

    def _usuario(self):
        return self.context["request"].user

    def get_pode_enviar_opcao(self, obj):
        usuario = self._usuario()
        return (
            usuario.is_authenticated
            and obj.empresa.usuario_id == usuario.id
            and obj.status in {Negociacao.ABERTA, Negociacao.OPCOES_ENVIADAS}
        )

    def get_pode_aceitar(self, obj):
        usuario = self._usuario()
        return (
            usuario.is_authenticated
            and obj.cliente_id == usuario.id
            and obj.status in {Negociacao.ABERTA, Negociacao.OPCOES_ENVIADAS}
            and obj.opcoes.exists()
        )

    def get_pode_mensagem(self, obj):
        usuario = self._usuario()
        if not usuario.is_authenticated or obj.status == Negociacao.ENCERRADA:
            return False
        return obj.cliente_id == usuario.id or obj.empresa.usuario_id == usuario.id


class AbrirNegociacaoSerializer(serializers.Serializer):
    produto = serializers.PrimaryKeyRelatedField(
        queryset=Produto.objects.filter(status=Produto.PUBLICADO, empresa__status="aprovada")
    )
    mensagem = serializers.CharField(required=False, allow_blank=True, max_length=2000)
