import tempfile
from io import BytesIO
from unittest.mock import patch

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from PIL import Image, ImageDraw
from rest_framework.test import APIClient

from contas.models import User
from empresas.cnpj import cnpj_valido, gerar_cnpj
from empresas.cores import extrair_cores
from empresas.models import Empresa

SENHA = "SenhaForte!123"


def png(cor, tamanho=(48, 48), faixa=None):
    imagem = Image.new("RGB", tamanho, cor)
    if faixa:
        ImageDraw.Draw(imagem).rectangle(faixa[0], fill=faixa[1])
    buffer = BytesIO()
    imagem.save(buffer, "PNG")
    return buffer.getvalue()


@override_settings(MEDIA_ROOT=tempfile.mkdtemp())
class CorLogoTests(TestCase):
    def test_cor_solida_quantizada(self):
        origem = BytesIO(png((17, 34, 51)))
        cores = extrair_cores(origem)
        self.assertEqual(cores["primaria"], "#102030")
        self.assertEqual(cores["destaque"], "#FFFFFF")
        self.assertNotEqual(cores["secundaria"], cores["primaria"])

    def test_separa_cor_predominante_e_secundaria(self):
        origem = BytesIO(png((0, 48, 144), faixa=((0, 0, 15, 47), (240, 176, 0))))
        cores = extrair_cores(origem)
        self.assertEqual(cores["primaria"], "#003090")
        self.assertEqual(cores["secundaria"], "#F0B000")
        self.assertEqual(cores["destaque"], "#FFFFFF")


@override_settings(MEDIA_ROOT=tempfile.mkdtemp())
class EmpresaFluxoTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.cnpj = gerar_cnpj("112223330001")
        self.assertTrue(cnpj_valido(self.cnpj))

    def test_rejeita_cnpj_invalido(self):
        resposta = self.client.post(
            "/api/v1/auth/registro/",
            {
                "email": "empresa@teste.local",
                "password": SENHA,
                "nome": "Dona Maria",
                "papel": "empresa",
                "razao_social": "Maria Alimentos LTDA",
                "nome_fantasia": "Maria Alimentos",
                "cnpj": "11111111111111",
                "cidade": "Campinas",
                "uf": "SP",
            },
            format="json",
        )
        self.assertEqual(resposta.status_code, 400)

    def test_aprovacao_exige_checklist_e_libera_pagina(self):
        registro = self.client.post(
            "/api/v1/auth/registro/",
            {
                "email": "empresa@teste.local",
                "password": SENHA,
                "nome": "Dona Maria",
                "papel": "empresa",
                "razao_social": "Maria Alimentos LTDA",
                "nome_fantasia": "Maria Alimentos",
                "cnpj": self.cnpj,
                "cidade": "Campinas",
                "uf": "SP",
            },
            format="json",
        )
        self.assertEqual(registro.status_code, 201, registro.content)
        token = registro.data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

        empresa = Empresa.objects.get(cnpj=self.cnpj)
        self.assertEqual(empresa.checklist.count(), 7)
        self.assertEqual(empresa.status, Empresa.RASCUNHO)

        self.client.patch(
            "/api/v1/empresas/minha/",
            {"logo": SimpleUploadedFile("logo.png", png((0, 48, 144), (64, 64), ((0, 0, 20, 63), (240, 176, 0))))},
            format="multipart",
        )
        self.client.post(
            "/api/v1/empresas/minha/documentos/",
            {
                "tipo": "contrato_social",
                "arquivo": SimpleUploadedFile("contrato.pdf", b"%PDF-1.4 demo", content_type="application/pdf"),
            },
            format="multipart",
        )
        envio = self.client.post("/api/v1/empresas/minha/enviar-analise/")
        self.assertEqual(envio.status_code, 200, envio.content)
        self.assertEqual(envio.data["status"], "em_analise")
        self.assertEqual(envio.data["cores"]["primaria"], "#003090")
        self.assertEqual(envio.data["cores"]["secundaria"], "#F0B000")

        pagina = self.client.get(f"/api/v1/fornecedores/{envio.data['slug']}/")
        self.assertEqual(pagina.status_code, 404)

        equipe = User.objects.create_user(
            email="equipe@teste.local",
            password=SENHA,
            nome="Equipe",
            papel=User.PAPEL_STAFF,
        )
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self._token(equipe)}")
        cedo = self.client.post(
            f"/api/v1/admin/empresas/{empresa.id}/decidir/",
            {"decisao": "aprovada"},
            format="json",
        )
        self.assertEqual(cedo.status_code, 400)
        self.assertIn("pendencias", cedo.data)

        for codigo in ("cnpj_ativo", "razao_social", "situacao_cadastral", "documento_responsavel", "sem_impedimento"):
            marcado = self.client.post(
                f"/api/v1/admin/empresas/{empresa.id}/checklist/{codigo}/",
                {"status": "ok", "observacao": "Conferido."},
                format="json",
            )
            self.assertEqual(marcado.status_code, 200, marcado.content)

        aprovado = self.client.post(
            f"/api/v1/admin/empresas/{empresa.id}/decidir/",
            {"decisao": "aprovada"},
            format="json",
        )
        self.assertEqual(aprovado.status_code, 200, aprovado.content)
        pagina = self.client.get("/api/v1/fornecedores/maria-alimentos/")
        self.assertEqual(pagina.status_code, 200)
        self.assertEqual(pagina.data["cores"]["primaria"], "#003090")
        self.assertEqual(pagina.data["cores"]["secundaria"], "#F0B000")

    def test_consulta_cnpj_preenche_checklist(self):
        usuario = User.objects.create_user(
            email="outra@teste.local",
            password=SENHA,
            nome="Outra",
            papel=User.PAPEL_EMPRESA,
        )
        empresa = Empresa.objects.create(
            usuario=usuario,
            razao_social="Agro Vale LTDA",
            nome_fantasia="Agro Vale",
            slug="agro-vale",
            cnpj=gerar_cnpj("223334440001"),
            cidade="Campinas",
            uf="SP",
            status=Empresa.EM_ANALISE,
        )
        equipe = User.objects.create_user(
            email="staff@teste.local",
            password=SENHA,
            nome="Staff",
            papel=User.PAPEL_STAFF,
        )
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self._token(equipe)}")
        payload = {
            "razao_social": "Agro Vale LTDA",
            "descricao_situacao_cadastral": "ATIVA",
            "cnae_fiscal_descricao": "Comércio de alimentos",
        }
        with patch("empresas.views.consultar_brasilapi", return_value=payload):
            resposta = self.client.post(f"/api/v1/admin/empresas/{empresa.id}/consultar-cnpj/")
        self.assertEqual(resposta.status_code, 200, resposta.content)
        itens = {item["codigo"]: item["status"] for item in resposta.data["checklist"]}
        self.assertEqual(itens["cnpj_ativo"], "ok")
        self.assertEqual(itens["situacao_cadastral"], "ok")
        self.assertEqual(itens["razao_social"], "ok")
        self.assertEqual(itens["cnae"], "pendente")
        self.assertIn("evidencia", resposta.data["checklist"][0])

    def _token(self, usuario):
        from rest_framework_simplejwt.tokens import RefreshToken

        return str(RefreshToken.for_user(usuario).access_token)
