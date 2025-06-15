# 🎭 Agent Role Recognition Guide

## 概要

Chimera Engineでは、各エージェントが自分の役割を明確に理解するための自動化された身元確認・役割認識システムを提供しています。これにより、参考記事の「You are Agent n. Read MULTI_AGENT_PLAN.md」問題を完全自動化で解決します。

## 🚀 自動役割認識システム

### システム起動時の自動実行

```bash
# Chimera Engine起動時に自動的に実行される
chimera start
```

起動時に各エージェントに以下のメッセージが自動送信されます：

```
🎭 **エージェント身元確認・役割認識**

**あなたは Agent 1 - Product Manager です。**

## 📋 現在の状況
- 時刻: 2024-12-14 15:30:45
- コンテキスト: 🚀 システム起動時の初期化中です。
- CHIMERA_PLAN.md: 利用可能

## 🎯 あなたの役割と責任
担当: 全体管理、要件定義、進捗監視。現在のスプリント目標と全体進捗を確認してください。

## 📚 必須確認事項
1. **CHIMERA_PLAN.mdを読み込み**: 必ずCHIMERA_PLAN.mdを読み込んで最新の状況を把握してください。
2. **自分のタスクを特定**: 待機中・実行中のタスクを確認
3. **現在の状況を把握**: プロジェクト全体の進捗を理解
4. **準備完了を報告**: 「Agent 1 - Product Manager 準備完了」と報告

## ⚡ 今すぐ実行してください
1. CHIMERA_PLAN.mdを読み込んで内容を確認
2. 「私はAgent 1 - Product Managerです。CHIMERA_PLAN.mdを確認しました。」と応答
3. 自分に関連するタスクがあれば状況を報告
```

## 🎯 エージェント別役割定義

### Agent 1 - Product Manager (PM)
- **身元**: Agent 1 - Product Manager
- **役割**: プロダクトマネージャー - プロジェクト全体の統括管理
- **責任**: 要件定義、タスク管理、進捗監視、品質判定
- **コンテキスト**: CHIMERA_PLAN.md、全エージェント状況、プロジェクト目標

### Agent 2 - Full-Stack Developer (Coder)
- **身元**: Agent 2 - Full-Stack Developer
- **役割**: フルスタック開発者 - 機能実装とコード作成
- **責任**: 実装、コーディング、技術的決定、成果物作成
- **コンテキスト**: CHIMERA_PLAN.md、技術仕様、実装タスク

### Agent 3 - Functional QA Specialist (QA-Functional)
- **身元**: Agent 3 - Functional QA Specialist
- **役割**: 機能テスト専門家 - 個別機能の詳細テスト
- **責任**: 機能テスト、バグ検出、テストケース作成
- **コンテキスト**: CHIMERA_PLAN.md、実装状況、テスト対象

### Agent 4 - QA Lead & Release Manager (QA-Lead)
- **身元**: Agent 4 - QA Lead & Release Manager
- **役割**: QAリード - 品質管理とリリース判定
- **責任**: 品質基準管理、最終承認、リリース判定
- **コンテキスト**: CHIMERA_PLAN.md、全テスト結果、品質メトリクス

### Agent 5 - System Monitor & Reporter (Monitor)
- **身元**: Agent 5 - System Monitor & Reporter
- **役割**: システムモニター - 状況監視と報告
- **責任**: 進捗監視、状況報告、システム健康度チェック
- **コンテキスト**: CHIMERA_PLAN.md、全エージェント活動、システム状態

## 🛠️ 手動コマンド

### 個別エージェント役割認識
```bash
# 特定のエージェントに役割認識メッセージを送信
chimera send role-recognition pm
chimera send role-recognition coder
chimera send role-recognition qa-functional
```

### 全エージェント役割認識
```bash
# 全エージェントに一括で役割認識メッセージを送信
chimera send role-recognition-all
```

### プロジェクト初期化（推奨）
```bash
# 新規プロジェクト開始時
chimera send project-init "ユーザー認証システム" "ログイン・登録機能の実装"
```

### 身元確認状態チェック
```bash
# 全エージェントの身元確認状態を確認
chimera send identity-status
```

### 緊急時の全エージェント再認識
```bash
# エージェントが混乱した場合の緊急処理
chimera send emergency-resync
```

## 📋 使用シーナリオ

### シナリオ1: 新規プロジェクト開始
```bash
# 1. プロジェクト初期化
chimera send project-init "ECサイト構築" "商品管理とカート機能の実装"

# 2. 身元確認状態チェック
chimera send identity-status

# 3. 必要に応じて個別再送信
chimera send role-recognition coder
```

### シナリオ2: 既存プロジェクトに参加
```bash
# 1. 全エージェント役割認識
chimera send role-recognition-all

# 2. 状態確認
chimera send identity-status
```

### シナリオ3: エージェントが混乱した場合
```bash
# 1. 緊急再同期
chimera send emergency-resync

# 2. 状態確認
chimera send identity-status

# 3. 個別対応（必要な場合）
chimera send role-recognition qa-lead
```

## 🔧 トラブルシューティング

### エージェントが応答しない
```bash
# 1. 健康状態チェック
chimera send health-check

# 2. 緊急再同期
chimera send emergency-resync

# 3. 個別役割認識
chimera send role-recognition <agent>
```

### CHIMERA_PLAN.mdが見つからない
```bash
# 1. プラン初期化
chimera send sync-plan

# 2. 役割認識再送信
chimera send role-recognition-all
```

### 複数エージェントが同じ役割を認識
```bash
# 1. 緊急再同期で全体リセット
chimera send emergency-resync

# 2. 個別に正しい役割を送信
chimera send role-recognition pm
chimera send role-recognition coder
```

## 🎯 参考記事との比較

| 項目 | 参考記事 | Chimera Engine |
|------|----------|----------------|
| **役割認識** | 手動「You are Agent n」 | **完全自動送信** |
| **プラン読み込み** | 手動「Read MULTI_AGENT_PLAN.md」 | **自動指示・確認** |
| **状態管理** | なし | **リアルタイム監視** |
| **エラー回復** | 手動再入力 | **自動再認識** |
| **身元確認** | なし | **24/7監視・記録** |

## 📈 メリット

1. **完全自動化**: 手動でのエージェント役割指定が不要
2. **確実性**: 各エージェントが必ずCHIMERA_PLAN.mdを読み込む
3. **回復力**: 混乱時の自動回復機能
4. **監視**: 身元確認状態のリアルタイム追跡
5. **効率性**: プロジェクト開始の大幅な時間短縮

この システムにより、参考記事の手動プロセスが完全自動化され、エージェントの役割認識に関する問題が根本的に解決されます。