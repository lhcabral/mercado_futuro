from decimal import Decimal
from io import BytesIO

from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand
from django.utils.text import slugify
from PIL import Image, ImageDraw

from catalogo.models import Categoria, Favorito, Produto
from contas.models import User
from empresas.cnpj import formatar_cnpj, gerar_cnpj
from empresas.models import DocumentoEmpresa, Empresa
from negociacoes.models import Mensagem, Negociacao, OpcaoNegociacao


class Command(BaseCommand):
    help = "Cria usuários, uma empresa aprovada com página colorida pela logo e uma empresa em análise."

    def handle(self, *args, **options):
        equipe = self._usuario(
            "equipe@mercadofuturo.local",
            "Equipe#2026",
            "Equipe Mercado Futuro",
            User.PAPEL_STAFF,
            is_superuser=True,
        )
        vendedor = self._usuario(
            "contato@agrovale.local",
            "Agrovale#2026",
            "Marina Costa",
            User.PAPEL_EMPRESA,
            telefone="1933334444",
            cidade="Campinas",
            uf="SP",
        )
        horti = self._usuario(
            "ana@hortisul.local",
            "Hortisul#2026",
            "Ana Ribeiro",
            User.PAPEL_EMPRESA,
            telefone="4130001122",
            cidade="Curitiba",
            uf="PR",
        )
        cliente = self._usuario(
            "cliente@mercadofuturo.local",
            "Cliente#2026",
            "João Almeida",
            User.PAPEL_CLIENTE,
            telefone="19988887777",
            cidade="Campinas",
            uf="SP",
        )

        alimentos, _ = Categoria.objects.get_or_create(slug="alimentos", defaults={"nome": "Alimentos"})
        casa, _ = Categoria.objects.get_or_create(slug="casa-e-jardim", defaults={"nome": "Casa e jardim"})

        agrovale = self._empresa(
            vendedor,
            razao_social="Agro Vale Alimentos LTDA",
            nome_fantasia="AgroVale",
            cnpj=gerar_cnpj("112223330001"),
            cidade="Campinas",
            uf="SP",
            descricao=(
                "Produtos de pequenos produtores da região de Campinas. "
                "A página desta empresa usa as cores extraídas da logomarca."
            ),
            telefone="1933334444",
            status=Empresa.APROVADA,
        )
        self._logo(agrovale, (11, 61, 145), (245, 179, 1), "agrovale.png")
        self._documento(agrovale)
        self._checklist(agrovale, equipe, "ok")

        hortisul = self._empresa(
            horti,
            razao_social="Horti Sul Hortifruti LTDA",
            nome_fantasia="HortiSul",
            cnpj=gerar_cnpj("223334440001"),
            cidade="Curitiba",
            uf="PR",
            descricao="Hortifruti aguardando validação da equipe.",
            telefone="4130001122",
            status=Empresa.EM_ANALISE,
        )
        self._logo(hortisul, (18, 107, 54), (242, 140, 40), "hortisul.png")
        self._documento(hortisul)
        self._checklist(hortisul, None, "pendente")

        cafe = self._produto(
            agrovale,
            alimentos,
            "Café especial da Mantiqueira 1kg",
            "Grãos torrados claros, embalados na semana.",
            Decimal("48.90"),
            (92, 58, 33),
        )
        mel = self._produto(
            agrovale,
            alimentos,
            "Mel silvestre 500g",
            "Mel de florada silvestre, pote de vidro.",
            Decimal("32.00"),
            (196, 132, 28),
        )
        self._produto(
            agrovale,
            casa,
            "Kit horta em casa",
            "Vasos, substrato e sementes para quem está começando.",
            Decimal("89.90"),
            (46, 120, 72),
        )
        self._produto(
            agrovale,
            alimentos,
            "Cesta orgânica semanal",
            "Seleção da semana com frutas, folhas e raízes.",
            Decimal("120.00"),
            (176, 72, 48),
        )
        self._produto(
            hortisul,
            alimentos,
            "Banana prata — rascunho",
            "Ainda não publicado. Só aparece depois da aprovação.",
            Decimal("7.50"),
            (230, 190, 40),
            status=Produto.RASCUNHO,
        )

        Favorito.objects.get_or_create(usuario=cliente, produto=cafe)
        self._mesa(cliente, mel)

        self.stdout.write(self.style.SUCCESS("Demonstração pronta."))
        self.stdout.write(f"Empresa aprovada: AgroVale · CNPJ {formatar_cnpj(agrovale.cnpj)}")
        self.stdout.write("Página do fornecedor: /api/v1/fornecedores/agrovale/")
        self.stdout.write("Equipe:    equipe@mercadofuturo.local  /  Equipe#2026")
        self.stdout.write("Empresa:   contato@agrovale.local       /  Agrovale#2026")
        self.stdout.write("Em análise: ana@hortisul.local          /  Hortisul#2026")
        self.stdout.write("Cliente:   cliente@mercadofuturo.local  /  Cliente#2026")
        self.stdout.write("Admin:     http://127.0.0.1:8000/admin/")

    def _usuario(self, email, senha, nome, papel, **extra):
        usuario, _ = User.objects.get_or_create(
            email=email,
            defaults={"nome": nome, "papel": papel},
        )
        usuario.nome = nome
        usuario.papel = papel
        usuario.is_superuser = papel == User.PAPEL_STAFF
        usuario.is_active = True
        for campo, valor in extra.items():
            setattr(usuario, campo, valor)
        usuario.set_password(senha)
        usuario.save()
        return usuario

    def _empresa(self, usuario, **dados):
        empresa = Empresa.objects.filter(usuario=usuario).first()
        if empresa is None:
            nome = dados["nome_fantasia"]
            empresa = Empresa.objects.create(
                usuario=usuario,
                slug=slugify(nome),
                email=usuario.email,
                **dados,
            )
            return empresa
        for campo, valor in dados.items():
            setattr(empresa, campo, valor)
        empresa.email = usuario.email
        empresa.save()
        return empresa

    def _logo(self, empresa, fundo, destaque, nome):
        imagem = Image.new("RGB", (320, 320), fundo)
        desenho = ImageDraw.Draw(imagem)
        desenho.ellipse((70, 70, 250, 250), fill=destaque)
        desenho.rounded_rectangle((118, 146, 202, 178), radius=8, fill=fundo)
        buffer = BytesIO()
        imagem.save(buffer, "PNG")
        empresa.logo.save(nome, ContentFile(buffer.getvalue()), save=False)
        empresa.aplicar_cores_da_logo()
        empresa.save()

    def _documento(self, empresa):
        if empresa.documentos.exists():
            return
        documento = DocumentoEmpresa(empresa=empresa, tipo=DocumentoEmpresa.CONTRATO)
        documento.arquivo.save(
            "contrato-social.txt",
            ContentFile(b"Contrato social de demonstracao do Mercado Futuro."),
            save=True,
        )

    def _checklist(self, empresa, usuario, status):
        from django.utils import timezone

        agora = timezone.now() if status == "ok" else None
        empresa.checklist.update(
            status=status,
            observacao="Conferido na carga de demonstração." if status == "ok" else "",
            evidencia="",
            marcado_por=usuario,
            marcado_em=agora,
        )

    def _produto(self, empresa, categoria, titulo, descricao, preco, cor, status=Produto.PUBLICADO):
        slug = slugify(titulo)[:80]
        produto, _ = Produto.objects.get_or_create(
            slug=slug,
            defaults={
                "empresa": empresa,
                "categoria": categoria,
                "titulo": titulo,
                "descricao": descricao,
                "preco": preco,
                "cidade": empresa.cidade,
                "uf": empresa.uf,
                "status": status,
                "condicao": Produto.NOVO,
                "estoque": 12,
            },
        )
        produto.empresa = empresa
        produto.categoria = categoria
        produto.titulo = titulo
        produto.descricao = descricao
        produto.preco = preco
        produto.cidade = empresa.cidade
        produto.uf = empresa.uf
        produto.status = status
        produto.save()
        if not produto.imagens.exists():
            imagem = Image.new("RGB", (960, 720), cor)
            desenho = ImageDraw.Draw(imagem)
            desenho.rectangle((0, 560, 960, 720), fill=(255, 255, 255))
            desenho.text((36, 590), slug.replace("-", " "), fill=cor)
            buffer = BytesIO()
            imagem.save(buffer, "PNG")
            from catalogo.models import ImagemProduto

            foto = ImagemProduto(produto=produto, ordem=0)
            foto.imagem.save(f"{slug}.png", ContentFile(buffer.getvalue()), save=True)
        return produto

    def _mesa(self, cliente, produto):
        negociacao = (
            Negociacao.objects.filter(produto=produto, cliente=cliente)
            .exclude(status__in=[Negociacao.RECUSADA, Negociacao.ENCERRADA])
            .first()
        )
        if negociacao is None:
            negociacao = Negociacao.objects.create(
                produto=produto,
                cliente=cliente,
                empresa=produto.empresa,
                status=Negociacao.OPCOES_ENVIADAS,
            )
        if not negociacao.mensagens.exists():
            Mensagem.objects.create(
                negociacao=negociacao,
                autor=cliente,
                texto="Olá, consigo retirar em Campinas ainda esta semana?",
            )
            Mensagem.objects.create(
                negociacao=negociacao,
                autor=produto.empresa.usuario,
                texto="Consegue sim. Deixei duas opções de entrega e pagamento.",
            )
        if not negociacao.opcoes.exists():
            OpcaoNegociacao.objects.create(
                negociacao=negociacao,
                preco=Decimal("32.00"),
                prazo_dias=0,
                tipo_entrega=OpcaoNegociacao.RETIRADA,
                formas_pagamento=["pix", "dinheiro"],
                observacao="Retirada na loja de Campinas, das 9h às 17h.",
            )
            OpcaoNegociacao.objects.create(
                negociacao=negociacao,
                preco=Decimal("39.90"),
                prazo_dias=5,
                tipo_entrega=OpcaoNegociacao.ENVIO,
                formas_pagamento=["pix", "boleto"],
                observacao="Envio para a cidade do cliente. Frete incluído neste valor.",
            )
        negociacao.status = Negociacao.OPCOES_ENVIADAS
        negociacao.save(update_fields=["status", "atualizada_em"])
