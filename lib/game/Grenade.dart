// ────────────────────────────────────────────────────────────
// Grenade
// ────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
class Grenade {
  Vector2 position;
  Vector2 velocity;
  double gravity = 500;
  double radius = 6;
  double explosionRadius = 80;
  double lifetime = 5.0;
  double currentTime = 0;

  Grenade({required this.position, required this.velocity});

  void update(double dt) {
    currentTime += dt;
    velocity.y += gravity * dt;
    position += velocity * dt;
  }

  bool isExpired() => currentTime >= lifetime;

  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(position.x, position.y),
      radius,
      Paint()..color = Colors.black,
    );
    canvas.drawLine(
      Offset(position.x, position.y - radius),
      Offset(position.x, position.y - radius - 5),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 1,
    );
  }
}