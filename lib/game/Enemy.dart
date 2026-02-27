// ────────────────────────────────────────────────────────────
// Enemy（普通士兵）
// ────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'Platform.dart';
class Enemy {
  Vector2 position;
  double width = 30;
  double height = 30;
  double moveSpeed = 50;
  double direction = 1;
  double shootTimer = 0;
  bool isDead = false;
  double velocityY = 0;
  static const double _gravity = 600;

  Enemy({required this.position});

  // 生成時把 y 對齊平台頂面，避免第一幀掉落
  factory Enemy.onPlatform(double x, Platform p) {
    return Enemy(position: Vector2(x, p.top - 15)); // 15 = height/2
  }

  void update(double dt, List<Platform> platforms) {
    if (isDead) return;
    shootTimer += dt;

    // 重力（velocityY 向下為正）
    velocityY += _gravity * dt;

    // 先移動 y
    double nextY = position.y + velocityY * dt;

    // 平台碰撞：掃描「移動前底部」到「移動後底部」之間是否穿越平台頂面
    Platform? standing;
    double prevBottom = position.y + height / 2;
    double nextBottom = nextY + height / 2;

    for (var p in platforms) {
      bool xOverlap =
          position.x + width / 2 > p.left && position.x - width / 2 < p.right;
      // 只要 x 重疊，且這一幀底部越過了平台頂面（從上方穿過）
      if (xOverlap &&
          velocityY >= 0 &&
          prevBottom <= p.top + 2 &&
          nextBottom >= p.top) {
        nextY = p.top - height / 2;
        velocityY = 0;
        standing = p;
        break;
      }
    }

    position.y = nextY;

    // 水平移動
    position.x += direction * moveSpeed * dt;

    // 平台邊緣反轉（站在平台上才判斷，不走下去）
    if (standing != null) {
      if (position.x - width / 2 < standing.left) {
        position.x = standing.left + width / 2;
        direction = 1;
      } else if (position.x + width / 2 > standing.right) {
        position.x = standing.right - width / 2;
        direction = -1;
      }
    } else {
      if (position.x < 15) direction = 1;
      if (position.x > 785) direction = -1;
    }
  }

  void render(Canvas canvas) {
    if (isDead) return;
    canvas.drawRect(
      Rect.fromLTWH(
        position.x - width / 2,
        position.y - height / 2,
        width,
        height,
      ),
      Paint()..color = Colors.blue,
    );
    canvas.drawCircle(
      Offset(position.x - 8, position.y - 8),
      2,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(position.x + 8, position.y - 8),
      2,
      Paint()..color = Colors.white,
    );
  }
}