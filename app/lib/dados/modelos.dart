class CoresMarca {
  const CoresMarca({required this.primaria, required this.secundaria, required this.destaque});

  final String primaria;
  final String secundaria;
  final String destaque;

  factory CoresMarca.deJson(Map<String, dynamic>? json) {
    return CoresMarca(
      primaria: json?['primaria'] as String? ?? '#0F6B4C',
      secundaria: json?['secundaria'] as String? ?? '#E8A317',
      destaque: json?['destaque'] as String? ?? '#FFFFFF',
    );
  }

  Map<String, dynamic> paraJson() => {
        'primaria': primaria,
        'secundaria': secundaria,
        'destaque': destaque,
      };
}

class EmpresaResumo {
  const EmpresaResumo({
    required this.id,
    required this.slug,
    required this.nomeFantasia,
    required this.status,
    required this.cidade,
    required this.uf,
    required this.logo,
    required this.cores,
  });

  final int id;
  final String slug;
  final String nomeFantasia;
  final String status;
  final String cidade;
  final String uf;
  final String? logo;
  final CoresMarca cores;

  factory EmpresaResumo.deJson(Map<String, dynamic> json) {
    return EmpresaResumo(
      id: (json['id'] as num).toInt(),
      slug: json['slug'] as String? ?? '',
      nomeFantasia: json['nome_fantasia'] as String? ?? '',
      status: json['status'] as String? ?? '',
      cidade: json['cidade'] as String? ?? '',
      uf: json['uf'] as String? ?? '',
      logo: json['logo'] as String?,
      cores: CoresMarca.deJson(json['cores'] == null ? null : Map<String, dynamic>.from(json['cores'] as Map)),
    );
  }

  Map<String, dynamic> paraJson() => {
        'id': id,
        'slug': slug,
        'nome_fantasia': nomeFantasia,
        'status': status,
        'cidade': cidade,
        'uf': uf,
        'logo': logo,
        'cores': cores.paraJson(),
      };
}

class Usuario {
  const Usuario({
    required this.id,
    required this.email,
    required this.nome,
    required this.papel,
    required this.telefone,
    required this.cidade,
    required this.uf,
    required this.empresa,
  });

  final int id;
  final String email;
  final String nome;
  final String papel;
  final String telefone;
  final String cidade;
  final String uf;
  final EmpresaResumo? empresa;

  factory Usuario.deJson(Map<String, dynamic> json) {
    return Usuario(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      papel: json['papel'] as String? ?? 'cliente',
      telefone: json['telefone'] as String? ?? '',
      cidade: json['cidade'] as String? ?? '',
      uf: json['uf'] as String? ?? '',
      empresa: json['empresa'] == null ? null : EmpresaResumo.deJson(Map<String, dynamic>.from(json['empresa'] as Map)),
    );
  }

  Map<String, dynamic> paraJson() => {
        'id': id,
        'email': email,
        'nome': nome,
        'papel': papel,
        'telefone': telefone,
        'cidade': cidade,
        'uf': uf,
        'empresa': empresa?.paraJson(),
      };
}

class Categoria {
  const Categoria({required this.id, required this.nome, required this.slug});

  final int id;
  final String nome;
  final String slug;

  factory Categoria.deJson(Map<String, dynamic> json) {
    return Categoria(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

class ProdutoCard {
  const ProdutoCard({
    required this.id,
    required this.titulo,
    required this.slug,
    required this.preco,
    required this.condicao,
    required this.cidade,
    required this.uf,
    required this.capa,
    required this.categoriaNome,
    required this.fornecedorNome,
    required this.fornecedorSlug,
    required this.favorito,
    required this.status,
  });

  final int id;
  final String titulo;
  final String slug;
  final String preco;
  final String condicao;
  final String cidade;
  final String uf;
  final String? capa;
  final String categoriaNome;
  final String fornecedorNome;
  final String fornecedorSlug;
  final bool favorito;
  final String status;

  factory ProdutoCard.deJson(Map<String, dynamic> json) {
    return ProdutoCard(
      id: (json['id'] as num).toInt(),
      titulo: json['titulo'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      preco: '${json['preco']}',
      condicao: json['condicao'] as String? ?? 'novo',
      cidade: json['cidade'] as String? ?? '',
      uf: json['uf'] as String? ?? '',
      capa: json['capa'] as String?,
      categoriaNome: json['categoria_nome'] as String? ?? '',
      fornecedorNome: json['fornecedor_nome'] as String? ?? '',
      fornecedorSlug: json['fornecedor_slug'] as String? ?? '',
      favorito: json['favorito'] == true,
      status: json['status'] as String? ?? 'publicado',
    );
  }
}

class ImagemProduto {
  const ImagemProduto({required this.id, required this.url});

  final int id;
  final String url;

  factory ImagemProduto.deJson(Map<String, dynamic> json) {
    return ImagemProduto(id: (json['id'] as num).toInt(), url: json['url'] as String? ?? '');
  }
}

class ProdutoDetalhe {
  const ProdutoDetalhe({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.preco,
    required this.condicao,
    required this.estoque,
    required this.cidade,
    required this.uf,
    required this.status,
    required this.categoriaId,
    required this.categoriaNome,
    required this.imagens,
    required this.fornecedor,
    required this.favorito,
  });

  final int id;
  final String titulo;
  final String descricao;
  final String preco;
  final String condicao;
  final int estoque;
  final String cidade;
  final String uf;
  final String status;
  final int? categoriaId;
  final String categoriaNome;
  final List<ImagemProduto> imagens;
  final EmpresaResumo fornecedor;
  final bool favorito;

  factory ProdutoDetalhe.deJson(Map<String, dynamic> json) {
    return ProdutoDetalhe(
      id: (json['id'] as num).toInt(),
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      preco: '${json['preco']}',
      condicao: json['condicao'] as String? ?? 'novo',
      estoque: (json['estoque'] as num?)?.toInt() ?? 0,
      cidade: json['cidade'] as String? ?? '',
      uf: json['uf'] as String? ?? '',
      status: json['status'] as String? ?? 'rascunho',
      categoriaId: (json['categoria'] as num?)?.toInt(),
      categoriaNome: json['categoria_nome'] as String? ?? '',
      imagens: (json['imagens'] as List? ?? []).map((item) => ImagemProduto.deJson(Map<String, dynamic>.from(item as Map))).toList(),
      fornecedor: EmpresaResumo.deJson(Map<String, dynamic>.from(json['fornecedor'] as Map)),
      favorito: json['favorito'] == true,
    );
  }
}

class PaginaProdutos {
  const PaginaProdutos({required this.total, required this.temProxima, required this.itens});

  final int total;
  final bool temProxima;
  final List<ProdutoCard> itens;

  factory PaginaProdutos.deJson(Map<String, dynamic> json) {
    return PaginaProdutos(
      total: (json['count'] as num?)?.toInt() ?? 0,
      temProxima: json['next'] != null,
      itens: (json['results'] as List? ?? []).map((item) => ProdutoCard.deJson(Map<String, dynamic>.from(item as Map))).toList(),
    );
  }
}

class ItemChecklist {
  const ItemChecklist({
    required this.codigo,
    required this.titulo,
    required this.status,
    required this.observacao,
    required this.evidencia,
    required this.marcadoEm,
  });

  final String codigo;
  final String titulo;
  final String status;
  final String observacao;
  final String evidencia;
  final String marcadoEm;

  factory ItemChecklist.deJson(Map<String, dynamic> json) {
    return ItemChecklist(
      codigo: json['codigo'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      status: json['status'] as String? ?? 'pendente',
      observacao: json['observacao'] as String? ?? '',
      evidencia: json['evidencia'] as String? ?? '',
      marcadoEm: json['marcado_em'] as String? ?? '',
    );
  }
}

class DocumentoEmpresa {
  const DocumentoEmpresa({required this.id, required this.tipo, required this.nome, required this.arquivo});

  final int id;
  final String tipo;
  final String nome;
  final String arquivo;

  factory DocumentoEmpresa.deJson(Map<String, dynamic> json) {
    return DocumentoEmpresa(
      id: (json['id'] as num).toInt(),
      tipo: json['tipo'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      arquivo: json['arquivo'] as String? ?? '',
    );
  }
}

class EmpresaDetalhe {
  const EmpresaDetalhe({
    required this.id,
    required this.razaoSocial,
    required this.nomeFantasia,
    required this.slug,
    required this.cnpj,
    required this.cnpjFormatado,
    required this.telefone,
    required this.email,
    required this.descricao,
    required this.endereco,
    required this.cidade,
    required this.uf,
    required this.logo,
    required this.cores,
    required this.status,
    required this.motivoRecusa,
    required this.checklist,
    required this.documentos,
  });

  final int id;
  final String razaoSocial;
  final String nomeFantasia;
  final String slug;
  final String cnpj;
  final String cnpjFormatado;
  final String telefone;
  final String email;
  final String descricao;
  final String endereco;
  final String cidade;
  final String uf;
  final String? logo;
  final CoresMarca cores;
  final String status;
  final String motivoRecusa;
  final List<ItemChecklist> checklist;
  final List<DocumentoEmpresa> documentos;

  factory EmpresaDetalhe.deJson(Map<String, dynamic> json) {
    return EmpresaDetalhe(
      id: (json['id'] as num).toInt(),
      razaoSocial: json['razao_social'] as String? ?? '',
      nomeFantasia: json['nome_fantasia'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      cnpj: json['cnpj'] as String? ?? '',
      cnpjFormatado: json['cnpj_formatado'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      endereco: json['endereco'] as String? ?? '',
      cidade: json['cidade'] as String? ?? '',
      uf: json['uf'] as String? ?? '',
      logo: json['logo'] as String?,
      cores: CoresMarca.deJson(json['cores'] == null ? null : Map<String, dynamic>.from(json['cores'] as Map)),
      status: json['status'] as String? ?? 'rascunho',
      motivoRecusa: json['motivo_recusa'] as String? ?? '',
      checklist: (json['checklist'] as List? ?? []).map((item) => ItemChecklist.deJson(Map<String, dynamic>.from(item as Map))).toList(),
      documentos: (json['documentos'] as List? ?? []).map((item) => DocumentoEmpresa.deJson(Map<String, dynamic>.from(item as Map))).toList(),
    );
  }
}

class PaginaFornecedor {
  const PaginaFornecedor({
    required this.id,
    required this.nomeFantasia,
    required this.slug,
    required this.descricao,
    required this.cidade,
    required this.uf,
    required this.telefone,
    required this.logo,
    required this.cores,
    required this.produtos,
  });

  final int id;
  final String nomeFantasia;
  final String slug;
  final String descricao;
  final String cidade;
  final String uf;
  final String telefone;
  final String? logo;
  final CoresMarca cores;
  final List<ProdutoCard> produtos;

  factory PaginaFornecedor.deJson(Map<String, dynamic> json) {
    return PaginaFornecedor(
      id: (json['id'] as num).toInt(),
      nomeFantasia: json['nome_fantasia'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      cidade: json['cidade'] as String? ?? '',
      uf: json['uf'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      logo: json['logo'] as String?,
      cores: CoresMarca.deJson(Map<String, dynamic>.from(json['cores'] as Map)),
      produtos: (json['produtos'] as List? ?? []).map((item) => ProdutoCard.deJson(Map<String, dynamic>.from(item as Map))).toList(),
    );
  }
}

class NegociacaoResumo {
  const NegociacaoResumo({
    required this.id,
    required this.status,
    required this.produtoId,
    required this.produtoTitulo,
    required this.fornecedorNome,
    required this.clienteNome,
    required this.atualizadaEm,
  });

  final int id;
  final String status;
  final int produtoId;
  final String produtoTitulo;
  final String fornecedorNome;
  final String clienteNome;
  final String atualizadaEm;

  factory NegociacaoResumo.deJson(Map<String, dynamic> json) {
    return NegociacaoResumo(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String? ?? '',
      produtoId: (json['produto_id'] as num).toInt(),
      produtoTitulo: json['produto_titulo'] as String? ?? '',
      fornecedorNome: json['fornecedor_nome'] as String? ?? '',
      clienteNome: json['cliente_nome'] as String? ?? '',
      atualizadaEm: json['atualizada_em'] as String? ?? '',
    );
  }
}

class MensagemNegociacao {
  const MensagemNegociacao({
    required this.id,
    required this.autorNome,
    required this.texto,
    required this.criadaEm,
    required this.meu,
  });

  final int id;
  final String autorNome;
  final String texto;
  final String criadaEm;
  final bool meu;

  factory MensagemNegociacao.deJson(Map<String, dynamic> json) {
    return MensagemNegociacao(
      id: (json['id'] as num).toInt(),
      autorNome: json['autor_nome'] as String? ?? '',
      texto: json['texto'] as String? ?? '',
      criadaEm: json['criada_em'] as String? ?? '',
      meu: json['meu'] == true,
    );
  }
}

class OpcaoNegociacao {
  const OpcaoNegociacao({
    required this.id,
    required this.preco,
    required this.prazoDias,
    required this.tipoEntrega,
    required this.formasPagamento,
    required this.observacao,
    required this.escolhida,
  });

  final int id;
  final String preco;
  final int? prazoDias;
  final String tipoEntrega;
  final List<String> formasPagamento;
  final String observacao;
  final bool escolhida;

  factory OpcaoNegociacao.deJson(Map<String, dynamic> json) {
    return OpcaoNegociacao(
      id: (json['id'] as num).toInt(),
      preco: '${json['preco']}',
      prazoDias: (json['prazo_dias'] as num?)?.toInt(),
      tipoEntrega: json['tipo_entrega'] as String? ?? '',
      formasPagamento: (json['formas_pagamento'] as List? ?? []).map((item) => '$item').toList(),
      observacao: json['observacao'] as String? ?? '',
      escolhida: json['escolhida'] == true,
    );
  }
}

class NegociacaoDetalhe {
  const NegociacaoDetalhe({
    required this.id,
    required this.status,
    required this.produtoId,
    required this.produtoTitulo,
    required this.fornecedorNome,
    required this.fornecedorTelefone,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.clienteCidade,
    required this.mensagens,
    required this.opcoes,
    required this.podeEnviarOpcao,
    required this.podeAceitar,
    required this.podeMensagem,
  });

  final int id;
  final String status;
  final int produtoId;
  final String produtoTitulo;
  final String fornecedorNome;
  final String fornecedorTelefone;
  final String clienteNome;
  final String clienteTelefone;
  final String clienteCidade;
  final List<MensagemNegociacao> mensagens;
  final List<OpcaoNegociacao> opcoes;
  final bool podeEnviarOpcao;
  final bool podeAceitar;
  final bool podeMensagem;

  factory NegociacaoDetalhe.deJson(Map<String, dynamic> json) {
    return NegociacaoDetalhe(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String? ?? '',
      produtoId: (json['produto_id'] as num).toInt(),
      produtoTitulo: json['produto_titulo'] as String? ?? '',
      fornecedorNome: json['fornecedor_nome'] as String? ?? '',
      fornecedorTelefone: json['fornecedor_telefone'] as String? ?? '',
      clienteNome: json['cliente_nome'] as String? ?? '',
      clienteTelefone: json['cliente_telefone'] as String? ?? '',
      clienteCidade: json['cliente_cidade'] as String? ?? '',
      mensagens: (json['mensagens'] as List? ?? []).map((item) => MensagemNegociacao.deJson(Map<String, dynamic>.from(item as Map))).toList(),
      opcoes: (json['opcoes'] as List? ?? []).map((item) => OpcaoNegociacao.deJson(Map<String, dynamic>.from(item as Map))).toList(),
      podeEnviarOpcao: json['pode_enviar_opcao'] == true,
      podeAceitar: json['pode_aceitar'] == true,
      podeMensagem: json['pode_mensagem'] == true,
    );
  }
}
