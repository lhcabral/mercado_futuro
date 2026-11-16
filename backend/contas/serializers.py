from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from comum.br import UFS
from contas.models import User
from empresas.cnpj import cnpj_valido, somente_digitos
from empresas.models import Empresa
from empresas.serializers import EmpresaResumoSerializer


class UsuarioSerializer(serializers.ModelSerializer):
    empresa = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "nome",
            "papel",
            "telefone",
            "cidade",
            "uf",
            "empresa",
        )
        read_only_fields = ("email", "papel")

    def get_empresa(self, obj):
        try:
            empresa = obj.empresa
        except Empresa.DoesNotExist:
            return None
        return EmpresaResumoSerializer(empresa, context=self.context).data


class RegistroSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    nome = serializers.CharField(max_length=150)
    papel = serializers.ChoiceField(choices=[User.PAPEL_CLIENTE, User.PAPEL_EMPRESA])
    telefone = serializers.CharField(required=False, allow_blank=True, max_length=20)
    cidade = serializers.CharField(required=False, allow_blank=True, max_length=120)
    uf = serializers.CharField(required=False, allow_blank=True, max_length=2)
    razao_social = serializers.CharField(required=False, allow_blank=True, max_length=200)
    nome_fantasia = serializers.CharField(required=False, allow_blank=True, max_length=200)
    cnpj = serializers.CharField(required=False, allow_blank=True, max_length=18)

    def validate_email(self, value):
        email = value.strip().lower()
        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError("Este e-mail já está cadastrado.")
        return email

    def validate_password(self, value):
        validate_password(value)
        return value

    def validate(self, attrs):
        if attrs["papel"] != User.PAPEL_EMPRESA:
            return attrs
        obrigatorios = ("razao_social", "nome_fantasia", "cnpj", "cidade", "uf")
        faltando = {
            campo: "Obrigatório no cadastro da empresa."
            for campo in obrigatorios
            if not (attrs.get(campo) or "").strip()
        }
        if faltando:
            raise serializers.ValidationError(faltando)
        cnpj = somente_digitos(attrs["cnpj"])
        if not cnpj_valido(cnpj):
            raise serializers.ValidationError({"cnpj": "CNPJ inválido."})
        if Empresa.objects.filter(cnpj=cnpj).exists():
            raise serializers.ValidationError({"cnpj": "Este CNPJ já está cadastrado."})
        uf = attrs["uf"].strip().upper()
        if uf not in UFS:
            raise serializers.ValidationError({"uf": "UF inválida."})
        attrs["cnpj"] = cnpj
        attrs["uf"] = uf
        return attrs

    @transaction.atomic
    def create(self, validated):
        from comum.slugs import gerar_slug

        papel = validated["papel"]
        usuario = User.objects.create_user(
            email=validated["email"],
            password=validated["password"],
            nome=validated["nome"].strip(),
            papel=papel,
            telefone=(validated.get("telefone") or "").strip(),
            cidade=(validated.get("cidade") or "").strip(),
            uf=(validated.get("uf") or "").strip().upper(),
        )
        if papel == User.PAPEL_EMPRESA:
            nome_fantasia = validated["nome_fantasia"].strip()
            Empresa.objects.create(
                usuario=usuario,
                razao_social=validated["razao_social"].strip(),
                nome_fantasia=nome_fantasia,
                slug=gerar_slug(nome_fantasia, Empresa),
                cnpj=validated["cnpj"],
                telefone=usuario.telefone,
                email=usuario.email,
                cidade=validated["cidade"].strip(),
                uf=validated["uf"],
            )
        return usuario


class LoginSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        if "email" in attrs:
            attrs["email"] = attrs["email"].strip().lower()
        dados = super().validate(attrs)
        dados["usuario"] = UsuarioSerializer(self.user, context=self.context).data
        return dados
