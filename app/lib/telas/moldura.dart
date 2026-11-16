import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Moldura extends StatelessWidget {
  const Moldura({required this.caminho, required this.child, super.key});

  final String caminho;
  final Widget child;

  int get _indice {
    if (caminho.startsWith('/favoritos')) return 1;
    if (caminho.startsWith('/negociacoes')) return 2;
    if (caminho.startsWith('/conta') || caminho.startsWith('/empresa') || caminho.startsWith('/equipe')) return 3;
    return 0;
  }

  void _ir(BuildContext context, int indice) {
    const rotas = ['/', '/favoritos', '/negociacoes', '/conta'];
    context.go(rotas[indice]);
  }

  @override
  Widget build(BuildContext context) {
    final largo = MediaQuery.sizeOf(context).width >= 840;
    if (largo) {
      return ColoredBox(
        color: const Color(0xFFF3F6F4),
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _indice,
              onDestinationSelected: (indice) => _ir(context, indice),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: Text('Explorar')),
                NavigationRailDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: Text('Favoritos')),
                NavigationRailDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: Text('Negociações')),
                NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Conta')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(child: child),
        NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: (indice) => _ir(context, indice),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Explorar'),
            NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favoritos'),
            NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'Negociações'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Conta'),
          ],
        ),
      ],
    );
  }
}
