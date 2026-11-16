from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

admin.site.site_header = "Mercado Futuro"
admin.site.site_title = "Mercado Futuro"
admin.site.index_title = "Operação"

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/", include("contas.urls")),
    path("api/v1/", include("empresas.urls")),
    path("api/v1/", include("catalogo.urls")),
    path("api/v1/", include("negociacoes.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
