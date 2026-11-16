import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../dados/modelos.dart';
import '../widgets/aviso.dart';
import '../widgets/cartao_produto.dart';

class InicioTela extends StatefulWidget {
  const InicioTela({super.key});

  @override
  State<InicioTela> createState() => _InicioTelaState();
}

class _InicioTelaState extends State<InicioTela> {
  final _busca = TextEditingController();
  final List<ProdutoCard> _produtos = [];
  List<Categoria> _categorias = [];
  String? _categoria;
  String? _uf;
  String? _condicao;
  final _precoMin = TextEditingController();
  final _precoMax = TextEditingController();
  int _pagina = 1;
  int _total = 0;
  bool _temProxima = false;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar(reiniciar: true);
    context.read<ApiCliente>().categorias().then((lista) {
      if (mounted) setState(() => _categorias = lista);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _busca.dispose();
    _precoMin.dispose();
    _precoMax.dispose();
    super.dispose();
  }

  Map<String, String> get _filtros {
    final filtros = <String, String>{};
    if (_busca.text.trim().isNotEmpty) filtros['q'] = _busca.text.trim();
    if (_categoria != null && _categoria!.isNotEmpty) filtros['categoria'] = _categoria!;
    if (_uf != null && _uf!.isNotEmpty) filtros['uf'] = _uf!;
    if (_condicao != null && _condicao!.isNotEmpty) filtros['condicao'] = _condicao!;
    if (_precoMin.text.trim().isNotEmpty) filtros['preco_min'] = _precoMin.text.trim().replaceAll(',', '.');
    if (_precoMax.text.trim().isNotEmpty) filtros['preco_max'] = _precoMax.text.trim().replaceAll(',', '.');
    return filtros;
  }

  Future<void> _carregar({required bool reiniciar}) async {
    if (reiniciar) {
      _pagina = 1;
      _produtos.clear();
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final pagina = await context.read<ApiCliente>().produtos(pagina: _pagina, filtros: _filtros);
      if (!mounted) return;
      setState(() {
        _produtos.addAll(pagina.itens);
        _total = pagina.total;
        _temProxima = pagina.temProxima;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro is ApiException ? erro.mensagem : 'Não foi possível carregar os produtos.';
        _carregando = false;
      });
    }
  }

  Future<void> _abrirFiltros() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (contexto) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(contexto).bottom),
          child: StatefulBuilder(
            builder: (contexto, atualizar) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _categoria,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Todas')),
                      for (final categoria in _categorias) DropdownMenuItem(value: categoria.slug, child: Text(categoria.nome)),
                    ],
                    onChanged: (valor) => atualizar(() => _categoria = valor),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _condicao,
                    decoration: const InputDecoration(labelText: 'Condição'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Todas')),
                      DropdownMenuItem(value: 'novo', child: Text('Novo')),
                      DropdownMenuItem(value: 'usado', child: Text('Usado')),
                    ],
                    onChanged: (valor) => atualizar(() => _condicao = valor),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _uf,
                    decoration: const InputDecoration(labelText: 'UF'),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 2,
                    onChanged: (valor) => _uf = valor.toUpperCase(),
                  ),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _precoMin, decoration: const InputDecoration(labelText: 'Preço mínimo'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _precoMax, decoration: const InputDecoration(labelText: 'Preço máximo'), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(contexto);
                      _carregar(reiniciar: true);
                    },
                    child: const Text('Aplicar filtros'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mercado Futuro')),
      body: RefreshIndicator(
        onRefresh: () => _carregar(reiniciar: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _busca,
                    decoration: const InputDecoration(
                      hintText: 'Buscar produto ou fornecedor',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _carregar(reiniciar: true),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(onPressed: _abrirFiltros, icon: const Icon(Icons.tune)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_carregando && _produtos.isEmpty ? 'Buscando anúncios...' : '$_total anúncio${_total == 1 ? '' : 's'}'),
            const SizedBox(height: 12),
            if (_erro != null && _produtos.isEmpty)
              FalhaCarregamento(mensagem: _erro!, aoTentar: () => _carregar(reiniciar: true))
            else if (!_carregando && _produtos.isEmpty)
              const MensagemVazia(texto: 'Nenhum produto encontrado com esses filtros.')
            else
              GradeProdutos(produtos: _produtos),
            if (_temProxima)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton(
                  onPressed: _carregando
                      ? null
                      : () {
                          _pagina += 1;
                          _carregar(reiniciar: false);
                        },
                  child: const Text('Carregar mais'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
