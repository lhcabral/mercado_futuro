from django.contrib import admin

from negociacoes.models import Mensagem, Negociacao, OpcaoNegociacao


class MensagemInline(admin.TabularInline):
    model = Mensagem
    extra = 0


class OpcaoInline(admin.TabularInline):
    model = OpcaoNegociacao
    extra = 0


@admin.register(Negociacao)
class NegociacaoAdmin(admin.ModelAdmin):
    list_display = ("id", "produto", "cliente", "empresa", "status", "atualizada_em")
    list_filter = ("status",)
    search_fields = ("produto__titulo", "cliente__email", "empresa__nome_fantasia")
    inlines = [OpcaoInline, MensagemInline]
