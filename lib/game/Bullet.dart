// ────────────────────────────────────────────────────────────
// Bullet
// ────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
class Bullet {
  Vector2 position;
  Vector2 velocity;
  bool isPlayerBullet;
  double radius;
  Color? color; // 若指定則使用此色，否則用預設

  Bullet({
    required this.position,
    required this.velocity,
    required this.isPlayerBullet,
    this.radius = 3,
    this.color,
  });

  void update(double dt) => position += velocity * dt;

  void render(Canvas canvas) {
    final c = color ?? (isPlayerBullet ? Colors.yellow : Colors.cyan);
    canvas.drawCircle(
      Offset(position.x, position.y),
      radius,
      Paint()..color = c,
    );
  }
}