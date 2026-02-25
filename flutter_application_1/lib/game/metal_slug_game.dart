import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class Bullet {
  Vector2 position;
  Vector2 velocity; // 改为 Vector2 支持 x, y 方向
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
  double lifetime = 3.0;
  double currentTime = 0;

  Grenade({
    required this.position,
    required this.velocity,
  });

  void update(double dt) {
    currentTime += dt;
    velocity.y += gravity * dt;
    position += velocity * dt;
  }

  bool isExploding(double currentGameTime) {
    return currentTime >= lifetime;
  }

  void render(Canvas canvas) {
    // 繪製手榴彈（黑色圓形）
    canvas.drawCircle(
      Offset(position.x, position.y),
      radius,
      Paint()..color = Colors.black,
    );
    // 繪製引信
    canvas.drawLine(
      Offset(position.x, position.y - radius),
      Offset(position.x, position.y - radius - 5),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 1,
    );
  }
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
        Rect.fromLTWH(position.x - width / 2, position.y - height / 2, width, height),
        Paint()..color = Colors.blue,
      );
      // Draw eyes
      canvas.drawCircle(Offset(position.x - 8, position.y - 8), 2, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(position.x + 8, position.y - 8), 2, Paint()..color = Colors.white);
    }
  }
}

class MetalSlugGame extends FlameGame with KeyboardEvents {
  static const double gameWidth = 800;
  static const double gameHeight = 600;

  late Vector2 playerPos;
  double playerWidth = 30;
  double playerHeight = 40;
  double playerVelocityX = 0;
  double playerVelocityY = 0;
  double moveSpeed = 150;
  double jumpForce = 300;
  double gravity = 500;
  bool isJumping = false;
  bool isFacingRight = true;
  bool isAiming = false; // 向上瞄準
  bool isCrouching = false; // 蹲下
  double invulnerableTimer = 0.0; // 無敵計時（秒），剛開始或重置時短暫無敵

  List<Bullet> bullets = [];
  List<Grenade> grenades = []; // 手榴彈
  List<Enemy> enemies = [];
  List<Vector2> platforms = [];

  int score = 0;
  int level = 1;
  bool gameOver = false;

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
    // 初始短暫無敵，避免剛進場被子彈秒殺
    invulnerableTimer = 1.5;
  }

  void _setupLevel() {
    bullets.clear();
    enemies.clear();
    platforms.clear();

    // Create platforms
    platforms = [
      Vector2(gameWidth / 2, gameHeight - 30), // Ground
      Vector2(300, 400),
      Vector2(600, 300),
    ];

    // Create enemies
    enemies = [
      Enemy(position: Vector2(400, 150)),
      Enemy(position: Vector2(500, 150)),
      Enemy(position: Vector2(600, 150)),
    ];
    // 每次建立關卡給予短暫無敵（玩家剛重新出現或關卡開始）
    invulnerableTimer = 1.5;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameOver) return;

    // 更新無敵計時
    if (invulnerableTimer > 0) {
      invulnerableTimer -= dt;
      if (invulnerableTimer < 0) invulnerableTimer = 0;
    }

    // Apply gravity
    playerVelocityY += gravity * dt;

    // Update player position
    playerPos.x += playerVelocityX * dt;
    playerPos.y += playerVelocityY * dt;

    // Boundary check
    if (playerPos.x < 0) playerPos.x = 0;
    if (playerPos.x + playerWidth > gameWidth) {
      playerPos.x = gameWidth - playerWidth;
    }

    // Platform collision
    for (var platform in platforms) {
      if (_checkPlatformCollision(platform)) {
        isJumping = false;
        playerVelocityY = 0;
        playerPos.y = platform.y - playerHeight;
      }
    }

    // Death boundary
    if (playerPos.y > gameHeight) {
      gameOver = true;
    }

    // Update grenades
    for (var grenade in List.from(grenades)) {
      grenade.update(dt);

      // 檢查爆炸
      if (grenade.isExploding(dt)) {
        // 爆炸傷害敵人
        for (var enemy in List.from(enemies)) {
          if ((enemy.position - grenade.position).length < grenade.explosionRadius) {
            enemy.isDead = true;
            score += 100;
          }
        }
        grenades.remove(grenade);
      }
      // 邊界外移除
      else if (grenade.position.x < 0 ||
          grenade.position.x > gameWidth ||
          grenade.position.y > gameHeight) {
        grenades.remove(grenade);
      }
      // 檢查與玩家碰撞（敵人手榴彈），若在無敵期間則忽略
      else if ((playerPos - grenade.position).length < 25) {
        if (invulnerableTimer <= 0) {
          gameOver = true;
        }
      }
    }

    // Update bullets
    for (var bullet in List.from(bullets)) {
      bullet.update(dt);
      if (bullet.position.x < 0 || 
          bullet.position.x > gameWidth ||
          bullet.position.y < 0 ||
          bullet.position.y > gameHeight) {
        bullets.remove(bullet);
      }
    }

    // Update enemies
    for (var enemy in List.from(enemies)) {
      enemy.update(dt);

      // Bounce at edges
      if (enemy.position.x < 20 || enemy.position.x > gameWidth - 20) {
        enemy.direction *= -1;
      }

      // Check collision with bullets
      for (var bullet in List.from(bullets)) {
        if (bullet.isPlayerBullet &&
            (enemy.position - bullet.position).length < 25) {
          enemy.isDead = true;
          bullets.remove(bullet);
          score += 100;
          break;
        }
      }

      // Shoot
      if (enemy.shootTimer > 2.0) {
        double direction = (playerPos.x > enemy.position.x) ? 1 : -1;
        bullets.add(Bullet(
          position: Vector2(enemy.position.x, enemy.position.y),
          velocity: Vector2(direction * 200, 0),
          isPlayerBullet: false,
        ));
        enemy.shootTimer = 0;
      }

      // Check collision with player
      if ((playerPos - enemy.position).length < 30) {
        if (invulnerableTimer <= 0) {
          gameOver = true;
        }
      }
    }

    enemies.removeWhere((e) => e.isDead);

    if (enemies.isEmpty) {
      level++;
      _setupLevel();
    }

    // Check enemy bullet collision with player
    for (var bullet in List.from(bullets)) {
      if (!bullet.isPlayerBullet &&
          (playerPos - bullet.position).length < 20) {
        if (invulnerableTimer <= 0) {
          gameOver = true;
        }
      }
    }
  }

  bool _checkPlatformCollision(Vector2 platform) {
    double platformWidth = 200;
    if (platform.x == gameWidth / 2) {
      platformWidth = gameWidth;
    }

    return playerPos.y + playerHeight >= platform.y - 15 &&
        playerPos.y + playerHeight <= platform.y + 15 &&
        playerPos.x + playerWidth > platform.x - platformWidth / 2 &&
        playerPos.x < platform.x + platformWidth / 2 &&
        playerVelocityY > 0;
  }

  void playerShoot() {
    double bulletX = isFacingRight
        ? playerPos.x + playerWidth
        : playerPos.x;
    
    Vector2 bulletVelocity;
    if (isAiming) {
      // 向上射击
      bulletVelocity = Vector2(0, -400);
    } else {
      // 水平射击
      bulletVelocity = Vector2(isFacingRight ? 300 : -300, 0);
    }

    bullets.add(Bullet(
      position: Vector2(bulletX, playerPos.y + playerHeight / 2),
      velocity: bulletVelocity,
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
    double grenadeX = isFacingRight
        ? playerPos.x + playerWidth
        : playerPos.x;
    
    // 手榴彈初速度
    double grenadeVelocityX = isFacingRight ? 150 : -150;
    double grenadeVelocityY = isAiming ? -200 : -100; // 瞄準時上拋更高

    grenades.add(Grenade(
      position: Vector2(grenadeX, playerPos.y + playerHeight / 2),
      velocity: Vector2(grenadeVelocityX, grenadeVelocityY),
    ));
  }

  void moveLeft() {
    playerVelocityX = -moveSpeed;
    isFacingRight = false;
  }

  void moveRight() {
    playerVelocityX = moveSpeed;
    isFacingRight = true;
  }

  void stopMoving() {
    playerVelocityX = 0;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      // A: 向左走
      if (event.logicalKey == LogicalKeyboardKey.keyA) {
        moveLeft();
      }
      // D: 向右走
      else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        moveRight();
      }
      // W: 向上瞄準
      else if (event.logicalKey == LogicalKeyboardKey.keyW) {
        isAiming = true;
      }
      // S: 蹲下
      else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        isCrouching = true;
      }
      // K: 向上跳躍
      else if (event.logicalKey == LogicalKeyboardKey.keyK) {
        playerJump();
      }
      // J: 開火
      else if (event.logicalKey == LogicalKeyboardKey.keyJ) {
        playerShoot();
      }
      // L: 丟手榴彈
      else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        throwGrenade();
      }
    } else if (event is KeyUpEvent) {
      // A 或 D: 停止移動
      if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.keyD) {
        stopMoving();
      }
      // W: 停止瞄準
      else if (event.logicalKey == LogicalKeyboardKey.keyW) {
        isAiming = false;
      }
      // S: 停止蹲下
      else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        isCrouching = false;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameWidth, gameHeight),
      Paint()..color = Colors.black87,
    );

    // Draw platforms
    for (var platform in platforms) {
      double width = 200;
      if (platform.x == gameWidth / 2) width = gameWidth;

      canvas.drawRect(
        Rect.fromLTWH(
          platform.x - width / 2,
          platform.y - 10,
          width,
          20,
        ),
        Paint()..color = Colors.green,
      );
    }

    // Draw player with states
    double playerRenderHeight = isCrouching ? playerHeight * 0.7 : playerHeight;
    double playerRenderY = playerPos.y + (isCrouching ? playerHeight * 0.3 : 0);
    
    canvas.drawRect(
      Rect.fromLTWH(playerPos.x, playerRenderY, playerWidth, playerRenderHeight),
      Paint()..color = Colors.red,
    );

    // Draw gun
    Paint gunPaint = Paint()..color = Colors.grey;
    double gunY = playerRenderY + playerRenderHeight / 2;
    
    if (isAiming) {
      // 向上瞄準
      if (isFacingRight) {
        canvas.drawLine(
          Offset(playerPos.x + playerWidth, gunY - 5),
          Offset(playerPos.x + playerWidth, gunY - 20),
          gunPaint,
        );
      } else {
        canvas.drawLine(
          Offset(playerPos.x, gunY - 5),
          Offset(playerPos.x, gunY - 20),
          gunPaint,
        );
      }
    } else {
      // 水平開火
      if (isFacingRight) {
        canvas.drawLine(
          Offset(playerPos.x + playerWidth, gunY),
          Offset(playerPos.x + playerWidth + 10, gunY),
          gunPaint,
        );
      } else {
        canvas.drawLine(
          Offset(playerPos.x, gunY),
          Offset(playerPos.x - 10, gunY),
          gunPaint,
        );
      }
    }

    // Draw enemies
    for (var enemy in enemies) {
      enemy.render(canvas);
    }

    // Draw bullets
    for (var bullet in bullets) {
      bullet.render(canvas);
    }

    // Draw grenades
    for (var grenade in grenades) {
      grenade.render(canvas);
    }

    // Draw UI
    textPaint.render(canvas, 'Score: $score', Vector2(10, 10));
    textPaint.render(canvas, 'Level: $level', Vector2(gameWidth - 150, 10));
    
    final smallTextPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
    );
    smallTextPaint.render(
      canvas,
      'A/D:Move | W:Aim | S:Crouch | K:Jump | J:Fire | L:Grenade',
      Vector2(10, gameHeight - 25),
    );

    if (gameOver) {
      final gameOverPaint = TextPaint(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      );
      gameOverPaint.render(
        canvas,
        'GAME OVER',
        Vector2(gameWidth / 2 - 120, gameHeight / 2 - 50),
      );
      final restartPaint = TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
        ),
      );
      restartPaint.render(
        canvas,
        'Final Score: $score',
        Vector2(gameWidth / 2 - 80, gameHeight / 2 + 20),
      );
    }
  }
}
