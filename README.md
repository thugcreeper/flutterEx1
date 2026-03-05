# Flutter Metal Slug 2D Shooter

這是一個使用 **Flutter + Flame** 製作的 2D 橫向動作射擊遊戲專案，包含主選單、角色選擇、關卡戰鬥、分數系統與音效管理。

專案核心目標是用 Flutter 建立可跨平台執行（Web / Android / iOS / Desktop）的遊戲原型，並透過模組化拆分讓你可以快速擴充角色、武器、敵人與關卡。

---

## 專案特色

- 🎮 Flame 驅動的 2D 遊戲迴圈與碰撞更新
- 🧍 角色選擇畫面（含倒數計時）
- 🔫 射擊、手榴彈、重武器與爆炸效果
- 👾 多種敵人類型（一般敵人 / 坦克 / Boss）
- 🏆 分數與戰利品系統
- 🔊 `just_audio` 音樂與音效播放（含淡入淡出切換）
- 🌐 Flutter 多平台專案結構（Android / iOS / Web / Windows / macOS / Linux）

---

## 技術棧

- **Framework**: Flutter
- **Game Engine**: Flame
- **Audio**: just_audio
- **Language**: Dart

---

## 專案資料結構

> 以下為主要目錄與核心檔案（省略平台自動產生檔案細節）：

```text
flutterEx1/
├── lib/
│   ├── main.dart                        # App 入口、主選單、故事與操作說明 UI
│   ├── screens/
│   │   └── character_select_screen.dart # 角色選擇畫面與倒數
│   ├── game/
│   │   ├── metal_slug_game.dart         # 遊戲主迴圈、場景、輸入、關卡流程
│   │   ├── Bullet.dart                  # 子彈邏輯
│   │   ├── Grenade.dart                 # 手榴彈邏輯
│   │   ├── Explosion.dart               # 爆炸效果
│   │   ├── HeavyWeapon.dart             # 重武器（撿取與使用）
│   │   ├── Enemy.dart                   # 一般敵人
│   │   ├── Tank.dart                    # 坦克敵人
│   │   ├── Boss.dart                    # Boss 敵人
│   │   ├── loot.dart                    # 戰利品與分數
│   │   └── Platform.dart                # 地形平台
│   └── services/
│       └── audio_manager.dart           # 音訊單例管理（播放/淡入淡出）
│
├── assets/
│   ├── images/                          # 角色圖片等
│   ├── background/                      # 背景圖/GIF
│   └── audio/                           # BGM 與音效
│       └── soundEffect/                 # 射擊、爆炸、拾取等 SFX
│
├── test/
│   └── widget_test.dart                 # Flutter 測試範例
│
├── pubspec.yaml                         # 套件與資源宣告
└── SETUP_GUIDE.md                       # 進一步設定與說明
```

---

## 遊戲流程簡介

1. 啟動 App 後進入主選單（可查看故事與操作說明）。
2. 進入角色選擇畫面，挑選角色進入關卡。
3. 在關卡中操作角色移動、射擊與投擲手榴彈。
4. 擊敗敵人、閃避攻擊並收集戰利品取得分數。
5. 推進關卡並挑戰更強敵人（如坦克與 Boss）。

---

## 鍵盤操作（預設）

| 按鍵 | 功能 |
|---|---|
| `←` | 向左移動 |
| `→` | 向右移動 |
| `↑` | 向上瞄準 |
| `↓` | 蹲下 |
| `K` | 跳躍 |
| `J` | 射擊 |
| `L` | 丟手榴彈 |

---

## 環境需求

- Flutter SDK（建議使用 stable channel）
- Dart SDK（隨 Flutter 安裝）
- 對應平台開發工具（Android Studio / Xcode / Chrome / Visual Studio 等）

可先用以下指令檢查環境：

```bash
flutter doctor
```

---

## 快速開始（簡易操作說明）

### 1) 安裝依賴

```bash
flutter pub get
```

### 2) 啟動遊戲（開發模式）

```bash
# 先查看可用裝置
flutter devices

# 例如在 Chrome 執行
flutter run -d chrome

# 或在 Windows 執行
flutter run -d windows
```

### 3) 執行測試

```bash
flutter test
```

### 4) 打包（可選）

```bash
# Android
flutter build apk

# Web
flutter build web
```

---

## 資源與設定注意事項

- 所有圖片、音檔都需在 `pubspec.yaml` 的 `flutter.assets` 區段宣告。
- 若你新增了 `assets/audio/...` 或 `assets/images/...` 檔案，請重新執行：

```bash
flutter pub get
```

- 音訊播放與淡入淡出邏輯集中於 `lib/services/audio_manager.dart`，建議所有音效切換都透過此服務管理，避免重複建立播放器實例。

---

## 推薦擴充方向

- 新增角色能力（衝刺、護盾、技能冷卻）
- 增加武器種類與子彈特效
- 做關卡資料化（JSON/Scriptable 設計）
- 加入存檔與排行榜（本地或雲端）
- 加入 UI/HUD 強化（血量、彈藥、任務提示）

---

## 參考文件

- Flutter: https://docs.flutter.dev/
- Flame: https://flame-engine.org/
- just_audio: https://pub.dev/packages/just_audio
- 專案內進階設定：`SETUP_GUIDE.md`

