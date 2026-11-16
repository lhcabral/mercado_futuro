import 'package:flutter/material.dart';

Color corHex(String? valor, {Color reserva = const Color(0xFF0F6B4C)}) {
  if (valor == null) return reserva;
  var hex = valor.trim().replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return reserva;
  final numero = int.tryParse(hex, radix: 16);
  if (numero == null) return reserva;
  return Color.fromARGB(
    (numero >> 24) & 255,
    (numero >> 16) & 255,
    (numero >> 8) & 255,
    numero & 255,
  );
}

Color clarear(Color cor, [double quantidade = 0.9]) {
  return Color.lerp(cor, Colors.white, quantidade) ?? cor;
}
