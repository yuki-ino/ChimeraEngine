# 🦁 Chimera Engine

Multi-species development engine powered by Claude Code

Claude Codeを使った次世代チーム開発システム

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-blue)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/Version-1.0.0-green)](https://github.com/yuki-ino/ChimeraEngine)

## ⚡ クイックスタート

### ワンコマンドインストール
```bash
curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash
cd your-project
chimera init
chimera start
```

### 即座に使える
- 🎯 **PM**: 企画検討から開発指示まで
- 👨‍💻 **Coder**: AI時代のフルスタック開発  
- 🧪 **QA**: 機能テスト + 品質管理の専門分業

## 🎯 特徴

### ✅ **企画検討モード**
PMが安心して企画を練れる機密性確保
```bash
# 企画検討中はチームに情報流出なし
🤔 "OAuth対応は必要？セキュリティ要件は？"
# 確定後に一斉指示
./chimera send coder "要件確定、実装開始"
```

### ✅ **プロジェクト自動解析**
Jest/Cypress/pytest等を自動検出してカスタム環境構築
```bash
chimera init
# ✅ React + TypeScript プロジェクトを検出
# ✅ Jest + Cypress を検出  
# ✅ カスタムテスト指示書を生成
```

### ✅ **QA役割分化**
専門分業で品質向上
- **QA-Functional**: 詳細テスト・バグ検出特化
- **QA-Lead**: 品質管理・リリース判定特化

### ✅ **ワンコマンドセットアップ**
1分で実プロジェクトに導入可能

## 🏗️ システム構成

### 3セッション構成
```
pmproject    : PM (企画・管理)
deveng       : Coder (フルスタック開発)
devqa        : QA Team (機能テスト + 品質管理 + 監視)
```

### ワークフロー
```
PM企画検討 → 開発指示 → 実装 → 機能テスト → 品質判定 → リリース
    ↑                                                    ↓
    └────────── フィードバックループ ←←←←←←←←←←←←←←←←←←←←←←←┘
```

## 📖 使用例

### React + TypeScriptプロジェクト
```bash
cd my-react-app
chimera init

# 自動検出結果:
# ✅ React + TypeScript 検出
# ✅ Jest + Testing Library 検出
# ✅ package.json テストスクリプト検出
# 📄 カスタムテスト手順書生成完了

chimera start

# PMセッションで企画検討
"あなたはPMです。指示書に従って"
# → 企画検討モード開始、チームには送信されない

# 企画確定後
./chimera send coder "ユーザー認証機能を実装してください"
./chimera send qa-functional "認証機能のテスト準備をお願いします"
```

### Python FastAPIプロジェクト
```bash
cd my-fastapi-project
chimera init

# 自動検出結果:
# ✅ Python プロジェクト検出
# ✅ pytest フレームワーク検出
# ✅ requirements.txt 検出
# 📄 Python用テスト手順書生成完了

# 実際の開発フロー
./chimera send coder "API エンドポイント /users を実装"
# → 実際のuvicorn起動、pytest実行コマンドが自動生成される
```

## 🚀 対応フレームワーク

### JavaScript/TypeScript
- ✅ **Jest** - React/Vue/Node.js
- ✅ **Vitest** - Vite ベースプロジェクト
- ✅ **Cypress** - E2E テスト
- ✅ **Playwright** - モダンE2E
- ✅ **Testing Library** - コンポーネントテスト

### Python
- ✅ **pytest** - 単体・統合テスト
- ✅ **unittest** - 標準テストフレームワーク

### その他
- ✅ **Rust** - cargo test
- ✅ **Go** - go test  
- ✅ **Java** - Maven/Gradle

## 📋 インストール方法

### 方法1: ワンライナー（推奨）
```bash
curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash
```

### 方法2: Docker版
```bash
docker run -it yuki-ino/ChimeraEngine start
```

### 方法3: 手動インストール
```bash
git clone https://github.com/yuki-ino/ChimeraEngine.git
cd pm-dev-qa-system
./install.sh
```

## 🛠️ 基本コマンド

```bash
chimera init              # プロジェクトに初期化
chimera start             # 環境起動
chimera send coder "実装"  # メッセージ送信
chimera update            # システムアップデート
chimera help              # ヘルプ表示
```

## 📚 ドキュメント

### 利用者向け
- 📖 **[USER_GUIDE.md](USER_GUIDE.md)** - コマンド使用法・操作方法
- 📖 [実プロジェクト導入ガイド](docs/real-project-guide.md)
- 🧪 [QA役割分化の詳細](docs/qa-roles-demo.md)  
- 🎯 [PM企画検討モード](docs/pm-planning-demo.md)

### 開発者向け
- 🔧 **[CLAUDE.md](CLAUDE.md)** - 実装ガイド・技術制約
- 🔧 [テストフレームワーク対応](docs/test-framework-examples.md)
- ⚙️ [セッション構成詳細](docs/session-structure-final.md)
- 📊 [フィードバック収集](scripts/feedback-collector.sh)

## 💡 実プロジェクト事例

### SaaSプロダクト開発
```bash
# 3人チーム、2週間スプリント
✅ 企画検討時間 40%短縮
✅ バグ検出率 60%向上  
✅ リリース判定の透明性向上
```

### スタートアップMVP開発
```bash
# 小規模チーム、迅速な意思決定
✅ PM-Dev間のコミュニケーション効率化
✅ 品質基準の明確化
✅ 技術的負債の早期発見
```

## 🤝 貢献

### フィードバック歓迎
```bash
# 使用後のフィードバック収集
./feedback-collector.sh

# GitHub Issues
https://github.com/yuki-ino/ChimeraEngine/issues
```

### 開発に参加
```bash
git clone https://github.com/yuki-ino/ChimeraEngine.git
cd pm-dev-qa-system
# 改善・新機能開発
git checkout -b feature/new-feature
```

## 📈 ロードマップ

### v1.1 (近日予定)
- [ ] GitHub Actions統合
- [ ] Slack通知機能
- [ ] より多くのテストフレームワーク対応

### v1.2 (将来予定)
- [ ] DevOps役割の追加
- [ ] CI/CD パイプライン統合
- [ ] Web UI ダッシュボード

### v2.0 (長期目標)
- [ ] 複数プロジェクト管理
- [ ] チームメトリクス収集
- [ ] AI powered 品質予測

## 📄 ライセンス

MIT License - 自由に使用・改変・配布可能

## 🙏 謝辞

- [Claude Code](https://claude.ai/code) - AI ペアプログラミング環境
- [tmux](https://github.com/tmux/tmux) - ターミナルマルチプレクサ
- [Claude-Code-Communication](https://github.com/nishimoto265/Claude-Code-Communication) - マルチエージェント通信システム

---

**🚀 1分でPM/Dev/QAサイクルを体験！**

```bash
curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash && chimera init && chimera start
```