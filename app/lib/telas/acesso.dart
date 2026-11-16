import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/rotulos.dart';
import '../widgets/aviso.dart';

class AcessoTela extends StatefulWidget {
  const AcessoTela.entrar({super.key}) : registrar = false;
  const AcessoTela.registrar({super.key}) : registrar = true;

  final bool registrar;

  @override
  State<AcessoTela> createState() => _AcessoTelaState();
}

class _AcessoTelaState extends State<AcessoTela> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _cidade = TextEditingController();
  final _razao = TextEditingController();
  final _fantasia = TextEditingController();
  final _cnpj = TextEditingController();
  String _papel = 'cliente';
  String _uf = 'SP';
  bool _enviando = false;

  @override
  void dispose() {
    for (final campo in [_email, _senha, _nome, _telefone, _cidade, _razao, _fantasia, _cnpj]) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final api = context.read<ApiCliente>();
      if (widget.registrar) {
        await api.registrar({
          'email': _email.text.trim(),
          'password': _senha.text,
          'nome': _nome.text.trim(),
          'papel': _papel,
          'telefone': _telefone.text.trim(),
          'cidade': _cidade.text.trim(),
          'uf': _papel == 'empresa' ? _uf : '',
          if (_papel == 'empresa') ...{
            'razao_social': _razao.text.trim(),
            'nome_fantasia': _fantasia.text.trim(),
            'cnpj': _cnpj.text.trim(),
            'cidade': _cidade.text.trim(),
            'uf': _uf,
          },
        });
      } else {
        await api.entrar(_email.text.trim(), _senha.text);
      }
      if (mounted) context.go('/');
    } catch (erro) {
      if (mounted) mostrarErro(context, erro);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.storefront, size: 48, color: Color(0xFF0F6B4C)),
                  const SizedBox(height: 8),
                  Text(
                    widget.registrar ? 'Criar conta' : 'Entrar',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text('Empresas verificadas, produtos e mesa de negociação.'),
                  const SizedBox(height: 20),
                  if (widget.registrar) ...[
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'cliente', label: Text('Cliente')),
                        ButtonSegment(value: 'empresa', label: Text('Empresa')),
                      ],
                      selected: {_papel},
                      onSelectionChanged: (valor) => setState(() => _papel = valor.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nome,
                      decoration: const InputDecoration(labelText: 'Seu nome'),
                      validator: (valor) => (valor == null || valor.trim().isEmpty) ? 'Informe seu nome.' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (valor) => (valor == null || !valor.contains('@')) ? 'Informe um e-mail válido.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senha,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    validator: (valor) => (valor == null || valor.length < 8) ? 'Use pelo menos 8 caracteres.' : null,
                  ),
                  if (widget.registrar && _papel == 'empresa') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _razao,
                      decoration: const InputDecoration(labelText: 'Razão social'),
                      validator: (valor) => (valor == null || valor.trim().isEmpty) ? 'Informe a razão social.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fantasia,
                      decoration: const InputDecoration(labelText: 'Nome fantasia'),
                      validator: (valor) => (valor == null || valor.trim().isEmpty) ? 'Informe o nome fantasia.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cnpj,
                      decoration: const InputDecoration(labelText: 'CNPJ'),
                      validator: (valor) => (valor == null || valor.trim().length < 14) ? 'Informe o CNPJ.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cidade,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      validator: (valor) => (valor == null || valor.trim().isEmpty) ? 'Informe a cidade.' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _uf,
                      decoration: const InputDecoration(labelText: 'UF'),
                      items: [for (final uf in ufs) DropdownMenuItem(value: uf, child: Text(uf))],
                      onChanged: (valor) => setState(() => _uf = valor ?? 'SP'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _enviando ? null : _enviar,
                    child: Text(_enviando ? 'Aguarde...' : widget.registrar ? 'Criar conta' : 'Entrar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go(widget.registrar ? '/entrar' : '/registrar'),
                    child: Text(widget.registrar ? 'Já tenho conta' : 'Criar conta'),
                  ),
                  TextButton(onPressed: () => context.go('/'), child: const Text('Continuar sem entrar')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
