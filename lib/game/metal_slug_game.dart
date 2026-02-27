import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'Grenade.dart';
import 'Bullet.dart';
import 'Explosion.dart';
import 'HeavyWeapon.dart';
import 'Enemy.dart';
import 'Platform.dart';
import 'Tank.dart';
import 'loot.dart';
import 'Boss.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart' show rootBundle;


Future<ui.Image> loadUiImage(String assetPath) async {
  final data = await rootBundle.load('assets/$assetPath');
  final bytes = data.buffer.asUint8List();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}
// ────────────────────────────────────────────────────────────
// 音效
// ────────────────────────────────────────────────────────────
Future<void> _playSfx(String assetPath) async {
  try {
    final player = AudioPlayer();
    print('[SFX] 正在加載: $assetPath');
    await player.setAudioSource(AudioSource.asset(assetPath));
    await player.play();
    print('[SFX] 播放開始: $assetPath');
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        print('[SFX] 播放完成，釋放資源: $assetPath');
        player.dispose();
      }
    });
  } catch (e) {
    print('[ERROR] 音效播放失敗 ($assetPath): $e');
  }
}


//顯示戰利品得分的浮動文字
class FloatingText {
  final String text;
  final Vector2 position;
  final Color color;
  double timer; // 剩餘顯示時間

  FloatingText({
    required this.text,
    required this.position,
    required this.color,
    this.timer = 2.0, // 顯示2秒
  });
}


// ────────────────────────────────────────────────────────────
// MetalSlugGame
// ────────────────────────────────────────────────────────────
class MetalSlugGame extends FlameGame with KeyboardEvents, TapDetector {
  static const double gameWidth = 800;
  static const double gameHeight = 600;
  final List<FloatingText> _floatingTexts = [];
  // ── 角色顏色（由外部 setPlayerColor 設定）────────────────
  Color playerColor = Colors.red;

  // 勝利旗標與回主畫面 callback
  bool gameVictory = false;
  VoidCallback? onReturnToMenu;
  late Rect _returnButtonRect; // 以遊戲座標表示的按鈕區域

  void setPlayerColor(int characterIndex) {
    switch (characterIndex) {
      case 0:
        playerColor = Colors.red;
        break;
      case 1:
        playerColor = Colors.blue;
        break;
      case 2:
        playerColor = Colors.green;
        break;
      case 3:
        playerColor = Colors.purple;
        break;
      default:
        playerColor = Colors.red;
    }
  }

  // ── 場景（zone）系統 ──────────────────────────────────────
  // zone 0 = 第一區，zone 1 = 第二區（向右走到底後觸發）
  int currentZone = 0;
  bool _transitionTriggered = false; // 防止重複觸發

  // ── 玩家 ──────────────────────────────────────────────────
  late Vector2 playerPos;
  double playerWidth = 30;
  double playerHeight = 40;
  double playerVelocityX = 0;
  double playerVelocityY = 0;
  double moveSpeed = 150;
  double jumpForce = 400;
  double gravity = 600;
  bool isJumping = false;
  bool isFacingRight = true;
  bool isAiming = false;
  bool isCrouching = false;

  // ── 生命值 ────────────────────────────────────────────────
  int lives = 3;
  final ValueNotifier<int> livesNotifier = ValueNotifier<int>(3);

  // ── 無敵 & 閃爍 ───────────────────────────────────────────
  double invulnerableTimer = 0.0;
  static const double _blinkDuration = 3.0;
  static const double _blinkPeriod = 0.15;
  double _blinkTimer = 0.0;
  bool _playerVisible = true;

  // ── 死亡重生 ──────────────────────────────────────────────
  bool _isDying = false;
  double _deathTimer = 0.0;
  double _deathX = 0.0;
  static const double _deathDelay = 2.0;

  // ── 場景切換過場 ──────────────────────────────────────────
  bool _zoneTransiting = false;
  double _zoneTransitTimer = 0.0;
  static const double _zoneTransitDuration = 1.5;

  // ── 遊戲物件 ──────────────────────────────────────────────
  List<Bullet> bullets = [];
  List<Grenade> grenades = [];
  List<Explosion> explosions = [];
  List<Enemy> enemies = [];
  List<Tank> tanks = [];
  List<Platform> platforms = [];
  List<Loot> loots = []; // 場上的戰利品

  // ── 分數 / 關卡 ───────────────────────────────────────────
  int score = 0;
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  int level = 1;
  bool gameOver = false;

  // ── 手榴彈 ────────────────────────────────────────────────
  int grenadesAvailable = 10;
  final ValueNotifier<int> grenadesAvailableNotifier = ValueNotifier<int>(10);
  double grenadeCooldownTimer = 0.0;
  final double grenadeCooldown = 0.5;

  // ── 射擊冷卻 ──────────────────────────────────────────────
  double shootCooldownTimer = 0.0;
  final double shootCooldown = 0.2; // 0.2 秒射一次

  // 子彈無限發（手槍）/ 機槍彈藥
  bool hasMachineGun = false;
  int machineGunAmmo = 0;
  static const int machineGunAmmoPerPickup = 200;
  final ValueNotifier<String> ammoNotifier = ValueNotifier<String>('∞');

  // H 道具列表
  List<HeavyWeapon> heavyWeapons = [];

  // ── 背景圖像 ──────────────────────────────────────────────
  late ui.Image zone1Background;
  late ui.Image zone2Background;
  late ui.Image zone3Background;

  // ────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // 初始化回主選單按鈕（以遊戲座標表示）
    _returnButtonRect = Rect.fromLTWH(gameWidth / 2 - 100, gameHeight / 2 + 60, 200, 40);
    playerPos = Vector2(100, 300);

    
    
    try {
        zone1Background = await loadUiImage('background/zone1.jpg');
        zone2Background = await loadUiImage('background/zone2.jpg');
        zone3Background = await loadUiImage('background/zone3.jpg');
      print('[Background] 背景圖像已加載');
    } catch (e) {
      print('[ERROR] 背景圖像加載失敗: $e');
    }
    

    _setupZone(0);
    invulnerableTimer = 1.5;
    // 延後播放，確保 audio context 已就緒
    Future.delayed(const Duration(milliseconds: 1000), () {
      _playSfx('audio/soundEffect/missonStart.mp3');
    });
  }

  // ────────────────────────────────────────────────────────
  // Zone 0：原始關卡（有高低平台，一般敵人）
  // Zone 1：新場景（開闊地形 + 坦克車）
  // ────────────────────────────────────────────────────────
  void _setupZone(int zone) {
    bullets.clear();
    grenades.clear();
    platforms.clear();
    enemies.clear();
    tanks.clear();
    heavyWeapons.clear();
    loots.clear();
    _transitionTriggered = false;

    currentZone = zone;

    const double groundY = gameHeight - 40;

    if (zone == 0) {
      // ── Zone 0 平台 ────────────────────────────────────
      const double mid1Y = 400;
      const double mid2Y = 320;
      const double high1Y = 220;
      const double high2Y = 200;

      final groundPlatform = Platform(
        x: gameWidth / 2,
        y: groundY,
        width: gameWidth,
      );
      final mid1 = Platform(x: 180, y: mid1Y, width: 200);
      final mid2 = Platform(x: 620, y: mid2Y, width: 200);
      final hi1 = Platform(x: 130, y: high1Y, width: 160);
      final hi2 = Platform(x: 400, y: high2Y, width: 180);
      final hi3 = Platform(x: 670, y: high1Y, width: 160);

      platforms = [groundPlatform, mid1, mid2, hi1, hi2, hi3];

      // ── 敵人：用 factory 確保站在平台頂面 ────────────────
      enemies = [
        Enemy.onPlatform(300, groundPlatform),
        Enemy.onPlatform(550, groundPlatform),
        Enemy.onPlatform(180, mid1),
        Enemy.onPlatform(620, mid2),
        Enemy.onPlatform(400, hi2),
      ];
    } else if (zone == 1) {
      // ── Zone 1：開闊平地 + 高台 ────────────────────────
      final groundPlatform = Platform(
        x: gameWidth / 2,
        y: groundY,
        width: gameWidth,
      );
      final shelf1 = Platform(x: 200, y: 350, width: 180);
      final shelf2 = Platform(x: 600, y: 280, width: 180);

      platforms = [groundPlatform, shelf1, shelf2];

      // 一般敵人
      enemies = [
        Enemy.onPlatform(150, groundPlatform),
        Enemy.onPlatform(650, groundPlatform),
        Enemy.onPlatform(200, shelf1),
        Enemy.onPlatform(600, shelf2),
      ];

      // H 道具：放在地面
      heavyWeapons = [HeavyWeapon(position: Vector2(350, groundY - 12))];

      // 坦克車：只放在地板
      tanks = [
        Tank.onPlatform(500, groundPlatform),
        Tank.onPlatform(680, groundPlatform),
      ];
    } else if (zone == 2) {
      // ── Zone 3 (Boss 區)：只有地面與魔王
      final groundPlatform = Platform(
        x: gameWidth / 2,
        y: groundY,
        width: gameWidth,
      );
      platforms = [groundPlatform];
      // 置入一隻 Boss
      enemies = [
        Boss(position: Vector2(gameWidth / 2, groundPlatform.top - 120), health: 120),
      ];
    }

    grenadesAvailable = 10;
    grenadesAvailableNotifier.value = grenadesAvailable;
  }

  // ────────────────────────────────────────────────────────
  bool get _allEnemiesDead => enemies.isEmpty && tanks.every((t) => t.isDead);

  // ── 場景切換 ─────────────────────────────────────────────
  void _triggerZoneTransition() {
    if (_transitionTriggered) return;
    _transitionTriggered = true;
    _zoneTransiting = true;
    _zoneTransitTimer = 0;
  }

  // ── 玩家受傷 ──────────────────────────────────────────────
  void _playerHit() {
    if (invulnerableTimer > 0 || _isDying || _zoneTransiting) return;
    lives--;
    livesNotifier.value = lives;
    if (lives <= 0) {
      gameOver = true;
      return;
    }
    _deathX = playerPos.x;
    _isDying = true;
    _deathTimer = 0.0;
    playerPos.y = gameHeight + 200;
    playerVelocityX = 0;
    playerVelocityY = 0;
  }

  // ── 重生 ─────────────────────────────────────────────────
  void _respawn() {
    _isDying = false;
    playerPos = Vector2(
      _deathX.clamp(playerWidth, gameWidth - playerWidth),
      -60,
    );
    playerVelocityX = 0;
    playerVelocityY = 0;
    isJumping = true;
    invulnerableTimer = _blinkDuration;
    _blinkTimer = 0.0;
    _playerVisible = true;
  }

  // ────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver || gameVictory) return;

    // ── 場景切換過場（黑屏等待）──────────────────────────
    if (_zoneTransiting) {
      _zoneTransitTimer += dt;
      if (_zoneTransitTimer >= _zoneTransitDuration) {
        _zoneTransiting = false;
        // 允許循環進入 0,1,2 三個 zone（包含 boss 區 zone==2）
        int nextZone = (currentZone + 1) % 3;
        _setupZone(nextZone);
        playerPos = Vector2(80, 300);
        playerVelocityX = 0;
        playerVelocityY = 0;
        invulnerableTimer = 1.5;
        _playSfx('audio/soundEffect/missionStart.mp3');
      }
      return;
    }

    // ── 死亡等待 ─────────────────────────────────────────
    if (_isDying) {
      _deathTimer += dt;
      if (_deathTimer >= _deathDelay) _respawn();
      _updateExplosions(dt);
      return;
    }

    // ── 無敵閃爍 ─────────────────────────────────────────
    if (invulnerableTimer > 0) {
      invulnerableTimer -= dt;
      if (invulnerableTimer <= 0) {
        invulnerableTimer = 0;
        _playerVisible = true;
      } else {
        _blinkTimer += dt;
        if (_blinkTimer >= _blinkPeriod) {
          _blinkTimer -= _blinkPeriod;
          _playerVisible = !_playerVisible;
        }
      }
    } else {
      _playerVisible = true;
    }

    // ── 物理 & 移動 ───────────────────────────────────────
    playerVelocityY += gravity * dt;
    playerPos.x += playerVelocityX * dt;
    playerPos.y += playerVelocityY * dt;

    // X 邊界：左邊擋住，右邊觸發場景切換
    if (playerPos.x < 0) playerPos.x = 0;
    if (playerPos.x + playerWidth >= gameWidth) {
      // 右邊界 → 觸發場景切換
      if (_allEnemiesDead) {
        _triggerZoneTransition();
      } else {
        playerPos.x = gameWidth - playerWidth;
      }
    }

    // 平台碰撞
    for (var p in platforms) {
      if (_checkPlatformCollision(p)) {
        isJumping = false;
        playerVelocityY = 0;
        playerPos.y = p.top - playerHeight;
      }
    }

    // 掉出底部 → 扣血
    if (playerPos.y > gameHeight) {
      _playerHit();
      return;
    }

    // ── 手榴彈 ───────────────────────────────────────────
    for (var grenade in List.from(grenades)) {
      grenade.update(dt);
      bool shouldExplode = false;
      for (var p in platforms) {
        if (grenade.position.x >= p.left &&
            grenade.position.x <= p.right &&
            grenade.position.y + grenade.radius >= p.top &&
            grenade.position.y < p.top + 20 &&
            grenade.velocity.y >= 0) {
          shouldExplode = true;
          break;
        }
      }
      if (grenade.isExpired()) shouldExplode = true;
      if (shouldExplode) {
        _triggerGrenadeExplosion(grenade);
      } else if (grenade.position.x < 0 ||
          grenade.position.x > gameWidth ||
          grenade.position.y > gameHeight) {
        grenades.remove(grenade);
      }
    }

    // ── 子彈（移動 + 邊界 + 玩家碰撞）──────────────────
    for (var bullet in List.from(bullets)) {
      bullet.update(dt);
      if (bullet.position.x < 0 ||
          bullet.position.x > gameWidth ||
          bullet.position.y < 0 ||
          bullet.position.y > gameHeight) {
        bullets.remove(bullet);
        continue;
      }
      if (!bullet.isPlayerBullet && invulnerableTimer <= 0) {
        final cx = playerPos.x + playerWidth / 2;
        final cy = playerPos.y + playerHeight / 2;
        final dx = bullet.position.x - cx;
        final dy = bullet.position.y - cy;
        if (dx * dx + dy * dy < (18 + bullet.radius) * (18 + bullet.radius)) {
          bullets.remove(bullet);
          _playerHit();
          continue;
        }
      }
    }
    _updateFloatingTexts(dt);
    _updateExplosions(dt);
    
    // ── H 道具撿取 ────────────────────────────────────────
    for (var hw in List.from(heavyWeapons)) {
      if (!hw.collected) {
        final dx = (playerPos.x + playerWidth / 2) - hw.position.x;
        final dy = (playerPos.y + playerHeight / 2) - hw.position.y;
        if (dx * dx + dy * dy < 30 * 30) {
          hw.collected = true;
          hasMachineGun = true;
          //撿起H後撥放機槍音效
          _playSfx('audio/soundEffect/heavymachinegun.mp3');
          machineGunAmmo = machineGunAmmoPerPickup;
          ammoNotifier.value = '$machineGunAmmo';
        }
      }
    }
    // ── 戰利品撿取 ────────────────────────────────────────
    for (var loot in List.from(loots)) {
      final dx = (playerPos.x + playerWidth / 2) - loot.position.x;
      final dy = (playerPos.y + playerHeight / 2) - loot.position.y;
      if (dx * dx + dy * dy < 30 * 30) {
        score = (score + loot.value).toInt();
        scoreNotifier.value = score;
        _playSfx('audio/soundEffect/pickup.mp3');

        // --- 新增：建立浮動文字 ---
        _floatingTexts.add(FloatingText(
          text: loot.value >= 0 ? '+${loot.value.toInt()}' : '${loot.value.toInt()}',
          position: Vector2(loot.position.x, loot.position.y - 20), // 在物體上方一點顯示
          color: loot.value >= 0 ? Colors.yellow : Colors.red,
        ));
        // -----------------------

        loots.remove(loot);
      }
    }

    // ── 一般敵人 ─────────────────────────────────────────
    for (var enemy in List.from(enemies)) {
      enemy.update(dt, platforms);

      // 子彈命中
      for (var bullet in List.from(bullets)) {
        if (bullet.isPlayerBullet &&
            (enemy.position - bullet.position).length < 22) {
          bullets.remove(bullet);
          // Boss 有血量機制，普通敵人則直接死亡
          bool died = false;
          if (enemy is Boss) {
            (enemy as Boss).health--;
            if (enemy.health <= 0) {
              enemy.isDead = true;
              died = true;
            }
            score += 50;
          } else {
            enemy.isDead = true;
            died = true;
            score += 100;
          }
          if (died) {
            loots.add(Loot.spawnAt(enemy.position));
          }
          scoreNotifier.value = score;
          break;
        }
      }

      // 敵人射擊：瞄準玩家中心（含 y 分量，平台敵人也能打到地面玩家）
      if (enemy.shootTimer > 2.5) {
        // Boss 有特殊攻擊方式，由 getBossBullets 處理
        if (enemy is Boss) {
          // Boss 會在 getBossBullets 中以不同方式射擊
        } else {
          // 普通敵人才用這個簡單射擊
          final double targetX = playerPos.x + playerWidth / 2;
          final double targetY = playerPos.y + playerHeight / 2;
          final double dx = targetX - enemy.position.x;
          final double dy = targetY - enemy.position.y;
          final double len = math.sqrt(dx * dx + dy * dy);
          const double spd = 220.0;
          final double vx = len < 1 ? spd : spd * dx / len;
          final double vy = len < 1 ? 0 : spd * dy / len;
          bullets.add(
            Bullet(
              position: Vector2(enemy.position.x, enemy.position.y),
              velocity: Vector2(vx, vy),
              isPlayerBullet: false,
            ),
          );
          enemy.shootTimer = 0;
        }
      }

      // Boss 特殊攻擊
      if (enemy is Boss) {
        final bossBullets = (enemy as Boss).getBossBullets(dt, playerPos.x + playerWidth / 2);
        bullets.addAll(bossBullets);
      }

      // 碰撞玩家
      if (invulnerableTimer <= 0 && (playerPos - enemy.position).length < 30) {
        _playerHit();
      }
    }
    enemies.removeWhere((e) => e.isDead);

    // 若為 boss 區 (zone 3) 且魔王被擊倒，標記勝利
    if (currentZone == 2 && enemies.isEmpty && !gameVictory) {
      gameVictory = true;
      // 播放通關音效
      _playSfx('audio/soundEffect/missioncomplete.mp3');
    }

    // ── 坦克車 ───────────────────────────────────────────
    for (var tank in List.from(tanks)) {
      tank.update(dt, platforms);

      // 子彈命中坦克（需 10 發）
      for (var bullet in List.from(bullets)) {
        if (bullet.isPlayerBullet) {
          final dx = bullet.position.x - tank.position.x;
          final dy = bullet.position.y - tank.position.y;
          if (dx.abs() < tank.width / 2 + 4 && dy.abs() < tank.height / 2 + 4) {
            bullets.remove(bullet);
            tank.hp--;
            tank.hitFlashTimer = 0.1;
            if (tank.hp <= 0) {
              tank.isDead = true;
              loots.add(Loot.spawnAt(tank.position));
              explosions.add(
                Explosion(
                  position: Vector2(tank.position.x, tank.position.y),
                  maxRadius: 100,
                ),
              );
              _playSfx('audio/soundEffect/bomb.wav');
              score += 500;
              scoreNotifier.value = score;
            }
            break;
          }
        }
      }

      // 坦克射擊（含延遲佇列）
      final newBullets = tank.updateShoot(dt, playerPos.x);
      bullets.addAll(newBullets);

      // 坦克碰撞玩家
      if (invulnerableTimer <= 0 && !tank.isDead) {
        final dx = (playerPos.x + playerWidth / 2) - tank.position.x;
        final dy = (playerPos.y + playerHeight / 2) - tank.position.y;
        if (dx.abs() < tank.width / 2 + playerWidth / 2 &&
            dy.abs() < tank.height / 2 + playerHeight / 2) {
          _playerHit();
        }
      }
    }
    tanks.removeWhere((t) => t.isDead);

    // ── 所有敵人消滅：提示可前進（由玩家走到右邊觸發切換）
    // 如果 zone 1 全清，自動回到 zone 0（循環關卡）
    if (_allEnemiesDead && currentZone == 1 && !_transitionTriggered) {
      // zone 1 清空後也需走到右邊才換回去，不用特別處理
    }

    // 冷卻
    if (grenadeCooldownTimer > 0) {
      grenadeCooldownTimer = (grenadeCooldownTimer - dt).clamp(
        0.0,
        double.infinity,
      );
    }

    // 射擊冷卻
    if (shootCooldownTimer > 0) {
      shootCooldownTimer = (shootCooldownTimer - dt).clamp(
        0.0,
        double.infinity,
      );
    }

    // 機槍延遲子彈
    _updatePendingPlayerBullets(dt);
  }

  void _updateFloatingTexts(double dt) {
    for (int i = _floatingTexts.length - 1; i >= 0; i--) {
      final ft = _floatingTexts[i];
      ft.timer -= dt;
      ft.position.y -= 20 * dt; 
      if (ft.timer <= 0) {
        _floatingTexts.removeAt(i);
      }
    }
  }
  void _updateExplosions(double dt) {
    for (var ex in List.from(explosions)) {
      ex.update(dt);
      if (ex.isFinished) explosions.remove(ex);
    }
  }

  void _triggerGrenadeExplosion(Grenade grenade) {
    explosions.add(
      Explosion(
        position: Vector2(grenade.position.x, grenade.position.y),
        maxRadius: grenade.explosionRadius,
      ),
    );
    _playSfx('audio/soundEffect/bomb.wav');

    // 炸一般敵人與 Boss
    for (var enemy in List.from(enemies)) {
      if ((enemy.position - grenade.position).length <
          grenade.explosionRadius) {
        // Boss 有血量機制：手榴彈傷害 10
        bool died = false;
        if (enemy is Boss) {
          (enemy as Boss).health -= 10;
          if (enemy.health <= 0) {
            enemy.isDead = true;
            died = true;
          }
          score += 50;
        } else {
          // 普通敵人直接死亡
          enemy.isDead = true;
          died = true;
          score += 100;
        }
        if (died) {
          loots.add(Loot.spawnAt(enemy.position));
        }
        scoreNotifier.value = score;
      }
    }

    // 炸坦克（需 2 顆手榴彈，用矩形範圍偵測）
    for (var tank in List.from(tanks)) {
      if (!tank.isDead) {
        final dx = (tank.position.x - grenade.position.x).abs();
        final dy = (tank.position.y - grenade.position.y).abs();
        if (dx < grenade.explosionRadius + tank.width / 2 &&
            dy < grenade.explosionRadius + tank.height / 2) {
          tank.grenadeHits++;
          tank.hitFlashTimer = 0.2;
          if (tank.grenadeHits >= Tank.grenadeHitsToKill) {
            tank.isDead = true;
            loots.add(Loot.spawnAt(tank.position));
            explosions.add(
              Explosion(
                position: Vector2(tank.position.x, tank.position.y),
                maxRadius: 110,
              ),
            );
            _playSfx('audio/soundEffect/bomb.wav');
            score += 500;
            scoreNotifier.value = score;
          }
        }
      }
    }

    grenades.remove(grenade);
  }

  bool _checkPlatformCollision(Platform p) {
    return playerPos.y + playerHeight >= p.top - 2 &&
        playerPos.y + playerHeight <= p.top + 22 &&
        playerPos.x + playerWidth > p.left &&
        playerPos.x < p.right &&
        playerVelocityY > 0;
  }

  // 機槍延遲子彈佇列：[剩餘延遲秒, bulletX, velX, velY]
  final List<List<double>> _pendingPlayerBullets = [];

  void playerShoot() {
    // 機槍有冷卻限制，手槍無限制
    if (hasMachineGun && shootCooldownTimer > 0) return;

    _playSfx('audio/soundEffect/shoot.wav');

    if (hasMachineGun && machineGunAmmo > 0) {
      // 機槍：一次排 5 顆，每顆間隔 0.06 秒，設置 1 秒冷卻
      shootCooldownTimer = shootCooldown;
      const int burst = 5;
      const double interval = 0.06;
      double bulletX = isFacingRight ? playerPos.x + playerWidth : playerPos.x;
      double velX = isFacingRight ? 380 : -380;
      double velY = isAiming ? -400 : 0;
      for (int i = 0; i < burst; i++) {
        _pendingPlayerBullets.add([
          i * interval,
          bulletX,
          velY == 0 ? velX : 0,
          velY,
          playerPos.y + playerHeight / 2,
        ]);
      }
      machineGunAmmo -= burst;
      if (machineGunAmmo <= 0) {
        machineGunAmmo = 0;
        hasMachineGun = false;
        ammoNotifier.value = '∞';
      } else {
        ammoNotifier.value = '$machineGunAmmo';
      }
    } else {
      // 手槍：單發，無冷卻限制
      double bulletX = isFacingRight ? playerPos.x + playerWidth : playerPos.x;
      Vector2 vel = isAiming
          ? Vector2(0, -400)
          : Vector2(isFacingRight ? 300 : -300, 0);
      bullets.add(
        Bullet(
          position: Vector2(bulletX, playerPos.y + playerHeight / 2),
          velocity: vel,
          isPlayerBullet: true,
        ),
      );
    }
  }

  // 每幀處理延遲玩家子彈
  void _updatePendingPlayerBullets(double dt) {
    final toRemove = <List<double>>[];
    for (var pb in _pendingPlayerBullets) {
      pb[0] -= dt;
      if (pb[0] <= 0) {
        bullets.add(
          Bullet(
            position: Vector2(pb[1], pb[4]),
            velocity: Vector2(pb[2], pb[3]),
            isPlayerBullet: true,
            color: Colors.orange,
            radius: 3,
          ),
        );
        toRemove.add(pb);
      }
    }
    for (var b in toRemove) _pendingPlayerBullets.remove(b);
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
        ? playerPos.x + playerWidth + 30
        : playerPos.x - 30;
    grenades.add(
      Grenade(
        position: Vector2(grenadeX, playerPos.y + playerHeight / 2 - 5),
        velocity: Vector2(
          isFacingRight ? 300.0 : -300.0,
          isAiming ? -300.0 : -150.0,
        ),
      ),
    );
    grenadesAvailable--;
    grenadesAvailableNotifier.value = grenadesAvailable;
    grenadeCooldownTimer = grenadeCooldown;
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
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // 先檢查是否按 Esc 返回主菜單（可在死亡或勝利時使用）
    if (event is KeyDownEvent && (gameOver || gameVictory || _isDying)) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        onReturnToMenu?.call();
        return KeyEventResult.handled;
      }
    }
    
    if (_isDying || gameOver || _zoneTransiting) return KeyEventResult.handled;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyA)
        moveLeft();
      else if (event.logicalKey == LogicalKeyboardKey.keyD)
        moveRight();
      else if (event.logicalKey == LogicalKeyboardKey.keyW)
        isAiming = true;
      else if (event.logicalKey == LogicalKeyboardKey.keyS)
        isCrouching = true;
      else if (event.logicalKey == LogicalKeyboardKey.keyK)
        playerJump();
      else if (event.logicalKey == LogicalKeyboardKey.keyJ)
        playerShoot();
      else if (event.logicalKey == LogicalKeyboardKey.keyL)
        throwGrenade();
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.keyD)
        stopMoving();
      else if (event.logicalKey == LogicalKeyboardKey.keyW)
        isAiming = false;
      else if (event.logicalKey == LogicalKeyboardKey.keyS)
        isCrouching = false;
    }
    return KeyEventResult.handled;
  }

    @override
    void onTapDown(info) {
      // 任何點擊時直接返回菜單
      if (gameOver || gameVictory || _isDying) {
        onReturnToMenu?.call();
      }
    }

@override
  void render(Canvas canvas) {
    // 1. 計算縮放比例：將實際螢幕尺寸 (size.x, size.y) 除以你的遊戲邏輯尺寸 (800, 600)
    final double scaleX = size.x / gameWidth;
    final double scaleY = size.y / gameHeight;

    // 2. 保存畫布狀態並執行縮放
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // ── 以下是你原本的繪製邏輯，現在它們都會自動適應螢幕了 ──

    super.render(canvas);

    // ── 場景切換過場：純黑 ──────────────────────────────
    if (_zoneTransiting) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, gameWidth, gameHeight),
        Paint()..color = Colors.black,
      );
      int nextZone = (currentZone + 1) % 3;
      TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ).render(
        canvas,
        'Zone ${nextZone + 1} ▶',
        Vector2(gameWidth / 2 - 70, gameHeight / 2 - 20),
      );
      canvas.restore(); // 過場時也要記得 restore
      return;
    }

    // ── 背景圖像 ────────────────────────────────────────────
    try {
      final ui.Image bgImage = currentZone == 0
          ? zone1Background
          : currentZone == 1
              ? zone2Background
              : zone3Background;
      canvas.drawImageRect(
        bgImage,
        Rect.fromLTWH(
          0,
          0,
          bgImage.width.toDouble(),
          bgImage.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, gameWidth, gameHeight),
        Paint()..filterQuality = FilterQuality.none, // 加入此行可保持像素感
      );
    } catch (e) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, gameWidth, gameHeight),
        Paint()
          ..color = currentZone == 0 ? Colors.black87 : const Color(0xFF3A2A10),
      );
    }

    // 平台
    final pColor = currentZone == 0 ? Colors.green : Colors.orange.shade800;
    final pHi = currentZone == 0 ? Colors.lightGreen : Colors.orange;
    for (var p in platforms) {
      canvas.drawRect(
        Rect.fromLTWH(p.left, p.top, p.width, 20),
        Paint()..color = pColor,
      );
      canvas.drawLine(
        Offset(p.left, p.top),
        Offset(p.right, p.top),
        Paint()
          ..color = pHi
          ..strokeWidth = 2,
      );
    }

    // 右邊界「前進」提示
    if (_allEnemiesDead) {
      final arrowPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.8)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      final double ax = gameWidth - 20;
      final double ay = gameHeight / 2;
      canvas.drawLine(Offset(ax - 15, ay - 15), Offset(ax, ay), arrowPaint);
      canvas.drawLine(Offset(ax - 15, ay + 15), Offset(ax, ay), arrowPaint);
      TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ).render(canvas, '前進 ▶', Vector2(gameWidth - 60, ay + 20));
    }

    // 玩家
    if (!_isDying && _playerVisible) {
      double renderH = isCrouching ? playerHeight * 0.7 : playerHeight;
      double renderY = playerPos.y + (isCrouching ? playerHeight * 0.3 : 0);
      canvas.drawRect(
        Rect.fromLTWH(playerPos.x, renderY, playerWidth, renderH),
        Paint()..color = playerColor,
      );
      final gunPaint = Paint()
        ..color = Colors.grey.shade800
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      double gunY = renderY + renderH / 2;
      if (isAiming) {//向上瞄準
        double gx = isFacingRight ? playerPos.x + playerWidth : playerPos.x;
        canvas.drawLine(Offset(gx, gunY - 8), Offset(gx, gunY - 25), gunPaint);
      } else {
        if (isFacingRight) {
          canvas.drawLine(
            Offset(playerPos.x + playerWidth, gunY),
            Offset(playerPos.x + playerWidth + 15, gunY),
            gunPaint,
          );
        } else {
          canvas.drawLine(
            Offset(playerPos.x, gunY),
            Offset(playerPos.x - 15, gunY),
            gunPaint,
          );
        }
      }
    }

    // 繪製其他物件
    for (var hw in heavyWeapons) hw.render(canvas);
    for (var e in enemies) e.render(canvas);
    for (var t in tanks) t.render(canvas);
    for (var b in bullets) b.render(canvas);
    for (var g in grenades) g.render(canvas);
    for (var ex in explosions) ex.render(canvas);
    for (var lt in loots) lt.render(canvas);

    // UI 標示
    TextPaint(
      style: const TextStyle(color: Colors.white70, fontSize: 13),
    ).render(
      canvas,
      'Zone ${currentZone + 1}  Lv.$level',
      Vector2(gameWidth - 110, 10),
    );

    TextPaint(style: const TextStyle(color: Colors.white, fontSize: 14)).render(
      canvas,
      'A/D:Move | W:Aim | S:Crouch | K:Jump | J:Fire | L:Grenade',
      Vector2(10, gameHeight - 25),
    );

    if (_isDying) {
      TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ).render(
        canvas,
        'Respawning...',
        Vector2(gameWidth / 2 - 80, gameHeight / 2 - 20),
      );
    }

    if (gameOver) {
      TextPaint(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ).render(
        canvas,
        'GAME OVER',
        Vector2(gameWidth / 2 - 120, gameHeight / 2 - 50),
      );
      TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ).render(
        canvas,
        'Final Score: $score',
        Vector2(gameWidth / 2 - 80, gameHeight / 2 + 20),
      );
      // Draw return button
      // 按鈕背景漸變效果
      canvas.drawRRect(
        RRect.fromRectAndRadius(_returnButtonRect, const Radius.circular(15)),
        Paint()
          ..color = const Color(0xFF2196F3)
          ..style = PaintingStyle.fill,
      );
      // 按鈕邊框
      canvas.drawRRect(
        RRect.fromRectAndRadius(_returnButtonRect, const Radius.circular(15)),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
      TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ).render(
        canvas,
        '返回主選單',
        Vector2(_returnButtonRect.left + 15, _returnButtonRect.top + 8),
      );
    }
    // 3. 【放置在這裡】 浮動分數（保證在所有遊戲物件上方）
    // ---------------------------------------------------------
    for (var ft in _floatingTexts) {
      // 根據剩餘時間計算透明度（淡出效果）
      final double opacity = (ft.timer / 2.0).clamp(0.0, 1.0);
      
      TextPaint(
        style: TextStyle(
          color: ft.color.withOpacity(opacity),
          fontSize: 18, // 稍微大一點比較清楚
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 3,
              color: Colors.black.withOpacity(opacity),
              offset: const Offset(1, 1),
            )
          ],
        ),
      ).render(canvas, ft.text, ft.position);
    }
    // 勝利顯示（若有）
    if (gameVictory) {
      TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 60,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        ),
      ).render(
        canvas,
        'MISSION COMPLETE',
        Vector2(gameWidth / 2 - 250, gameHeight / 2 - 30),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(_returnButtonRect, const Radius.circular(15)),
        Paint()
          ..color = const Color(0xFF2196F3)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(_returnButtonRect, const Radius.circular(15)),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
      TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ).render(
        canvas,
        '返回主選單',
        Vector2(_returnButtonRect.left + 15, _returnButtonRect.top + 8),
      );
    }

    // 3. 最後恢復畫布狀態
    canvas.restore();
  }
}