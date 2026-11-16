import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../dados/modelos.dart';
import '../widgets/aviso.dart';
import '../widgets/cartao_produto.dart';

class FavoritosTela extends StatefulWidget {
  const FavoritosTela({super.key});

  @override
  State<FavoritosTela> createState() => _FavoritosTelaState();
}

class _FavoritosTelaState extends State<FavoritosTela> {
  List<ProdutoCard> _produtos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final produtos = await context.read<ApiCliente>().favoritos();
      if (mounted) setState(() => _produtos = produtos);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro is ApiException ? erro.mensagem : 'Não foi possível carregar os favoritos.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_carregando)
              const Carregando()
            else if (_erro != null)
              FalhaCarregamento(mensagem: _erro!, aoTentar: _carregar)
            else if (_produtos.isEmpty)
              const MensagemVazia(texto: 'Você ainda não favoritou produtos.')
            else
              GradeProdutos(produtos: _produtos),
          ],
        ),
      ),
    );
  }
}
