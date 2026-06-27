# AI生成的，凑合着看吧

# llama.cpp CUDA 预编译包

[![Build llama.cpp with CUDA Support](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/build-llama-cuda.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/build-llama-cuda.yml)

基于 GitHub Actions 自动编译的 **llama.cpp CUDA 预编译包**，支持 OpenAI 兼容 API，开箱即用。

## ✨ 特性

- 🚀 **预编译 CUDA 版本** - 无需本地安装 CUDA Toolkit
- 🔌 **OpenAI 兼容 API** - 支持 `/v1/chat/completions`、`/v1/embeddings` 等标准接口
- 📦 **完整运行时库** - 包含 CUDA 运行时依赖 (`libcudart`, `libcublas`)
- 🛠 **生产级脚本** - 启动/停止/健康检查脚本
- 🎯 **多架构支持** - 支持 Pascal 到 Ada Lovelace (GTX 10xx ~ RTX 40系列)

## 📋 系统要求

| 组件 | 要求 |
|------|------|
| **操作系统** | Ubuntu 20.04 / 22.04 或兼容 Linux 发行版 |
| **GPU** | NVIDIA GPU (Compute Capability ≥ 6.0) |
| **NVIDIA 驱动** | 版本 ≥ 535.xx |
| **内存** | ≥ 8GB (推荐 16GB+) |
| **存储** | ≥ 10GB (含模型文件) |

### 支持的 GPU 架构

| 架构 | GPU 系列 | 代表型号 |
|------|----------|----------|
| `compute_60/61` | Pascal | GTX 1080, P100 |
| `compute_70` | Volta | V100 |
| `compute_75` | Turing | T4, RTX 2080 |
| `compute_80/86` | Ampere | A100, RTX 3090/3070 |
| `compute_89` | Ada Lovelace | RTX 4090 |

> **注意**: CUDA 12.x 不再支持 Maxwell 架构 (GTX 9xx 及更早)

## 📦 快速开始

### 1. 下载预编译包

从 [Releases](https://github.com/YOUR_USERNAME/YOUR_REPO/releases) 或 Actions Artifacts 下载：

```bash
# 下载最新版本
wget https://github.com/YOUR_USERNAME/YOUR_REPO/releases/latest/download/llama-cuda-ubuntu2204-Release-xxx.tar.gz

# 或从 Actions Artifacts 下载
```

### 2. 解压

```bash
tar -xzf llama-cuda-ubuntu2204-Release-*.tar.gz
cd llama-cuda-package
```

### 3. 配置

编辑 `llama_server.conf`：

```bash
vim llama_server.conf
```

```ini
# 必须修改: 模型文件路径
MODEL_PATH="/path/to/your/model.gguf"

# 可选配置
HOST="0.0.0.0"
PORT="8080"
USE_GPU=true
GPU_LAYERS=-1              # -1 = 全部层卸载到 GPU
CONTEXT_SIZE=4096
BATCH_SIZE=512
OPENAI_COMPAT=true
API_KEY=""                 # 生产环境建议设置
VERBOSE=1
```

### 4. 启动服务

```bash
# 赋予执行权限
chmod +x *.sh

# 启动服务
./start_llama_server.sh
```

### 5. 测试 API

```bash
# 健康检查
curl http://localhost:8080/health

# 列出模型
curl http://localhost:8080/v1/models

# Chat Completion (OpenAI 标准)
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama",
    "messages": [{"role": "user", "content": "Hello, how are you?"}],
    "max_tokens": 100
  }'

# 流式输出
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama",
    "messages": [{"role": "user", "content": "Write a poem about AI"}],
    "stream": true
  }'
```

### 6. 停止服务

```bash
./stop_llama_server.sh
```

## 📁 包结构

```
llama-cuda-package/
├── bin/                         # 可执行文件
│   ├── llama-server            # API 服务器 (主程序)
│   ├── llama-cli               # 命令行推理
│   ├── llama-perplexity        # 困惑度测试
│   └── llama-bench             # 性能基准测试
├── libs/                        # CUDA 运行时库
│   ├── libcudart.so.12
│   ├── libcublas.so.12
│   └── libcublasLt.so.12
├── start_llama_server.sh        # 启动脚本
├── stop_llama_server.sh         # 停止脚本
├── llama_server.conf            # 配置文件
├── health_check.sh              # 健康检查脚本
├── logs/                        # 日志目录 (自动创建)
├── VERSION.txt                  # 版本信息
└── README.md                    # 本文件
```

## 🔧 配置详解

### `llama_server.conf` 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `MODEL_PATH` | (必需) | GGUF 模型文件路径 |
| `HOST` | `0.0.0.0` | 监听地址 (0.0.0.0 = 允许外部访问) |
| `PORT` | `8080` | 服务端口 |
| `USE_GPU` | `true` | 启用 GPU 加速 |
| `GPU_LAYERS` | `-1` | GPU 卸载层数 (-1=全部) |
| `THREADS` | `$(nproc)` | CPU 线程数 |
| `CONTEXT_SIZE` | `4096` | 上下文长度 |
| `BATCH_SIZE` | `512` | 批处理大小 |
| `N_PARALLEL` | `1` | 并行请求数 |
| `FLASH_ATTN` | `true` | Flash Attention (显存优化) |
| `KV_CACHE_TYPE` | `f16` | KV 缓存类型: f16/q8_0/q4_0 |
| `OPENAI_COMPAT` | `true` | OpenAI 兼容模式 |
| `API_KEY` | (空) | API 密钥 (空则不校验) |
| `CORS` | `true` | 启用 CORS |
| `VERBOSE` | `1` | 日志级别: 0=静默, 1=普通, 2=详细 |

### 多 GPU 配置

```bash
# 2 张 RTX 4090
TENSOR_SPLIT="2,2"
GPU_SPLIT_MODE="layer"
MAIN_GPU=0
```

### 大上下文场景

```bash
CONTEXT_SIZE=8192
BATCH_SIZE=1024
UBATCH_SIZE=1024
FLASH_ATTN=true
```

## 🔍 健康检查

```bash
# 单次检查
./health_check.sh

# 详细输出 + 自动修复
./health_check.sh -v -a

# 禁用通知
./health_check.sh -n
```

### 定时监控 (Crontab)

```bash
# 每分钟检查一次，自动修复
* * * * * /opt/llama-cuda-package/health_check.sh -a >> /var/log/llama-health.log 2>&1
```

## 🐳 Docker 部署 (可选)

```dockerfile
FROM nvidia/cuda:12.6.0-runtime-ubuntu22.04

COPY llama-cuda-package /app
WORKDIR /app

EXPOSE 8080

CMD ["./start_llama_server.sh"]
```

```bash
docker build -t llama-server .
docker run --gpus all -p 8080:8080 -v /models:/models llama-server
```

## 🔄 自动编译 (GitHub Actions)

### 触发方式

1. **手动触发**: Actions → "Build llama.cpp with CUDA" → Run workflow
2. **自动触发**: 推送代码到 `main`/`master` 分支
3. **Tag 触发**: 创建 tag 会自动创建 Release

### 工作流配置

```yaml
# .github/workflows/build-llama-cuda.yml
name: Build llama.cpp with CUDA Support
on:
  workflow_dispatch:
    inputs:
      cuda_version:
        default: '12.6'
      cuda_arch:
        default: '60;61;70;75;80;86;89'
```

### 自定义编译参数

在 `.github/workflows/build-llama-cuda.yml` 中修改：

```yaml
# 修改 CUDA 架构
cuda_architectures:
  - "80;86;89"  # 仅 Ampere+ (RTX 30/40)

# 修改构建类型
build_type: 'Release'  # Release / Debug / RelWithDebInfo
```

## 🆘 故障排查

### 1. CUDA 库找不到

```bash
export LD_LIBRARY_PATH=$PWD/libs:$LD_LIBRARY_PATH
./start_llama_server.sh
```

### 2. 端口被占用

```bash
# 修改配置文件
PORT=8081
./start_llama_server.sh
```

### 3. 模型加载失败

```bash
# 检查模型文件格式
file /path/to/model.gguf
# 应显示: GGUF model data

# 检查模型路径权限
ls -la /path/to/model.gguf
```

### 4. GPU 内存不足

```bash
# 减少 GPU 层数
GPU_LAYERS=20

# 减小上下文
CONTEXT_SIZE=2048

# 启用 Flash Attention
FLASH_ATTN=true
```

### 5. 查看日志

```bash
# 服务日志
tail -f logs/llama_server_*.log

# 健康检查日志
tail -f logs/health_check.log
```

## 📊 OpenAI API 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/health` | GET | 健康检查 |
| `/v1/models` | GET | 列出可用模型 |
| `/v1/chat/completions` | POST | 聊天补全 (Chat Completion) |
| `/v1/completions` | POST | 文本补全 (Text Completion) |
| `/v1/embeddings` | POST | 文本嵌入 (Embeddings) |
| `/metrics` | GET | Prometheus 指标 |

### Python 客户端示例

```python
import openai

client = openai.OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="your-api-key"  # 如果设置了 API_KEY
)

response = client.chat.completions.create(
    model="llama",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Explain quantum computing"}
    ],
    temperature=0.7,
    max_tokens=500
)

print(response.choices[0].message.content)
```

## 📝 更新日志

### [Latest] - 2026-06-27
- ✅ 基于 CUDA 12.6 编译
- ✅ 支持 OpenAI 兼容 API
- ✅ 包含启动/停止/健康检查脚本
- ✅ 支持 Pascal 到 Ada Lovelace 架构

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 本地编译测试

```bash
# 克隆仓库
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO

# 安装 CUDA Toolkit (无驱动)
wget https://developer.download.nvidia.com/compute/cuda/12.6.0/local_installers/cuda_12.6.0_linux.run
sudo sh cuda_12.6.0_linux.run --silent --toolkit --no-driver

# 编译
cd llama.cpp
mkdir build && cd build
cmake .. -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="60;61;70;75;80;86;89"
make -j$(nproc)
```

## 📄 许可证

本项目基于 [llama.cpp](https://github.com/ggerganov/llama.cpp) 构建，遵循其许可证。

## 🔗 相关链接

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - 原始项目
- [GGUF 模型下载](https://huggingface.co/models?search=gguf) - Hugging Face
- [OpenAI API 文档](https://platform.openai.com/docs/api-reference)

---

**⭐ 如果这个项目对你有帮助，请给个 Star！**

[![GitHub stars](https://img.shields.io/github/stars/YOUR_USERNAME/YOUR_REPO)](https://github.com/YOUR_USERNAME/YOUR_REPO/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/YOUR_USERNAME/YOUR_REPO)](https://github.com/YOUR_USERNAME/YOUR_REPO/issues)
[![GitHub license](https://img.shields.io/github/license/YOUR_USERNAME/YOUR_REPO)](https://github.com/YOUR_USERNAME/YOUR_REPO/blob/main/LICENSE)
