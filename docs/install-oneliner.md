# 🚀 PM/Dev/QA System - ワンコマンドインストール

## インストール方法

### 方法1: curl を使う場合
```bash
curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash
```

### 方法2: wget を使う場合
```bash
wget -qO- https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash
```

### 方法3: ローカルインストール（このリポジトリをclone済みの場合）
```bash
./install.sh
```

## インストール後の使い方

### 1. グローバルコマンドとして使う
```bash
# どこからでも実行可能
chimera help              # ヘルプ表示
chimera init              # プロジェクトに初期化
chimera start             # 環境起動
chimera send coder "タスク" # メッセージ送信
```

### 2. プロジェクトでの使用例
```bash
# 新規プロジェクトで使う
cd my-awesome-project
chimera init              # PM/Dev/QA設定をコピー
chimera start             # tmux環境を起動

# Claude Code起動後
chimera send pm "あなたはPMです。指示書に従って"
```

## カスタムインストール

### 特定のディレクトリにインストール
```bash
PMDEVQA_DIR=/opt/chimera curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash
```

### Docker版（さらに簡単に）
```bash
docker run -it --rm yuki-ino/ChimeraEngine
```

## アンインストール

```bash
# インストールしたファイルを削除
rm -rf ~/.chimera
# PATHから削除（.bashrc/.zshrcを編集）
```

## トラブルシューティング

### tmuxがない場合
```bash
# macOS
brew install tmux

# Ubuntu/Debian
sudo apt-get install tmux

# CentOS/RHEL
sudo yum install tmux
```

### 権限エラーの場合
```bash
# ユーザーディレクトリにインストール
PMDEVQA_DIR=$HOME/bin/chimera curl -sSL ... | bash
```

## 高度な使い方

### エイリアスで更に短縮
```bash
# .bashrc/.zshrcに追加
alias pq='chimera'
alias pqs='chimera send'

# 使用例
pq init
pqs coder "実装開始"
```

### プロジェクトテンプレートとして
```bash
# テンプレート作成
chimera init
vim instructions/*.md  # カスタマイズ
git add .
git commit -m "Add PM/Dev/QA template"

# 別プロジェクトで再利用
git clone template new-project
cd new-project
chimera start
```