import 'package:flutter/material.dart';
import 'dart:async';
import '../services/audio_manager.dart';

class Character {
  final String name;
  final Color color;
  final String imagePath;

  Character({required this.name, required this.color, required this.imagePath});
}

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  late AudioManager audioManager;
  int _timeRemaining = 30;
  int? _selectedCharacterIndex;
  late Timer _timer;

  final List<Character> characters = [
    Character(
      name: 'comar',
      color: Colors.red,
      imagePath: 'assets/images/player1.jpg',
    ),
    Character(
      name: 'matar',
      color: Colors.blue,
      imagePath: 'assets/images/player2.jpg',
    ),
    Character(
      name: 'ofi',
      color: Colors.green,
      imagePath: 'assets/images/player3.jpg',
    ),
    Character(
      name: 'ier',
      color: Colors.purple,
      imagePath: 'assets/images/player4.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    audioManager = AudioManager();
    _startGame();
  }

  void _startGame() async {
    // 先啟動倒數計時（避免被音樂或 await 阻塞）
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });

      // 時間到或已選擇角色
      if (_timeRemaining <= 0 || _selectedCharacterIndex != null) {
        if (_timer.isActive) _timer.cancel();
        _onCharacterSelected(_selectedCharacterIndex ?? 0);
      }
    });

    // 背景音樂非同步播放，若發生錯誤則不影響倒數
    try {
      audioManager.play('assets/audio/selectPlayer.mp3').then((_) {
        audioManager.setLooping(true);
      });
    } catch (e) {
      // 忽略音樂播放錯誤，不干擾選角流程
    }
  }

  void _onCharacterSelected(int index) {
    setState(() {
      _selectedCharacterIndex = index;
    });
    if (_timer.isActive) _timer.cancel();

    // 非同步淡出當前音樂，實際播放關卡背景音樂由遊戲畫面負責啟動
    audioManager
        .fadeOut(duration: const Duration(milliseconds: 800))
        .catchError((e) {});

    // 讓使用者能看見已選擇狀態，短暫延遲後立即返回選擇結果
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        Navigator.of(context).pop(characters[index]);
      }
    });
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = isLandscape ? 4 : 2;
    final progress = (_timeRemaining / 30).clamp(0.0, 1.0);
    final timerColor = _timeRemaining <= 10
        ? const Color(0xFFD32F2F)
        : const Color(0xFF1976D2);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background/mainBg.gif', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.72)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '選擇角色',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: timerColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_timeRemaining 秒',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: progress,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _timeRemaining <= 10
                                  ? const Color(0xFFFF8A80)
                                  : const Color(0xFF42A5F5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 12.0;
                        final rows = (characters.length / crossAxisCount)
                            .ceil();
                        final tileHeight =
                            (constraints.maxHeight - (rows - 1) * spacing) /
                            rows;

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                mainAxisExtent: tileHeight,
                              ),
                          itemCount: characters.length,
                          itemBuilder: (context, index) {
                            final character = characters[index];
                            final isSelected = _selectedCharacterIndex == index;

                            return GestureDetector(
                              onTap: () {
                                if (_selectedCharacterIndex == null) {
                                  _onCharacterSelected(index);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                transform: Matrix4.identity()
                                  ..scale(isSelected ? 1.01 : 1.0),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.42),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.yellowAccent
                                        : character.color.withOpacity(0.9),
                                    width: isSelected ? 2.8 : 1.6,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isSelected
                                                  ? character.color
                                                  : Colors.black)
                                              .withOpacity(
                                                isSelected ? 0.45 : 0.30,
                                              ),
                                      blurRadius: isSelected ? 14 : 8,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: Image.asset(
                                          character.imagePath,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.08),
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.6),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 6,
                                        right: 6,
                                        bottom: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.58,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              7,
                                            ),
                                          ),
                                          child: Text(
                                            character.name.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.7,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.yellowAccent,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: const Text(
                                              '已選擇',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
