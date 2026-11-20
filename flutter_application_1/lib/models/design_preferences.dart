import 'package:flutter/material.dart';

class DesignPreferences {
  const DesignPreferences({
    this.roomType = 'living',
    this.style = 'scandinavian',
    this.palette = 'beige',
    this.budget = 2000000,
    this.prompt = 'Цэлгэр энгийн буйдан, дугуй модон ширээтэй, гэрэлтэй, тухтай зочны өрөө болгоорой. Цонх болон шалыг хэвээр үлдээ.',
    this.seed = 42,
  });
  final String roomType, style, palette, prompt;
  final int budget, seed;
  static const roomTypes = {'living': 'Зочны өрөө', 'bedroom': 'Унтлагын өрөө'};
  static const styles = {
    'scandinavian': 'Скандинав',
    'warm_minimal': 'Дулаан минимал',
    'modern': 'Орчин үеийн',
    'classic': 'Сонгодог',
  };
  static const palettes = {
    'beige': 'Элсэн шаргал',
    'sage': 'Зөөлөн ногоон',
    'brown': 'Дулаан бор',
    'gray': 'Цайвар саарал',
    'forest': 'Ойн ногоон',
  };
  static const paletteColors = {
    'beige': Color(0xFFE7DDCA),
    'sage': Color(0xFFBAC4AC),
    'brown': Color(0xFFD2B298),
    'gray': Color(0xFFD9D9D2),
    'forest': Color(0xFF345346),
  };
  String get summary =>
      '${styles[style]} · ${palettes[palette]} · Төсөв ${formatMoney(budget)} ₮';
  Map<String, dynamic> toJson() => {
    'room_type': roomType,
    'style': style,
    'palette': palette,
    'budget': budget,
    'prompt': prompt,
    'seed': seed,
  };
  factory DesignPreferences.fromJson(Map<String, dynamic> json) =>
      DesignPreferences(
        roomType: json['room_type'] as String? ?? 'living',
        style: json['style'] as String? ?? 'scandinavian',
        palette: json['palette'] as String? ?? 'beige',
        budget: (json['budget'] as num?)?.toInt() ?? 2000000,
        prompt: json['prompt'] as String? ?? '',
        seed: (json['seed'] as num?)?.toInt() ?? 42,
      );
  DesignPreferences copyWith({
    String? roomType,
    String? style,
    String? palette,
    int? budget,
    String? prompt,
    int? seed,
  }) => DesignPreferences(
    roomType: roomType ?? this.roomType,
    style: style ?? this.style,
    palette: palette ?? this.palette,
    budget: budget ?? this.budget,
    prompt: prompt ?? this.prompt,
    seed: seed ?? this.seed,
  );
}

String formatMoney(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]},',
);
