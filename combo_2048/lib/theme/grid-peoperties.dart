import 'package:flutter/material.dart';

const double cornerRadius = 12.0; // leve upgrade no visual
const double moveInterval = .5;

// Paleta nova (substitui os marrons/bege por azul petróleo + acentos neon)
const Color lightBrown = Color(0xFF334155); // células vazias (Slate 700)
const Color darkBrown = Color(0xFF0B1220); // tabuleiro (quase preto azulado)
const Color orange = Color(0xFF22D3EE); // cor de destaque (Cyan 400) -> botões etc.
const Color tan = Color(0xFF0F172A); // fundo da app (Slate 900)
const Color numColor = Color(0xFFE2E8F0); // texto claro (Slate 200)
const Color greyText = Color(0xFFCBD5E1); // texto secundário (Slate 300)

// Cores dos tiles por valor — gradiente “neon” bem diferente do original
const Map<int, Color> numTileColor = {
  2: Color(0xFF0EA5E9), // Sky 500
  4: Color(0xFF38BDF8), // Sky 400
  8: Color(0xFF22D3EE), // Cyan 400
  16: Color(0xFF2DD4BF), // Teal 400
  32: Color(0xFF34D399), // Green 400
  64: Color(0xFFA3E635), // Lime 400
  128: Color(0xFFF59E0B), // Amber 500
  256: Color(0xFFF97316), // Orange 500
  512: Color(0xFFFB7185), // Rose 400
  1024: Color(0xFF8B5CF6), // Violet 500
  2048: Color(0xFFF43F5E), // Rose 500 (final bem diferente do dourado clássico)
};

// Texto dos tiles — tudo branco para máximo contraste com as novas cores
const Map<int, Color> numTextColor = {
  2: Colors.white,
  4: Colors.white,
  8: Colors.white,
  16: Colors.white,
  32: Colors.white,
  64: Colors.white,
  128: Colors.white,
  256: Colors.white,
  512: Colors.white,
  1024: Colors.white,
  2048: Colors.white,
};
