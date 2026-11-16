import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/cores.dart';
import '../core/rotulos.dart';
import '../dados/modelos.dart';
import '../widgets/aviso.dart';

class EmpresaTela extends StatefulWidget {
  const EmpresaTela({super.key});

  @override
  State<EmpresaTela> createState() => _EmpresaTelaState();
}

class _EmpresaTelaState extends State<EmpresaTela> {
  final _razao = TextEditingController();
  final _fantasia = TextEditingController();
  final _cnpj = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _descricao = TextEditingController();
  final _endereco = TextEditingController();
  final _cidade = TextEditingController();
  String _uf = 'SP';
  String _tipoDocumento = 'contrato_social';
  EmpresaDetalhe? _empresa;
  List<ProdutoCard> _produtos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    for (final campo in [_razao, _fantasia, _cnpj, _telefone, _email, _descricao, _endereco, _cidade]) {
      campo.dispose();
    }
    super.dispose();
  }

  void _preencher(EmpresaDetalhe empresa) {
    _empresa = empresa;
    _razao.text = empresa.razaoSocial;
    _fantasia.text = empresa.nomeFantasia;
    _cnpj.text = empresa.cnpjFormatado.isEmpty ? empresa.cnpj : empresa.cnpjFormatado;
    _telefone.text = empresa.telefone;
    _email.text = empresa.email;
    _descricao.text = empresa.descricao;
    _endereco.text = empresa.endereco;
    _cidade.text = empresa.cidade;
    if (ufs.contains(empresa.uf)) _uf = empresa.uf;
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final api = context.read<ApiCliente>();
      final empresa = await api.minhaEmpresa();
      if (!mounted) return;
      if (empresa != null) {
        _preencher(empresa);
        if (empresa.status == 'aprovada') {
          _produtos = await api.meusProdutos();
        }
        await api.eu();
      }
    } catch (erro) {
      if (mounted) _erro = erro is ApiException ? erro.mensagem : 'Não foi possível abrir o painel.';
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    final corpo = {
      'razao_social': _razao.text.trim(),
      'nome_fantasia': _fantasia.text.trim(),
      'cnpj': _cnpj.text.trim(),
      'telefone': _telefone.text.trim(),
      'email': _email.text.trim(),
      'descricao': _descricao.text.trim(),
      'endereco': _endereco.text.trim(),
      'cidade': _cidade.text.trim(),
      'uf': _uf,
    };
    try {
      final empresa = await context.read<ApiCliente>().salvarEmpresa(corpo, nova: _empresa == null);
      if (!mounted) return;
      setState(() => _preencher(empresa));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastro salvo.')));
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  Future<void> _logo() async {
    final arquivo = await FilePicker.platform.pickFiles(type: FileType.image);
    if (!mounted) return;
    final caminho = arquivo?.files.single.path;
    if (caminho == null) return;
    final api = context.read<ApiCliente>();
    try {
      final empresa = await api.enviarLogo(caminho);
      if (!mounted) return;
      setState(() => _preencher(empresa));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logomarca atualizada. As cores da página foram recalculadas.')));
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  Future<void> _documento() async {
    final arquivo = await FilePicker.platform.pickFiles();
    if (!mounted) return;
    final caminho = arquivo?.files.single.path;
    if (caminho == null) return;
    final api = context.read<ApiCliente>();
    try {
      await api.enviarDocumento(caminho, _tipoDocumento);
      await _carregar();
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  Future<void> _enviarAnalise() async {
    try {
      final empresa = await context.read<ApiCliente>().enviarAnalise();
      if (!mounted) return;
      setState(() => _preencher(empresa));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastro enviado para análise.')));
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Scaffold(body: Carregando());
    if (_erro != null && _empresa == null) {
      return Scaffold(appBar: AppBar(title: const Text('Empresa')), body: FalhaCarregamento(mensagem: _erro!, aoTentar: _carregar));
    }
    final empresa = _empresa;
    final cores = empresa?.cores;
    final primaria = corHex(cores?.primaria);
    final secundaria = corHex(cores?.secundaria);
    final destaque = corHex(cores?.destaque, reserva: const Color(0xFF1A1A1A));

    return Scaffold(
      appBar: AppBar(title: const Text('Painel da empresa')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (empresa != null)
            Card(
              color: primaria,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Situação: ${rotulo(statusEmpresa, empresa.status)}${empresa.motivoRecusa.isEmpty ? '' : '\n${empresa.motivoRecusa}'}',
                  style: TextStyle(color: destaque, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(controller: _razao, decoration: const InputDecoration(labelText: 'Razão social')),
          const SizedBox(height: 12),
          TextField(controller: _fantasia, decoration: const InputDecoration(labelText: 'Nome fantasia')),
          const SizedBox(height: 12),
          TextField(controller: _cnpj, decoration: const InputDecoration(labelText: 'CNPJ')),
          const SizedBox(height: 12),
          TextField(controller: _telefone, decoration: const InputDecoration(labelText: 'Telefone')),
          const SizedBox(height: 12),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'E-mail de contato')),
          const SizedBox(height: 12),
          TextField(controller: _descricao, decoration: const InputDecoration(labelText: 'Apresentação da página'), minLines: 3, maxLines: 5),
          const SizedBox(height: 12),
          TextField(controller: _endereco, decoration: const InputDecoration(labelText: 'Endereço')),
          const SizedBox(height: 12),
          TextField(controller: _cidade, decoration: const InputDecoration(labelText: 'Cidade')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _uf,
            decoration: const InputDecoration(labelText: 'UF'),
            items: [for (final uf in ufs) DropdownMenuItem(value: uf, child: Text(uf))],
            onChanged: (valor) => setState(() => _uf = valor ?? 'SP'),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _salvar, child: Text(empresa == null ? 'Criar cadastro' : 'Salvar cadastro')),
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed: empresa == null ? null : _logo, icon: const Icon(Icons.image_outlined), label: const Text('Enviar logomarca')),
          if (empresa?.logo != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(empresa!.logo!, height: 96, width: 96, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            const Text('A página pública usa estas cores, tiradas da logomarca.'),
            const SizedBox(height: 8),
            Row(
              children: [
                _Amostra(cor: primaria, nome: 'Fundo'),
                _Amostra(cor: secundaria, nome: 'Destaque'),
                _Amostra(cor: destaque, nome: 'Texto'),
              ],
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _tipoDocumento,
            decoration: const InputDecoration(labelText: 'Tipo de documento'),
            items: [for (final item in tiposDocumento.entries) DropdownMenuItem(value: item.key, child: Text(item.value))],
            onChanged: (valor) => setState(() => _tipoDocumento = valor ?? 'contrato_social'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: empresa == null ? null : _documento, icon: const Icon(Icons.upload_file), label: const Text('Anexar documento')),
          if (empresa != null && empresa.documentos.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final documento in empresa.documentos) Text('• ${rotulo(tiposDocumento, documento.tipo)} — ${documento.nome}'),
          ],
          if (empresa != null && (empresa.status == 'rascunho' || empresa.status == 'recusada')) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: _enviarAnalise, child: const Text('Enviar para análise')),
            const SizedBox(height: 8),
            const Text('A análise pede logomarca, CNPJ, cidade e ao menos um documento. A equipe confere o checklist antes de liberar os anúncios.'),
          ],
          if (empresa != null && empresa.checklist.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Checklist', style: Theme.of(context).textTheme.titleMedium),
            for (final item in empresa.checklist)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.titulo),
                subtitle: Text(item.observacao.isEmpty ? rotulo(statusChecklist, item.status) : '${rotulo(statusChecklist, item.status)} · ${item.observacao}'),
              ),
          ],
          if (empresa?.status == 'aprovada') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Produtos', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                FilledButton.tonalIcon(onPressed: () => context.push('/empresa/produto/novo'), icon: const Icon(Icons.add), label: const Text('Novo')),
              ],
            ),
            const SizedBox(height: 8),
            if (_produtos.isEmpty)
              const MensagemVazia(texto: 'Nenhum produto cadastrado.')
            else
              for (final produto in _produtos)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(produto.titulo),
                    subtitle: Text('${moeda(produto.preco)} · ${rotulo(statusProduto, produto.status)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/empresa/produto/${produto.id}'),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _Amostra extends StatelessWidget {
  const _Amostra({required this.cor, required this.nome});

  final Color cor;
  final String nome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: cor, shape: BoxShape.circle, border: Border.all(color: const Color(0x22000000)))),
          const SizedBox(height: 4),
          Text(nome, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
