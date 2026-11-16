from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from contas.serializers import LoginSerializer, RegistroSerializer, UsuarioSerializer
from empresas.models import Empresa


class RegistroView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        from rest_framework_simplejwt.tokens import RefreshToken

        serial = RegistroSerializer(data=request.data, context={"request": request})
        serial.is_valid(raise_exception=True)
        usuario = serial.save()
        refresh = RefreshToken.for_user(usuario)
        return Response(
            {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "usuario": UsuarioSerializer(usuario, context={"request": request}).data,
            },
            status=201,
        )


class LoginView(TokenObtainPairView):
    permission_classes = [AllowAny]
    serializer_class = LoginSerializer


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UsuarioSerializer(request.user, context={"request": request}).data)

    def patch(self, request):
        serial = UsuarioSerializer(
            request.user,
            data=request.data,
            partial=True,
            context={"request": request},
        )
        serial.is_valid(raise_exception=True)
        usuario = serial.save()
        if usuario.papel == usuario.PAPEL_EMPRESA:
            try:
                empresa = usuario.empresa
            except Empresa.DoesNotExist:
                empresa = None
            if empresa is not None:
                for campo in ("telefone", "cidade", "uf"):
                    if campo in request.data and not getattr(empresa, campo):
                        setattr(empresa, campo, getattr(usuario, campo))
                empresa.save()
        return Response(UsuarioSerializer(usuario, context={"request": request}).data)
