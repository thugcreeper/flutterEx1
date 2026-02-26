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
      audioManager.play('audio/selectPlayer.mp3').then((_) {
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[900]!, Colors.grey[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // 標題和倒數計時
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '選擇你的角色',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _timeRemaining <= 10 ? Colors.red : Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '剩餘時間: $_timeRemaining 秒',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 角色選擇網格
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.75,
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
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color.fromRGBO(
                                character.color.red,
                                character.color.green,
                                character.color.blue,
                                0.8,
                              )
                            : Colors.black54,
                        border: Border.all(
                          color: isSelected ? Colors.yellow : character.color,
                          width: isSelected ? 4 : 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color.fromRGBO(
                                    character.color.red,
                                    character.color.green,
                                    character.color.blue,
                                    0.5,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 使用圖片顯示角色
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              character.imagePath,
                              width: 250,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            character.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '已選擇',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 底部提示
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '點擊選擇角色，或等待倒數計時結束自動選擇第一個角色',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
