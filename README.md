# Llama 部署与使用说明（Windows / Ubuntu 24.04）

> 注意：以下命令中的模型文件名、路径、IP 地址和 API Key 请根据实际情况修改。

## 目录

- [Windows 使用](#windows-使用)
  - [准备依赖文件](#准备依赖文件)
  - [启动 llama-server](#启动-llama-server)
  - [多机分布式推理](#多机分布式推理)
- [Ubuntu 24.04 使用](#ubuntu-2404-使用)
  - [安装 NVIDIA 驱动](#安装-nvidia-驱动)
  - [安装 CUDA Toolkit 与 llama](#安装-cuda-toolkit-与-llama)
  - [监控 GPU](#监控-gpu)

---

## Windows 使用

### 准备依赖文件

1. 下载 CUDA Toolkit 对应版本后解压，需要以下三个文件：

   - `cudart64_12.dll`
   - `cublasLt64_12.dll`
   - `cublas64_12.dll`

   CUDA Toolkit 下载地址：

   <https://developer.nvidia.com/cuda-toolkit-archive>

2. 下载 Git for Windows x64 Portable 便携版并解压，需要以下两个文件：

   - `libssl-3-x64.dll`
   - `libcrypto-3-x64.dll`

   Git for Windows 下载地址：

   <https://git-scm.com/install/windows>

3. 把以上所有 DLL 文件与 llama 可执行文件放在同一目录。

### 启动 llama-server

```powershell
.\llama-server.exe -m .\Qwen3.5-4B-Q4_K_M.gguf --host 0.0.0.0 --port 8080 -c 131072 -ngl 999 --api-key sk-12345678
