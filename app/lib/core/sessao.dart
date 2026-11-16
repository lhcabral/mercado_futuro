import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../dados/modelos.dart';

class Sessao extends ChangeNotifier {
  Sessao(this._prefs);

  final SharedPreferences _prefs;
  String? access;
  String? refresh;
  Usuario? usuario;

  bool get logado => access != null && access!.isNotEmpty;
  String get papel => usuario?.papel ?? '';

  Future<void> restaurar() async {
    access = _prefs.getString('mf_access');
    refresh = _prefs.getString('mf_refresh');
    final bruto = _prefs.getString('mf_usuario');
    if (bruto != null && bruto.isNotEmpty) {
      usuario = Usuario.deJson(jsonDecode(bruto) as Map<String, dynamic>);
    }
  }

  Future<void> guardar(Map<String, dynamic> dados) async {
    access = dados['access'] as String?;
    refresh = dados['refresh'] as String? ?? refresh;
    usuario = Usuario.deJson(Map<String, dynamic>.from(dados['usuario'] as Map));
    if (access != null) await _prefs.setString('mf_access', access!);
    if (refresh != null) await _prefs.setString('mf_refresh', refresh!);
    await _prefs.setString('mf_usuario', jsonEncode(usuario!.paraJson()));
    notifyListeners();
  }

  Future<void> definirUsuario(Usuario novo) async {
    usuario = novo;
    await _prefs.setString('mf_usuario', jsonEncode(novo.paraJson()));
    notifyListeners();
  }

  Future<void> persistirAccess() async {
    if (access != null) await _prefs.setString('mf_access', access!);
  }

  Future<void> sair() async {
    access = null;
    refresh = null;
    usuario = null;
    await _prefs.remove('mf_access');
    await _prefs.remove('mf_refresh');
    await _prefs.remove('mf_usuario');
    notifyListeners();
  }
}
