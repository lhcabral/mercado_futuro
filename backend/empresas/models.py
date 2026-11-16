from django.conf import settings
from django.db import models


class Empresa(models.Model):
    RASCUNHO = "rascunho"
    EM_ANALISE = "em_analise"
    APROVADA = "aprovada"
    RECUSADA = "recusada"
    SUSPENSA = "suspensa"
    STATUS = [
        (RASCUNHO, "Rascunho"),
        (EM_ANALISE, "Em análise"),
        (APROVADA, "Aprovada"),
        (RECUSADA, "Recusada"),
        (SUSPENSA, "Suspensa"),
    ]

    usuario = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="empresa",
    )
    razao_social = models.CharField("razão social", max_length=200)
    nome_fantasia = models.CharField("nome fantasia", max_length=200)
    slug = models.SlugField(max_length=80, unique=True)
    cnpj = models.CharField("CNPJ", max_length=14, unique=True)
    telefone = models.CharField(max_length=20, blank=True)
    email = models.EmailField(blank=True)
    descricao = models.TextField("descrição", blank=True)
    endereco = models.CharField("endereço", max_length=250, blank=True)
    cidade = models.CharField(max_length=120)
    uf = models.CharField("UF", max_length=2)
    logo = models.ImageField("logomarca", upload_to="empresas/logos/", blank=True)
    cor_primaria = models.CharField(max_length=7, default="#0F6B4C")
    cor_secundaria = models.CharField(max_length=7, default="#E8A317")
    cor_destaque = models.CharField(max_length=7, default="#FFFFFF")
    status = models.CharField(max_length=20, choices=STATUS, default=RASCUNHO)
    motivo_recusa = models.TextField(blank=True)
    criada_em = models.DateTimeField(auto_now_add=True)
    atualizada_em = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "empresa"
        verbose_name_plural = "empresas"
        ordering = ["nome_fantasia"]

    def __str__(self):
        return self.nome_fantasia

    @property
    def cores(self):
        return {
            "primaria": self.cor_primaria,
            "secundaria": self.cor_secundaria,
            "destaque": self.cor_destaque,
        }

    def aplicar_cores_da_logo(self):
        if not self.logo:
            return
        from empresas.cores import extrair_cores

        self.logo.open("rb")
        try:
            cores = extrair_cores(self.logo)
        finally:
            self.logo.close()
        self.cor_primaria = cores["primaria"]
        self.cor_secundaria = cores["secundaria"]
        self.cor_destaque = cores["destaque"]


class DocumentoEmpresa(models.Model):
    CONTRATO = "contrato_social"
    IDENTIDADE = "identidade"
    OUTRO = "outro"
    TIPOS = [
        (CONTRATO, "Contrato social ou equivalente"),
        (IDENTIDADE, "Documento do responsável"),
        (OUTRO, "Outro"),
    ]

    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name="documentos")
    tipo = models.CharField(max_length=30, choices=TIPOS, default=CONTRATO)
    arquivo = models.FileField(upload_to="empresas/documentos/")
    enviado_em = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "documento da empresa"
        verbose_name_plural = "documentos da empresa"
        ordering = ["-enviado_em"]

    def __str__(self):
        return f"{self.get_tipo_display()} — {self.empresa}"


class ItemChecklist(models.Model):
    PENDENTE = "pendente"
    OK = "ok"
    FALHA = "falha"
    NAO_SE_APLICA = "nao_se_aplica"
    STATUS = [
        (PENDENTE, "Pendente"),
        (OK, "Conferido"),
        (FALHA, "Divergente"),
        (NAO_SE_APLICA, "Não se aplica"),
    ]

    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name="checklist")
    codigo = models.CharField(max_length=40)
    titulo = models.CharField(max_length=180)
    ordem = models.PositiveSmallIntegerField(default=0)
    status = models.CharField(max_length=20, choices=STATUS, default=PENDENTE)
    observacao = models.TextField(blank=True)
    evidencia = models.TextField(blank=True)
    marcado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="itens_marcados",
    )
    marcado_em = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "item do checklist"
        verbose_name_plural = "itens do checklist"
        ordering = ["ordem", "id"]
        constraints = [
            models.UniqueConstraint(fields=["empresa", "codigo"], name="checklist_empresa_codigo"),
        ]

    def __str__(self):
        return f"{self.titulo} ({self.get_status_display()})"
