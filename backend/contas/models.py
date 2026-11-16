from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models


class UserManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, email, password, **extra):
        if not email:
            raise ValueError("E-mail é obrigatório.")
        email = self.normalize_email(email).lower()
        user = self.model(email=email, **extra)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, **extra):
        extra.setdefault("is_staff", False)
        extra.setdefault("is_superuser", False)
        return self._create_user(email, password, **extra)

    def create_superuser(self, email, password=None, **extra):
        extra.setdefault("is_staff", True)
        extra.setdefault("is_superuser", True)
        extra.setdefault("papel", User.PAPEL_STAFF)
        if extra.get("is_staff") is not True:
            raise ValueError("Superusuário precisa de is_staff=True.")
        if extra.get("is_superuser") is not True:
            raise ValueError("Superusuário precisa de is_superuser=True.")
        return self._create_user(email, password, **extra)


class User(AbstractUser):
    PAPEL_STAFF = "staff"
    PAPEL_EMPRESA = "empresa"
    PAPEL_CLIENTE = "cliente"
    PAPEIS = [
        (PAPEL_STAFF, "Equipe"),
        (PAPEL_EMPRESA, "Empresa"),
        (PAPEL_CLIENTE, "Cliente"),
    ]

    username = None
    email = models.EmailField("e-mail", unique=True)
    nome = models.CharField(max_length=150)
    papel = models.CharField(max_length=20, choices=PAPEIS, default=PAPEL_CLIENTE)
    telefone = models.CharField(max_length=20, blank=True)
    cidade = models.CharField(max_length=120, blank=True)
    uf = models.CharField("UF", max_length=2, blank=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["nome"]

    objects = UserManager()

    class Meta:
        verbose_name = "usuário"
        verbose_name_plural = "usuários"

    def __str__(self):
        return self.nome or self.email

    def save(self, *args, **kwargs):
        self.email = (self.email or "").lower()
        if self.papel == self.PAPEL_STAFF:
            self.is_staff = True
        super().save(*args, **kwargs)
