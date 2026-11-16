from django.contrib import admin

from catalogo.models import Categoria, Favorito, ImagemProduto, Produto


class ImagemInline(admin.TabularInline):
    model = ImagemProduto
    extra = 0


@admin.register(Categoria)
class CategoriaAdmin(admin.ModelAdmin):
    list_display = ("nome", "slug", "pai")
    prepopulated_fields = {"slug": ("nome",)}
    search_fields = ("nome",)


@admin.register(Produto)
class ProdutoAdmin(admin.ModelAdmin):
    list_display = ("titulo", "empresa", "preco", "status", "cidade", "uf")
    list_filter = ("status", "condicao", "uf")
    search_fields = ("titulo", "empresa__nome_fantasia")
    inlines = [ImagemInline]


@admin.register(Favorito)
class FavoritoAdmin(admin.ModelAdmin):
    list_display = ("usuario", "produto", "criado_em")
    search_fields = ("usuario__email", "produto__titulo")
