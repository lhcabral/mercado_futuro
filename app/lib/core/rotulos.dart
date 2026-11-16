const entregas = {
  'retirada': 'Retirada',
  'envio': 'Envio',
  'combinar': 'A combinar',
};

const pagamentos = {
  'pix': 'PIX',
  'boleto': 'Boleto',
  'cartao': 'Cartão',
  'dinheiro': 'Dinheiro',
};

const condicoes = {
  'novo': 'Novo',
  'usado': 'Usado',
};

const statusEmpresa = {
  'rascunho': 'Rascunho',
  'em_analise': 'Em análise',
  'aprovada': 'Aprovada',
  'recusada': 'Recusada',
  'suspensa': 'Suspensa',
};

const statusProduto = {
  'rascunho': 'Rascunho',
  'publicado': 'Publicado',
  'pausado': 'Pausado',
};

const statusNegociacao = {
  'aberta': 'Aberta',
  'opcoes_enviadas': 'Opções enviadas',
  'aceita': 'Aceita',
  'recusada': 'Recusada',
  'encerrada': 'Encerrada',
};

const statusChecklist = {
  'pendente': 'Pendente',
  'ok': 'Conferido',
  'falha': 'Divergente',
  'nao_se_aplica': 'Não se aplica',
};

const tiposDocumento = {
  'contrato_social': 'Contrato social ou equivalente',
  'identidade': 'Documento do responsável',
  'outro': 'Outro',
};

const ufs = [
  'AC',
  'AL',
  'AP',
  'AM',
  'BA',
  'CE',
  'DF',
  'ES',
  'GO',
  'MA',
  'MT',
  'MS',
  'MG',
  'PA',
  'PB',
  'PR',
  'PE',
  'PI',
  'RJ',
  'RN',
  'RS',
  'RO',
  'RR',
  'SC',
  'SP',
  'SE',
  'TO',
];

String rotulo(Map<String, String> tabela, String? chave) {
  if (chave == null || chave.isEmpty) return '';
  return tabela[chave] ?? chave;
}

String moeda(dynamic valor) {
  final numero = double.tryParse('$valor') ?? 0;
  final negativo = numero < 0;
  final partes = numero.abs().toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  return '${negativo ? '-' : ''}R\$ $inteiro,${partes[1]}';
}

String dataHora(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final data = DateTime.tryParse(iso)?.toLocal();
  if (data == null) return '';
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(data.day)}/${dois(data.month)}/${data.year} ${dois(data.hour)}:${dois(data.minute)}';
}
