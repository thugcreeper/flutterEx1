// ────────────────────────────────────────────────────────────
// Explosion
// ────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
class Explosion {
  Vector2 position;
  double maxRadius;
  double currentTime = 0.0;
  double duration = 0.6;

  Explosion({required this.position, required this.maxRadius});

  void update(double dt) => currentTime += dt;
  bool get isFinished => currentTime >= duration;

  void render(Canvas canvas) {
    final t = (currentTime / duration).clamp(0.0, 1.0);
    final r = maxRadius * t;
    final alpha = ((1 - t) * 0.9).clamp(0.0, 0.9);
    canvas.drawCircle(
      Offset(position.x, position.y),
      r,
      Paint()..color = Colors.orange.withOpacity(alpha),
    );
    canvas.drawCircle(
      Offset(position.x, position.y),
      r * 0.4,
      Paint()..color = Colors.white.withOpacity((1 - t) * 0.6),
    );
  }
}