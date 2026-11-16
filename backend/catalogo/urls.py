from django.urls import include, path
from rest_framework.routers import DefaultRouter

from catalogo.views import (
    CategoriaListView,
    FavoritoItemView,
    FavoritoView,
    ImagemProdutoView,
    PaginaFornecedorView,
    ProdutoViewSet,
)

router = DefaultRouter()
router.register("produtos", ProdutoViewSet, basename="produto")

urlpatterns = [
    path("categorias/", CategoriaListView.as_view(), name="categorias"),
    path("fornecedores/<slug:slug>/", PaginaFornecedorView.as_view(), name="pagina-fornecedor"),
    path("favoritos/", FavoritoView.as_view(), name="favoritos"),
    path("favoritos/<int:produto_id>/", FavoritoItemView.as_view(), name="favorito-item"),
    path("produtos/<int:produto_id>/imagens/", ImagemProdutoView.as_view(), name="imagens-produto"),
    path(
        "produtos/<int:produto_id>/imagens/<int:imagem_id>/",
        ImagemProdutoView.as_view(),
        name="imagem-produto",
    ),
    path("", include(router.urls)),
]
