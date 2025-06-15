# Chimera Engine メモリシステムガイド

## 概要

Chimera Engineのメモリシステムは、Claude Codeの`--memory-dir`機能を活用して、プロジェクトごとに動的にエージェントの役割を定義できる仕組みです。

## 主な機能

### 1. 動的役割定義
- プロジェクトの特性に応じてエージェントの振る舞いをカスタマイズ
- 言語、フレームワーク、ビジネスルールなどを柔軟に設定
- 既存の静的役割定義をベースに拡張可能

### 2. プロジェクトコンテキスト
- プロジェクト固有の情報を一元管理
- 全エージェントが共通のコンテキストを参照
- プロジェクトの進行に応じて更新可能

### 3. 学習と記憶
- 過去の決定事項を記録
- チームの作業パターンを学習
- プロジェクト固有のベストプラクティスを蓄積

## セットアップ

### 初期セットアップ

```bash
# プロジェクトにChimera Engineを初期化（メモリシステムも自動で初期化されます）
chimera init

# または、既存プロジェクトでメモリシステムのみ初期化
chimera memory init
```

### プロジェクトコンテキストの設定

```bash
# インタラクティブモードで設定
chimera memory configure

# または、パラメータを指定
chimera memory configure --project "E-commerce Platform"
```

### エージェント役割のカスタマイズ

```bash
# PMの言語設定を日本語に変更
chimera memory update-role pm PROJECT_LANGUAGE=Japanese FORMALITY_LEVEL=Casual

# 開発者の技術スタックを更新
chimera memory update-role coder PRIMARY_LANGUAGE=Python FRAMEWORKS="Django, React"

# QAの品質基準を設定
chimera memory update-role qa-lead RELEASE_STANDARDS="Zero Bugs" COVERAGE_GOALS="95%"
```

## ディレクトリ構造

```
.chimera/
└── memory/
    ├── agent-roles/            # 各エージェントの動的役割定義
    │   ├── pm-role.md
    │   ├── coder-role.md
    │   ├── qa-functional-role.md
    │   ├── qa-lead-role.md
    │   └── monitor-role.md
    ├── project-context.md      # プロジェクト全体のコンテキスト
    ├── decisions/              # 意思決定の履歴
    ├── patterns/               # 発見されたパターン
    └── team-dynamics/          # チームの作業傾向
```

## 使用例

### 例1: 日本語プロジェクトの設定

```bash
# プロジェクトコンテキストを日本語に設定
chimera memory configure
# プロジェクト名: ECサイト
# プロジェクトタイプ: Webアプリケーション
# 主要言語: TypeScript
# フレームワーク: Next.js, NestJS

# PMを日本語モードに設定
chimera memory update-role pm PROJECT_LANGUAGE=Japanese

# 起動
chimera start
```

### 例2: 技術スタックの変更

```bash
# Pythonプロジェクトへの対応
chimera memory update-role coder \
    PRIMARY_LANGUAGE=Python \
    FRAMEWORKS="FastAPI, Vue.js" \
    DATABASE=MongoDB \
    TEST_STRATEGY=pytest

# QAツールも合わせて更新
chimera memory update-role qa-functional \
    TEST_TOOLS="pytest, Selenium" \
    COVERAGE_GOALS="90%"
```

### 例3: プロジェクトフェーズごとの調整

```bash
# 開発フェーズ
chimera memory update-role pm PROJECT_PHASE=Development

# リリース準備フェーズ
chimera memory update-role pm PROJECT_PHASE=Release
chimera memory update-role qa-lead RISK_TOLERANCE=Very-Low
```

## 高度な使用方法

### メモリのエクスポート/インポート

```bash
# 現在の設定をエクスポート
chimera memory export my-project-memory.tar.gz

# 別のプロジェクトで設定をインポート
chimera memory import my-project-memory.tar.gz
```

### カスタム属性の追加

役割定義ファイルに独自の属性を追加できます：

```markdown
# .chimera/memory/agent-roles/pm-role.md に追加

### Custom Attributes
- Sprint Duration: ${SPRINT_DURATION:-2 weeks}
- Standup Time: ${STANDUP_TIME:-10:00 AM}
- Retrospective Frequency: ${RETRO_FREQUENCY:-Every Sprint}
```

### プロジェクト固有のパターン記録

```bash
# パターンファイルを作成
echo "# コーディングパターン
- APIエンドポイントは必ずRESTful設計に従う
- エラーハンドリングは共通フォーマットを使用
" > .chimera/memory/patterns/coding-patterns.md
```

## ベストプラクティス

1. **プロジェクト開始時に設定**
   - 最初にプロジェクトコンテキストを設定
   - チームメンバーの好みに合わせて役割を調整

2. **定期的な更新**
   - プロジェクトフェーズの変更時に更新
   - 学んだ教訓を記録

3. **チーム間での共有**
   - メモリ設定をバージョン管理に含める
   - チームメンバー間で設定を共有

4. **段階的な調整**
   - 最初は基本設定から開始
   - プロジェクトの進行に応じて詳細化

## トラブルシューティング

### メモリが読み込まれない場合

```bash
# メモリディレクトリの確認
ls -la .chimera/memory/

# セッションの再起動
tmux kill-session -t chimera-workspace
chimera start
```

### 設定が反映されない場合

```bash
# 現在の設定を確認
chimera memory show

# Claude Codeの再起動が必要な場合
# 各ペインでCtrl+Cを押してClaude Codeを終了し、再度起動
```

## まとめ

メモリシステムにより、Chimera Engineは単なるマルチエージェントシステムから、プロジェクトに適応する知的なチームへと進化します。各プロジェクトの特性に合わせて最適な開発環境を構築できます。