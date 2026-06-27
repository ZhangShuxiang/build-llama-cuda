#!/bin/bash
###############################################################################
# llama-server 启动脚本 (OpenAI兼容模式)
# 用法: ./start_llama_server.sh [config_file.conf] 或 直接编辑下方参数
###############################################################################

# ==================== 基础配置 ====================
MODEL_PATH="${MODEL_PATH:-/path/to/your/model.gguf}"          # 模型文件路径
HOST="${HOST:-0.0.0.0}"                                        # 监听地址 (0.0.0.0允许外部访问)
PORT="${PORT:-8080}"                                           # 监听端口
THREADS="${THREADS:-$(nproc)}"                                 # CPU线程数 (GPU模式可设小一些)

# ==================== GPU配置 ====================
USE_GPU="${USE_GPU:-true}"                                     # 是否启用GPU
GPU_LAYERS="${GPU_LAYERS:-99}"                                 # 卸载到GPU的层数 (-1=全部, 99=全部)
GPU_SPLIT_MODE="${GPU_SPLIT_MODE:-layer}"                     # 多GPU分摊模式: layer/row/none
MAIN_GPU="${MAIN_GPU:-0}"                                      # 主GPU设备ID

# ==================== 性能优化 ====================
BATCH_SIZE="${BATCH_SIZE:-512}"                                # 批处理大小 (显存充足可提高)
UBATCH_SIZE="${UBATCH_SIZE:-512}"                              # 微批处理大小
CONTEXT_SIZE="${CONTEXT_SIZE:-4096}"                           # 上下文长度 (根据模型支持调整)
N_PARALLEL="${N_PARALLEL:-1}"                                  # 并行请求数 (多GPU可增加)

# ==================== 内存优化 ====================
FLASH_ATTN="${FLASH_ATTN:-true}"                               # Flash Attention (显存优化)
KV_CACHE_TYPE="${KV_CACHE_TYPE:-f16}"                          # KV缓存类型: f16/q8_0/q4_0
NO_MMAP="${NO_MMAP:-false}"                                    # 禁用mmap (文件系统慢时启用)

# ==================== OpenAI兼容参数 ====================
OPENAI_COMPAT="${OPENAI_COMPAT:-true}"                         # 启用OpenAI兼容模式
API_KEY="${API_KEY:-}"                                         # API密钥 (留空则不校验)
CORS="${CORS:-true}"                                           # 启用CORS跨域
CORS_ALLOWED_ORIGINS="${CORS_ALLOWED_ORIGINS:-*}"             # 允许的跨域源

# ==================== 日志与调试 ====================
VERBOSE="${VERBOSE:-1}"                                        # 日志级别: 0=静默, 1=普通, 2=详细
LOG_FILE="${LOG_FILE:-./llama_server.log}"                     # 日志文件路径
METRICS="${METRICS:-true}"                                     # 启用指标统计

# ==================== 高级参数 ====================
# 以下参数一般不需要修改
ROPE_SCALING="${ROPE_SCALING:-}"                               # RoPE缩放 (如: linear, yarn)
ROPE_FREQ_BASE="${ROPE_FREQ_BASE:-}"                           # RoPE基础频率
TENSOR_SPLIT="${TENSOR_SPLIT:-}"                               # 张量并行分割 (多GPU: 2,3)
CACHE_CAPACITY="${CACHE_CAPACITY:-}"                           # 缓存容量 (MB)

# ==================== 环境检测 ====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_BIN="${SCRIPT_DIR}/bin/llama-server"
LIBS_DIR="${SCRIPT_DIR}/libs"

# 设置库路径 (如果存在本地CUDA库)
if [ -d "$LIBS_DIR" ]; then
    export LD_LIBRARY_PATH="$LIBS_DIR:$LD_LIBRARY_PATH"
    echo "✅ 加载本地CUDA库: $LIBS_DIR"
fi

# 检查服务器二进制文件
if [ ! -f "$SERVER_BIN" ]; then
    echo "❌ 错误: 找不到 $SERVER_BIN"
    echo "请确保llama-server在 bin/ 目录下"
    exit 1
fi

# ==================== 构建参数 ====================
BUILD_ARGS=(
    -m "$MODEL_PATH"
    --host "$HOST"
    --port "$PORT"
    -t "$THREADS"
    -c "$CONTEXT_SIZE"
    -b "$BATCH_SIZE"
    -ub "$UBATCH_SIZE"
    --parallel "$N_PARALLEL"
    --verbosity "$VERBOSE"
)

# GPU参数
if [ "$USE_GPU" = "true" ]; then
    BUILD_ARGS+=(
        -ngl "$GPU_LAYERS"
        --main-gpu "$MAIN_GPU"
    )
    # 多GPU支持
    if [ -n "$TENSOR_SPLIT" ]; then
        BUILD_ARGS+=(--tensor-split "$TENSOR_SPLIT")
    fi
    if [ -n "$GPU_SPLIT_MODE" ]; then
        BUILD_ARGS+=(--gpu-split-mode "$GPU_SPLIT_MODE")
    fi
fi

# OpenAI兼容
if [ "$OPENAI_COMPAT" = "true" ]; then
    BUILD_ARGS+=(--api-key "$API_KEY")
    BUILD_ARGS+=(--embedding)  # 支持embedding接口
    BUILD_ARGS+=(--slot-save-reuse)  # 插槽复用
fi

# 性能优化
if [ "$FLASH_ATTN" = "true" ]; then
    BUILD_ARGS+=(--flash-attn)
fi
if [ -n "$KV_CACHE_TYPE" ]; then
    BUILD_ARGS+=(--cache-type-k "$KV_CACHE_TYPE")
    BUILD_ARGS+=(--cache-type-v "$KV_CACHE_TYPE")
fi
if [ "$NO_MMAP" = "true" ]; then
    BUILD_ARGS+=(--no-mmap)
fi

# CORS
if [ "$CORS" = "true" ]; then
    BUILD_ARGS+=(--allow-origin "$CORS_ALLOWED_ORIGINS")
fi

# 高级参数
if [ -n "$ROPE_SCALING" ]; then
    BUILD_ARGS+=(--rope-scaling "$ROPE_SCALING")
fi
if [ -n "$ROPE_FREQ_BASE" ]; then
    BUILD_ARGS+=(--rope-freq-base "$ROPE_FREQ_BASE")
fi
if [ -n "$CACHE_CAPACITY" ]; then
    BUILD_ARGS+=(--cache-capacity "$CACHE_CAPACITY")
fi
if [ "$METRICS" = "true" ]; then
    BUILD_ARGS+=(--metrics)
fi

# ==================== 启动服务 ====================
echo "=========================================="
echo "🚀 启动 llama-server (OpenAI兼容)"
echo "=========================================="
echo "📁 模型路径: $MODEL_PATH"
echo "🌐 服务地址: http://$HOST:$PORT"
echo "🖥️  GPU状态: $([ "$USE_GPU" = "true" ] && echo "启用 ($GPU_LAYERS层)" || echo "禁用")"
echo "🧵 线程数: $THREADS"
echo "📦 上下文: $CONTEXT_SIZE"
echo "📊 批处理: $BATCH_SIZE"
echo "🔗 OpenAI: $([ "$OPENAI_COMPAT" = "true" ] && echo "启用" || echo "禁用")"
echo "📝 日志文件: $LOG_FILE"
echo "=========================================="
echo ""

# 启动并记录PID
nohup "$SERVER_BIN" "${BUILD_ARGS[@]}" >> "$LOG_FILE" 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > llama_server.pid

echo "✅ 服务已启动 (PID: $SERVER_PID)"
echo "📋 查看日志: tail -f $LOG_FILE"
echo "🛑 停止服务: kill $SERVER_PID 或 ./stop_llama_server.sh"
echo ""
echo "🔍 测试接口:"
echo "   curl http://$HOST:$PORT/v1/models"
echo "   curl http://$HOST:$PORT/health"
echo "   curl http://$HOST:$PORT/v1/chat/completions \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"model\":\"$MODEL_PATH\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}]}'"
