import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:flame/game.dart';
import 'game/metal_slug_game.dart';
import 'screens/character_select_screen.dart';
import 'services/audio_manager.dart';

void main() {
  runApp(const MyApp()); // 啟動 Flutter 應用程式，根組件為 MyApp
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metal Slug Game', // 應用程式標題
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // 主題顏色
        useMaterial3: true, // 使用 Material3 風格
      ),
      home: const MainMenu(), // 首頁為 MainMenu
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState(); // 建立狀態
}

class _MainMenuState extends State<MainMenu> {
  bool _showStory = false; // 控制是否顯示故事與操作說明

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand, // 讓 Stack 撐滿整個 Scaffold body
        children: [
          // ── 背景圖：完整顯示，不截斷 ────────────────────────
          Positioned.fill(
            child: Image.asset(
              'background/mainBg.gif',
              fit: BoxFit.contain, // 完整顯示，不裁切
              alignment: Alignment.center,
            ),
          ),

          // ── 半透明遮罩，提升文字可讀性 ──────────────────────
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),

          // ── 主內容 ───────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [ 

                  if (!_showStory) ...[
                    // 首頁簡介與按鈕
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
                        // 開始遊戲按鈕
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
                        // 故事與操作按鈕
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
                    // 故事與操作說明頁面
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
                          // 故事標題
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
                          // 故事內容框
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
                              '在一個被敵人占領的城市中，你作為一名勇敢的士兵，必須穿越重重危險，消滅所有敵人，拯救被俘虜的同伴，並完成每一關的任務。準備好迎接挑戰了嗎？注意你只能失誤3次，碰到小兵、坦克、魔王都會扣血',
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

                          // 操作方法與遊戲說明分欄
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 操作方法標題
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
                                    // 操作按鍵列表
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
                                      // 遊戲說明標題
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
                                      // 遊戲道具與效果提示
                                      _buildTipRow('🔵 藍色方塊', '敵人，碰到會掉血'),
                                      _buildTipRow('💛 黃色圓點', '你的子彈，擊中敵人造成傷害'),
                                      _buildTipRow('💎 青色圓點', '敵人的子彈，碰到玩家會掉血'),
                                      _buildTipRow('💣 黑色圓形', '手榴彈（會爆炸，擊中敵人）'),
                                      _buildTipRow('H圖案', '機槍，撿起後可持續射擊'),
                                      _buildTipRow('💠 青色菱形', '戰利品：鑽石，+100 分數'),
                                      _buildTipRow('🍎 紅色水果', '戰利品：水果，+20 分數'),
                                      _buildTipRow('🐷 粉紅小豬', '戰利品：豬，+50 分數'),
                                      _buildTipRow('💩 棕色螺旋', '戰利品：便便，-10 分數'),
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
                    // 返回主頁面按鈕
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

  // 建立控制按鍵列
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
                fontSize:20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(action, style: const TextStyle(fontSize:20,color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 建立遊戲提示列
  Widget _buildTipRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20,color:Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize:20,color: Colors.white)),
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
  Character? _selectedCharacter; // 選中的角色
  bool _characterSelected = false; // 是否已選角色
  late final MetalSlugGame _game; // 遊戲核心物件

  @override
  void initState() {
    super.initState();
    _game = MetalSlugGame(); // 初始化遊戲
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCharacterSelection(); // 畫面建立後立即顯示角色選擇
    });
  }

  // 顯示角色選擇畫面
  void _showCharacterSelection() async {
    final result = await Navigator.of(context).push<Character>(
      MaterialPageRoute(
        builder: (context) => const CharacterSelectScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      // 依角色名稱判斷 index 並設定玩家顏色
      const charNames = ['comar', 'matar', 'ofi', 'ier'];
      final charIndex = charNames.indexOf(result.name);
      _game.setPlayerColor(charIndex >= 0 ? charIndex : 0);

      setState(() {
        _selectedCharacter = result;
        _characterSelected = true;
      });
      try {
        log('Main: triggering levelbgm play', name: 'Main');
        AudioManager().play('audio/levelbgm.mp3').then((_) async {
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
      // 尚未選角時顯示載入畫面
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
        Navigator.of(context).pop(); // 返回主選單
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Metal Slug 2D Game - ${_selectedCharacter?.name ?? ''}', // 顯示角色名稱
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            // ── 遊戲畫面 ────────────────────────────────
            GameWidget(
              game: _game..onReturnToMenu = () => Navigator.of(context).pop(),
            ),
            // ── HUD：左上角三列顯示 ─────────────────────
            Positioned(
              top: 10,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 愛心生命顯示
                  ValueListenableBuilder<int>(
                    valueListenable: _game.livesNotifier,
                    builder: (context, lives, child) {
                      return Row(
                        children: List.generate(3, (i) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            i < lives ? Icons.favorite : Icons.favorite_border,
                            color: i < lives ? Colors.red : Colors.grey,
                            size: 24,
                          ),
                        )),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  // 彈藥列（手榴彈與子彈）
                  Row(
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: _game.grenadesAvailableNotifier,
                        builder: (context, grenades, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Grenade  x$grenades',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              )),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<String>(
                        valueListenable: _game.ammoNotifier,
                        builder: (context, ammo, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Ammo  $ammo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              )),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 分數顯示
                  ValueListenableBuilder<int>(
                    valueListenable: _game.scoreNotifier,
                    builder: (context, score, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Score  $score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}