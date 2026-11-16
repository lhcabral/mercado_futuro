from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from contas.models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    ordering = ("email",)
    list_display = ("email", "nome", "papel", "cidade", "uf", "is_active")
    list_filter = ("papel", "is_active", "is_staff")
    search_fields = ("email", "nome")
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Perfil", {"fields": ("nome", "papel", "telefone", "cidade", "uf")}),
        ("Permissões", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Datas", {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "nome", "papel", "password1", "password2"),
            },
        ),
    )
