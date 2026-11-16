from django.db.models import Exists, OuterRef
from rest_framework import serializers

from comum.arquivos import url_absoluta
from comum.slugs import gerar_slug
from empresas.models import Empresa
from empresas.serializers import EmpresaResumoSerializer
from catalogo.models import Categoria, Favorito, ImagemProduto, Produto


class CategoriaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Categoria
        fields = ("id", "nome", "slug", "pai")


class ImagemProdutoSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = ImagemProduto
        fields = ("id", "url", "ordem")

    def get_url(self, obj):
        return url_absoluta(self.context.get("request"), obj.imagem)


class ProdutoCardSerializer(serializers.ModelSerializer):
    capa = serializers.SerializerMethodField()
    categoria_nome = serializers.SerializerMethodField()
    fornecedor_nome = serializers.CharField(source="empresa.nome_fantasia", read_only=True)
    fornecedor_slug = serializers.CharField(source="empresa.slug", read_only=True)
    favorito = serializers.SerializerMethodField()

    class Meta:
        model = Produto
        fields = (
            "id",
            "titulo",
            "slug",
            "preco",
            "condicao",
            "cidade",
            "uf",
            "capa",
            "categoria_nome",
            "fornecedor_nome",
            "fornecedor_slug",
            "favorito",
            "status",
        )

    def get_categoria_nome(self, obj):
        if not obj.categoria_id:
            return ""
        return obj.categoria.nome

    def get_capa(self, obj):
        imagens = list(obj.imagens.all())
        if not imagens:
            return None
        return url_absoluta(self.context.get("request"), imagens[0].imagem)

    def get_favorito(self, obj):
        if hasattr(obj, "eh_favorito"):
            return bool(obj.eh_favorito)
        usuario = self.context["request"].user
        if not usuario.is_authenticated:
            return False
        return Favorito.objects.filter(usuario=usuario, produto=obj).exists()


class ProdutoSerializer(serializers.ModelSerializer):
    imagens = ImagemProdutoSerializer(many=True, read_only=True)
    fornecedor = EmpresaResumoSerializer(source="empresa", read_only=True)
    categoria_nome = serializers.SerializerMethodField()
    favorito = serializers.SerializerMethodField()

    class Meta:
        model = Produto
        fields = (
            "id",
            "titulo",
            "slug",
            "descricao",
            "preco",
            "condicao",
            "estoque",
            "cidade",
            "uf",
            "status",
            "categoria",
            "categoria_nome",
            "imagens",
            "fornecedor",
            "favorito",
            "criado_em",
            "atualizado_em",
        )
        read_only_fields = ("slug", "criado_em", "atualizado_em")

    def get_categoria_nome(self, obj):
        if not obj.categoria_id:
            return ""
        return obj.categoria.nome

    def get_favorito(self, obj):
        if hasattr(obj, "eh_favorito"):
            return bool(obj.eh_favorito)
        usuario = self.context["request"].user
        if not usuario.is_authenticated:
            return False
        return Favorito.objects.filter(usuario=usuario, produto=obj).exists()

    def validate_preco(self, value):
        if value < 0:
            raise serializers.ValidationError("O preço não pode ser negativo.")
        return value

    def validate(self, attrs):
        status = attrs.get("status", getattr(self.instance, "status", Produto.RASCUNHO))
        empresa = getattr(self.instance, "empresa", None) or self.context.get("empresa")
        if status == Produto.PUBLICADO and (empresa is None or empresa.status != Empresa.APROVADA):
            raise serializers.ValidationError(
                "A empresa precisa estar aprovada para publicar produtos."
            )
        return attrs

    def create(self, validated):
        empresa = validated.pop("empresa")
        validated["slug"] = gerar_slug(validated["titulo"], Produto)
        validated["cidade"] = validated.get("cidade") or empresa.cidade
        validated["uf"] = validated.get("uf") or empresa.uf
        return Produto.objects.create(empresa=empresa, **validated)


class PaginaFornecedorSerializer(serializers.ModelSerializer):
    cores = serializers.SerializerMethodField()
    logo = serializers.SerializerMethodField()
    produtos = serializers.SerializerMethodField()

    class Meta:
        model = Empresa
        fields = (
            "id",
            "nome_fantasia",
            "slug",
            "descricao",
            "cidade",
            "uf",
            "telefone",
            "logo",
            "cores",
            "produtos",
        )

    def get_cores(self, obj):
        return obj.cores

    def get_logo(self, obj):
        return url_absoluta(self.context.get("request"), obj.logo)

    def get_produtos(self, obj):
        consulta = (
            obj.produtos.filter(status=Produto.PUBLICADO)
            .select_related("categoria", "empresa")
            .prefetch_related("imagens")
            .order_by("-criado_em")[:200]
        )
        consulta = _anotar_favorito(consulta, self.context["request"].user)
        return ProdutoCardSerializer(consulta, many=True, context=self.context).data


def _anotar_favorito(consulta, usuario):
    if not usuario.is_authenticated:
        return consulta
    return consulta.annotate(
        eh_favorito=Exists(Favorito.objects.filter(usuario=usuario, produto=OuterRef("pk")))
    )
