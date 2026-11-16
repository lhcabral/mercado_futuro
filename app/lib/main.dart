import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'aplicacao.dart';
import 'core/api.dart';
import 'core/sessao.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final sessao = Sessao(prefs);
  await sessao.restaurar();
  const base = String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:8000');
  runApp(MercadoFuturoApp(sessao: sessao, api: ApiCliente(baseUrl: base, sessao: sessao)));
}
