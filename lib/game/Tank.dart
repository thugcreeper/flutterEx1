// ────────────────────────────────────────────────────────────
// Tank（坦克車）
// ────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'Bullet.dart';
import 'Platform.dart';
class Tank {
  Vector2 position;
  double width = 70;
  double height = 40;
  double moveSpeed = 30;
  double direction = -1; // 預設向左（面向玩家）
  double shootTimer = 0;
  double shootInterval = 6.0;
  bool isDead = false;
  int hp = 30;
  int grenadeHits = 0;
  static const int grenadeHitsToKill = 2;
  double velocityY = 0;
  static const double _gravity = 600;
  double hitFlashTimer = 0;

  // 延遲發射佇列：每筆為 (剩餘等待時間, 方向)
  final List<List<double>> _pendingShots = []; // [remainingDelay, dir]

  Tank({required this.position});

  factory Tank.onPlatform(double x, Platform p) {
    return Tank(position: Vector2(x, p.top - 20)); // 20 = height/2
  }

  void update(double dt, List<Platform> platforms) {
    if (isDead) return;
    shootTimer += dt;
    if (hitFlashTimer > 0) hitFlashTimer -= dt;

    // 重力
    velocityY += _gravity * dt;
    position.y += velocityY * dt;

    // 平台碰撞（掃描式，防止高速穿透）
    double prevBottom = position.y + height / 2;
    double nextY = position.y + velocityY * dt;
    double nextBottom = nextY + height / 2;

    for (var p in platforms) {
      bool xOverlap =
          position.x + width / 2 > p.left && position.x - width / 2 < p.right;
      if (xOverlap &&
          velocityY >= 0 &&
          prevBottom <= p.top + 2 &&
          nextBottom >= p.top) {
        nextY = p.top - height / 2;
        velocityY = 0;
        break;
      }
    }
    position.y = nextY;

    // 水平移動
    position.x += direction * moveSpeed * dt;

    // 平台邊緣反轉
    for (var p in platforms) {
      bool xOvlp =
          position.x + width / 2 > p.left && position.x - width / 2 < p.right;
      bool onTop = (position.y + height / 2 - p.top).abs() < 8;
      if (xOvlp && onTop) {
        if (position.x - width / 2 < p.left) {
          position.x = p.left + width / 2;
          direction = 1;
        } else if (position.x + width / 2 > p.right) {
          position.x = p.right - width / 2;
          direction = -1;
        }
        break;
      }
    }
  }

  // 每 frame 呼叫，回傳本幀應發射的砲彈
  List<Bullet> updateShoot(double dt, double playerX) {
    final result = <Bullet>[];

    // 主計時器：到時間就排入 3 顆延遲砲彈
    shootTimer += dt;
    if (shootTimer >= shootInterval) {
      shootTimer = 0;
      double dir = (playerX < position.x) ? -1.0 : 1.0;
      // 3 顆：延遲 0、0.1、0.2 秒
      _pendingShots.add([0.0, dir]);
      _pendingShots.add([0.1, dir]);
      _pendingShots.add([0.2, dir]);
    }

    // 處理延遲佇列
    final toRemove = <List<double>>[];
    for (var shot in _pendingShots) {
      shot[0] -= dt; // 倒計時
      if (shot[0] <= 0) {
        double dir = shot[1];
        double cx = position.x + dir * (width / 2 + 2);
        double cy = position.y;
        // cy: 坦克腳底往上 21px = 蹲下時頭頂剛好通過的高度
        final double bulletCY = position.y + height / 2 - 21;
        result.add(
          Bullet(
            position: Vector2(cx, bulletCY),
            velocity: Vector2(dir * 280, 0),
            isPlayerBullet: false,
            radius: 7,
            color: Colors.red,
          ),
        );
        toRemove.add(shot);
      }
    }
    for (var s in toRemove) _pendingShots.remove(s);

    return result;
  }

  void render(Canvas canvas) {
    if (isDead) return;
    final bodyColor = hitFlashTimer > 0 ? Colors.white : Colors.brown.shade700;

    // 車體
    canvas.drawRect(
      Rect.fromLTWH(
        position.x - width / 2,
        position.y - height / 2,
        width,
        height,
      ),
      Paint()..color = bodyColor,
    );
    // 砲塔
    canvas.drawRect(
      Rect.fromLTWH(position.x - 18, position.y - height / 2 - 16, 36, 18),
      Paint()
        ..color = hitFlashTimer > 0
            ? Colors.white
            : const Color.fromARGB(225, 255, 207, 35),
    );
    // 砲管
    double barrelDir = direction;
    canvas.drawRect(
      Rect.fromLTWH(
        barrelDir > 0 ? position.x + 18 : position.x - 18 - 28,
        position.y - height / 2 - 11,
        28,
        8,
      ),
      Paint()..color = Colors.grey.shade800,
    );
    // 履帶
    canvas.drawRect(
      Rect.fromLTWH(
        position.x - width / 2,
        position.y + height / 2 - 8,
        width,
        8,
      ),
      Paint()..color = Colors.grey.shade600,
    );
  }
}