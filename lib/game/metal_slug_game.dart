import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class Bullet {
  Vector2 position;
  Vector2 velocity;
  bool isPlayerBullet;

  Bullet({
    required this.position,
    required this.velocity,
    required this.isPlayerBullet,
  });

  void update(double dt) {
    position += velocity * dt;
  }

  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(position.x, position.y),
      3,
      Paint()..color = isPlayerBullet ? Colors.yellow : Colors.cyan,
    );
  }
}

class Grenade {
  Vector2 position;
  Vector2 velocity;
  double gravity = 500;
  double radius = 6;
  double explosionRadius = 80;
  // 移除 lifetime 自動爆炸機制，改為只靠碰地爆炸
  // 但保留最長存活時間（防止手榴彈飛出畫面外卡住）
  double lifetime = 5.0;
  double currentTime = 0;

  Grenade({required this.position, required this.velocity});

  void update(double dt) {
    currentTime += dt;
    velocity.y += gravity * dt;
    position += velocity * dt;
  }

  /// 超過最長存活時間才自爆（純保險用）
  bool isExpired() {
    return currentTime >= lifetime;
  }

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

class Explosion {
  Vector2 position;
  double maxRadius;
  double currentTime = 0.0;
  double duration = 0.6;

  Explosion({required this.position, required this.maxRadius});

  void update(double dt) {
    currentTime += dt;
  }

  bool get isFinished => currentTime >= duration;

  void render(Canvas canvas) {
    final t = (currentTime / duration).clamp(0.0, 1.0);
    final radius = maxRadius * t;
    final alpha = ((1 - t) * 0.9).clamp(0.0, 0.9);
    final paint = Paint()..color = Colors.orange.withOpacity(alpha);
    canvas.drawCircle(Offset(position.x, position.y), radius, paint);
    final corePaint = Paint()..color = Colors.white.withOpacity((1 - t) * 0.6);
    canvas.drawCircle(Offset(position.x, position.y), radius * 0.4, corePaint);
  }
}

// ── 平台資料結構 ──────────────────────────────────────────────
class Platform {
  final double x;      // 中心 x
  final double y;      // 平台頂面 y（玩家落腳點）
  final double width;

  const Platform({required this.x, required this.y, required this.width});

  double get left  => x - width / 2;
  double get right => x + width / 2;
  double get top   => y;
}

class Enemy {
  Vector2 position;
  double width = 30;
  double height = 30;
  double moveSpeed = 50;
  double direction = 1;
  double shootTimer = 0;
  bool isDead = false;

  Enemy({required this.position});

  void update(double dt) {
    if (isDead) return;
    position.x += direction * moveSpeed * dt;
    shootTimer += dt;
  }

  void render(Canvas canvas) {
    if (!isDead) {
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
}

class MetalSlugGame extends FlameGame with KeyboardEvents {
  static const double gameWidth  = 800;
  static const double gameHeight = 600;

  late Vector2 playerPos;
  double playerWidth  = 30;
  double playerHeight = 40;
  double playerVelocityX = 0;
  double playerVelocityY = 0;
  double moveSpeed  = 150;
  double jumpForce  = 400;
  double gravity    = 600;
  bool isJumping    = false;
  bool isFacingRight = true;
  bool isAiming     = false;
  bool isCrouching  = false;
  double invulnerableTimer = 0.0;

  List<Bullet>    bullets    = [];
  List<Grenade>   grenades   = [];
  List<Explosion> explosions = [];
  List<Enemy>     enemies    = [];

  // ── 新的平台列表（使用 Platform 物件）──────────────────────
  List<Platform> platforms = [];

  int score = 0;
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  int level = 1;
  bool gameOver = false;

  int grenadesAvailable = 10;
  final ValueNotifier<int> grenadesAvailableNotifier = ValueNotifier<int>(10);
  double grenadeCooldownTimer = 0.0;
  final double grenadeCooldown = 0.5;

  TextPaint textPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    playerPos = Vector2(100, 300);
    _setupLevel();
    invulnerableTimer = 1.5;
  }

  void _setupLevel() {
    bullets.clear();
    enemies.clear();
    grenades.clear();
    platforms.clear();

    // ── 重新設計地圖平台 ──────────────────────────────────────
    // 地板（全寬）
    const double groundY   = gameHeight - 40;   // 地板頂面 y
    // 中層平台
    const double mid1Y     = 400;
    const double mid2Y     = 320;
    // 高層平台
    const double high1Y    = 220;
    const double high2Y    = 200;

    platforms = [
      // 地板
      Platform(x: gameWidth / 2, y: groundY,  width: gameWidth),
      // 左側中層
      Platform(x: 180,           y: mid1Y,    width: 200),
      // 右側中層
      Platform(x: 620,           y: mid2Y,    width: 200),
      // 左側高層
      Platform(x: 130,           y: high1Y,   width: 160),
      // 中央高層
      Platform(x: 400,           y: high2Y,   width: 180),
      // 右側高層
      Platform(x: 670,           y: high1Y,   width: 160),
    ];

    // ── 敵人放置在平台頂面（y = platformTop - height/2）────────
    const double eH = 30; // enemy height
    enemies = [
      // 地板敵人
      Enemy(position: Vector2(300,  groundY - eH / 2)),
      Enemy(position: Vector2(550,  groundY - eH / 2)),
      // 中層敵人
      Enemy(position: Vector2(180,  mid1Y   - eH / 2)),
      Enemy(position: Vector2(620,  mid2Y   - eH / 2)),
      // 高層敵人
      Enemy(position: Vector2(400,  high2Y  - eH / 2)),
    ];

    invulnerableTimer    = 1.5;
    grenadesAvailable    = 10;
    grenadesAvailableNotifier.value = grenadesAvailable;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver) return;

    if (invulnerableTimer > 0) {
      invulnerableTimer = (invulnerableTimer - dt).clamp(0, double.infinity);
    }

    // 重力 & 移動
    playerVelocityY += gravity * dt;
    playerPos.x += playerVelocityX * dt;
    playerPos.y += playerVelocityY * dt;

    // 邊界
    if (playerPos.x < 0)                         playerPos.x = 0;
    if (playerPos.x + playerWidth > gameWidth)    playerPos.x = gameWidth - playerWidth;

    // 平台碰撞
    for (var p in platforms) {
      if (_checkPlatformCollision(p)) {
        isJumping       = false;
        playerVelocityY = 0;
        playerPos.y     = p.top - playerHeight;
      }
    }

    if (playerPos.y > gameHeight) gameOver = true;

    // ── 手榴彈更新 ──────────────────────────────────────────
    for (var grenade in List.from(grenades)) {
      grenade.update(dt);

      bool shouldExplode = false;

      // 【修正】只有碰到平台頂面才爆炸
      for (var p in platforms) {
        if (grenade.position.x >= p.left &&
            grenade.position.x <= p.right &&
            grenade.position.y + grenade.radius >= p.top &&
            grenade.position.y < p.top + 20 &&
            grenade.velocity.y >= 0) {   // 確保是向下飛行時才判定碰地
          shouldExplode = true;
          break;
        }
      }

      // 超過最長存活時間（保險）
      if (grenade.isExpired()) shouldExplode = true;

      if (shouldExplode) {
        _triggerGrenadeExplosion(grenade);
      } else if (grenade.position.x < 0 ||
                 grenade.position.x > gameWidth ||
                 grenade.position.y > gameHeight) {
        grenades.remove(grenade);
      } else if (invulnerableTimer <= 0 &&
                 (playerPos - grenade.position).length < 25) {
        gameOver = true;
      }
    }

    // ── 子彈更新 ─────────────────────────────────────────────
    for (var bullet in List.from(bullets)) {
      bullet.update(dt);
      if (bullet.position.x < 0  ||
          bullet.position.x > gameWidth ||
          bullet.position.y < 0  ||
          bullet.position.y > gameHeight) {
        bullets.remove(bullet);
      }
    }

    // ── 爆炸特效更新 ─────────────────────────────────────────
    for (var ex in List.from(explosions)) {
      ex.update(dt);
      if (ex.isFinished) explosions.remove(ex);
    }

    // ── 敵人更新 ─────────────────────────────────────────────
    for (var enemy in List.from(enemies)) {
      enemy.update(dt);

      // 敵人在平台邊緣反彈
      if (enemy.position.x < 20 || enemy.position.x > gameWidth - 20) {
        enemy.direction *= -1;
      }

      // 子彈命中
      for (var bullet in List.from(bullets)) {
        if (bullet.isPlayerBullet &&
            (enemy.position - bullet.position).length < 25) {
          enemy.isDead = true;
          bullets.remove(bullet);
          score += 100;
          scoreNotifier.value = score;
          break;
        }
      }

      // 敵人射擊
      if (enemy.shootTimer > 2.0) {
        double dir = (playerPos.x > enemy.position.x) ? 1 : -1;
        bullets.add(Bullet(
          position: Vector2(enemy.position.x, enemy.position.y),
          velocity: Vector2(dir * 200, 0),
          isPlayerBullet: false,
        ));
        enemy.shootTimer = 0;
      }

      // 敵人體碰玩家
      if (invulnerableTimer <= 0 &&
          (playerPos - enemy.position).length < 30) {
        gameOver = true;
      }
    }

    enemies.removeWhere((e) => e.isDead);
    if (enemies.isEmpty) {
      level++;
      _setupLevel();
    }

    // 敵人子彈碰玩家
    for (var bullet in List.from(bullets)) {
      if (!bullet.isPlayerBullet &&
          invulnerableTimer <= 0 &&
          (playerPos - bullet.position).length < 20) {
        gameOver = true;
      }
    }

    // 手榴彈冷卻
    if (grenadeCooldownTimer > 0) {
      grenadeCooldownTimer = (grenadeCooldownTimer - dt).clamp(0, double.infinity);
    }
  }

  void _triggerGrenadeExplosion(Grenade grenade) {
    explosions.add(Explosion(
      position: Vector2(grenade.position.x, grenade.position.y),
      maxRadius: grenade.explosionRadius,
    ));
    for (var enemy in List.from(enemies)) {
      if ((enemy.position - grenade.position).length < grenade.explosionRadius) {
        enemy.isDead = true;
        score += 100;
        scoreNotifier.value = score;
      }
    }
    grenades.remove(grenade);
  }

  bool _checkPlatformCollision(Platform p) {
    return playerPos.y + playerHeight >= p.top - 5 &&
           playerPos.y + playerHeight <= p.top + 20 &&
           playerPos.x + playerWidth  >  p.left &&
           playerPos.x                < p.right &&
           playerVelocityY > 0;
  }

  void playerShoot() {
    double bulletX = isFacingRight ? playerPos.x + playerWidth : playerPos.x;
    Vector2 vel = isAiming
        ? Vector2(0, -400)
        : Vector2(isFacingRight ? 300 : -300, 0);
    bullets.add(Bullet(
      position: Vector2(bulletX, playerPos.y + playerHeight / 2),
      velocity: vel,
      isPlayerBullet: true,
    ));
  }

  void playerJump() {
    if (!isJumping) {
      playerVelocityY = -jumpForce;
      isJumping = true;
    }
  }

  void throwGrenade() {
    if (grenadeCooldownTimer > 0 || grenadesAvailable <= 0) return;

    double grenadeX = isFacingRight
        ? playerPos.x + playerWidth + 5
        : playerPos.x - 5;
    double velX = isFacingRight ? 300 : -300;
    double velY = isAiming ? -300 : -150;

    grenades.add(Grenade(
      position: Vector2(grenadeX, playerPos.y + playerHeight / 2 - 5),
      velocity: Vector2(velX, velY),
    ));

    grenadesAvailable--;
    grenadesAvailableNotifier.value = grenadesAvailable;
    grenadeCooldownTimer = grenadeCooldown;
  }

  void moveLeft()  { playerVelocityX = -moveSpeed; isFacingRight = false; }
  void moveRight() { playerVelocityX =  moveSpeed; isFacingRight = true;  }
  void stopMoving(){ playerVelocityX = 0; }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if      (event.logicalKey == LogicalKeyboardKey.keyA) moveLeft();
      else if (event.logicalKey == LogicalKeyboardKey.keyD) moveRight();
      else if (event.logicalKey == LogicalKeyboardKey.keyW) isAiming    = true;
      else if (event.logicalKey == LogicalKeyboardKey.keyS) isCrouching = true;
      else if (event.logicalKey == LogicalKeyboardKey.keyK) playerJump();
      else if (event.logicalKey == LogicalKeyboardKey.keyJ) playerShoot();
      else if (event.logicalKey == LogicalKeyboardKey.keyL) throwGrenade();
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.keyD) {
        stopMoving();
      } else if (event.logicalKey == LogicalKeyboardKey.keyW) {
        isAiming    = false;
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        isCrouching = false;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameWidth, gameHeight),
      Paint()..color = Colors.black87,
    );

    // ── 繪製平台 ─────────────────────────────────────────────
    for (var p in platforms) {
      // 平台本體
      canvas.drawRect(
        Rect.fromLTWH(p.left, p.top, p.width, 20),
        Paint()..color = Colors.green,
      );
      // 平台頂部高光
      canvas.drawLine(
        Offset(p.left, p.top),
        Offset(p.right, p.top),
        Paint()..color = Colors.lightGreen..strokeWidth = 2,
      );
    }

    // ── 繪製玩家 ─────────────────────────────────────────────
    double playerRenderHeight = isCrouching ? playerHeight * 0.7 : playerHeight;
    double playerRenderY      = playerPos.y + (isCrouching ? playerHeight * 0.3 : 0);

    canvas.drawRect(
      Rect.fromLTWH(playerPos.x, playerRenderY, playerWidth, playerRenderHeight),
      Paint()..color = Colors.red,
    );

    // 槍
    Paint gunPaint = Paint()..color = Colors.grey;
    double gunY = playerRenderY + playerRenderHeight / 2;
    if (isAiming) {
      double gx = isFacingRight ? playerPos.x + playerWidth : playerPos.x;
      canvas.drawLine(Offset(gx, gunY - 5), Offset(gx, gunY - 20), gunPaint);
    } else {
      if (isFacingRight) {
        canvas.drawLine(Offset(playerPos.x + playerWidth, gunY),
                        Offset(playerPos.x + playerWidth + 10, gunY), gunPaint);
      } else {
        canvas.drawLine(Offset(playerPos.x, gunY),
                        Offset(playerPos.x - 10, gunY), gunPaint);
      }
    }

    for (var enemy   in enemies)    { enemy.render(canvas);    }
    for (var bullet  in bullets)    { bullet.render(canvas);   }
    for (var grenade in grenades)   { grenade.render(canvas);  }
    for (var ex      in explosions) { ex.render(canvas);       }

    // 操作提示
    TextPaint(style: const TextStyle(color: Colors.white, fontSize: 14))
      .render(canvas,
        'A/D:Move | W:Aim | S:Crouch | K:Jump | J:Fire | L:Grenade',
        Vector2(10, gameHeight - 25));

    if (gameOver) {
      TextPaint(style: const TextStyle(
        color: Colors.red, fontSize: 48, fontWeight: FontWeight.bold))
        .render(canvas, 'GAME OVER',
          Vector2(gameWidth / 2 - 120, gameHeight / 2 - 50));
      TextPaint(style: const TextStyle(color: Colors.white, fontSize: 24))
        .render(canvas, 'Final Score: $score',
          Vector2(gameWidth / 2 - 80, gameHeight / 2 + 20));
    }
  }
}