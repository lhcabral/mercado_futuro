from django.db import models

from empresas.models import Empresa


class Categoria(models.Model):
    nome = models.CharField(max_length=120)
    slug = models.SlugField(max_length=80, unique=True)
    pai = models.ForeignKey(
        "self",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="filhas",
    )

    class Meta:
        verbose_name = "categoria"
        verbose_name_plural = "categorias"
        ordering = ["nome"]

    def __str__(self):
        return self.nome


class Produto(models.Model):
    NOVO = "novo"
    USADO = "usado"
    CONDICOES = [
        (NOVO, "Novo"),
        (USADO, "Usado"),
    ]
    RASCUNHO = "rascunho"
    PUBLICADO = "publicado"
    PAUSADO = "pausado"
    STATUS = [
        (RASCUNHO, "Rascunho"),
        (PUBLICADO, "Publicado"),
        (PAUSADO, "Pausado"),
    ]

    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name="produtos")
    categoria = models.ForeignKey(
        Categoria,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="produtos",
    )
    titulo = models.CharField("título", max_length=180)
    slug = models.SlugField(max_length=80, unique=True)
    descricao = models.TextField("descrição", blank=True)
    preco = models.DecimalField("preço", max_digits=12, decimal_places=2)
    condicao = models.CharField("condição", max_length=10, choices=CONDICOES, default=NOVO)
    estoque = models.PositiveIntegerField(default=1)
    cidade = models.CharField(max_length=120, blank=True)
    uf = models.CharField("UF", max_length=2, blank=True)
    status = models.CharField(max_length=20, choices=STATUS, default=RASCUNHO)
    criado_em = models.DateTimeField(auto_now_add=True)
    atualizado_em = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "produto"
        verbose_name_plural = "produtos"
        ordering = ["-criado_em"]
        indexes = [models.Index(fields=["status", "criado_em"])]

    def __str__(self):
        return self.titulo


class ImagemProduto(models.Model):
    produto = models.ForeignKey(Produto, on_delete=models.CASCADE, related_name="imagens")
    imagem = models.ImageField(upload_to="produtos/%Y/%m/")
    ordem = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ["ordem", "id"]

    def __str__(self):
        return f"Imagem de {self.produto}"


class Favorito(models.Model):
    usuario = models.ForeignKey(
        "contas.User",
        on_delete=models.CASCADE,
        related_name="favoritos",
    )
    produto = models.ForeignKey(Produto, on_delete=models.CASCADE, related_name="favoritos")
    criado_em = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "favorito"
        verbose_name_plural = "favoritos"
        constraints = [
            models.UniqueConstraint(fields=["usuario", "produto"], name="favorito_unico"),
        ]
        ordering = ["-criado_em"]

    def __str__(self):
        return f"{self.usuario} → {self.produto}"
