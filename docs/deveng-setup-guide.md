# 🚀 DevEng セッション構成ガイド

## 📋 セッション名変更

### 新しい構成
```bash
chimera-workspace:0.0 : PM (プロダクトマネージャー)
chimera-workspace:0.1 : Coder (フルスタック開発者)
chimera-workspace:0.2 : QA-Functional (機能テスト担当)
chimera-workspace:0.3 : QA-Lead (品質管理・リリース判定)
chimera-workspace:0.4 : Monitor (ステータス監視)
```

### 変更点
- 統合された単一セッション`chimera-workspace`に変更
- 5ペイン構成でチーム全体を統合管理

## 🛠️ 使用方法

### 1. 環境構築
```bash
# Chimera版セットアップ
chimera start

# セッション確認
tmux list-sessions
# 出力例:
# chimera-workspace: 1 windows
```

### 2. Claude Code起動
```bash
# 全エージェント一括起動
for i in {0..4}; do tmux send-keys -t chimera-workspace:0.$i 'claude --dangerously-skip-permissions' C-m; done
```

### 3. セッションアタッチ
```bash
# Chimeraワークスペース確認
tmux attach-session -t chimera-workspace
```

### 4. メッセージ送信
```bash
# 新しいターゲット名で送信
chimera send coder "実装開始してください"
chimera send qa-functional "機能テスト準備お願いします"
chimera send qa-lead "品質計画策定してください"
chimera send monitor "プロジェクト状況監視開始"

# エージェント一覧確認
chimera send --list
```

## 📊 ペイン構成詳細

### tmux ペインレイアウト
```
┌─────────────────────────────────────┐
│                 PM                   │
│         (chimera-workspace:0.0)      │
├─────────────┬───────────────────────┤
│    Coder    │     QA-Functional     │
│ (pane 0.1)  │      (pane 0.2)       │
├─────────────┼──────────┬────────────┤
│   QA-Lead   │  Monitor │            │
│ (pane 0.3)  │(pane 0.4)│            │
└─────────────┴──────────┴────────────┘
```

### 各ペインの役割
- **chimera-workspace:0.0 (PM)**: プロダクトマネージャー・計画策定
- **chimera-workspace:0.1 (coder)**: フルスタック開発
- **chimera-workspace:0.2 (qa-functional)**: 機能テスト・バグ検出
- **chimera-workspace:0.3 (qa-lead)**: 品質管理・リリース判定
- **chimera-workspace:0.4 (monitor)**: プロジェクト監視・レポート

## 🔄 ワークフロー例

### 完全なフロー
```bash
# 1. PM企画・指示
chimera send coder "ログイン機能実装"
chimera send qa-functional "テスト準備"
chimera send qa-lead "品質計画策定"

# 2. 開発完了
chimera send qa-functional "実装完了、テスト開始可能"

# 3. 機能テスト
chimera send qa-lead "バグ発見、重要度評価お願いします"

# 4. 品質判定
chimera send pm "最終品質判定：リリース承認"
```

## 💡 Chimera Engine の構成

### Chimera = 統合された多機能システム
- **PM**: プロダクト管理・計画策定
- **Coder**: フルスタック開発・実装
- **QA-Functional**: 機能テスト・品質検証
- **QA-Lead**: 品質管理・リリース判定
- **Monitor**: プロジェクト監視・状況報告

### 統合ワークスペースの利点
```bash
# 従来: 分散セッション
→ pmproject + devqa の2セッション管理

# Chimera: 統合ワークスペース
→ chimera-workspace の単一セッション管理
→ 全エージェントが同じ環境で連携
```

これで**Chimera Engine**として、統合された多機能エンジニアリングシステムになりました！