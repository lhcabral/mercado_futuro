from django.test import TestCase
from rest_framework.test import APIClient

from catalogo.models import Categoria, Produto
from contas.models import User
from empresas.cnpj import gerar_cnpj
from empresas.models import Empresa
from negociacoes.models import Negociacao

SENHA = "SenhaForte!123"


class NegociacaoTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.categoria = Categoria.objects.create(nome="Casa", slug="casa")
        self.vendedor = User.objects.create_user(
            email="loja@teste.local",
            password=SENHA,
            nome="Loja",
            papel=User.PAPEL_EMPRESA,
            telefone="11999990000",
        )
        self.empresa = Empresa.objects.create(
            usuario=self.vendedor,
            razao_social="Loja LTDA",
            nome_fantasia="Loja",
            slug="loja",
            cnpj=gerar_cnpj("445556660001"),
            cidade="Recife",
            uf="PE",
            status=Empresa.APROVADA,
            telefone="1133334444",
        )
        self.produto = Produto.objects.create(
            empresa=self.empresa,
            categoria=self.categoria,
            titulo="Jarra",
            slug="jarra",
            preco="50.00",
            status=Produto.PUBLICADO,
            cidade="Recife",
            uf="PE",
        )
        self.cliente = User.objects.create_user(
            email="ana@teste.local",
            password=SENHA,
            nome="Ana",
            papel=User.PAPEL_CLIENTE,
            telefone="11988887777",
            cidade="Olinda",
        )

    def _entrar(self, usuario):
        from rest_framework_simplejwt.tokens import RefreshToken

        token = str(RefreshToken.for_user(usuario).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def test_mesa_com_opcoes_de_entrega_e_pagamento(self):
        self._entrar(self.cliente)
        aberta = self.client.post(
            "/api/v1/negociacoes/",
            {"produto": self.produto.id, "mensagem": "Consigo retirar amanhã?"},
            format="json",
        )
        self.assertEqual(aberta.status_code, 201, aberta.content)
        repetida = self.client.post(
            "/api/v1/negociacoes/",
            {"produto": self.produto.id, "mensagem": "Oi de novo"},
            format="json",
        )
        self.assertEqual(repetida.status_code, 200)
        self.assertEqual(Negociacao.objects.count(), 1)
        negociacao_id = aberta.data["id"]

        self._entrar(self.vendedor)
        opcao = self.client.post(
            f"/api/v1/negociacoes/{negociacao_id}/opcoes/",
            {
                "preco": "45.00",
                "prazo_dias": 1,
                "tipo_entrega": "retirada",
                "formas_pagamento": ["pix", "dinheiro"],
                "observacao": "Retirada no centro.",
            },
            format="json",
        )
        self.assertEqual(opcao.status_code, 201, opcao.content)
        self.client.post(
            f"/api/v1/negociacoes/{negociacao_id}/mensagens/",
            {"texto": "Pode retirar no centro a partir das 9h."},
            format="json",
        )

        self._entrar(self.cliente)
        aceita = self.client.post(f"/api/v1/negociacoes/{negociacao_id}/opcoes/{opcao.data['id']}/aceitar/")
        self.assertEqual(aceita.status_code, 200, aceita.content)
        self.assertEqual(aceita.data["status"], "aceita")
        self.assertTrue(aceita.data["opcoes"][0]["escolhida"])
        self.assertFalse(aceita.data["pode_aceitar"])

        self._entrar(self.vendedor)
        extra = self.client.post(
            f"/api/v1/negociacoes/{negociacao_id}/opcoes/",
            {
                "preco": "60.00",
                "tipo_entrega": "envio",
                "formas_pagamento": ["boleto"],
            },
            format="json",
        )
        self.assertEqual(extra.status_code, 400)
