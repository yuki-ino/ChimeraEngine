#!/bin/bash

# 🧠 Chimera Engine - メモリ管理システム
# 動的役割定義とプロジェクトコンテキストの管理

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/config.sh"

# メモリディレクトリのパス
MEMORY_DIR=".chimera/memory"
AGENT_ROLES_DIR="$MEMORY_DIR/agent-roles"
PROJECT_CONTEXT_FILE="$MEMORY_DIR/project-context.md"

# 使用方法表示
show_usage() {
    cat << EOF
🧠 Chimera メモリ管理システム

使用方法:
    $0 [command] [options]

コマンド:
    init              メモリ構造を初期化
    configure         プロジェクトコンテキストを設定
    update-role       特定エージェントの役割を更新
    show              現在の設定を表示
    export            設定をエクスポート
    import            設定をインポート

オプション:
    -h, --help        このヘルプを表示
    -v, --verbose     詳細なログ出力
    -p, --project     プロジェクト名を指定

例:
    $0 init
    $0 configure --project "E-commerce Platform"
    $0 update-role pm --language "Japanese"
    $0 show
EOF
}

# メモリ構造を初期化
init_memory() {
    log_info "メモリ構造を初期化中..."
    
    # ディレクトリ作成
    safe_mkdir "$MEMORY_DIR"
    safe_mkdir "$AGENT_ROLES_DIR"
    safe_mkdir "$MEMORY_DIR/decisions"
    safe_mkdir "$MEMORY_DIR/patterns"
    safe_mkdir "$MEMORY_DIR/team-dynamics"
    
    # 既存の静的役割定義から動的版を生成
    if [[ -d "instructions" ]]; then
        log_info "既存の役割定義から動的版を生成中..."
        
        # 各エージェントの役割定義をコピー
        for agent in pm coder qa-functional qa-lead monitor; do
            local static_file="instructions/${agent}.md"
            local dynamic_file="$AGENT_ROLES_DIR/${agent}-role.md"
            
            if [[ -f "$static_file" ]] && [[ ! -f "$dynamic_file" ]]; then
                log_debug "生成中: $dynamic_file"
                # 既に動的版を作成済みなのでスキップ
            fi
        done
    fi
    
    # プロジェクトコンテキストテンプレートの作成
    if [[ ! -f "$PROJECT_CONTEXT_FILE" ]]; then
        create_project_context_template
    fi
    
    log_success "メモリ構造の初期化完了"
}

# プロジェクトコンテキストテンプレート作成
create_project_context_template() {
    cat > "$PROJECT_CONTEXT_FILE" << 'EOF'
# Project Context

## Project Information
- **Name**: ${PROJECT_NAME:-Unnamed Project}
- **Type**: ${PROJECT_TYPE:-Software Development}
- **Phase**: ${PROJECT_PHASE:-Planning}
- **Start Date**: $(date +%Y-%m-%d)
- **Target Release**: ${TARGET_RELEASE_DATE:-TBD}

## Technical Context
- **Primary Language**: ${PRIMARY_LANGUAGE:-JavaScript}
- **Framework**: ${FRAMEWORK:-Not Specified}
- **Architecture**: ${ARCHITECTURE_STYLE:-Microservices}
- **Deployment Target**: ${DEPLOYMENT_TARGET:-Cloud}

## Business Context
- **Industry**: ${INDUSTRY:-Technology}
- **Target Users**: ${TARGET_USERS:-General Users}
- **Key Features**: ${KEY_FEATURES:-Core Features}
- **Success Metrics**: ${SUCCESS_METRICS:-User Satisfaction}

## Team Context
- **Team Size**: ${TEAM_SIZE:-5}
- **Time Zone**: ${TIME_ZONE:-UTC}
- **Working Hours**: ${WORKING_HOURS:-9-5}
- **Communication Preferences**: ${COMM_PREFERENCES:-Async}

## Current Priorities
1. Initial setup and configuration
2. Core feature development
3. Testing and quality assurance

## Notes
This context is dynamically loaded and can be updated as the project evolves.
EOF
}

# プロジェクトコンテキストを設定
configure_project() {
    local project_name="${1:-}"
    
    log_info "プロジェクトコンテキストを設定中..."
    
    # インタラクティブモード
    if [[ -z "$project_name" ]]; then
        echo -n "プロジェクト名を入力してください: "
        read -r project_name
    fi
    
    # プロジェクト情報を収集
    echo "プロジェクト情報を設定します（Enterでデフォルト値を使用）:"
    
    echo -n "プロジェクトタイプ [Software Development]: "
    read -r project_type
    project_type="${project_type:-Software Development}"
    
    echo -n "主要言語 [JavaScript]: "
    read -r primary_language
    primary_language="${primary_language:-JavaScript}"
    
    echo -n "フレームワーク [React/Node.js]: "
    read -r framework
    framework="${framework:-React/Node.js}"
    
    echo -n "対象ユーザー [General Users]: "
    read -r target_users
    target_users="${target_users:-General Users}"
    
    # コンテキストファイルを更新
    update_project_context \
        "PROJECT_NAME=$project_name" \
        "PROJECT_TYPE=$project_type" \
        "PRIMARY_LANGUAGE=$primary_language" \
        "FRAMEWORK=$framework" \
        "TARGET_USERS=$target_users"
    
    log_success "プロジェクトコンテキスト設定完了"
}

# プロジェクトコンテキストを更新
update_project_context() {
    local temp_file="${PROJECT_CONTEXT_FILE}.tmp"
    cp "$PROJECT_CONTEXT_FILE" "$temp_file"
    
    for var in "$@"; do
        local key="${var%%=*}"
        local value="${var#*=}"
        
        # 環境変数形式で置換
        sed -i.bak "s|\${${key}:-[^}]*}|${value}|g" "$temp_file"
        sed -i.bak "s|\${${key}}|${value}|g" "$temp_file"
    done
    
    mv "$temp_file" "$PROJECT_CONTEXT_FILE"
    rm -f "${temp_file}.bak"
}

# 特定エージェントの役割を更新
update_agent_role() {
    local agent="$1"
    shift
    
    local role_file="$AGENT_ROLES_DIR/${agent}-role.md"
    
    if [[ ! -f "$role_file" ]]; then
        log_error "エージェント '$agent' の役割定義が見つかりません"
        return 1
    fi
    
    log_info "エージェント '$agent' の役割を更新中..."
    
    # 引数から更新内容を適用
    local temp_file="${role_file}.tmp"
    cp "$role_file" "$temp_file"
    
    for update in "$@"; do
        local key="${update%%=*}"
        local value="${update#*=}"
        
        # 動的属性を更新
        sed -i.bak "s|\${${key}:-[^}]*}|${value}|g" "$temp_file"
        sed -i.bak "s|\${${key}}|${value}|g" "$temp_file"
    done
    
    mv "$temp_file" "$role_file"
    rm -f "${temp_file}.bak"
    
    log_success "エージェント '$agent' の役割更新完了"
}

# 現在の設定を表示
show_memory_config() {
    echo ""
    echo "📊 Chimera メモリ設定:"
    echo "===================="
    
    # プロジェクトコンテキスト
    if [[ -f "$PROJECT_CONTEXT_FILE" ]]; then
        echo ""
        echo "📋 プロジェクトコンテキスト:"
        echo "----------------------------"
        head -n 20 "$PROJECT_CONTEXT_FILE" | grep -E "^- \*\*|^[0-9]\."
    fi
    
    # エージェント役割
    echo ""
    echo "🤖 エージェント役割定義:"
    echo "------------------------"
    for role_file in "$AGENT_ROLES_DIR"/*-role.md; do
        if [[ -f "$role_file" ]]; then
            local agent_name=$(basename "$role_file" | sed 's/-role.md//')
            echo "  • $agent_name: $(grep -m1 "^## Role Overview" -A1 "$role_file" | tail -1)"
        fi
    done
}

# 設定をエクスポート
export_memory() {
    local export_file="${1:-chimera-memory-export.tar.gz}"
    
    log_info "メモリ設定をエクスポート中..."
    
    tar -czf "$export_file" -C "$(dirname "$MEMORY_DIR")" "$(basename "$MEMORY_DIR")"
    
    log_success "エクスポート完了: $export_file"
}

# 設定をインポート
import_memory() {
    local import_file="$1"
    
    if [[ ! -f "$import_file" ]]; then
        log_error "インポートファイルが見つかりません: $import_file"
        return 1
    fi
    
    log_info "メモリ設定をインポート中..."
    
    # バックアップ作成
    if [[ -d "$MEMORY_DIR" ]]; then
        mv "$MEMORY_DIR" "${MEMORY_DIR}.backup.$(date +%Y%m%d%H%M%S)"
    fi
    
    # インポート実行
    tar -xzf "$import_file" -C "$(dirname "$MEMORY_DIR")"
    
    log_success "インポート完了"
}

# メイン処理
main() {
    local command="${1:-}"
    shift
    
    case "$command" in
        init)
            init_memory
            ;;
        configure)
            configure_project "$@"
            ;;
        update-role)
            update_agent_role "$@"
            ;;
        show)
            show_memory_config
            ;;
        export)
            export_memory "$@"
            ;;
        import)
            import_memory "$@"
            ;;
        -h|--help|"")
            show_usage
            ;;
        *)
            log_error "不明なコマンド: $command"
            show_usage
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@"