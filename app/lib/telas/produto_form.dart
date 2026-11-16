import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/rotulos.dart';
import '../dados/modelos.dart';
import '../widgets/aviso.dart';

class ProdutoFormTela extends StatefulWidget {
  const ProdutoFormTela({this.produtoId, super.key});

  final int? produtoId;

  @override
  State<ProdutoFormTela> createState() => _ProdutoFormTelaState();
}

class _ProdutoFormTelaState extends State<ProdutoFormTela> {
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _preco = TextEditingController();
  final _estoque = TextEditingController(text: '1');
  final _cidade = TextEditingController();
  String _uf = 'SP';
  String _condicao = 'novo';
  String _status = 'rascunho';
  int? _categoriaId;
  List<Categoria> _categorias = [];
  List<ImagemProduto> _imagens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _preco.dispose();
    _estoque.dispose();
    _cidade.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final api = context.read<ApiCliente>();
      final categorias = await api.categorias();
      ProdutoDetalhe? produto;
      if (widget.produtoId != null) produto = await api.produto(widget.produtoId!);
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        if (produto != null) {
          _titulo.text = produto.titulo;
          _descricao.text = produto.descricao;
          _preco.text = produto.preco;
          _estoque.text = '${produto.estoque}';
          _cidade.text = produto.cidade;
          if (ufs.contains(produto.uf)) _uf = produto.uf;
          _condicao = produto.condicao;
          _status = produto.status;
          _categoriaId = produto.categoriaId;
          _imagens = produto.imagens;
        }
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() => _carregando = false);
      mostrarErro(context, erro);
    }
  }

  Future<void> _salvar() async {
    final preco = double.tryParse(_preco.text.trim().replaceAll(',', '.'));
    if (_titulo.text.trim().isEmpty || preco == null) {
      mostrarErro(context, ApiException(0, 'Informe o título e um preço válido.'));
      return;
    }
    try {
      final produto = await context.read<ApiCliente>().salvarProduto({
        'titulo': _titulo.text.trim(),
        'descricao': _descricao.text.trim(),
        'preco': preco.toStringAsFixed(2),
        'estoque': int.tryParse(_estoque.text.trim()) ?? 1,
        'cidade': _cidade.text.trim(),
        'uf': _uf,
        'condicao': _condicao,
        'status': _status,
        'categoria': _categoriaId,
      }, id: widget.produtoId);
      if (!mounted) return;
      if (widget.produtoId == null) {
        context.replace('/empresa/produto/${produto.id}');
      } else {
        setState(() => _imagens = produto.imagens);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto salvo.')));
      }
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  Future<void> _imagem() async {
    if (widget.produtoId == null) {
      mostrarErro(context, ApiException(0, 'Salve o produto antes de enviar fotos.'));
      return;
    }
    final arquivo = await FilePicker.platform.pickFiles(type: FileType.image);
    if (!mounted) return;
    final caminho = arquivo?.files.single.path;
    if (caminho == null) return;
    final api = context.read<ApiCliente>();
    try {
      await api.enviarImagem(widget.produtoId!, caminho);
      final produto = await api.produto(widget.produtoId!);
      if (mounted) setState(() => _imagens = produto.imagens);
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  Future<void> _apagar() async {
    final id = widget.produtoId;
    if (id == null) return;
    try {
      await context.read<ApiCliente>().apagarProduto(id);
      if (mounted) context.go('/empresa');
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Scaffold(body: Carregando());
    return Scaffold(
      appBar: AppBar(title: Text(widget.produtoId == null ? 'Novo produto' : 'Editar produto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _titulo, decoration: const InputDecoration(labelText: 'Título')),
          const SizedBox(height: 12),
          TextField(controller: _descricao, decoration: const InputDecoration(labelText: 'Descrição'), minLines: 3, maxLines: 6),
          const SizedBox(height: 12),
          TextField(controller: _preco, decoration: const InputDecoration(labelText: 'Preço'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextField(controller: _estoque, decoration: const InputDecoration(labelText: 'Estoque'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _categoriaId,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: [for (final categoria in _categorias) DropdownMenuItem(value: categoria.id, child: Text(categoria.nome))],
            onChanged: (valor) => setState(() => _categoriaId = valor),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _condicao,
            decoration: const InputDecoration(labelText: 'Condição'),
            items: [for (final item in condicoes.entries) DropdownMenuItem(value: item.key, child: Text(item.value))],
            onChanged: (valor) => setState(() => _condicao = valor ?? 'novo'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Situação'),
            items: [for (final item in statusProduto.entries) DropdownMenuItem(value: item.key, child: Text(item.value))],
            onChanged: (valor) => setState(() => _status = valor ?? 'rascunho'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _cidade, decoration: const InputDecoration(labelText: 'Cidade')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _uf,
            decoration: const InputDecoration(labelText: 'UF'),
            items: [for (final uf in ufs) DropdownMenuItem(value: uf, child: Text(uf))],
            onChanged: (valor) => setState(() => _uf = valor ?? 'SP'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _salvar, child: const Text('Salvar')),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: _imagem, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Adicionar foto')),
          const SizedBox(height: 8),
          SizedBox(
            height: _imagens.isEmpty ? 0 : 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final imagem in _imagens)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(imagem.url, width: 110, height: 110, fit: BoxFit.cover),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.produtoId != null)
            TextButton(onPressed: _apagar, child: const Text('Excluir produto')),
        ],
      ),
    );
  }
}
