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
```

### 多机分布式推理

#### 子节点

```powershell
.\ggml-rpc-server.exe --device CUDA0 --host 0.0.0.0 --port 50052
```

#### 主节点

```powershell
.\llama-server.exe -m .\Qwen3.5-4B-Q4_K_M.gguf --host 0.0.0.0 --port 8080 -c 131072 --rpc 192.168.101.109:50052 --tensor-split 1,1 -ngl 999 --api-key sk-12345678
```

---

## Ubuntu 24.04 使用

### 安装 NVIDIA 驱动

执行 `nvidia-smi` 时，如果提示：

```text
Command 'nvidia-smi' not found
```

通常是由于缺少 NVIDIA 驱动造成的。

#### 一、确认系统是否识别到显卡

先确认系统是否检测到显卡：

```bash
lspci | grep -i nvidia
```

如果看到类似输出：

```text
01:00.0 VGA compatible controller: NVIDIA Corporation Device 2d04 (rev a1)
01:00.1 Audio device: NVIDIA Corporation Device 22eb (rev a1)
```

说明硬件没有问题，只是驱动还没安装。

#### 二、让 Ubuntu 自动推荐驱动

Ubuntu 24.04 自带自动驱动推荐工具：

```bash
ubuntu-drivers devices
```

终端最后可能会输出类似内容：

```text
driver   : nvidia-driver-590-open - distro non-free recommended
driver   : nvidia-driver-580-server-open - distro non-free
driver   : nvidia-driver-580 - distro non-free
```

建议安装 `recommended` 版本。

#### 三、正式安装

1. 安装推荐驱动：

   ```bash
   sudo apt update
   sudo apt install nvidia-driver-xxx-open
   ```

   请将 `nvidia-driver-xxx-open` 替换为实际推荐的驱动版本。

2. 安装过程中可能会出现 Secure Boot 提示界面。

   - 会出现一个类似 BIOS 风格的蓝色界面，需要为内核模块设置密码（MOK）。
   - 设置一个密码，例如 `12345678`。
   - 密码要求约为 8～16 位。
   - 请记住这个密码，重启时会用到。
   - 再次输入密码确认。

3. 等待安装完成后重启：

   ```bash
   sudo reboot
   ```

   一定要等终端命令执行完成后再重启。

#### 四、重启时必须完成的一步：Enroll MOK

如果 Secure Boot 处于开启状态，重启后会进入 MOK Management 界面。

依次选择：

```text
Enroll MOK
→ Continue
→ Yes
→ 输入刚才设置的密码
→ 最后重启
```

完成后继续启动系统。

#### 五、验证是否安装成功

开机后执行：

```bash
nvidia-smi
```

如果看到类似输出：

```text
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 590.xx       Driver Version: 590.xx       CUDA Version: xx.x     |
+-----------------------------------------------------------------------------+
```

说明驱动安装成功。

### 安装 CUDA Toolkit 与 llama

CUDA Toolkit 下载地址同上：

<https://developer.nvidia.com/cuda-toolkit-archive>

下载并解压 llama 后，启动命令参考上方 Windows 部分。

### 监控 GPU

使用以下命令监控 GPU：

```bash
watch -n 1 -d nvidia-smi
```

或：

```bash
watch nvidia-smi
```
