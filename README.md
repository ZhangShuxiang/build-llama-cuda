Windows使用
下载cuda-toolkit对应版本后解压，需要这三个文件cudart64_12.dll，cublasLt64_12.dll，cublas64_12.dll
https://developer.nvidia.com/cuda-toolkit-archive
下载GitforWindows/x64Portable便携版解压，需要这两个文件libssl-3-x64.dll，libcrypto-3-x64.dll
https://git-scm.com/install/windows
把以上文件全部和llama可执行文件放一块
.\llama-server.exe -m .\Qwen3.5-4B-Q4_K_M.gguf --host 0.0.0.0 --port 8080 -c 131072 -ngl 999 --api-key sk-12345678
多机分布式推理子节点
.\ggml-rpc-server.exe --device CUDA0 --host 0.0.0.0 --port 50052
多机分布式推理主节点
.\llama-server.exe -m .\Qwen3.5-4B-Q4_K_M.gguf --host 0.0.0.0 --port 8080 -c 131072 --rpc 192.168.101.109:50052 --tensor-split 1,1 -ngl 999 --api-key sk-12345678


Ubuntu24.4使用
Ubuntu24.04安装NVIDIA驱动简单指南
执行nvidia-smi时，提示nvidia-smiCommand 'nvidia-smi' not found
这是由于缺少Nvidia驱动造成的。
一、确认系统是否识别到显卡
如果 nvidia-smi 不存在，说明驱动还没安装。
先确认系统是否检测到显卡：
lspci | grep -i nvidia
如果看到类似输出：
01:00.0 VGA compatible controller: NVIDIA Corporation Device 2d04 (rev a1)
01:00.1 Audio device: NVIDIA Corporation Device 22eb (rev a1)@改一下配置文件
说明：硬件没问题只是驱动没装
二、让Ubuntu自动推荐驱动
Ubuntu 24.04自带自动驱动推荐工具：
ubuntu-drivers devices
终端最后的输出类似：
driver   : nvidia-driver-590-open - distro non-free recommended
driver   : nvidia-driver-580-server-open - distro non-free
driver   : nvidia-driver-580 - distro non-free
最好是安装 recommended 版本。
三、正式安装
1.安装推荐驱动
sudo apt update
sudo apt install nvidia-driver-xxx-open
2.安装过程中可能会出现下面的界面
（1）Secure Boot提示界面
会出现一个蓝色界面（类似 BIOS 风格）：
需要为内核模块设置密码（MOK）
会让你设置一个密码（比如：12345678）
要求：好像是要求8-16位
记住这个密码 重启时会用到
（3）确认密码再次输入密码确认。
3.等待安装完成后重启
一定等终端的命令执行完在重启。
sudo reboot
四、重启时必须做的一步（Enroll MOK）
如果你的Secure Boot是开启状态：
重启后会进入：
MOK Managerment
选择：
Enroll MOK
→ Continue
→ Yes
→ 输入刚才设置的密码
→ 最后重启
完成后继续启动系统。
五、验证是否成功
开机后执行：
nvidia-smi
如果看到类似：
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 590.xx       Driver Version: 590.xx       CUDA Version: xx.x  |
+-----------------------------------------------------------------------------+
说明安装成功
然后安装cuda-toolkit，网址同上
然后下载解压llama，命令参考Windows

watch -n 1 -d nvidia-smi
watch nvidia-smi
