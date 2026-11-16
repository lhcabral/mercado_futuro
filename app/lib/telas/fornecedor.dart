import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/cores.dart';
import '../dados/modelos.dart';
import '../widgets/aviso.dart';
import '../widgets/cartao_produto.dart';

class FornecedorTela extends StatefulWidget {
  const FornecedorTela({required this.slug, super.key});

  final String slug;

  @override
  State<FornecedorTela> createState() => _FornecedorTelaState();
}

class _FornecedorTelaState extends State<FornecedorTela> {
  PaginaFornecedor? _pagina;
  String? _erro;
  bool _carregando = true;

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
      final pagina = await context.read<ApiCliente>().paginaFornecedor(widget.slug);
      if (mounted) setState(() => _pagina = pagina);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro is ApiException ? erro.mensagem : 'Não foi possível abrir a página do fornecedor.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Scaffold(body: Carregando());
    final pagina = _pagina;
    if (_erro != null || pagina == null) {
      return Scaffold(appBar: AppBar(), body: FalhaCarregamento(mensagem: _erro ?? 'Fornecedor indisponível.', aoTentar: _carregar));
    }

    final primaria = corHex(pagina.cores.primaria);
    final secundaria = corHex(pagina.cores.secundaria);
    final destaque = corHex(pagina.cores.destaque);
    final fundo = clarear(primaria, 0.9);
    final iniciais = pagina.nomeFantasia.isEmpty ? '?' : pagina.nomeFantasia[0].toUpperCase();

    return Scaffold(
      backgroundColor: fundo,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: primaria,
            foregroundColor: destaque,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(pagina.nomeFantasia, style: TextStyle(color: destaque, fontWeight: FontWeight.w700)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: primaria),
                  Positioned(
                    right: -36,
                    top: -20,
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(color: secundaria.withValues(alpha: 0.92), shape: BoxShape.circle),
                    ),
                  ),
                  Positioned(
                    left: -46,
                    bottom: -40,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(color: secundaria.withValues(alpha: 0.35), shape: BoxShape.circle),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 88, 24, 64),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: pagina.logo == null
                                ? ColoredBox(
                                    color: clarear(primaria, 0.8),
                                    child: SizedBox(width: 84, height: 84, child: Center(child: Text(iniciais, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: primaria)))),
                                  )
                                : Image.network(
                                    pagina.logo!,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) => SizedBox(width: 84, height: 84, child: Center(child: Text(iniciais))),
                                  ),
                          ),
                        ),
                        const Spacer(),
                        Text('${pagina.cidade} · ${pagina.uf}', style: TextStyle(color: destaque.withValues(alpha: 0.92))),
                        if (pagina.telefone.isNotEmpty)
                          Text(pagina.telefone, style: TextStyle(color: destaque.withValues(alpha: 0.92))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: Container(height: 10, color: secundaria)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(pagina.descricao.isEmpty ? 'Este fornecedor ainda não escreveu uma apresentação.' : pagina.descricao),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('Produtos', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: primaria, fontWeight: FontWeight.w700)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverToBoxAdapter(
              child: pagina.produtos.isEmpty
                  ? const MensagemVazia(texto: 'Este fornecedor ainda não publicou produtos.')
                  : GradeProdutos(produtos: pagina.produtos, corAcento: secundaria, mostrarFornecedor: false),
            ),
          ),
        ],
      ),
    );
  }
}
