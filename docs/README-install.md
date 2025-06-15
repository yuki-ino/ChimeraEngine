# 🚀 PM/Dev/QA System - インストールガイド

## ⚡ クイックインストール（推奨）

### ワンライナーでインストール
```bash
curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash
```

### 即座に使い始める
```bash
# どこでも実行可能
chimera init      # プロジェクトに初期化
chimera start     # 環境起動
```

---

## 📦 インストール方法一覧

### 1. 🌐 オンラインインストール（推奨）
```bash
# curl版
curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash

# wget版  
wget -qO- https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash

# カスタムディレクトリ
PMDEVQA_DIR=/opt/chimera curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash
```

### 2. 🐳 Docker版（最も簡単）
```bash
# イメージをpull
docker pull yuki-ino/ChimeraEngine

# 即座に開始
docker run -it --name chimera yuki-ino/ChimeraEngine start

# 別ターミナルでtmuxに接続
docker exec -it chimera tmux attach-session -t chimera-workspace
```

### 3. 📁 ローカルクローン版
```bash
git clone https://github.com/yuki-ino/ChimeraEngine.git
cd chimera
./install.sh
```

### 4. 🔧 手動インストール
```bash
mkdir -p ~/.chimera
cd ~/.chimera
curl -O https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/setup-chimera.sh
curl -O https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/chimera-send.sh
chmod +x *.sh
```

---

## 🎯 使用方法

### 基本コマンド
```bash
chimera help              # ヘルプ表示
chimera init              # プロジェクトに初期化
chimera start             # 環境起動
chimera send coder "実装" # メッセージ送信
chimera update            # アップデート
```

### 典型的なワークフロー
```bash
# 1. 新しいプロジェクトで
cd my-project
chimera init

# 2. PM/Dev/QA環境を起動
chimera start

# 3. Claude Code起動（別ターミナル）
for i in {0..4}; do tmux send-keys -t chimera-workspace:0.$i 'claude --dangerously-skip-permissions' C-m; done

# 4. デモ実行
chimera send pm "あなたはPMです。指示書に従って"
```

---

## 🔧 詳細設定

### 環境変数
```bash
export PMDEVQA_DIR="$HOME/my-chimera"    # インストールディレクトリ
export PMDEVQA_PROJECT_ID="project1"    # プロジェクトID
```

### エイリアス設定
```bash
# .bashrc/.zshrcに追加
alias pq='chimera'
alias pqs='chimera send'
alias pqstart='chimera start'

# 使用例
pq init
pqs coder "実装開始"
```

---

## 🌟 高度な使い方

### プロジェクトテンプレート化
```bash
# テンプレート作成
mkdir chimera-template
cd chimera-template
chimera init
# instructions/*.md をカスタマイズ
git init && git add . && git commit -m "PM/Dev/QA template"

# 新プロジェクトで再利用
git clone chimera-template new-project
cd new-project
chimera start
```

### CI/CDとの統合
```bash
# .github/workflows/chimera.yml
name: PM/Dev/QA Demo
on: [push]
jobs:
  demo:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install PM/Dev/QA
        run: curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash
      - name: Run Demo
        run: chimera start
```

### Docker Compose版
```yaml
# docker-compose.yml
version: '3.8'
services:
  chimera:
    image: yuki-ino/ChimeraEngine
    command: start
    volumes:
      - .:/workspace
    tty: true
    stdin_open: true
```

---

## 🛠️ トラブルシューティング

### 依存関係のインストール

#### macOS
```bash
# Homebrew
brew install tmux git curl

# MacPorts
sudo port install tmux git curl
```

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install tmux git curl
```

#### CentOS/RHEL
```bash
sudo yum install tmux git curl
# または
sudo dnf install tmux git curl
```

### よくある問題

#### tmuxセッションが作成できない
```bash
# tmuxサーバーをリセット
tmux kill-server
chimera start
```

#### 権限エラー
```bash
# ユーザーディレクトリにインストール
PMDEVQA_DIR=$HOME/bin/chimera curl -sSL ... | bash
```

#### パスが通らない
```bash
# 手動でPATH追加
export PATH="$HOME/.chimera:$PATH"
# または
echo 'export PATH="$HOME/.chimera:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## 🗑️ アンインストール

```bash
# ファイル削除
rm -rf ~/.chimera

# PATH設定削除（.bashrc/.zshrcを編集）
# CHIMERA関連の行を削除

# tmuxセッション削除
tmux kill-session -t chimera-workspace 2>/dev/null
```

---

## 📚 詳細ドキュメント

- [実プロジェクト活用ガイド](real-project-guide.md)
- [フィードバック収集](feedback-collector.sh)
- [カスタマイズ方法](project-config.sh)

---

**🎉 1分でPM/Dev/QAサイクルを体験！**
```bash
curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash && chimera init && chimera start
```