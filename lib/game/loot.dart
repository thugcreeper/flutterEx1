/*這個檔案紀錄遊戲中的戰利品*/ 
import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum LootType { diamond, fruit, pig, poop }

class Loot {
  Vector2 position;
  final LootType type;
  late int value;
  late Color color;

  Loot({required this.position, required this.type}) {
    switch (type) {
      case LootType.diamond:
        value = 100;
        color = Colors.cyanAccent;
        break;
      case LootType.fruit:
        value = 20;
        color = Colors.redAccent;
        break;
      case LootType.pig:
        value = 50;
        color = Colors.pinkAccent;
        break;
      case LootType.poop:
        value = -10;
        color = const Color(0xFF795548);
        break;
    }
  }

  static Loot spawnAt(Vector2 pos) {
    // 隨機挑選一種戰利品
    final rand = DateTime.now().millisecondsSinceEpoch;
    final idx = rand % LootType.values.length;
    return Loot(position: pos.clone(), type: LootType.values[idx]);
  }

  void render(Canvas canvas) {
    final Paint paint = Paint()..color = color;
    const double size = 12.0;
    switch (type) {
      case LootType.diamond:
        // 畫菱形
        final path = Path();
        const double size = 12.0;
        // 菱形
        path.moveTo(position.x, position.y - size);
        path.lineTo(position.x + size, position.y);
        path.lineTo(position.x, position.y + size);
        path.lineTo(position.x - size, position.y);
        path.close();
        // 漸層閃亮
        final gradient = RadialGradient(
          colors: [Colors.cyanAccent.shade100, Colors.cyanAccent.shade700],
          center: Alignment.center,
          radius: 0.6,
        );
        final rect = Rect.fromCenter(center: Offset(position.x, position.y), width: size*2, height: size*2);
        paint.shader = gradient.createShader(rect);
        canvas.drawPath(path, paint);
        break;
      case LootType.fruit:
        const double size = 12.0;
        // 水果主體
        paint.color = Colors.redAccent;
        canvas.drawCircle(Offset(position.x, position.y), size, paint);
        // 葉子
        paint.color = Colors.green;
        final leafPath = Path()
          ..moveTo(position.x, position.y - size)
          ..lineTo(position.x + 4, position.y - size - 6)
          ..lineTo(position.x - 4, position.y - size - 6)
          ..close();
        canvas.drawPath(leafPath, paint);
        // 加一點高光
        paint.color = Colors.white.withOpacity(0.6);
        canvas.drawCircle(Offset(position.x - 4, position.y - 4), 3, paint);
        break;
      case LootType.pig:
        const double size = 12.0;
        paint.color = Colors.pinkAccent;
        canvas.drawCircle(Offset(position.x, position.y), size, paint);
        // 兩個小耳朵
        paint.color = Colors.pink.shade200;
        canvas.drawCircle(Offset(position.x - 7, position.y - 7), 4, paint);
        canvas.drawCircle(Offset(position.x + 7, position.y - 7), 4, paint);
        // 眼睛
        paint.color = Colors.black;
        canvas.drawCircle(Offset(position.x - 4, position.y - 2), 2, paint);
        canvas.drawCircle(Offset(position.x + 4, position.y - 2), 2, paint);
        // 鼻子
        paint.color = Colors.pink.shade400;
        canvas.drawOval(Rect.fromCenter(center: Offset(position.x, position.y + 3), width: 6, height: 4), paint);
        break;
      case LootType.poop:
        const double size = 12.0;
        final p = Path();
        double r = size / 2;
        p.moveTo(position.x, position.y);
        for (double t = 0; t < 6.28; t += 0.3) {
          final dx = r * math.cos(t);
          final dy = r * math.sin(t);
          p.lineTo(position.x + dx, position.y + dy);
          r -= 0.4;
        }
        paint.color = Color(0xFF6D4C41);
        canvas.drawPath(p, paint);
        // 加個小亮點
        paint.color = Colors.brown.shade300.withOpacity(0.5);
        canvas.drawCircle(Offset(position.x - 2, position.y - 2), 2, paint);
        break;
    }
  }
}
