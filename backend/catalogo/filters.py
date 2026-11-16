import django_filters
from django.db.models import Q

from catalogo.models import Produto


class ProdutoFilter(django_filters.FilterSet):
    q = django_filters.CharFilter(method="filtrar_texto")
    categoria = django_filters.CharFilter(field_name="categoria__slug")
    cidade = django_filters.CharFilter(field_name="cidade", lookup_expr="icontains")
    uf = django_filters.CharFilter(field_name="uf", lookup_expr="iexact")
    preco_min = django_filters.NumberFilter(field_name="preco", lookup_expr="gte")
    preco_max = django_filters.NumberFilter(field_name="preco", lookup_expr="lte")
    condicao = django_filters.CharFilter(field_name="condicao")
    fornecedor = django_filters.CharFilter(field_name="empresa__slug")

    class Meta:
        model = Produto
        fields = []

    def filtrar_texto(self, queryset, nome, valor):
        del nome
        return queryset.filter(
            Q(titulo__icontains=valor)
            | Q(descricao__icontains=valor)
            | Q(empresa__nome_fantasia__icontains=valor)
        )
