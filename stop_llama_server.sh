#!/bin/bash
###############################################################################
# 停止 llama-server
###############################################################################

if [ -f "llama_server.pid" ]; then
    PID=$(cat llama_server.pid)
    if kill -0 "$PID" 2>/dev/null; then
        echo "🛑 停止服务 (PID: $PID)"
        kill "$PID"
        rm llama_server.pid
        echo "✅ 服务已停止"
    else
        echo "⚠️  进程不存在 (PID: $PID)"
        rm llama_server.pid
    fi
else
    echo "⚠️  未找到PID文件，尝试强制停止..."
    pkill -f "llama-server"
fi
