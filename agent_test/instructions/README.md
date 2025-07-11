# 📋 Chimera Engine - 指示書ディレクトリ

## 🎯 統一5エージェントシステム指示書

このディレクトリには、Chimera Engineの統一5エージェントシステム用の指示書が含まれています。

### 📁 現在の指示書（6ファイル）

| ファイル | エージェント | 役割 | 連携先 |
|---------|-------------|------|--------|
| `pm-improved.md` | PM | プロダクトマネージャー | 全エージェント |
| `coder.md` | Coder | フルスタック開発者 | QA-Functional, Monitor |
| `qa-functional.md` | QA-Functional | 機能テスト担当 | Coder, QA-Lead, Monitor |
| `qa-lead.md` | QA-Lead | 品質管理・リリース判定 | 全エージェント |
| `monitor.md` | Monitor | 監視・レポート担当 | 状況レポート作成 |
| `AGENT_FLOW_GUIDE.md` | - | エージェント間連携ガイド | - |

### 🔄 自律的な連携フロー

```
🎯 PM (企画確定)
    ↓ 一斉指示
👨‍💻 Coder (実装) → 🧪 QA-Functional (テスト) → 👑 QA-Lead (品質判定)
    ↓                    ↓                      ↓
    📊 Monitor による全工程監視・レポート作成
```

### ✅ 完了した改善項目

1. **Monitor エージェント指示書を新規作成**
   - 全エージェントの監視とレポート機能
   - リアルタイム状態確認
   - エラー検出と仲介機能

2. **レガシー指示書を完全削除**（5ファイル）
   - `president.md` - 旧階層システム用
   - `boss.md` - 旧階層システム用
   - `worker.md` - 旧階層システム用
   - `pm.md` - 旧PM指示書
   - `tester.md` - 旧テスター指示書

3. **エージェント間連携を統一・強化**
   - 各エージェントが完了時に次のエージェントに自動通知
   - Monitorによる全工程の状況把握
   - 明確な完了報告フローの確立

4. **自律的な完了報告フローを明確化**
   - バグ発見時の自動修正サイクル
   - 品質判定結果の全体通知
   - プロジェクト完了時の総括レポート

### 🚀 使用方法

#### プロジェクト開始
```bash
# PM企画確定後の統一指示
chimera send pm-self "START_DEVELOPMENT"
```

#### 自動連携フロー
1. **PM** → 全エージェントに開始指示
2. **Coder** → 実装完了後、QA-Functionalに自動通知
3. **QA-Functional** → テスト完了後、QA-Leadに自動通知
4. **QA-Lead** → 品質判定後、全体に結果通知
5. **Monitor** → 全工程を監視し、最終レポート作成

### 📊 システムの特徴

- **完全自律**: PMの初期指示後、手動介入不要
- **透明性**: Monitor による全工程の可視化
- **品質保証**: 多段階チェックと自動フィードバック
- **エラー処理**: バグ発見時の自動修正サイクル
- **拡張性**: 新エージェント追加が容易

### 🔄 修正フィードバックループ

バグ発見時は自動的に修正サイクルが継続：
```
QA-Functional (バグ発見) → Coder (修正) → QA-Functional (再テスト) → QA-Lead (再判定)
```

### 📝 注意事項

- 各指示書は統一5エージェントシステム専用
- レガシーシステム（president-boss-worker）の指示書は削除済み
- エージェント間の連携は `chimera send` コマンドで自動実行
- Monitor エージェントが全体の進捗を管理・レポート

### 🎯 成功パターン

理想的な実行例：約30分で完全自律実行
- PM企画確定（5分）→ Coder実装（15分）→ QA-Functional テスト（10分）→ QA-Lead判定（5分）→ 完了

詳細なフローは `AGENT_FLOW_GUIDE.md` を参照してください。