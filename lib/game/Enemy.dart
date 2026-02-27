// ────────────────────────────────────────────────────────────
// Enemy（普通士兵）
// ────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'Platform.dart';

class Enemy {
  Vector2 position; // 敵人位置
  double width = 30; // 寬度
  double height = 30; // 高度
  double moveSpeed = 50; // 移動速度
  double direction = 1; // 移動方向（1=右，-1=左）
  double shootTimer = 0; // 射擊計時器
  bool isDead = false; // 是否死亡
  double velocityY = 0; // 垂直速度（向下為正）
  static const double _gravity = 600; // 重力加速度

  Enemy({required this.position});

  // 生成時把 y 對齊平台頂面，避免第一幀掉落
  factory Enemy.onPlatform(double x, Platform p) {
    return Enemy(position: Vector2(x, p.top - 15)); // 15 = height/2
  }

  // 更新邏輯，每幀呼叫
  void update(double dt, List<Platform> platforms) {
    if (isDead) return; // 死亡則不更新
    shootTimer += dt; // 射擊計時器累加

    // 重力（velocityY 向下為正）
    velocityY += _gravity * dt;

    // 計算下一幀 y 位置
    double nextY = position.y + velocityY * dt;

    // 平台碰撞檢測
    Platform? standing; // 站立的平台
    double prevBottom = position.y + height / 2; // 當前底部
    double nextBottom = nextY + height / 2; // 下一幀底部

    for (var p in platforms) {
      bool xOverlap =
          position.x + width / 2 > p.left && position.x - width / 2 < p.right;
      // 只要 x 重疊，且這一幀底部越過平台頂面（從上方穿過）
      if (xOverlap &&
          velocityY >= 0 &&
          prevBottom <= p.top + 2 &&
          nextBottom >= p.top) {
        nextY = p.top - height / 2; // 對齊平台頂
        velocityY = 0; // 停止下落
        standing = p; // 記錄站立平台
        break;
      }
    }

    position.y = nextY; // 更新 y 位置

    // 水平移動
    position.x += direction * moveSpeed * dt;

    // 平台邊緣反轉（站在平台上才判斷，不走下去）
    if (standing != null) {
      if (position.x - width / 2 < standing.left) {
        position.x = standing.left + width / 2;
        direction = 1; // 右移
      } else if (position.x + width / 2 > standing.right) {
        position.x = standing.right - width / 2;
        direction = -1; // 左移
      }
    } else {
      // 如果不在平台上，限制邊界反轉
      if (position.x < 15) direction = 1;
      if (position.x > 785) direction = -1;
    }
  }

  // 繪製敵人
  void render(Canvas canvas) {
    if (isDead) return; // 死亡不繪製
    // 身體矩形
    canvas.drawRect(
      Rect.fromLTWH(
        position.x - width / 2,
        position.y - height / 2,
        width,
        height,
      ),
      Paint()..color = Colors.blue,
    );
    // 眼睛
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