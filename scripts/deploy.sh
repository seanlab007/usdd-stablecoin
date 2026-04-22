#!/bin/bash
# ================================================
# USDD Stablecoin - 一键更新脚本
# 用法: ./scripts/deploy.sh "提交消息"
# 示例: ./scripts/deploy.sh "修复首页标题"
# ================================================

set -e

PROJECT="usdd-clone"
REMOTE="https://github.com/seanlab007/usdd-stablecoin.git"
WRANGLER_PROJECT="usdd-stablecoin"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 检查 git 状态
check_git() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "不是 Git 仓库"
    fi
}

# 获取变更文件
get_changes() {
    git status --porcelain | grep -v "^??"
}

# 提交并推送 GitHub
push_github() {
    local msg="$1"
    
    if [ -z "$(get_changes)" ]; then
        warn "没有变更，跳过 GitHub 提交"
        return 0
    fi
    
    log "📦 提交到 GitHub..."
    git add -A
    git commit -m "$msg"
    git push origin main
    log "✅ GitHub 推送完成"
}

# 部署到 Cloudflare Pages
deploy_cloudflare() {
    log "☁️  部署到 Cloudflare Pages..."
    
    local result
    result=$(npx wrangler pages deploy . --project-name="$WRANGLER_PROJECT" 2>&1)
    
    if echo "$result" | grep -q "Success!\|Deployment complete\|✨"; then
        local url
        url=$(echo "$result" | grep -o 'https://[^ ]*\.pages\.dev' | tail -1)
        log "✅ Cloudflare 部署完成"
        [ -n "$url" ] && echo "   $url"
    else
        warn "Cloudflare 部署输出："
        echo "$result" | tail -5
    fi
}

# 主流程
main() {
    local msg="${1:-更新 $PROJECT $(date '+%Y-%m-%d %H:%M')}"
    
    cd "$(dirname "$0")/.."
    
    log "🚀 开始部署 $PROJECT"
    echo ""
    
    check_git
    push_github "$msg"
    deploy_cloudflare
    
    echo ""
    log "🎉 全部完成！"
}

main "$@"
