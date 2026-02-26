import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:flame/game.dart';
import 'game/metal_slug_game.dart';
import 'screens/character_select_screen.dart';
import 'services/audio_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metal Slug Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  bool _showStory = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,   // 讓 Stack 撐滿整個 Scaffold body
        children: [
          // ── 背景圖：完整顯示，不截斷 ────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/background/mainBg.gif',
              fit: BoxFit.contain,          // 完整顯示，不裁切
              alignment: Alignment.center,
            ),
          ),

          // ── 半透明遮罩，提升文字可讀性 ──────────────────────
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),

          // ── 主內容 ───────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  const SizedBox(height: 50),

                  if (!_showStory) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: Text(
                        '經典的 2D 橫向射擊遊戲，消滅所有敵人來完成每一關\n收集分數並升級你的技能！',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),

                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const GameScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow, size: 28),
                          label: const Text(
                            '開始遊戲',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showStory = true;
                            });
                          },
                          icon: const Icon(Icons.info_outline, size: 28),
                          label: const Text(
                            '故事與操作',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              '故事簡介',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orangeAccent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orangeAccent.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '在一個被敵人占領的城市中，你作為一名勇敢的士兵，必須穿越重重危險，消滅所有敵人，拯救被俘虜的同伴，並完成每一關的任務。準備好迎接挑戰了嗎？',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.amberAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 6,
                                        color: Colors.black45,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(
                                        '操作方法',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.yellow,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildControlRow('A 鍵', '向左走'),
                                    _buildControlRow('D 鍵', '向右走'),
                                    _buildControlRow('W 鍵', '向上瞄準'),
                                    _buildControlRow('S 鍵', '蹲下'),
                                    _buildControlRow('K 鍵', '向上跳躍'),
                                    _buildControlRow('J 鍵', '開火射擊'),
                                    _buildControlRow('L 鍵', '丟手榴彈'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(
                                        '遊戲說明',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTipRow('🔴 紅色', '玩家（你）'),
                                    _buildTipRow('🔵 藍色方塊', '敵人'),
                                    _buildTipRow('💛 黃色圓點', '你的子彈'),
                                    _buildTipRow('💎 青色圓點', '敵人的子彈'),
                                    _buildTipRow('💣 黑色圓形', '手榴彈（會爆炸）'),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showStory = false;
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('返回主頁面'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow(String key, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(action, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Character? _selectedCharacter;
  bool _characterSelected = false;
  late final MetalSlugGame _game;

  @override
  void initState() {
    super.initState();
    _game = MetalSlugGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCharacterSelection();
    });
  }

  void _showCharacterSelection() async {
    final result = await Navigator.of(context).push<Character>(
      MaterialPageRoute(
        builder: (context) => const CharacterSelectScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCharacter = result;
        _characterSelected = true;
      });
      try {
        log('Main: triggering levelbgm play', name: 'Main');
        AudioManager().play('assets/audio/levelbgm.mp3').then((_) async {
          AudioManager().setLooping(true);
          try {
            await AudioManager().fadeIn(
              duration: const Duration(milliseconds: 800),
              targetVolume: 1.0,
            );
          } catch (e) {}
        }).catchError((e) {});
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_characterSelected) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.grey[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Metal Slug 2D Game - ${_selectedCharacter?.name ?? ''}',
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            GameWidget(game: _game),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: _game.scoreNotifier,
                      builder: (context, score, child) {
                        return Text(
                          '分數: $score',
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.brightness_5,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    ValueListenableBuilder<int>(
                      valueListenable: _game.grenadesAvailableNotifier,
                      builder: (context, value, child) {
                        return Text(
                          '手榴彈: $value',
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}