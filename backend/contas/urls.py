from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from contas.views import LoginView, MeView, RegistroView

urlpatterns = [
    path("auth/registro/", RegistroView.as_view(), name="registro"),
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="refresh"),
    path("auth/me/", MeView.as_view(), name="me"),
]
