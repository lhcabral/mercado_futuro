import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/cores.dart';
import '../core/rotulos.dart';
import '../dados/modelos.dart';

class CartaoProduto extends StatelessWidget {
  const CartaoProduto({
    required this.produto,
    this.corAcento,
    this.mostrarFornecedor = true,
    super.key,
  });

  final ProdutoCard produto;
  final Color? corAcento;
  final bool mostrarFornecedor;

  @override
  Widget build(BuildContext context) {
    final acento = corAcento ?? const Color(0xFF0F6B4C);
    final local = [produto.cidade, produto.uf].where((parte) => parte.isNotEmpty).join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/produto/${produto.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: acento),
            SizedBox(
              height: 148,
              child: produto.capa == null
                  ? ColoredBox(
                      color: clarear(acento, 0.75),
                      child: Icon(Icons.inventory_2_outlined, color: acento, size: 42),
                    )
                  : Image.network(
                      produto.capa!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => ColoredBox(
                        color: clarear(acento, 0.75),
                        child: Icon(Icons.broken_image_outlined, color: acento),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, height: 1.2),
                    ),
                    const Spacer(),
                    Text(moeda(produto.preco), style: TextStyle(color: acento, fontWeight: FontWeight.w700, fontSize: 16)),
                    if (local.isNotEmpty) Text(local, style: const TextStyle(color: Color(0xFF5C6B64), fontSize: 12)),
                    if (mostrarFornecedor && produto.fornecedorNome.isNotEmpty)
                      Text(
                        produto.fornecedorNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GradeProdutos extends StatelessWidget {
  const GradeProdutos({
    required this.produtos,
    this.corAcento,
    this.mostrarFornecedor = true,
    super.key,
  });

  final List<ProdutoCard> produtos;
  final Color? corAcento;
  final bool mostrarFornecedor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final colunas = limites.maxWidth >= 1100
            ? 4
            : limites.maxWidth >= 800
                ? 3
                : limites.maxWidth >= 560
                    ? 2
                    : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: produtos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colunas,
            mainAxisExtent: 292,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, indice) => CartaoProduto(
            produto: produtos[indice],
            corAcento: corAcento,
            mostrarFornecedor: mostrarFornecedor,
          ),
        );
      },
    );
  }
}
