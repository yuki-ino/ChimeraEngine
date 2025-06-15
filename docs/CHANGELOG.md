# Changelog

All notable changes to the Chimera Engine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-20

### Added
- 🎯 **PM企画検討モード**: PMが安心して企画を練れる機密性確保機能
- 👨‍💻 **フルスタック開発者対応**: AI時代に適した1人でFrontend/Backend/Mobile対応
- 🧪 **QA役割分化**: 機能テスト担当とQA総合判定担当の専門分業
- 🔍 **プロジェクト自動解析**: Jest/Cypress/pytest等の自動検出
- 📖 **カスタムテストマニュアル生成**: プロジェクトに最適化されたテスト手順書
- ⚡ **ワンコマンドインストール**: `curl | bash` での簡単導入
- 🏗️ **3セッション構成**: pmproject/deveng/devqa の分離設計

### Core Features
- **PM Mode Controller**: 企画検討と開発指示の段階的管理
- **Project Analyzer**: 20以上のテストフレームワーク自動検出
- **Test Manual Generator**: プロジェクト固有のテスト指示書生成
- **Agent Communication**: tmuxベースのエージェント間メッセージング
- **Feedback Collector**: 使用経験のフィードバック収集システム

### Supported Frameworks
#### JavaScript/TypeScript
- Jest (React/Vue/Node.js)
- Vitest (Vite based projects)
- Cypress (E2E testing)
- Playwright (Modern E2E)
- Testing Library (Component testing)
- Mocha/Chai

#### Python
- pytest (Unit/Integration testing)
- unittest (Standard testing framework)

#### Other Languages
- Rust (cargo test)
- Go (go test)
- Java (Maven/Gradle)

### Scripts
- `install.sh`: ワンコマンドインストーラー
- `setup-chimera.sh`: 3セッション環境構築
- `chimera-send.sh`: エージェント間通信
- `project-analyzer.sh`: プロジェクト解析
- `test-manual-generator.sh`: テストマニュアル生成
- `pm-mode-controller.sh`: PM作業モード管理
- `feedback-collector.sh`: フィードバック収集

### Documentation
- Comprehensive README.md with usage examples
- Real project integration guide
- QA role separation details
- PM planning mode documentation
- Test framework support examples
- Session structure documentation

### Files Structure
```
pmproject/     - PM (Product Manager)
deveng/        - Coder (Full-stack Developer)  
devqa:0.0      - QA-Functional (Feature Testing)
devqa:0.1      - QA-Lead (Quality Management)
devqa:0.2      - Monitor (Status Monitoring)
```

### Workflow
```
PM企画検討 → 開発指示 → 実装 → 機能テスト → 品質判定 → リリース
    ↑                                                    ↓
    └────────── フィードバックループ ←←←←←←←←←←←←←←←←←←←←←←←┘
```

## [Unreleased]

### Planned Features
- GitHub Actions integration
- Slack notification support
- More test framework support
- DevOps role addition
- CI/CD pipeline integration
- Web UI dashboard

---

## Version History

- **v1.0.0**: Initial release with core PM/Dev/QA workflow
- **v0.x.x**: Development and testing phases

## Migration Guide

### From Original Demo System
```bash
# 従来のシステムからの移行
cp instructions/pm.md instructions/pm-original.md
cp instructions/pm-improved.md instructions/pm.md
./setup-chimera.sh
```

## Support

- 📖 [Documentation](README.md)
- 🐛 [Bug Reports](https://github.com/yuki-ino/ChimeraEngine/issues)
- 💡 [Feature Requests](https://github.com/yuki-ino/ChimeraEngine/issues)
- 🤝 [Contributing](CONTRIBUTING.md)