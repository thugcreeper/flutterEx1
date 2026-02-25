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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[900]!, Colors.grey[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 遊戲標題
                Text(
                  'METAL SLUG',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Color.fromRGBO(Colors.red.red, Colors.red.green, Colors.red.blue, 1.0),
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Color.fromRGBO(Colors.red.red, Colors.red.green, Colors.red.blue, 0.5),
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '2D 射擊遊戲',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 50),

                if (!_showStory) ...[
                  // 遊戲描述
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

                  // 按鈕組
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
                        label: const Text('開始遊戲', style: TextStyle(fontSize: 18)),
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
                        label: const Text('故事與操作', style: TextStyle(fontSize: 18)),
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
                  // 故事和操作說明
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
                        // 故事
                        Center(
                          child: Text(
                            '故事簡介',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          '在一個被敵人占領的城市中，你作為一名勇敢的士兵，必須穿越重重危險，消滅所有敵人，拯救被俘虜的同伴，並完成每一關的任務。準備好迎接挑戰了嗎？(純AI唬爛))',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // 操作說明
                        Center(
                          child: Text(
                            '操作方法',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildControlRow('A 键', '向左走'),
                        _buildControlRow('D 键', '向右走'),
                        _buildControlRow('W 键', '向上瞄準'),
                        _buildControlRow('S 键', '蹲下'),
                        _buildControlRow('K 键', '向上跳躍'),
                        _buildControlRow('J 键', '開火射擊'),
                        _buildControlRow('L 键', '丟手榴彈'),
                        const SizedBox(height: 30),

                        // 遊戲說明
                        Center(
                          child: Text(
                            '遊戲說明',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildTipRow('🔴 紅色', '玩家（你）'),
                        _buildTipRow('🔵 藍色方塊', '敵人'),
                        _buildTipRow('💛 黃色圓點', '你的子彈'),
                        _buildTipRow('💎 青色圓點', '敵人的子彈'),
                        _buildTipRow('💣 黑色圓形', '手榴彈（會爆炸）'),
                        const SizedBox(height: 15),
                        Text(
                          '• 消滅所有敵人來完成關卡\n• 避免被敵人射擊的子彈擊中\n• 獲得分數來提升你的排名\n• 每關敵人會增加，難度會上升',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
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
      ),
    );
  }

  Widget _buildControlRow(String key, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            action,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 15),
          Text(
            text,
            style: const TextStyle(color: Colors.white),
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

  @override
  void initState() {
    super.initState();
    // 避免在 widget 建構期直接 push 導致路由堆疊問題，改為於首畫面幀後再觸發
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
      // 選角後由遊戲畫面負責播放關卡 BGM，這裡先啟動背景音樂
      try {
        log('Main: triggering levelbgm play', name: 'Main');
        AudioManager()
            .play('assets/audio/levelbgm.mp3')
            .then((_) async {
          AudioManager().setLooping(true);
          log('Main: setLooping true', name: 'Main');
          // fade in 音量，確保先前 fadeOut 不會讓新曲靜音
          try {
            await AudioManager().fadeIn(duration: const Duration(milliseconds: 800), targetVolume: 1.0);
            log('Main: fadeIn complete', name: 'Main');
          } catch (e) {
            log('Main: fadeIn error: $e', name: 'Main', error: e);
          }
        }).catchError((e) {
          log('Main: levelbgm play error: $e', name: 'Main', error: e);
        });
      } catch (e) {
        log('Main: levelbgm launch caught error: $e', name: 'Main', error: e);
      }
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
          child: const Center(
            child: CircularProgressIndicator(),
          ),
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
          title: Text('Metal Slug 2D Game - ${_selectedCharacter?.name ?? ''}'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: GameWidget(
          game: MetalSlugGame(),
        ),
      ),
    );
  }
}
