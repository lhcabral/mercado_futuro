# Mercado Futuro

API em Django e aplicativo Flutter (Android, iOS e desktop) para um marketplace de empresas verificadas.

## Subir a API

Na raiz do projeto:

```bash
.venv/bin/python backend/manage.py migrate
.venv/bin/python backend/manage.py popular_demo
.venv/bin/python backend/manage.py runserver 0.0.0.0:8000
```

Contas da demonstração:

| Papel | E-mail | Senha |
|---|---|---|
| Equipe | equipe@mercadofuturo.local | Equipe#2026 |
| Empresa aprovada (AgroVale) | contato@agrovale.local | Agrovale#2026 |
| Empresa em análise | ana@hortisul.local | Hortisul#2026 |
| Cliente | cliente@mercadofuturo.local | Cliente#2026 |

O admin da equipe também abre em http://127.0.0.1:8000/admin/ com a conta da equipe.

## Aplicativo

O SDK usado neste ambiente fica em `.tooling/flutter` (não entra no git). Com o Flutter no PATH, os mesmos comandos valem com `flutter` no lugar do caminho abaixo.

Nesta máquina ainda não há compilador C++, CMake, Ninja nem GTK de desenvolvimento, então a janela nativa do Linux não compila. O mesmo app abre no Chrome:

```bash
cd app
../.tooling/flutter/bin/flutter pub get
../.tooling/flutter/bin/flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:8000
```

Para a janela nativa, instale as ferramentas e rode de novo:

```bash
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
cd app
../.tooling/flutter/bin/flutter run -d linux --dart-define=API_URL=http://127.0.0.1:8000
```

No emulador Android use `--dart-define=API_URL=http://10.0.2.2:8000`.

## Página do fornecedor

No anúncio, o botão **Produtos desse fornecedor** abre a página interna da empresa. As cores vêm da logomarca, gravadas na aprovação do cadastro e atualizadas quando a logo muda.

A AgroVale de demonstração fica em `/fornecedor/agrovale` no app e em `/api/v1/fornecedores/agrovale/` na API.
