#!/bin/bash
###############################################################################
# llama-server 健康检查脚本
# 功能: 检查服务状态、响应时间、GPU状态、模型加载情况
# 用法: ./health_check.sh [options]
#   选项: -v 详细输出, -a 自动修复, -n 禁用通知
###############################################################################

set -euo pipefail

# ==================== 配置 ====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/llama_server.conf"
PID_FILE="${SCRIPT_DIR}/llama_server.pid"
LOG_FILE="${SCRIPT_DIR}/logs/health_check.log"

# 服务配置
HOST="${HOST:-localhost}"
PORT="${PORT:-8080}"
API_KEY="${API_KEY:-}"

# 检查阈值
MAX_RESPONSE_TIME=5           # 最大响应时间（秒）
MAX_GPU_TEMP=85               # GPU最大温度（摄氏度）
MIN_GPU_UTIL=10               # GPU最小利用率（%）
HEALTH_CHECK_INTERVAL=60      # 检查间隔（秒）
AUTO_RESTART=true             # 自动重启
RETRY_COUNT=3                 # 重试次数
RETRY_INTERVAL=2              # 重试间隔（秒）

# 通知配置
ENABLE_NOTIFY=true
NOTIFY_WEBHOOK=""             # 企业微信/DingTalk/Slack Webhook
NOTIFY_EMAIL=""               # 邮件地址（需配置mailx）

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==================== 参数解析 ====================
VERBOSE=false
AUTO_FIX=false
while getopts "van:h" opt; do
    case $opt in
        v) VERBOSE=true ;;
        a) AUTO_FIX=true ;;
        n) ENABLE_NOTIFY=false ;;
        h) 
            echo "用法: $0 [选项]"
            echo "选项:"
            echo "  -v    详细输出"
            echo "  -a    自动修复（重启服务）"
            echo "  -n    禁用通知"
            echo "  -h    显示帮助"
            exit 0
            ;;
        *) echo "无效选项"; exit 1 ;;
    esac
done

# ==================== 加载配置 ====================
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# ==================== 日志函数 ====================
log() {
    local level=$1
    local msg=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        INFO)  echo -e "${GREEN}[INFO]${NC} $msg" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $msg" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $msg" ;;
        DEBUG) [ "$VERBOSE" = true ] && echo -e "${BLUE}[DEBUG]${NC} $msg" ;;
    esac
    
    # 写入日志文件
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"
}

# ==================== 通知函数 ====================
send_notification() {
    local status=$1
    local message=$2
    
    [ "$ENABLE_NOTIFY" = false ] && return 0
    
    log DEBUG "发送通知: $status - $message"
    
    # Webhook通知 (企业微信/DingTalk/Slack)
    if [ -n "$NOTIFY_WEBHOOK" ]; then
        curl -s -X POST "$NOTIFY_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{
                \"msgtype\": \"text\",
                \"text\": {
                    \"content\": \"[llama-server] $status\n$message\n时间: $(date '+%Y-%m-%d %H:%M:%S')\"
                }
            }" > /dev/null 2>&1 || log WARN "Webhook通知发送失败"
    fi
    
    # 邮件通知
    if [ -n "$NOTIFY_EMAIL" ]; then
        echo "$message" | mail -s "[llama-server] $status" "$NOTIFY_EMAIL" 2>/dev/null || log WARN "邮件通知发送失败"
    fi
}

# ==================== 检查函数 ====================

# 1. 检查进程是否存在
check_process() {
    if [ ! -f "$PID_FILE" ]; then
        log ERROR "PID文件不存在: $PID_FILE"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    if ! kill -0 "$pid" 2>/dev/null; then
        log ERROR "进程不存在 (PID: $pid)"
        return 1
    fi
    
    log DEBUG "进程运行正常 (PID: $pid)"
    return 0
}

# 2. 检查HTTP服务
check_http() {
    local url="http://${HOST}:${PORT}/health"
    local auth_header=""
    
    if [ -n "$API_KEY" ]; then
        auth_header="-H \"Authorization: Bearer $API_KEY\""
    fi
    
    local start_time=$(date +%s.%N)
    
    for i in $(seq 1 $RETRY_COUNT); do
        log DEBUG "HTTP检查尝试 $i/$RETRY_COUNT: $url"
        
        # 执行curl请求
        local response=$(curl -s -o /dev/null -w "%{http_code}" \
            --max-time $MAX_RESPONSE_TIME \
            ${auth_header} \
            "$url" 2>/dev/null || echo "000")
        
        local end_time=$(date +%s.%N)
        local response_time=$(echo "$end_time - $start_time" | bc)
        
        case $response in
            200|204)
                log INFO "HTTP检查成功 (状态码: $response, 耗时: ${response_time}s)"
                return 0
                ;;
            000)
                log WARN "HTTP检查超时或无响应 (尝试 $i/$RETRY_COUNT)"
                sleep $RETRY_INTERVAL
                ;;
            *)
                log WARN "HTTP检查返回异常状态码: $response (尝试 $i/$RETRY_COUNT)"
                sleep $RETRY_INTERVAL
                ;;
        esac
    done
    
    log ERROR "HTTP检查失败，所有重试均失败"
    return 1
}

# 3. 检查OpenAI接口
check_openai_api() {
    local url="http://${HOST}:${PORT}/v1/models"
    local auth_header=""
    
    if [ -n "$API_KEY" ]; then
        auth_header="-H \"Authorization: Bearer $API_KEY\""
    fi
    
    log DEBUG "OpenAI API检查: $url"
    
    local response=$(curl -s --max-time 10 \
        ${auth_header} \
        "$url" 2>/dev/null || echo "")
    
    if echo "$response" | grep -q '"object":"list"'; then
        log INFO "OpenAI API检查成功"
        return 0
    else
        log ERROR "OpenAI API检查失败"
        [ "$VERBOSE" = true ] && echo "响应: $response"
        return 1
    fi
}

# 4. 检查GPU状态（如果有nvidia-smi）
check_gpu() {
    if ! command -v nvidia-smi &> /dev/null; then
        log DEBUG "nvidia-smi不可用，跳过GPU检查"
        return 0
    fi
    
    log DEBUG "检查GPU状态..."
    
    # 获取GPU信息
    local gpu_info=$(nvidia-smi --query-gpu=index,temperature.gpu,utilization.gpu,memory.used,memory.total \
        --format=csv,noheader,nounits 2>/dev/null || echo "")
    
    if [ -z "$gpu_info" ]; then
        log WARN "无法获取GPU信息"
        return 1
    fi
    
    local gpu_count=$(echo "$gpu_info" | wc -l)
    local gpu_healthy=true
    
    echo "$gpu_info" | while IFS=, read -r idx temp util mem_used mem_total; do
        # 去除空格
        idx=$(echo "$idx" | xargs)
        temp=$(echo "$temp" | xargs)
        util=$(echo "$util" | xargs)
        mem_used=$(echo "$mem_used" | xargs)
        mem_total=$(echo "$mem_total" | xargs)
        
        local mem_percent=$((mem_used * 100 / mem_total))
        
        # 检查温度
        if [ "$temp" -gt "$MAX_GPU_TEMP" ]; then
            log ERROR "GPU $idx 温度过高: ${temp}°C (阈值: ${MAX_GPU_TEMP}°C)"
            gpu_healthy=false
        fi
        
        # 检查利用率
        if [ "$util" -lt "$MIN_GPU_UTIL" ] && [ "$mem_percent" -gt 50 ]; then
            log WARN "GPU $idx 利用率低: ${util}% (内存使用: ${mem_percent}%)"
        fi
        
        # 检查内存
        if [ "$mem_percent" -gt 90 ]; then
            log WARN "GPU $idx 内存使用率高: ${mem_percent}% (${mem_used}/${mem_total} MB)"
        fi
        
        log DEBUG "GPU $idx: ${temp}°C, 利用率${util}%, 内存${mem_percent}%"
    done
    
    # 检查是否至少有一个GPU可用
    if [ "$gpu_count" -eq 0 ]; then
        log ERROR "未检测到可用GPU"
        return 1
    fi
    
    return 0
}

# 5. 检查模型加载状态（通过metrics端点）
check_model_loaded() {
    local url="http://${HOST}:${PORT}/metrics"
    
    log DEBUG "检查模型加载状态..."
    
    local metrics=$(curl -s --max-time 5 "$url" 2>/dev/null || echo "")
    
    if echo "$metrics" | grep -q "llama_model_loaded"; then
        local model_count=$(echo "$metrics" | grep "llama_model_loaded" | awk '{print $2}')
        log INFO "模型已加载 (计数: $model_count)"
        return 0
    else
        log WARN "无法获取模型加载状态（metrics端点可能未启用）"
        return 0  # 不致命错误
    fi
}

# 6. 检查系统资源
check_system_resources() {
    log DEBUG "检查系统资源..."
    
    # CPU负载
    local load=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | xargs)
    local cpu_count=$(nproc)
    local load_percent=$(echo "$load * 100 / $cpu_count" | bc 2>/dev/null || echo "0")
    
    if [ "$load_percent" -gt 100 ]; then
        log WARN "CPU负载过高: $load (${load_percent}%)"
    fi
    
    # 内存使用
    local mem_total=$(free -m | awk '/^Mem:/{print $2}')
    local mem_used=$(free -m | awk '/^Mem:/{print $3}')
    local mem_percent=$((mem_used * 100 / mem_total))
    
    if [ "$mem_percent" -gt 90 ]; then
        log WARN "内存使用率过高: ${mem_percent}% (${mem_used}/${mem_total} MB)"
    fi
    
    # 磁盘空间
    local disk_used=$(df -h . | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$disk_used" -gt 90 ]; then
        log WARN "磁盘使用率过高: ${disk_used}%"
    fi
    
    log DEBUG "系统资源: CPU负载${load_percent}%, 内存${mem_percent}%, 磁盘${disk_used}%"
    return 0
}

# ==================== 自动修复 ====================
auto_fix() {
    local issue=$1
    
    if [ "$AUTO_FIX" != true ] && [ "$AUTO_RESTART" != true ]; then
        log DEBUG "自动修复未启用"
        return 1
    fi
    
    log WARN "尝试自动修复: $issue"
    
    # 重启服务
    if [ -f "${SCRIPT_DIR}/stop_llama_server.sh" ] && [ -f "${SCRIPT_DIR}/start_llama_server.sh" ]; then
        log INFO "重启llama-server..."
        "${SCRIPT_DIR}/stop_llama_server.sh" 2>/dev/null || true
        sleep 2
        "${SCRIPT_DIR}/start_llama_server.sh" 2>/dev/null || true
        sleep 5
        
        # 验证重启是否成功
        if check_http; then
            log INFO "✅ 自动修复成功，服务已恢复"
            send_notification "RECOVERED" "服务已自动恢复\n问题: $issue"
            return 0
        else
            log ERROR "❌ 自动修复失败，服务仍然异常"
            send_notification "CRITICAL" "自动修复失败\n问题: $issue\n需要人工介入"
            return 1
        fi
    else
        log ERROR "找不到启动/停止脚本，无法自动修复"
        return 1
    fi
}

# ==================== 主检查流程 ====================
main() {
    log INFO "========== 开始健康检查 =========="
    
    local health_status=0
    local issues=()
    
    # 1. 检查进程
    if ! check_process; then
        issues+=("进程不存在")
        health_status=1
    fi
    
    # 2. 检查HTTP服务
    if ! check_http; then
        issues+=("HTTP服务异常")
        health_status=1
    fi
    
    # 3. 检查OpenAI API
    if ! check_openai_api; then
        issues+=("OpenAI API异常")
        health_status=1
    fi
    
    # 4. 检查GPU状态（可选）
    if ! check_gpu; then
        issues+=("GPU状态异常")
        health_status=1
    fi
    
    # 5. 检查模型加载
    if ! check_model_loaded; then
        issues+=("模型加载异常")
        # 不致命，仅警告
    fi
    
    # 6. 检查系统资源
    if ! check_system_resources; then
        issues+=("系统资源异常")
        # 不致命，仅警告
    fi
    
    # ==================== 结果处理 ====================
    if [ $health_status -eq 0 ]; then
        log INFO "✅ 健康检查通过 - 服务运行正常"
        echo -e "${GREEN}✅ HEALTHY${NC} - 所有检查通过"
        send_notification "HEALTHY" "服务运行正常"
        exit 0
    else
        log ERROR "❌ 健康检查失败"
        echo -e "${RED}❌ UNHEALTHY${NC}"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
        
        # 尝试自动修复
        if [ "$AUTO_FIX" = true ] || [ "$AUTO_RESTART" = true ]; then
            local issue_summary=$(IFS=", " ; echo "${issues[*]}")
            if auto_fix "$issue_summary"; then
                exit 0
            else
                exit 1
            fi
        else
            send_notification "UNHEALTHY" "服务异常\n$(printf '%s\n' "${issues[@]}")"
            exit 1
        fi
    fi
}

# ==================== 执行 ====================
main "$@"
