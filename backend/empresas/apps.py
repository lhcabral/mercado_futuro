from django.apps import AppConfig


class EmpresasConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "empresas"
    verbose_name = "Empresas"

    def ready(self):
        import empresas.signals  # noqa: F401
