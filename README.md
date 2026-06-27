OpenAI接口测试命令
服务启动后，测试各端点：
# 1. 健康检查
curl http://localhost:8080/health

# 2. 列出模型
curl http://localhost:8080/v1/models

# 3. Chat Completion (OpenAI标准)
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-your-api-key-here" \
  -d '{
    "model": "llama",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Explain quantum computing in simple terms"}
    ],
    "temperature": 0.7,
    "max_tokens": 500,
    "stream": false
  }'

# 4. 流式输出
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama",
    "messages": [{"role": "user", "content": "Write a haiku about AI"}],
    "stream": true
  }'

# 5. Embedding (需模型支持)
curl http://localhost:8080/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama",
    "input": "Hello world"
  }'

使用方式
# 1. 赋予执行权限
chmod +x start_llama_server.sh stop_llama_server.sh

# 2. 直接启动 (使用脚本内默认参数)
./start_llama_server.sh

# 3. 使用配置文件
./start_llama_server.sh llama_server.conf

# 4. 环境变量覆盖
MODEL_PATH="/models/mistral.gguf" PORT=8081 ./start_llama_server.sh

# 5. 后台运行 + 自动重启 (配合systemd)
# 见下方systemd服务示例

Systemd服务 (开机自启)
创建 /etc/systemd/system/llama-server.service：
[Unit]
Description=llama-server OpenAI Compatible API
After=network.target

[Service]
Type=forking

User=ubuntu
WorkingDirectory=/opt/llama-cuda-package
ExecStart=/opt/llama-cuda-package/start_llama_server.sh /opt/llama-cuda-package/llama_server.conf
ExecStop=/opt/llama-cuda-package/stop_llama_server.sh
PIDFile=/opt/llama-cuda-package/llama_server.pid
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target

启用服务：
sudo systemctl daemon-reload
sudo systemctl enable llama-server
sudo systemctl start llama-server
sudo systemctl status llama-server

关键优化说明
参数	推荐值	说明
-ngl -1	全部卸载	显存充足时性能最佳
--flash-attn	启用	减少显存占用30%+
--parallel 4	4-8	支持并发请求数
--slot-save-reuse	启用	缓存复用，提升吞吐
--cache-type-k q8_0	q8_0	显存减半，精度略降


