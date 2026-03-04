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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ), // 主題顏色
        scaffoldBackgroundColor: const Color(0xFF0F1118),
        useMaterial3: true, // 使用 Material3 風格
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xCC121521),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 760;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand, // 讓 Stack 撐滿整個 Scaffold body
        children: [
          // ── 背景圖：完整顯示，不截斷 ────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/background/mainBg.gif',
              fit: BoxFit.cover, // 覆蓋畫面
              alignment: Alignment.center,
            ),
          ),

          // ── 半透明遮罩，提升文字可讀性 ──────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.78),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // ── 主內容 ───────────────────────────────────────────
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_showStory) ...[
                        Text(
                          'METAL SLUG 2D',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: isNarrow ? double.infinity : 680,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.46),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.orangeAccent.withOpacity(0.7),
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.42),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Text(
                            '經典 2D 橫向射擊，穿越戰場、消滅敵人並完成任務。\n收集分數與武器，挑戰你的操作極限！',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Wrap(
                          spacing: 16,
                          runSpacing: 14,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildMenuButton(
                              label: '開始遊戲',
                              icon: Icons.play_arrow_rounded,
                              background: const Color(0xFFE53935),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const GameScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuButton(
                              label: '故事與操作',
                              icon: Icons.menu_book_rounded,
                              background: const Color(0xFF1E88E5),
                              onPressed: () {
                                setState(() {
                                  _showStory = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: EdgeInsets.all(isNarrow ? 18 : 24),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.lightBlueAccent.withOpacity(0.65),
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  '故事與操作',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.lightBlueAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.32),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orangeAccent.withOpacity(0.6),
                                  ),
                                ),
                                child: Text(
                                  '在被敵軍佔領的城市中，你是唯一能突破重圍的士兵。擊退小兵、坦克與魔王，救回同伴並完成每一關任務。注意生命只有 3 次，任何碰撞都可能讓你倒下。',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.amber.shade100,
                                        height: 1.45,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 900;
                                  final controlsColumn = Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.28),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.yellow.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Text(
                                            '操作方法',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: Colors.yellow,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        _buildControlRow('←', '向左移動'),
                                        _buildControlRow('→', '向右移動'),
                                        _buildControlRow('↑', '向上瞄準'),
                                        _buildControlRow('↓', '蹲下'),
                                        _buildControlRow('K', '跳躍'),
                                        _buildControlRow('J', '射擊'),
                                        _buildControlRow('L', '手榴彈'),
                                      ],
                                    ),
                                  );

                                  final tipsColumn = Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.28),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.greenAccent.withOpacity(
                                          0.45,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Text(
                                            '遊戲說明',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: Colors.greenAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        _buildTipRow('🔵 藍色方塊', '敵人，碰到會扣血'),
                                        _buildTipRow('💛 黃色圓點', '你的子彈，會造成傷害'),
                                        _buildTipRow('💎 青色圓點', '敵方子彈，碰到會扣血'),
                                        _buildTipRow('💣 黑色圓形', '手榴彈，可造成範圍爆炸'),
                                        _buildTipRow('H 圖案', '機槍，撿起後可連射'),
                                        _buildTipRow('💠 青色菱形', '鑽石 +100 分'),
                                        _buildTipRow('🍎 紅色水果', '水果 +20 分'),
                                        _buildTipRow('🐷 粉紅小豬', '小豬 +50 分'),
                                        _buildTipRow('💩 棕色螺旋', '便便 -10 分'),
                                      ],
                                    ),
                                  );

                                  if (compact) {
                                    return Column(
                                      children: [
                                        controlsColumn,
                                        const SizedBox(height: 14),
                                        tipsColumn,
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: controlsColumn),
                                      const SizedBox(width: 16),
                                      Expanded(child: tipsColumn),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildMenuButton(
                          label: '返回主頁面',
                          icon: Icons.arrow_back_rounded,
                          background: const Color(0xFF5E6374),
                          onPressed: () {
                            setState(() {
                              _showStory = false;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String label,
    required IconData icon,
    required Color background,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: Colors.white,
        minimumSize: const Size(200, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
      ),
    );
  }

  // 建立控制按鍵列
  Widget _buildControlRow(String key, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              key,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 建立遊戲提示列
  Widget _buildTipRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 108),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              icon,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
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

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  Character? _selectedCharacter; // 選中的角色
  bool _characterSelected = false; // 是否已選角色
  late final MetalSlugGame _game; // 遊戲核心物件

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = MetalSlugGame(); // 初始化遊戲
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCharacterSelection(); // 畫面建立後立即顯示角色選擇
    });
  }

  Future<void> _stopLevelBgm() async {
    try {
      await AudioManager().stop();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopLevelBgm();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLevelBgm();
    super.dispose();
  }

  // 顯示角色選擇畫面
  void _showCharacterSelection() async {
    final result = await Navigator.of(context).push<Character>(
      MaterialPageRoute(
        builder: (context) => const CharacterSelectScreen(),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;

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
        AudioManager()
            .play('assets/audio/levelbgm.mp3')
            .then((_) async {
              AudioManager().setLooping(true);
              try {
                await AudioManager().fadeIn(
                  duration: const Duration(milliseconds: 800),
                  targetVolume: 1.0,
                );
              } catch (e) {}
            })
            .catchError((e) {});
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_characterSelected) {
      // 尚未選角時顯示載入畫面
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/background/mainBg.gif', fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.68)),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        await _stopLevelBgm();
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
            onPressed: () {
              _stopLevelBgm();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Stack(
          children: [
            // ── 遊戲畫面 ────────────────────────────────
            GameWidget(
              game: _game
                ..onReturnToMenu = () {
                  _stopLevelBgm();
                  Navigator.of(context).pop();
                },
            ),
            // ── HUD：左上角三列顯示 ─────────────────────
            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: _game.livesNotifier,
                        builder: (context, lives, child) {
                          return Row(
                            children: List.generate(
                              3,
                              (i) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  i < lives
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: i < lives
                                      ? const Color(0xFFFF5252)
                                      : Colors.white54,
                                  size: 22,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ValueListenableBuilder<int>(
                            valueListenable: _game.grenadesAvailableNotifier,
                            builder: (context, grenades, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  '💣 x$grenades',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          ValueListenableBuilder<String>(
                            valueListenable: _game.ammoNotifier,
                            builder: (context, ammo, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  'Ammo $ammo',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<int>(
                        valueListenable: _game.scoreNotifier,
                        builder: (context, score, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              'Score $score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
