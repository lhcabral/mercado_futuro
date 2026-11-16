import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/cores.dart';
import '../core/rotulos.dart';
import '../core/sessao.dart';
import '../dados/modelos.dart';
import '../widgets/aviso.dart';

class ProdutoTela extends StatefulWidget {
  const ProdutoTela({required this.id, super.key});

  final int id;

  @override
  State<ProdutoTela> createState() => _ProdutoTelaState();
}

class _ProdutoTelaState extends State<ProdutoTela> {
  ProdutoDetalhe? _produto;
  String? _erro;
  bool _carregando = true;
  final _mensagem = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _mensagem.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final produto = await context.read<ApiCliente>().produto(widget.id);
      if (mounted) setState(() => _produto = produto);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro is ApiException ? erro.mensagem : 'Não foi possível abrir o anúncio.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _favorito() async {
    final produto = _produto;
    final sessao = context.read<Sessao>();
    if (!sessao.logado) {
      context.push('/entrar');
      return;
    }
    if (produto == null) return;
    try {
      final api = context.read<ApiCliente>();
      if (produto.favorito) {
        await api.desfavoritar(produto.id);
      } else {
        await api.favoritar(produto.id);
      }
      await _carregar();
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  Future<void> _negociar() async {
    final produto = _produto;
    final sessao = context.read<Sessao>();
    if (produto == null) return;
    if (!sessao.logado) {
      context.push('/entrar');
      return;
    }
    try {
      final negociacao = await context.read<ApiCliente>().abrirNegociacao(produto.id, _mensagem.text);
      if (mounted) context.push('/negociacoes/${negociacao.id}');
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Scaffold(body: Carregando());
    if (_erro != null || _produto == null) {
      return Scaffold(appBar: AppBar(), body: FalhaCarregamento(mensagem: _erro ?? 'Anúncio indisponível.', aoTentar: _carregar));
    }
    final produto = _produto!;
    final fornecedor = produto.fornecedor;
    final primaria = corHex(fornecedor.cores.primaria);
    final secundaria = corHex(fornecedor.cores.secundaria);
    final destaque = corHex(fornecedor.cores.destaque);
    final sessao = context.watch<Sessao>();
    final proprio = sessao.usuario?.empresa?.id == fornecedor.id;
    final local = [produto.cidade, produto.uf].where((parte) => parte.isNotEmpty).join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: Text(produto.titulo),
        actions: [
          IconButton(
            onPressed: _favorito,
            icon: Icon(produto.favorito ? Icons.favorite : Icons.favorite_border),
            color: produto.favorito ? Colors.red : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 280,
              child: produto.imagens.isEmpty
                  ? ColoredBox(color: clarear(primaria, 0.75), child: Icon(Icons.inventory_2_outlined, size: 64, color: primaria))
                  : PageView(
                      children: [
                        for (final imagem in produto.imagens)
                          Image.network(imagem.url, fit: BoxFit.cover, errorBuilder: (context, error, stack) => const Icon(Icons.broken_image_outlined)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(moeda(produto.preco), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: primaria, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${rotulo(condicoes, produto.condicao)} · $local'),
          const SizedBox(height: 16),
          Text(produto.descricao.isEmpty ? 'Sem descrição.' : produto.descricao),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(fornecedor.nomeFantasia, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  Text('${fornecedor.cidade} · ${fornecedor.uf}'),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: primaria, foregroundColor: destaque, minimumSize: const Size.fromHeight(48)),
                    onPressed: () => context.push('/fornecedor/${fornecedor.slug}'),
                    child: const Text('Produtos desse fornecedor'),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 6, decoration: BoxDecoration(color: secundaria, borderRadius: BorderRadius.circular(99))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (proprio)
            const MensagemVazia(texto: 'Este anúncio é da sua empresa.')
          else if (sessao.papel == 'empresa')
            const MensagemVazia(texto: 'A mesa de negociação é aberta por uma conta de cliente.')
          else ...[
            TextField(
              controller: _mensagem,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mensagem para o vendedor',
                hintText: 'Conte como prefere receber e pagar.',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _negociar,
              icon: const Icon(Icons.forum_outlined),
              label: Text(sessao.logado ? 'Abrir mesa de negociação' : 'Entrar para negociar'),
            ),
          ],
        ],
      ),
    );
  }
}
