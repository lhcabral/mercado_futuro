import 'package:flutter/material.dart';

import '../core/api.dart';

void mostrarErro(BuildContext context, Object erro) {
  final mensagem = erro is ApiException ? erro.mensagem : 'Não foi possível concluir. Tente de novo.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
}

class Carregando extends StatelessWidget {
  const Carregando({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
  }
}

class FalhaCarregamento extends StatelessWidget {
  const FalhaCarregamento({required this.mensagem, required this.aoTentar, super.key});

  final String mensagem;
  final VoidCallback aoTentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 42),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: aoTentar, child: const Text('Tentar de novo')),
          ],
        ),
      ),
    );
  }
}

class MensagemVazia extends StatelessWidget {
  const MensagemVazia({required this.texto, super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF5C6B64))),
    );
  }
}
