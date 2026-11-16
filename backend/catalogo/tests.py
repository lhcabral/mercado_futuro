import tempfile

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from catalogo.models import Categoria, Favorito, Produto
from contas.models import User
from empresas.cnpj import gerar_cnpj
from empresas.models import Empresa

SENHA = "SenhaForte!123"


@override_settings(MEDIA_ROOT=tempfile.mkdtemp())
class CatalogoTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.categoria = Categoria.objects.create(nome="Alimentos", slug="alimentos")
        self.vendedor = User.objects.create_user(
            email="venda@teste.local",
            password=SENHA,
            nome="Vendedor",
            papel=User.PAPEL_EMPRESA,
        )
        self.empresa = Empresa.objects.create(
            usuario=self.vendedor,
            razao_social="Venda Boa LTDA",
            nome_fantasia="Venda Boa",
            slug="venda-boa",
            cnpj=gerar_cnpj("334445550001"),
            cidade="Santos",
            uf="SP",
            status=Empresa.EM_ANALISE,
            cor_primaria="#112233",
            cor_secundaria="#AABBCC",
            cor_destaque="#FFFFFF",
        )
        self.cliente = User.objects.create_user(
            email="compra@teste.local",
            password=SENHA,
            nome="Cliente",
            papel=User.PAPEL_CLIENTE,
        )

    def _entrar(self, usuario):
        from rest_framework_simplejwt.tokens import RefreshToken

        token = str(RefreshToken.for_user(usuario).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def test_empresa_em_analise_nao_publica_e_nao_aparece(self):
        self._entrar(self.vendedor)
        bloqueado = self.client.post(
            "/api/v1/produtos/",
            {
                "titulo": "Café",
                "descricao": "Grãos",
                "preco": "20.00",
                "categoria": self.categoria.id,
                "status": "publicado",
            },
            format="json",
        )
        self.assertEqual(bloqueado.status_code, 400, bloqueado.content)

        criado = self.client.post(
            "/api/v1/produtos/",
            {
                "titulo": "Café",
                "descricao": "Grãos torrados",
                "preco": "20.00",
                "categoria": self.categoria.id,
                "status": "rascunho",
            },
            format="json",
        )
        self.assertEqual(criado.status_code, 201, criado.content)
        lista = APIClient().get("/api/v1/produtos/")
        self.assertEqual(lista.data["count"], 0)

        self.empresa.status = Empresa.APROVADA
        self.empresa.save(update_fields=["status"])
        publicado = self.client.patch(
            f"/api/v1/produtos/{criado.data['id']}/",
            {"status": "publicado"},
            format="json",
        )
        self.assertEqual(publicado.status_code, 200, publicado.content)
        self.assertEqual(publicado.data["fornecedor"]["cores"]["primaria"], "#112233")

        busca = APIClient().get("/api/v1/produtos/", {"q": "torrados", "uf": "sp"})
        self.assertEqual(busca.data["count"], 1)
        self.assertEqual(busca.data["results"][0]["fornecedor_slug"], "venda-boa")

    def test_favoritar_e_pagina_do_fornecedor(self):
        self.empresa.status = Empresa.APROVADA
        self.empresa.save(update_fields=["status"])
        produto = Produto.objects.create(
            empresa=self.empresa,
            categoria=self.categoria,
            titulo="Mel",
            slug="mel",
            descricao="Silvestre",
            preco="32.00",
            cidade="Santos",
            uf="SP",
            status=Produto.PUBLICADO,
        )
        self._entrar(self.cliente)
        primeiro = self.client.post("/api/v1/favoritos/", {"produto": produto.id}, format="json")
        segundo = self.client.post("/api/v1/favoritos/", {"produto": produto.id}, format="json")
        self.assertEqual(primeiro.status_code, 201)
        self.assertEqual(segundo.status_code, 201)
        self.assertEqual(Favorito.objects.count(), 1)
        self.assertEqual(len(self.client.get("/api/v1/favoritos/").data), 1)

        pagina = self.client.get("/api/v1/fornecedores/venda-boa/")
        self.assertEqual(pagina.status_code, 200)
        self.assertEqual(pagina.data["cores"]["secundaria"], "#AABBCC")
        self.assertEqual(pagina.data["produtos"][0]["favorito"], True)
        self.assertEqual(pagina.data["produtos"][0]["titulo"], "Mel")

        apagado = self.client.delete(f"/api/v1/favoritos/{produto.id}/")
        self.assertEqual(apagado.status_code, 204)
        self.assertEqual(Favorito.objects.count(), 0)

    def test_imagem_de_produto(self):
        self.empresa.status = Empresa.APROVADA
        self.empresa.save(update_fields=["status"])
        self._entrar(self.vendedor)
        criado = self.client.post(
            "/api/v1/produtos/",
            {"titulo": "Cesta", "preco": "10.00", "status": "publicado", "categoria": self.categoria.id},
            format="json",
        )
        from io import BytesIO
        from PIL import Image

        buffer = BytesIO()
        Image.new("RGB", (8, 8), (10, 20, 30)).save(buffer, "PNG")
        arquivo = SimpleUploadedFile("cesta.png", buffer.getvalue(), content_type="image/png")
        envio = self.client.post(
            f"/api/v1/produtos/{criado.data['id']}/imagens/",
            {"imagem": arquivo},
            format="multipart",
        )
        self.assertEqual(envio.status_code, 201, envio.content)
        self.assertTrue(envio.data["url"].startswith("http"))
