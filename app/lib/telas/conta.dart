import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/rotulos.dart';
import '../core/sessao.dart';
import '../widgets/aviso.dart';

class ContaTela extends StatefulWidget {
  const ContaTela({super.key});

  @override
  State<ContaTela> createState() => _ContaTelaState();
}

class _ContaTelaState extends State<ContaTela> {
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _cidade = TextEditingController();
  String _uf = '';
  bool _pronto = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final usuario = context.read<Sessao>().usuario;
    if (usuario != null && !_pronto) {
      _nome.text = usuario.nome;
      _telefone.text = usuario.telefone;
      _cidade.text = usuario.cidade;
      _uf = usuario.uf;
      _pronto = true;
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _cidade.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    try {
      await context.read<ApiCliente>().atualizarEu({
        'nome': _nome.text.trim(),
        'telefone': _telefone.text.trim(),
        'cidade': _cidade.text.trim(),
        'uf': _uf,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados atualizados.')));
      }
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<Sessao>();
    final usuario = sessao.usuario;
    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conta')),
        body: Center(child: FilledButton(onPressed: () => context.push('/entrar'), child: const Text('Entrar'))),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Conta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(usuario.email, style: const TextStyle(color: Color(0xFF5C6B64))),
          Text(rotulo({'cliente': 'Cliente', 'empresa': 'Empresa', 'staff': 'Equipe'}, usuario.papel), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome')),
          const SizedBox(height: 12),
          TextField(controller: _telefone, decoration: const InputDecoration(labelText: 'Telefone')),
          const SizedBox(height: 12),
          TextField(controller: _cidade, decoration: const InputDecoration(labelText: 'Cidade')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: ufs.contains(_uf) ? _uf : null,
            decoration: const InputDecoration(labelText: 'UF'),
            items: [for (final uf in ufs) DropdownMenuItem(value: uf, child: Text(uf))],
            onChanged: (valor) => setState(() => _uf = valor ?? ''),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _salvar, child: const Text('Salvar dados')),
          const SizedBox(height: 24),
          if (usuario.papel == 'empresa')
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Painel da empresa'),
              subtitle: Text(usuario.empresa == null ? 'Complete o cadastro' : rotulo(statusEmpresa, usuario.empresa!.status)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/empresa'),
            ),
          if (usuario.papel == 'staff')
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Validar empresas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/equipe'),
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              await sessao.sair();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
    );
  }
}
