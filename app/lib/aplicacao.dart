import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/sessao.dart';
import 'telas/acesso.dart';
import 'telas/conta.dart';
import 'telas/empresa.dart';
import 'telas/equipe.dart';
import 'telas/favoritos.dart';
import 'telas/fornecedor.dart';
import 'telas/inicio.dart';
import 'telas/moldura.dart';
import 'telas/negociacoes.dart';
import 'telas/produto.dart';
import 'telas/produto_form.dart';

ThemeData temaMercado() {
  const tinta = Color(0xFF14211C);
  final esquema = ColorScheme.fromSeed(seedColor: const Color(0xFF0F6B4C));
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: const Color(0xFFF3F6F4),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: tinta,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );
}

GoRouter criarRoteador(Sessao sessao) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: sessao,
    redirect: (context, state) {
      final caminho = state.uri.path;
      final protegida = caminho.startsWith('/favoritos') ||
          caminho.startsWith('/negociacoes') ||
          caminho.startsWith('/conta') ||
          caminho.startsWith('/empresa') ||
          caminho.startsWith('/equipe');
      if (protegida && !sessao.logado) return '/entrar';
      if (sessao.logado && (caminho == '/entrar' || caminho == '/registrar')) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/entrar', builder: (context, state) => const AcessoTela.entrar()),
      GoRoute(path: '/registrar', builder: (context, state) => const AcessoTela.registrar()),
      ShellRoute(
        builder: (context, state, child) => Moldura(caminho: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const InicioTela()),
          GoRoute(path: '/favoritos', builder: (context, state) => const FavoritosTela()),
          GoRoute(path: '/negociacoes', builder: (context, state) => const NegociacoesTela()),
          GoRoute(
            path: '/negociacoes/:id',
            builder: (context, state) => NegociacaoTela(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/conta', builder: (context, state) => const ContaTela()),
          GoRoute(
            path: '/produto/:id',
            builder: (context, state) => ProdutoTela(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/fornecedor/:slug',
            builder: (context, state) => FornecedorTela(slug: state.pathParameters['slug']!),
          ),
          GoRoute(path: '/empresa', builder: (context, state) => const EmpresaTela()),
          GoRoute(path: '/empresa/produto/novo', builder: (context, state) => const ProdutoFormTela()),
          GoRoute(
            path: '/empresa/produto/:id',
            builder: (context, state) => ProdutoFormTela(produtoId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/equipe', builder: (context, state) => const EquipeTela()),
          GoRoute(
            path: '/equipe/:id',
            builder: (context, state) => EquipeDetalheTela(empresaId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ],
  );
}

class MercadoFuturoApp extends StatefulWidget {
  const MercadoFuturoApp({required this.sessao, required this.api, super.key});

  final Sessao sessao;
  final ApiCliente api;

  @override
  State<MercadoFuturoApp> createState() => _MercadoFuturoAppState();
}

class _MercadoFuturoAppState extends State<MercadoFuturoApp> {
  late final GoRouter _roteador = criarRoteador(widget.sessao);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Sessao>.value(value: widget.sessao),
        Provider<ApiCliente>.value(value: widget.api),
      ],
      child: MaterialApp.router(
        title: 'Mercado Futuro',
        theme: temaMercado(),
        routerConfig: _roteador,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
