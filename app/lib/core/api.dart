import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dados/modelos.dart';
import 'sessao.dart';

class ApiException implements Exception {
  ApiException(this.status, this.mensagem);

  final int status;
  final String mensagem;

  @override
  String toString() => mensagem;
}

class ApiCliente {
  ApiCliente({required this.baseUrl, required this.sessao});

  final String baseUrl;
  final Sessao sessao;

  Uri _uri(String caminho, [Map<String, String>? consulta]) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$base$caminho').replace(
      queryParameters: consulta == null || consulta.isEmpty ? null : consulta,
    );
  }

  Map<String, String> _cabecalhos({required bool autenticado}) {
    final cabecalhos = {'Accept': 'application/json'};
    if (autenticado && sessao.access != null) {
      cabecalhos['Authorization'] = 'Bearer ${sessao.access}';
    }
    return cabecalhos;
  }

  Future<http.Response> _enviar(
    Future<http.Response> Function(Map<String, String> cabecalhos) chamada, {
    bool autenticado = true,
  }) async {
    http.Response resposta;
    try {
      resposta = await chamada(_cabecalhos(autenticado: autenticado)).timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw ApiException(0, 'A API demorou para responder.');
    } on http.ClientException {
      throw ApiException(0, 'Sem conexão com a API. Confira se o servidor está no ar.');
    }

    if (resposta.statusCode == 401 && autenticado && sessao.refresh != null) {
      final renovou = await _renovar();
      if (renovou) {
        try {
          resposta = await chamada(_cabecalhos(autenticado: true)).timeout(const Duration(seconds: 25));
        } on TimeoutException {
          throw ApiException(0, 'A API demorou para responder.');
        } on http.ClientException {
          throw ApiException(0, 'Sem conexão com a API. Confira se o servidor está no ar.');
        }
      } else {
        await sessao.sair();
      }
    }

    if (resposta.statusCode >= 400) {
      throw ApiException(resposta.statusCode, _mensagem(resposta));
    }
    return resposta;
  }

  Future<bool> _renovar() async {
    final token = sessao.refresh;
    if (token == null) return false;
    try {
      final resposta = await http
          .post(
            _uri('/api/v1/auth/refresh/'),
            headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': token}),
          )
          .timeout(const Duration(seconds: 25));
      if (resposta.statusCode >= 400) return false;
      final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
      sessao.access = dados['access'] as String?;
      await sessao.persistirAccess();
      return sessao.access != null;
    } catch (_) {
      return false;
    }
  }

  String _mensagem(http.Response resposta) {
    try {
      final corpo = jsonDecode(resposta.body);
      if (corpo is Map) {
        final detalhe = corpo['detail'];
        if (detalhe is String && detalhe.isNotEmpty) return detalhe;
        if (detalhe is List && detalhe.isNotEmpty) return detalhe.join('\n');
        final partes = <String>[];
        corpo.forEach((chave, valor) {
          if (chave == 'detail') return;
          if (valor is List) {
            partes.add(valor.join(' '));
          } else if (valor != null) {
            partes.add('$valor');
          }
        });
        if (partes.isNotEmpty) return partes.join('\n');
      }
    } catch (_) {}
    return 'Não foi possível concluir a operação.';
  }

  Map<String, dynamic> _mapa(http.Response resposta) {
    if (resposta.body.isEmpty) return {};
    final corpo = jsonDecode(resposta.body);
    if (corpo is Map<String, dynamic>) return corpo;
    if (corpo is Map) return Map<String, dynamic>.from(corpo);
    return {};
  }

  List<dynamic> _lista(http.Response resposta) {
    if (resposta.body.isEmpty) return [];
    final corpo = jsonDecode(resposta.body);
    if (corpo is List) return corpo;
    throw ApiException(resposta.statusCode, 'Resposta inesperada da API.');
  }

  Future<Map<String, dynamic>> _postJson(String caminho, Map<String, dynamic> corpo, {bool autenticado = true}) async {
    final resposta = await _enviar(
      (cabecalhos) => http.post(
        _uri(caminho),
        headers: {...cabecalhos, 'Content-Type': 'application/json'},
        body: jsonEncode(corpo),
      ),
      autenticado: autenticado,
    );
    return _mapa(resposta);
  }

  Future<Map<String, dynamic>> _patchJson(String caminho, Map<String, dynamic> corpo) async {
    final resposta = await _enviar(
      (cabecalhos) => http.patch(
        _uri(caminho),
        headers: {...cabecalhos, 'Content-Type': 'application/json'},
        body: jsonEncode(corpo),
      ),
    );
    return _mapa(resposta);
  }

  Future<Map<String, dynamic>> _enviarArquivo(
    String metodo,
    String caminho,
    String campo,
    String arquivo, {
    Map<String, String>? campos,
  }) async {
    final resposta = await _enviar((cabecalhos) async {
      final pedido = http.MultipartRequest(metodo, _uri(caminho));
      pedido.headers.addAll(cabecalhos);
      if (campos != null) pedido.fields.addAll(campos);
      pedido.files.add(await http.MultipartFile.fromPath(campo, arquivo));
      final enviado = await pedido.send();
      return http.Response.fromStream(enviado);
    });
    return _mapa(resposta);
  }

  Future<Usuario> entrar(String email, String senha) async {
    final dados = await _postJson('/api/v1/auth/login/', {'email': email, 'password': senha}, autenticado: false);
    await sessao.guardar(dados);
    return sessao.usuario!;
  }

  Future<Usuario> registrar(Map<String, dynamic> corpo) async {
    final dados = await _postJson('/api/v1/auth/registro/', corpo, autenticado: false);
    await sessao.guardar(dados);
    return sessao.usuario!;
  }

  Future<Usuario> eu() async {
    final dados = _mapa(await _enviar((cabecalhos) => http.get(_uri('/api/v1/auth/me/'), headers: cabecalhos)));
    final usuario = Usuario.deJson(dados);
    await sessao.definirUsuario(usuario);
    return usuario;
  }

  Future<Usuario> atualizarEu(Map<String, dynamic> corpo) async {
    final dados = await _patchJson('/api/v1/auth/me/', corpo);
    final usuario = Usuario.deJson(dados);
    await sessao.definirUsuario(usuario);
    return usuario;
  }

  Future<List<Categoria>> categorias() async {
    final resposta = await _enviar((cabecalhos) => http.get(_uri('/api/v1/categorias/'), headers: cabecalhos), autenticado: false);
    return _lista(resposta).map((item) => Categoria.deJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<PaginaProdutos> produtos({int pagina = 1, Map<String, String>? filtros}) async {
    final consulta = {'page': '$pagina', ...?filtros};
    final resposta = await _enviar(
      (cabecalhos) => http.get(_uri('/api/v1/produtos/', consulta), headers: cabecalhos),
      autenticado: sessao.logado,
    );
    return PaginaProdutos.deJson(_mapa(resposta));
  }

  Future<List<ProdutoCard>> meusProdutos() async {
    final resposta = await _enviar((cabecalhos) => http.get(_uri('/api/v1/produtos/', {'meus': '1'}), headers: cabecalhos));
    return PaginaProdutos.deJson(_mapa(resposta)).itens;
  }

  Future<ProdutoDetalhe> produto(int id) async {
    final resposta = await _enviar(
      (cabecalhos) => http.get(_uri('/api/v1/produtos/$id/'), headers: cabecalhos),
      autenticado: sessao.logado,
    );
    return ProdutoDetalhe.deJson(_mapa(resposta));
  }

  Future<ProdutoDetalhe> salvarProduto(Map<String, dynamic> corpo, {int? id}) async {
    final dados = id == null
        ? await _postJson('/api/v1/produtos/', corpo)
        : await _patchJson('/api/v1/produtos/$id/', corpo);
    return ProdutoDetalhe.deJson(dados);
  }

  Future<void> apagarProduto(int id) async {
    await _enviar((cabecalhos) => http.delete(_uri('/api/v1/produtos/$id/'), headers: cabecalhos));
  }

  Future<void> enviarImagem(int produtoId, String arquivo) async {
    await _enviarArquivo('POST', '/api/v1/produtos/$produtoId/imagens/', 'imagem', arquivo);
  }

  Future<PaginaFornecedor> paginaFornecedor(String slug) async {
    final resposta = await _enviar(
      (cabecalhos) => http.get(_uri('/api/v1/fornecedores/$slug/'), headers: cabecalhos),
      autenticado: sessao.logado,
    );
    return PaginaFornecedor.deJson(_mapa(resposta));
  }

  Future<List<ProdutoCard>> favoritos() async {
    final resposta = await _enviar((cabecalhos) => http.get(_uri('/api/v1/favoritos/'), headers: cabecalhos));
    return _lista(resposta).map((item) => ProdutoCard.deJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<void> favoritar(int produtoId) async {
    await _postJson('/api/v1/favoritos/', {'produto': produtoId});
  }

  Future<void> desfavoritar(int produtoId) async {
    await _enviar((cabecalhos) => http.delete(_uri('/api/v1/favoritos/$produtoId/'), headers: cabecalhos));
  }

  Future<EmpresaDetalhe?> minhaEmpresa() async {
    try {
      final resposta = await _enviar((cabecalhos) => http.get(_uri('/api/v1/empresas/minha/'), headers: cabecalhos));
      return EmpresaDetalhe.deJson(_mapa(resposta));
    } on ApiException catch (erro) {
      if (erro.status == 404) return null;
      rethrow;
    }
  }

  Future<EmpresaDetalhe> salvarEmpresa(Map<String, dynamic> corpo, {bool nova = false}) async {
    final dados = nova ? await _postJson('/api/v1/empresas/minha/', corpo) : await _patchJson('/api/v1/empresas/minha/', corpo);
    return EmpresaDetalhe.deJson(dados);
  }

  Future<EmpresaDetalhe> enviarLogo(String arquivo) async {
    final dados = await _enviarArquivo('PATCH', '/api/v1/empresas/minha/', 'logo', arquivo);
    return EmpresaDetalhe.deJson(dados);
  }

  Future<void> enviarDocumento(String arquivo, String tipo) async {
    await _enviarArquivo('POST', '/api/v1/empresas/minha/documentos/', 'arquivo', arquivo, campos: {'tipo': tipo});
  }

  Future<EmpresaDetalhe> enviarAnalise() async {
    final dados = await _postJson('/api/v1/empresas/minha/enviar-analise/', {});
    return EmpresaDetalhe.deJson(dados);
  }

  Future<List<EmpresaResumo>> filaEmpresas({String? status}) async {
    final consulta = status == null || status.isEmpty ? null : {'status': status};
    final resposta = await _enviar((cabecalhos) => http.get(_uri('/api/v1/admin/empresas/', consulta), headers: cabecalhos));
    return _lista(resposta).map((item) => EmpresaResumo.deJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<EmpresaDetalhe> empresaEquipe(int id) async {
    final resposta = await _enviar((cabecalhos) => http.get(_uri('/api/v1/admin/empresas/$id/'), headers: cabecalhos));
    return EmpresaDetalhe.deJson(_mapa(resposta));
  }

  Future<EmpresaDetalhe> marcarChecklist(int empresaId, String codigo, String status, String observacao) async {
    await _postJson('/api/v1/admin/empresas/$empresaId/checklist/$codigo/', {
      'status': status,
      'observacao': observacao,
    });
    return empresaEquipe(empresaId);
  }

  Future<EmpresaDetalhe> consultarCnpj(int empresaId) async {
    final dados = await _postJson('/api/v1/admin/empresas/$empresaId/consultar-cnpj/', {});
    return EmpresaDetalhe.deJson(dados);
  }

  Future<EmpresaDetalhe> decidirEmpresa(int empresaId, String decisao, String motivo) async {
    final dados = await _postJson('/api/v1/admin/empresas/$empresaId/decidir/', {
      'decisao': decisao,
      'motivo': motivo,
    });
    return EmpresaDetalhe.deJson(dados);
  }

  Future<List<NegociacaoResumo>> negociacoes() async {
    final resposta = await _enviar((cabecalhos) => http.get(_uri('/api/v1/negociacoes/'), headers: cabecalhos));
    return _lista(resposta).map((item) => NegociacaoResumo.deJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<NegociacaoDetalhe> negociacao(int id) async {
    final resposta = await _enviar((cabecalhos) => http.get(_uri('/api/v1/negociacoes/$id/'), headers: cabecalhos));
    return NegociacaoDetalhe.deJson(_mapa(resposta));
  }

  Future<NegociacaoDetalhe> abrirNegociacao(int produtoId, String mensagem) async {
    final dados = await _postJson('/api/v1/negociacoes/', {
      'produto': produtoId,
      if (mensagem.trim().isNotEmpty) 'mensagem': mensagem.trim(),
    });
    return NegociacaoDetalhe.deJson(dados);
  }

  Future<NegociacaoDetalhe> enviarMensagem(int negociacaoId, String texto) async {
    await _postJson('/api/v1/negociacoes/$negociacaoId/mensagens/', {'texto': texto});
    return negociacao(negociacaoId);
  }

  Future<NegociacaoDetalhe> enviarOpcao(int negociacaoId, Map<String, dynamic> corpo) async {
    await _postJson('/api/v1/negociacoes/$negociacaoId/opcoes/', corpo);
    return negociacao(negociacaoId);
  }

  Future<NegociacaoDetalhe> aceitarOpcao(int negociacaoId, int opcaoId) async {
    final dados = await _postJson('/api/v1/negociacoes/$negociacaoId/opcoes/$opcaoId/aceitar/', {});
    return NegociacaoDetalhe.deJson(dados);
  }

  Future<void> encerrarNegociacao(int negociacaoId) async {
    await _postJson('/api/v1/negociacoes/$negociacaoId/encerrar/', {});
  }
}
