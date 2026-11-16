import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/rotulos.dart';
import '../core/sessao.dart';
import '../dados/modelos.dart';
import '../widgets/aviso.dart';

class NegociacoesTela extends StatefulWidget {
  const NegociacoesTela({super.key});

  @override
  State<NegociacoesTela> createState() => _NegociacoesTelaState();
}

class _NegociacoesTelaState extends State<NegociacoesTela> {
  List<NegociacaoResumo> _itens = [];
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
      final itens = await context.read<ApiCliente>().negociacoes();
      if (mounted) setState(() => _itens = itens);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro is ApiException ? erro.mensagem : 'Não foi possível carregar as negociações.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final papel = context.watch<Sessao>().papel;
    return Scaffold(
      appBar: AppBar(title: const Text('Negociações')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_carregando)
              const Carregando()
            else if (_erro != null)
              FalhaCarregamento(mensagem: _erro!, aoTentar: _carregar)
            else if (_itens.isEmpty)
              const MensagemVazia(texto: 'Nenhuma negociação por aqui.')
            else
              for (final item in _itens)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(item.produtoTitulo),
                    subtitle: Text('${papel == 'empresa' ? item.clienteNome : item.fornecedorNome}\n${rotulo(statusNegociacao, item.status)} · ${dataHora(item.atualizadaEm)}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/negociacoes/${item.id}'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class NegociacaoTela extends StatefulWidget {
  const NegociacaoTela({required this.id, super.key});

  final int id;

  @override
  State<NegociacaoTela> createState() => _NegociacaoTelaState();
}

class _NegociacaoTelaState extends State<NegociacaoTela> {
  NegociacaoDetalhe? _negociacao;
  String? _erro;
  bool _carregando = true;
  final _texto = TextEditingController();
  final _preco = TextEditingController();
  final _prazo = TextEditingController();
  final _observacao = TextEditingController();
  String _entrega = 'retirada';
  final Set<String> _pagamentos = {'pix'};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _texto.dispose();
    _preco.dispose();
    _prazo.dispose();
    _observacao.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final negociacao = await context.read<ApiCliente>().negociacao(widget.id);
      if (mounted) {
        setState(() {
          _negociacao = negociacao;
          _erro = null;
        });
      }
    } catch (erro) {
      if (mounted) setState(() => _erro = erro is ApiException ? erro.mensagem : 'Não foi possível abrir a mesa.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviarMensagem() async {
    if (_texto.text.trim().isEmpty) return;
    try {
      final negociacao = await context.read<ApiCliente>().enviarMensagem(widget.id, _texto.text.trim());
      _texto.clear();
      if (mounted) setState(() => _negociacao = negociacao);
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  Future<void> _enviarOpcao() async {
    final preco = double.tryParse(_preco.text.trim().replaceAll(',', '.'));
    if (preco == null || _pagamentos.isEmpty) {
      mostrarErro(context, ApiException(0, 'Informe o preço e ao menos uma forma de pagamento.'));
      return;
    }
    try {
      final negociacao = await context.read<ApiCliente>().enviarOpcao(widget.id, {
        'preco': preco.toStringAsFixed(2),
        'prazo_dias': int.tryParse(_prazo.text.trim()),
        'tipo_entrega': _entrega,
        'formas_pagamento': _pagamentos.toList(),
        'observacao': _observacao.text.trim(),
      });
      _preco.clear();
      _prazo.clear();
      _observacao.clear();
      if (mounted) setState(() => _negociacao = negociacao);
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  Future<void> _aceitar(int opcaoId) async {
    try {
      final negociacao = await context.read<ApiCliente>().aceitarOpcao(widget.id, opcaoId);
      if (mounted) setState(() => _negociacao = negociacao);
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando && _negociacao == null) return const Scaffold(body: Carregando());
    if (_erro != null && _negociacao == null) {
      return Scaffold(appBar: AppBar(), body: FalhaCarregamento(mensagem: _erro!, aoTentar: _carregar));
    }
    final mesa = _negociacao!;
    return Scaffold(
      appBar: AppBar(
        title: Text(mesa.produtoTitulo),
        actions: [
          IconButton(onPressed: () => context.push('/produto/${mesa.produtoId}'), icon: const Icon(Icons.inventory_2_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(rotulo(statusNegociacao, mesa.status), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Cliente: ${mesa.clienteNome}${mesa.clienteTelefone.isEmpty ? '' : ' · ${mesa.clienteTelefone}'}'),
          Text('Vendedor: ${mesa.fornecedorNome}${mesa.fornecedorTelefone.isEmpty ? '' : ' · ${mesa.fornecedorTelefone}'}'),
          const SizedBox(height: 16),
          Text('Conversa', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (mesa.mensagens.isEmpty) const MensagemVazia(texto: 'Nenhuma mensagem ainda.'),
          for (final mensagem in mesa.mensagens)
            Align(
              alignment: mensagem.meu ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 460),
                decoration: BoxDecoration(
                  color: mensagem.meu ? const Color(0xFF0F6B4C) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mensagem.autorNome, style: TextStyle(fontSize: 12, color: mensagem.meu ? Colors.white70 : const Color(0xFF5C6B64))),
                    Text(mensagem.texto, style: TextStyle(color: mensagem.meu ? Colors.white : const Color(0xFF14211C))),
                    Text(dataHora(mensagem.criadaEm), style: TextStyle(fontSize: 11, color: mensagem.meu ? Colors.white70 : const Color(0xFF5C6B64))),
                  ],
                ),
              ),
            ),
          if (mesa.podeMensagem) ...[
            TextField(
              controller: _texto,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mensagem'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: _enviarMensagem, child: const Text('Enviar')),
            ),
          ],
          const SizedBox(height: 20),
          Text('Opções do vendedor', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (mesa.opcoes.isEmpty) const MensagemVazia(texto: 'O vendedor ainda não deixou opções de entrega e pagamento.'),
          for (final opcao in mesa.opcoes)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moeda(opcao.preco), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('${rotulo(entregas, opcao.tipoEntrega)}${opcao.prazoDias == null ? '' : ' · ${opcao.prazoDias} dia(s)'}'),
                    Text(opcao.formasPagamento.map((item) => rotulo(pagamentos, item)).join(', ')),
                    if (opcao.observacao.isNotEmpty) Text(opcao.observacao),
                    if (opcao.escolhida) const Text('Opção escolhida', style: TextStyle(color: Color(0xFF0F6B4C), fontWeight: FontWeight.w700)),
                    if (mesa.podeAceitar && !opcao.escolhida)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(onPressed: () => _aceitar(opcao.id), child: const Text('Aceitar esta opção')),
                      ),
                  ],
                ),
              ),
            ),
          if (mesa.podeEnviarOpcao) ...[
            const SizedBox(height: 8),
            Text('Nova opção', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(controller: _preco, decoration: const InputDecoration(labelText: 'Preço'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: _prazo, decoration: const InputDecoration(labelText: 'Prazo em dias'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _entrega,
              decoration: const InputDecoration(labelText: 'Entrega'),
              items: [for (final item in entregas.entries) DropdownMenuItem(value: item.key, child: Text(item.value))],
              onChanged: (valor) => setState(() => _entrega = valor ?? 'retirada'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final item in pagamentos.entries)
                  FilterChip(
                    label: Text(item.value),
                    selected: _pagamentos.contains(item.key),
                    onSelected: (marcado) => setState(() {
                      if (marcado) {
                        _pagamentos.add(item.key);
                      } else {
                        _pagamentos.remove(item.key);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(controller: _observacao, decoration: const InputDecoration(labelText: 'Observação'), maxLines: 2),
            const SizedBox(height: 8),
            FilledButton(onPressed: _enviarOpcao, child: const Text('Publicar opção')),
          ],
        ],
      ),
    );
  }
}
