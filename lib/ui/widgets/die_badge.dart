import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/character_sheet.dart';

/// A die drawn as a shape (d4 triangle, d6 square, d8 diamond,
/// d10 hexagon, d12 decagon, d20 hexagon) with the number of sides inside.
class DieBadge extends StatelessWidget {
  const DieBadge({super.key, required this.die, this.size = 40, this.onTap});

  final Die die;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DiePainter(die, const Color(0xFFE6E6E6)),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: die == Die.d4 ? size * 0.22 : 0),
            child: Text(
              '${die.sides}',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontVariations: const [FontVariation('wght', 650)],
                fontSize: size * (die.sides >= 10 ? 0.34 : 0.42),
                color: const Color(0xFF2A2A2A),
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      label: die.label,
      button: onTap != null,
      child: onTap == null ? badge : GestureDetector(onTap: onTap, child: badge),
    );
  }
}

class _DiePainter extends CustomPainter {
  _DiePainter(this.die, this.color);

  final Die die;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path();
    switch (die) {
      case Die.d4:
        path.addPolygon(
            [Offset(w / 2, h * 0.04), Offset(w * 0.98, h * 0.92), Offset(w * 0.02, h * 0.92)],
            true);
      case Die.d6:
        path.addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.76, h * 0.76), Radius.circular(w * 0.06)));
      case Die.d8:
        path.addPolygon(
            [Offset(w / 2, 0), Offset(w, h / 2), Offset(w / 2, h), Offset(0, h / 2)], true);
      case Die.d10:
        path.addPolygon(_regular(6, w, h, -math.pi / 2), true);
      case Die.d12:
        path.addPolygon(_regular(10, w, h, -math.pi / 2), true);
      case Die.d20:
        path.addPolygon(_regular(6, w, h, -math.pi / 2), true);
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  List<Offset> _regular(int sides, double w, double h, double start) => [
        for (var i = 0; i < sides; i++)
          Offset(
            w / 2 + w / 2 * math.cos(start + 2 * math.pi * i / sides),
            h / 2 + h / 2 * math.sin(start + 2 * math.pi * i / sides),
          ),
      ];

  @override
  bool shouldRepaint(_DiePainter old) => old.die != die || old.color != color;
}

/// Lets the player pick a die. Returns null if dismissed.
Future<Die?> pickDie(BuildContext context, {required String title, required Die current}) {
  return showDialog<Die>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final d in Die.values)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DieBadge(die: d, size: 44, onTap: () => Navigator.pop(context, d)),
                Text(d.label,
                    style:
                        TextStyle(fontWeight: d == current ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
        ],
      ),
    ),
  );
}
