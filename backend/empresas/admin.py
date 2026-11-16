from django import forms
from django.contrib import admin

from empresas.models import DocumentoEmpresa, Empresa, ItemChecklist
from empresas.servicos import pendencias_para_aprovacao


class EmpresaAdminForm(forms.ModelForm):
    class Meta:
        model = Empresa
        fields = "__all__"

    def clean(self):
        cleaned = super().clean()
        if cleaned.get("status") == Empresa.APROVADA and self.instance.pk:
            pendencias = pendencias_para_aprovacao(self.instance)
            if pendencias:
                raise forms.ValidationError(
                    "Salve o checklist conferido antes de aprovar. Pendente: " + "; ".join(pendencias)
                )
        return cleaned


class DocumentoInline(admin.TabularInline):
    model = DocumentoEmpresa
    extra = 0


class ChecklistInline(admin.TabularInline):
    model = ItemChecklist
    extra = 0
    can_delete = False
    fields = ("ordem", "titulo", "status", "observacao", "marcado_em")
    readonly_fields = ("ordem", "titulo", "marcado_em")

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(Empresa)
class EmpresaAdmin(admin.ModelAdmin):
    form = EmpresaAdminForm
    list_display = ("nome_fantasia", "cnpj", "cidade", "uf", "status", "cor_primaria", "cor_secundaria")
    list_filter = ("status", "uf")
    search_fields = ("nome_fantasia", "razao_social", "cnpj", "slug")
    readonly_fields = ("cor_primaria", "cor_secundaria", "cor_destaque", "criada_em", "atualizada_em")
    inlines = [ChecklistInline, DocumentoInline]

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        if obj.logo and (not change or "logo" in form.changed_data):
            obj.aplicar_cores_da_logo()
            obj.save(update_fields=["cor_primaria", "cor_secundaria", "cor_destaque"])
