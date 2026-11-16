import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/rotulos.dart';
import '../core/sessao.dart';
import '../dados/modelos.dart';
import '../widgets/aviso.dart';

class EquipeTela extends StatefulWidget {
  const EquipeTela({super.key});

  @override
  State<EquipeTela> createState() => _EquipeTelaState();
}

class _EquipeTelaState extends State<EquipeTela> {
  String _status = 'em_analise';
  List<EmpresaResumo> _empresas = [];
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
      final empresas = await context.read<ApiCliente>().filaEmpresas(status: _status);
      if (mounted) setState(() => _empresas = empresas);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro is ApiException ? erro.mensagem : 'Não foi possível carregar a fila.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<Sessao>().papel != 'staff') {
      return const Scaffold(body: Center(child: Text('Área restrita à equipe do aplicativo.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Validar empresas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Situação'),
            items: [for (final item in statusEmpresa.entries) DropdownMenuItem(value: item.key, child: Text(item.value))],
            onChanged: (valor) {
              setState(() => _status = valor ?? 'em_analise');
              _carregar();
            },
          ),
          const SizedBox(height: 12),
          if (_carregando)
            const Carregando()
          else if (_erro != null)
            FalhaCarregamento(mensagem: _erro!, aoTentar: _carregar)
          else if (_empresas.isEmpty)
            const MensagemVazia(texto: 'Nenhuma empresa nesta situação.')
          else
            for (final empresa in _empresas)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(empresa.nomeFantasia),
                  subtitle: Text('${empresa.cidade} · ${empresa.uf}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/equipe/${empresa.id}'),
                ),
              ),
        ],
      ),
    );
  }
}

class EquipeDetalheTela extends StatefulWidget {
  const EquipeDetalheTela({required this.empresaId, super.key});

  final int empresaId;

  @override
  State<EquipeDetalheTela> createState() => _EquipeDetalheTelaState();
}

class _EquipeDetalheTelaState extends State<EquipeDetalheTela> {
  EmpresaDetalhe? _empresa;
  String? _erro;
  bool _carregando = true;
  final _motivo = TextEditingController();
  final Map<String, String> _observacoes = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final empresa = await context.read<ApiCliente>().empresaEquipe(widget.empresaId);
      if (!mounted) return;
      setState(() {
        _empresa = empresa;
        _motivo.text = empresa.motivoRecusa;
        _erro = null;
        for (final item in empresa.checklist) {
          _observacoes.putIfAbsent(item.codigo, () => item.observacao);
        }
      });
    } catch (erro) {
      if (mounted) setState(() => _erro = erro is ApiException ? erro.mensagem : 'Não foi possível abrir a empresa.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _marcar(ItemChecklist item, String status) async {
    try {
      final empresa = await context.read<ApiCliente>().marcarChecklist(
            widget.empresaId,
            item.codigo,
            status,
            _observacoes[item.codigo] ?? '',
          );
      if (mounted) setState(() => _empresa = empresa);
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  Future<void> _consultar() async {
    try {
      final empresa = await context.read<ApiCliente>().consultarCnpj(widget.empresaId);
      if (!mounted) return;
      setState(() => _empresa = empresa);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consulta de CNPJ registrada no checklist.')));
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  Future<void> _decidir(String decisao) async {
    try {
      final empresa = await context.read<ApiCliente>().decidirEmpresa(widget.empresaId, decisao, _motivo.text.trim());
      if (!mounted) return;
      setState(() => _empresa = empresa);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Empresa ${rotulo(statusEmpresa, empresa.status).toLowerCase()}.')));
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando && _empresa == null) return const Scaffold(body: Carregando());
    if (_erro != null && _empresa == null) {
      return Scaffold(appBar: AppBar(), body: FalhaCarregamento(mensagem: _erro!, aoTentar: _carregar));
    }
    final empresa = _empresa!;
    return Scaffold(
      appBar: AppBar(title: Text(empresa.nomeFantasia)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${empresa.razaoSocial}\nCNPJ ${empresa.cnpjFormatado}\n${empresa.cidade} · ${empresa.uf}', style: const TextStyle(height: 1.4)),
          const SizedBox(height: 8),
          Text('Situação atual: ${rotulo(statusEmpresa, empresa.status)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(onPressed: _consultar, icon: const Icon(Icons.travel_explore), label: const Text('Consultar CNPJ')),
          const SizedBox(height: 16),
          Text('Checklist', style: Theme.of(context).textTheme.titleMedium),
          for (final item in empresa.checklist)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey('${item.codigo}-${item.status}'),
                      initialValue: item.status,
                      decoration: const InputDecoration(labelText: 'Resultado'),
                      items: [for (final opcao in statusChecklist.entries) DropdownMenuItem(value: opcao.key, child: Text(opcao.value))],
                      onChanged: (valor) {
                        if (valor != null) _marcar(item, valor);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _observacoes[item.codigo] ?? '',
                      decoration: const InputDecoration(labelText: 'Observação'),
                      onChanged: (valor) => _observacoes[item.codigo] = valor,
                    ),
                    if (item.evidencia.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(item.evidencia, maxLines: 6, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextField(controller: _motivo, decoration: const InputDecoration(labelText: 'Motivo, se for recusar ou suspender'), minLines: 2, maxLines: 4),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => _decidir('aprovada'), child: const Text('Aprovar empresa')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => _decidir('recusada'), child: const Text('Recusar')),
          TextButton(onPressed: () => _decidir('suspensa'), child: const Text('Suspender')),
        ],
      ),
    );
  }
}
