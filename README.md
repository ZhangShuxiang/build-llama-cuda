llama.cpp 部署与使用说明（Windows / Ubuntu 24.04）

本文档整理 Windows 与 Ubuntu 24.04 下运行 llama.cpp 所需依赖、启动命令及多机分布式推理配置。

目录

· Windows 使用
· Ubuntu 24.04 使用
· NVIDIA 驱动安装
· 验证与监控

---

Windows 使用

1. 准备 CUDA Toolkit 依赖

下载 CUDA Toolkit 对应版本后解压，需要以下三个文件：

· cudart64_12.dll
· cublasLt64_12.dll
· cublas64_12.dll

下载地址：

· CUDA Toolkit Archive

2. 准备 Git for Windows 依赖

下载 Git for Windows / x64 Portable 便携版并解压，需要以下两个文件：

· libssl-3-x64.dll
· libcrypto-3-x64.dll

下载地址：

· Git for Windows 安装包下载

3. 放置依赖文件

将以上所有 DLL 文件与 llama 可执行文件放在同一目录下。

```text
llama/
├─ llama-server.exe
├─ ggml-rpc-server.exe
├─ cudart64_12.dll
├─ cublasLt64_12.dll
├─ cublas64_12.dll
├─ libssl-3-x64.dll
└─ libcrypto-3-x64.dll
```

4. 启动 llama-server

```powershell
.\llama-server.exe -m .\Qwen3.5-4B-Q4_K_M.gguf --host 0.0.0.0 --port 8080 -c 131072 -ngl 999 --api-key sk-12345678
```

请根据实际情况修改模型文件名、端口、上下文长度及 API Key。

5. 多机分布式推理

子节点

在子节点上启动 RPC Server：

```powershell
.\ggml-rpc-server.exe --device CUDA0 --host 0.0.0.0 --port 50052
```

主节点

在主节点上启动 llama-server，并连接子节点：

```powershell
.\llama-server.exe -m .\Qwen3.5-4B-Q4_K_M.gguf --host 0.0.0.0 --port 8080 -c 131072 --rpc 192.168.101.109:50052 --tensor-split 1,1 -ngl 999 --api-key sk-12345678
```

192.168.101.109:50052 为示例子节点地址，请替换为实际 IP 和端口。

---

Ubuntu 24.04 使用

NVIDIA 驱动安装简单指南

执行 nvidia-smi 时提示：

```bash
nvidia-smi
```

```text
Command 'nvidia-smi' not found
```

这通常是由于缺少 NVIDIA 驱动造成的。

一、确认系统是否识别到显卡

如果 nvidia-smi 不存在，说明驱动还没安装。先确认系统是否检测到显卡：

```bash
lspci | grep -i nvidia
```

如果看到类似输出：

```text
01:00.0 VGA compatible controller: NVIDIA Corporation Device 2d04 (rev a1)
01:00.1 Audio device: NVIDIA Corporation Device 22eb (rev a1)
```

说明硬件没有问题，只是驱动未安装。

二、让 Ubuntu 自动推荐驱动

Ubuntu 24.04 自带自动驱动推荐工具：

```bash
ubuntu-drivers devices
```

终端最后输出类似：

```text
driver   : nvidia-driver-590-open - distro non-free recommended
driver   : nvidia-driver-580-server-open - distro non-free
driver   : nvidia-driver-580 - distro non-free
```

建议安装 recommended 版本。

三、正式安装

1. 安装推荐驱动

```bash
sudo apt update
sudo apt install nvidia-driver-xxx-open
```

将 xxx 替换为 ubuntu-drivers devices 推荐的实际版本号。

2. Secure Boot 提示界面

安装过程中可能出现蓝色 BIOS 风格界面，需要为内核模块设置密码（MOK）。

· 设置一个密码，例如：12345678
· 密码要求：约 8–16 位
· 请记住该密码，重启时会用到
· 再次输入密码确认

3. 等待安装完成并重启

一定等终端命令执行完成后再重启：

```bash
sudo reboot
```

四、重启时必须做的一步：Enroll MOK

如果 Secure Boot 处于开启状态，重启后会进入 MOK Management。

选择流程：

```text
Enroll MOK
→ Continue
→ Yes
→ 输入刚才设置的密码
→ 最后重启
```

完成后继续启动系统。

五、验证驱动是否安装成功

开机后执行：

```bash
nvidia-smi
```

如果看到类似输出：

```text
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 590.xx       Driver Version: 590.xx       CUDA Version: xx.x  |
+-----------------------------------------------------------------------------+
```

说明驱动安装成功。

六、安装 CUDA Toolkit 与 llama

安装 CUDA Toolkit，下载地址同上：

· CUDA Toolkit Archive

然后下载并解压 llama，命令参考 Windows 部分。

---

验证与监控

查看 GPU 使用情况：

```bash
watch nvidia-smi
```

高亮显示变化：

```bash
watch -n 1 -d nvidia-smi
```

---

注意事项

· 示例中的模型文件、IP 地址、端口和 API Key 请按实际环境替换。
· Windows 下请确保所有 DLL 与 llama 可执行文件位于同一目录。
· Ubuntu 安装 NVIDIA 驱动时，如启用了 Secure Boot，重启后必须完成 Enroll MOK。
· 分布式推理时，主节点需能访问子节点的 RPC 端口。
