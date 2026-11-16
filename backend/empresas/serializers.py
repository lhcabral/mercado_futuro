import os

from rest_framework import serializers

from comum.arquivos import url_absoluta
from comum.br import UFS
from comum.slugs import gerar_slug
from empresas.cnpj import cnpj_valido, formatar_cnpj, somente_digitos
from empresas.models import DocumentoEmpresa, Empresa, ItemChecklist


class EmpresaResumoSerializer(serializers.ModelSerializer):
    cores = serializers.SerializerMethodField()
    logo = serializers.SerializerMethodField()

    class Meta:
        model = Empresa
        fields = (
            "id",
            "slug",
            "nome_fantasia",
            "status",
            "cidade",
            "uf",
            "logo",
            "cores",
        )

    def get_cores(self, obj):
        return obj.cores

    def get_logo(self, obj):
        return url_absoluta(self.context.get("request"), obj.logo)


class ItemChecklistSerializer(serializers.ModelSerializer):
    class Meta:
        model = ItemChecklist
        fields = (
            "codigo",
            "titulo",
            "status",
            "observacao",
            "evidencia",
            "marcado_em",
        )

    def to_representation(self, instance):
        dados = super().to_representation(instance)
        request = self.context.get("request")
        papel = getattr(getattr(request, "user", None), "papel", None)
        if papel != "staff":
            dados.pop("evidencia", None)
        return dados


class DocumentoEmpresaSerializer(serializers.ModelSerializer):
    arquivo = serializers.SerializerMethodField()
    nome = serializers.SerializerMethodField()

    class Meta:
        model = DocumentoEmpresa
        fields = ("id", "tipo", "nome", "arquivo", "enviado_em")

    def get_arquivo(self, obj):
        return url_absoluta(self.context.get("request"), obj.arquivo)

    def get_nome(self, obj):
        return os.path.basename(obj.arquivo.name)


class EmpresaDetalheSerializer(serializers.ModelSerializer):
    cores = serializers.SerializerMethodField()
    logo = serializers.SerializerMethodField()
    cnpj_formatado = serializers.SerializerMethodField()
    checklist = ItemChecklistSerializer(many=True, read_only=True)
    documentos = DocumentoEmpresaSerializer(many=True, read_only=True)

    class Meta:
        model = Empresa
        fields = (
            "id",
            "razao_social",
            "nome_fantasia",
            "slug",
            "cnpj",
            "cnpj_formatado",
            "telefone",
            "email",
            "descricao",
            "endereco",
            "cidade",
            "uf",
            "logo",
            "cores",
            "status",
            "motivo_recusa",
            "checklist",
            "documentos",
            "criada_em",
            "atualizada_em",
        )

    def get_cores(self, obj):
        return obj.cores

    def get_logo(self, obj):
        return url_absoluta(self.context.get("request"), obj.logo)

    def get_cnpj_formatado(self, obj):
        return formatar_cnpj(obj.cnpj)


class EmpresaEscritaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = (
            "razao_social",
            "nome_fantasia",
            "cnpj",
            "telefone",
            "email",
            "descricao",
            "endereco",
            "cidade",
            "uf",
            "logo",
        )

    def validate_cnpj(self, value):
        digitos = somente_digitos(value)
        if not cnpj_valido(digitos):
            raise serializers.ValidationError("CNPJ inválido.")
        consulta = Empresa.objects.filter(cnpj=digitos)
        if self.instance is not None:
            consulta = consulta.exclude(pk=self.instance.pk)
        if consulta.exists():
            raise serializers.ValidationError("Este CNPJ já está cadastrado.")
        return digitos

    def validate_uf(self, value):
        uf = value.strip().upper()
        if uf not in UFS:
            raise serializers.ValidationError("UF inválida.")
        return uf

    def validate(self, attrs):
        if self.instance and self.instance.status == Empresa.APROVADA and "cnpj" in attrs:
            if attrs["cnpj"] != self.instance.cnpj:
                raise serializers.ValidationError({"cnpj": "CNPJ de empresa aprovada não pode ser alterado."})
        return attrs

    def create(self, validated):
        usuario = self.context["request"].user
        if getattr(usuario, "papel", None) != "empresa":
            raise serializers.ValidationError("Apenas uma conta de empresa pode fazer este cadastro.")
        if Empresa.objects.filter(usuario=usuario).exists():
            raise serializers.ValidationError("Este usuário já possui uma empresa.")
        validated["usuario"] = usuario
        validated["slug"] = gerar_slug(validated["nome_fantasia"], Empresa)
        validated["email"] = validated.get("email") or usuario.email
        empresa = super().create(validated)
        if empresa.logo:
            empresa.aplicar_cores_da_logo()
            empresa.save(update_fields=["cor_primaria", "cor_secundaria", "cor_destaque"])
        return empresa

    def update(self, instance, validated):
        nome = validated.get("nome_fantasia")
        if nome and nome != instance.nome_fantasia and instance.status != Empresa.APROVADA:
            validated["slug"] = gerar_slug(nome, Empresa, instance)
        empresa = super().update(instance, validated)
        if "logo" in validated and empresa.logo:
            empresa.aplicar_cores_da_logo()
            empresa.save(update_fields=["cor_primaria", "cor_secundaria", "cor_destaque"])
        return empresa


class DocumentoEnvioSerializer(serializers.ModelSerializer):
    class Meta:
        model = DocumentoEmpresa
        fields = ("tipo", "arquivo")
