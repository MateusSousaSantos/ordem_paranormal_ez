import 'package:flutter/material.dart';

/// Colors and text styles of the in-session (landscape) character sheet.
class SheetStyle {
  static const background = Color(0xFF2E2E2E);
  static const panel = Color(0xFF3C3C3C);
  static const sidePanel = Color(0xFF4A4A4A);
  static const ink = Color(0xFFF2F2F2);
  static const box = Color(0xFFD9D9D9);
  static const dark = Color(0xFF2A2A2A);

  static TextStyle fredoka(double size, {double weight = 500, Color color = ink}) => TextStyle(
        fontFamily: 'Fredoka',
        fontSize: size,
        fontVariations: [FontVariation('wght', weight)],
        color: color,
        height: 1.1,
      );

  static TextStyle mono(double size, {bool bold = false, Color color = ink}) => TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: color,
        height: 1.25,
      );
}

/// Renders text where **double asterisks** mark bold parts.
class RichDescription extends StatelessWidget {
  const RichDescription(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    return Text.rich(
      TextSpan(children: [
        for (var i = 0; i < parts.length; i++)
          TextSpan(
            text: parts[i],
            style: i.isOdd ? style.copyWith(fontWeight: FontWeight.w700) : style,
          ),
      ]),
    );
  }
}
