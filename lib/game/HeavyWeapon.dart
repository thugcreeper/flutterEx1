// ────────────────────────────────────────────────────────────
// HeavyWeapon（H 道具箱，重機槍）
// ────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
class HeavyWeapon {
  Vector2 position;
  bool collected = false;
  static const double size = 24.0;

  HeavyWeapon({required this.position});

  Rect get rect =>
      Rect.fromLTWH(position.x - size / 2, position.y - size / 2, size, size);

  void render(Canvas canvas) {
    if (collected) return;
    // 外框
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFFFFCC00)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // 字母 H
    final tp = TextPainter(
      text: const TextSpan(
        text: 'H',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(position.x - tp.width / 2, position.y - tp.height / 2),
    );
  }
}