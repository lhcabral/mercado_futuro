import 'package:flutter_test/flutter_test.dart';
import 'package:mercado_futuro/core/cores.dart';

void main() {
  test('interpreta a cor hexadecimal da logomarca', () {
    expect(corHex('#003090').toARGB32(), 0xFF003090);
    expect(corHex('#F0B000').toARGB32(), 0xFFF0B000);
  });
}
