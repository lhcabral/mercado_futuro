from django.shortcuts import get_object_or_404
from rest_framework import viewsets
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from catalogo.filters import ProdutoFilter
from catalogo.models import Categoria, Favorito, ImagemProduto, Produto
from catalogo.serializers import (
    CategoriaSerializer,
    ImagemProdutoSerializer,
    PaginaFornecedorSerializer,
    ProdutoCardSerializer,
    ProdutoSerializer,
    _anotar_favorito,
)
from empresas.models import Empresa


class CategoriaListView(APIView):
    permission_classes = [AllowAny]
    pagination_class = None

    def get(self, request):
        return Response(CategoriaSerializer(Categoria.objects.all(), many=True).data)


class ProdutoViewSet(viewsets.ModelViewSet):
    filterset_class = ProdutoFilter
    ordering_fields = ["preco", "criado_em"]
    ordering = ["-criado_em"]
    parser_classes = [JSONParser, FormParser, MultiPartParser]
    http_method_names = ["get", "post", "patch", "delete", "head", "options"]

    def get_permissions(self):
        if self.action in {"list", "retrieve"}:
            return [AllowAny()]
        return [IsAuthenticated()]

    def get_serializer_class(self):
        if self.action == "list":
            return ProdutoCardSerializer
        return ProdutoSerializer

    def get_queryset(self):
        consulta = Produto.objects.select_related("empresa", "categoria").prefetch_related("imagens")
        usuario = self.request.user
        meus = self.request.query_params.get("meus") == "1"
        if meus or self.action in {"update", "partial_update", "destroy"}:
            if usuario.is_authenticated and usuario.papel == "empresa":
                return _anotar_favorito(consulta.filter(empresa__usuario=usuario), usuario)
            return consulta.none()
        publicados = consulta.filter(status=Produto.PUBLICADO, empresa__status=Empresa.APROVADA)
        if self.action == "retrieve" and usuario.is_authenticated and usuario.papel == "empresa":
            proprios = consulta.filter(empresa__usuario=usuario)
            return _anotar_favorito((publicados | proprios).distinct(), usuario)
        return _anotar_favorito(publicados, usuario)

    def get_serializer_context(self):
        contexto = super().get_serializer_context()
        if self.request.user.is_authenticated and self.request.user.papel == "empresa":
            try:
                contexto["empresa"] = self.request.user.empresa
            except Empresa.DoesNotExist:
                contexto["empresa"] = None
        return contexto

    def perform_create(self, serializer):
        if self.request.user.papel != "empresa":
            raise PermissionDenied("Apenas empresas cadastram produtos.")
        try:
            empresa = self.request.user.empresa
        except Empresa.DoesNotExist as exc:
            raise PermissionDenied("Cadastre a empresa antes de criar produtos.") from exc
        serializer.save(empresa=empresa)


class ImagemProdutoView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request, produto_id):
        produto = get_object_or_404(Produto, pk=produto_id, empresa__usuario=request.user)
        arquivo = request.FILES.get("imagem")
        if arquivo is None:
            return Response({"imagem": "Envie o arquivo no campo imagem."}, status=400)
        imagem = ImagemProduto.objects.create(produto=produto, imagem=arquivo, ordem=produto.imagens.count())
        return Response(ImagemProdutoSerializer(imagem, context={"request": request}).data, status=201)

    def delete(self, request, produto_id, imagem_id):
        imagem = get_object_or_404(
            ImagemProduto,
            pk=imagem_id,
            produto_id=produto_id,
            produto__empresa__usuario=request.user,
        )
        imagem.imagem.delete(save=False)
        imagem.delete()
        return Response(status=204)


class FavoritoView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        favoritos = (
            Favorito.objects.filter(usuario=request.user)
            .select_related("produto__empresa", "produto__categoria")
            .prefetch_related("produto__imagens")
        )
        produtos = [item.produto for item in favoritos]
        for produto in produtos:
            produto.eh_favorito = True
        return Response(ProdutoCardSerializer(produtos, many=True, context={"request": request}).data)

    def post(self, request):
        produto = get_object_or_404(
            Produto,
            pk=request.data.get("produto"),
            status=Produto.PUBLICADO,
            empresa__status=Empresa.APROVADA,
        )
        Favorito.objects.get_or_create(usuario=request.user, produto=produto)
        return Response({"produto": produto.id, "favorito": True}, status=201)


class FavoritoItemView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, produto_id):
        Favorito.objects.filter(usuario=request.user, produto_id=produto_id).delete()
        return Response(status=204)


class PaginaFornecedorView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, slug):
        empresa = get_object_or_404(Empresa, slug=slug, status=Empresa.APROVADA)
        return Response(PaginaFornecedorSerializer(empresa, context={"request": request}).data)
