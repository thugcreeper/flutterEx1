// ────────────────────────────────────────────────────────────
// Boss（魔王）- 簡化版，繼承 Enemy 並擴充血條與更大體型
// ────────────────────────────────────────────────────────────
import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'Enemy.dart';
import 'Bullet.dart';
import 'Platform.dart';
class Boss extends Enemy {
  int health;
  final int maxHealth;
  double bossWidth = 100;
  double bossHeight = 80;
  double bossShootTimer = 0;
  int attackPhase = 0; // 0=單發, 1=速射, 2=範圍砲擊

  Boss({required Vector2 position, this.health = 50})
      : maxHealth = health,
        super(position: position) {
    // 將 Enemy 預設尺寸擴大以符合 boss
    width = bossWidth;
    height = bossHeight;
    moveSpeed = 40;
  }

  @override
  void update(double dt, List<Platform> platforms) {
    if (isDead) return;
    // 使用父類別處理重力與平台碰撞
    super.update(dt, platforms);
    // 簡單左右巡邏（遇邊界會由父類調整 direction）
    position.x += direction * moveSpeed * dt;
  }

  // Boss 的攻擊方法：回傳發射的子彈
  List<Bullet> getBossBullets(double dt, double playerX) {
    final result = <Bullet>[];
    bossShootTimer += dt;

    // 根據生命值選擇攻擊方式
    if (health > maxHealth * 0.66) {
      // 上半血 - 單發大子彈
      attackPhase = 0;
      if (bossShootTimer >= 2.0) {
        bossShootTimer = 0;
        final double targetX = playerX;
        final double dx = targetX - position.x;
        final double distSq = dx * dx;
        final double vel = 200.0;
        final double vx = dx.abs() < 1 ? vel : (dx > 0 ? vel : -vel);
        result.add(
          Bullet(
            position: Vector2(position.x, position.y),
            velocity: Vector2(vx, 0),
            isPlayerBullet: false,
            radius: 12, // 大子彈
            color: const Color(0xFFFF6B00), // 深橙色
          ),
        );
      }
    } else if (health > maxHealth * 0.33) {
      // 中血 - 速射
      attackPhase = 1;
      if (bossShootTimer >= 0.4) {
        bossShootTimer = 0;
        final double targetX = playerX;
        final double dx = targetX - position.x;
        final double vel = 250.0;
        final double vx = dx.abs() < 1 ? vel : (dx > 0 ? vel : -vel);
        result.add(
          Bullet(
            position: Vector2(position.x, position.y - 15),
            velocity: Vector2(vx, 0),
            isPlayerBullet: false,
            radius: 8,
            color: const Color(0xFFFF4444), // 紅色
          ),
        );
      }
    } else {
      // 低血 - 範圍砲擊（6個方向）
      attackPhase = 2;
      if (bossShootTimer >= 1.2) {
        bossShootTimer = 0;
        const double vel = 200.0;
        final List<double> angles = [0, 60, 120, 180, 240, 300];
        for (final angle in angles) {
          final double rad = angle * 3.14159 / 180;
          final double vx = vel * (angle == 0 || angle == 360 ? 1 : (angle == 180 ? -1 : math.cos(rad)));
          final double vy = vel * math.sin(rad);
          result.add(
            Bullet(
              position: Vector2(position.x, position.y),
              velocity: Vector2(vx, vy),
              isPlayerBullet: false,
              radius: 10,
              color: const Color(0xFFFFD700), // 金黃色
            ),
          );
        }
      }
    }

    return result;
  }

  @override
  void render(Canvas canvas) {
    if (isDead) return;

    // ── 身體：月亮形狀（半圓＋圓形組合） ──
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.purple.shade400, Colors.purple.shade900],
        center: const Alignment(-0.2, -0.2),
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: Offset(position.x, position.y), radius: bossWidth / 2))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(position.x, position.y), bossWidth / 2, bodyPaint);

    // ── 眼睛：黑眼珠＋白眼圈（向上看） ──
    final eyeWhite = Paint()..color = Colors.white;
    final eyePupilL = Paint()..color = const Color.fromARGB(255, 61, 21, 241);//左瞳孔
    final eyePupilR = Paint()..color = const Color.fromARGB(255, 255, 24, 24);//右瞳孔
    final eyeOffsetX = bossWidth / 4;
    final eyeOffsetY = -bossHeight / 6;

    // 左眼
    canvas.drawCircle(Offset(position.x - eyeOffsetX, position.y + eyeOffsetY), 10, eyeWhite);
    canvas.drawCircle(Offset(position.x - eyeOffsetX, position.y + eyeOffsetY), 5, eyePupilL);

    // 右眼
    canvas.drawCircle(Offset(position.x + eyeOffsetX, position.y + eyeOffsetY), 10, eyeWhite);
    canvas.drawCircle(Offset(position.x + eyeOffsetX, position.y + eyeOffsetY), 5, eyePupilR);

    // ── 嘴巴：向下弧線（生氣） ──
    final mouthPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final mouthRect = Rect.fromCenter(
        center: Offset(position.x, position.y + bossHeight / 6),
        width: bossWidth / 2,
        height: 12);
    canvas.drawArc(mouthRect, 3.14 +0.4, 2.34, false, mouthPaint);

    // ── 手（簡單兩條曲線） ──
    final handPaint = Paint()
      ..color = Colors.purple.shade700
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    // 左手
    canvas.drawLine(
        Offset(position.x - bossWidth / 2, position.y - 10),
        Offset(position.x - bossWidth / 2 - 20, position.y + 20),
        handPaint);
    // 右手
    canvas.drawLine(
        Offset(position.x + bossWidth / 2, position.y - 10),
        Offset(position.x + bossWidth / 2 + 20, position.y + 20),
        handPaint);

    // ── 腳（兩條短線） ──
    // 左腳
    canvas.drawLine(
        Offset(position.x - bossWidth / 4, position.y + bossHeight / 2),
        Offset(position.x - bossWidth / 4, position.y + bossHeight / 2 + 20),
        handPaint);
    // 右腳
    canvas.drawLine(
        Offset(position.x + bossWidth / 4, position.y + bossHeight / 2),
        Offset(position.x + bossWidth / 4, position.y + bossHeight / 2 + 20),
        handPaint);
  }
}