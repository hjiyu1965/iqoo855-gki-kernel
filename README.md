# Android Kernel Build System

完整的Android内核编译流程管理与自动化构建系统，支持多架构、多设备的内核编译。

## 功能特性

- 自动化源码获取与完整性校验
- Docker容器化编译环境
- 多架构支持 (arm64-v8a, armeabi-v7a, x86_64)
- 增量编译与ccache加速
- 详细的错误处理与日志记录
- CI/CD自动化构建
- 编译产物自动打包
- 多设备预设配置

## 目录结构

```
.
├── .github/
│   └── workflows/
│       └── kernel-build.yml    # GitHub Actions CI/CD配置
├── configs/
│   └── arch/
│       ├── arm64/
│       │   └── defconfig      # ARM64内核配置
│       ├── arm/
│       │   └── defconfig      # ARM内核配置
│       └── x86_64/
│           └── defconfig      # x86_64内核配置
├── docker/
│   ├── Dockerfile             # Docker镜像定义
│   ├── docker-compose.yml     # Docker Compose配置
│   └── build-docker.sh       # Docker镜像构建脚本
├── scripts/
│   ├── fetch_kernel.sh        # 内核源码获取脚本
│   ├── build.sh              # 内核编译脚本
│   ├── error_handler.sh      # 错误处理脚本
│   └── setup.sh              # 环境设置脚本
├── output/
│   ├── images/               # 内核镜像输出
│   ├── modules/              # 内核模块输出
│   ├── dtbs/                 # 设备树输出
│   ├── packages/             # 打包产物
│   └── logs/                 # 编译日志
├── config.env                # 环境配置文件
├── README.md                 # 项目文档
└── LICENSE                   # 许可证
```

## 环境要求

### 系统要求
- 操作系统: Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch Linux
- 内存: 至少 8GB RAM (推荐 16GB+)
- 磁盘空间: 至少 50GB 可用空间
- CPU: 多核处理器 (推荐 4核+)

### 软件依赖
- Git 2.0+
- Make 4.0+
- GCC 9.0+ 或 Clang 10.0+
- Python 3.6+
- Docker (可选，用于容器化编译)

### 交叉编译器
- ARM64: aarch64-linux-gnu-gcc
- ARM: arm-linux-gnueabihf-gcc
- x86_64: gcc/clang

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/yourusername/android-kernel-build.git
cd android-kernel-build
```

### 2. 设置编译环境

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 3. 获取内核源码

```bash
chmod +x scripts/fetch_kernel.sh
./scripts/fetch_kernel.sh -b android13-5.15
```

### 4. 编译内核

```bash
chmod +x scripts/build.sh
./scripts/build.sh -a arm64 -d pixel6 --pack
```

### 5. 查看编译产物

```bash
ls -la output/images/
ls -la output/packages/
```

## 详细使用说明

### 获取内核源码

使用 `fetch_kernel.sh` 脚本自动获取Android内核源码：

```bash
# 基本用法
./scripts/fetch_kernel.sh -b android13-5.15

# 使用特定分支
./scripts/fetch_kernel.sh -b android12-5.10

# 使用特定标签
./scripts/fetch_kernel.sh -b android-5.15.110

# 使用第三方仓库
./scripts/fetch_kernel.sh -r https://github.com/LineageOS/android_kernel_qcom_sm8150 -b lineage-20

# 启用代码完整性校验
./scripts/fetch_kernel.sh -b android13-5.15 -v

# 清理后重新获取
./scripts/fetch_kernel.sh -b android13-5.15 -c

# 使用浅克隆节省空间
./scripts/fetch_kernel.sh -b android13-5.15 -s
```

支持的内核版本：
- android13-5.15
- android13-5.10
- android12-5.10
- android12-5.4
- android11-5.4
- android-4.19-stable
- android-4.14-stable

### 编译内核

使用 `build.sh` 脚本编译内核：

```bash
# 基本用法
./scripts/build.sh -a arm64

# 为特定设备编译
./scripts/build.sh -a arm64 -d pixel6

# 使用自定义配置文件
./scripts/build.sh -a arm64 -c configs/arch/arm64/defconfig

# 指定并行任务数
./scripts/build.sh -a arm64 -j 8

# 启用增量编译
./scripts/build.sh -a arm64 -i

# 使用ccache加速
./scripts/build.sh -a arm64 --ccache

# 打包编译产物
./scripts/build.sh -a arm64 --pack

# 清理编译产物
./scripts/build.sh -a arm64 --clean

# 完全清理
./scripts/build.sh -a arm64 --mrproper

# 详细输出
./scripts/build.sh -a arm64 -v
```

支持的架构：
- `arm64` - 64位ARM，适用于现代Android设备
- `arm` - 32位ARM，适用于传统Android设备
- `x86_64` - 64位x86，适用于Android模拟器

支持的设备：
- Google Pixel系列: `pixel6`, `pixel5`, `pixel4`, `pixel3`
- Samsung系列: `samsung_s21`, `samsung_s20`
- Xiaomi系列: `xiaomi_mi11`, `xiaomi_mi10`
- OnePlus系列: `oneplus_9`, `oneplus_8`
- 通用设备: `generic_arm64`, `generic_arm`, `generic_x86_64`

### 使用Docker编译

使用Docker容器进行编译，确保环境一致性：

```bash
# 构建Docker镜像
cd docker
chmod +x build-docker.sh
./build-docker.sh

# 使用docker-compose启动容器
docker-compose up -d kernel-builder

# 进入容器
docker-compose exec kernel-builder bash

# 在容器中编译
cd /workspace
./scripts/fetch_kernel.sh -b android13-5.15
./scripts/build.sh -a arm64 -d pixel6

# 退出容器
exit

# 停止容器
docker-compose down
```

### 错误处理

使用 `error_handler.sh` 脚本诊断和解决编译问题：

```bash
# 检查系统资源和依赖
./scripts/error_handler.sh --check

# 检查特定架构的编译器
./scripts/error_handler.sh --check --arch arm64

# 分析日志文件
./scripts/error_handler.sh --log output/logs/build.log

# 生成错误报告
./scripts/error_handler.sh --report

# 启用调试模式
./scripts/error_handler.sh --debug
```

常见问题解决：
- **缺少依赖**: 运行 `./scripts/setup.sh` 安装所需依赖
- **内存不足**: 减少并行任务数 `-j 4` 或增加swap空间
- **磁盘空间不足**: 运行 `./scripts/build.sh -a arm64 --clean` 清理
- **编译错误**: 查看详细日志 `cat output/logs/build_*.log`

## 编译产物

编译完成后，产物将输出到以下目录：

```
output/
├── images/               # 内核镜像
│   ├── Image.gz          # ARM64压缩内核镜像
│   ├── Image.gz-dtb      # ARM64内核+设备树镜像
│   ├── zImage           # ARM内核镜像
│   └── bzImage          # x86_64内核镜像
├── modules/              # 内核模块
│   └── *.ko             # 内核模块文件
├── dtbs/                 # 设备树文件
│   └── *.dtb            # 设备树二进制文件
├── packages/             # 打包产物
│   └── kernel_*.tar.gz # 完整的内核包
└── logs/                # 编译日志
    ├── build_*.log      # 编译日志
    ├── error_*.log      # 错误日志
    └── debug_*.log      # 调试日志
```

## 配置文件

### 环境配置 (config.env)

```bash
# 内核源码配置
KERNEL_SOURCE=https://github.com/hjiyu1965/linux-sprd
KERNEL_SOURCE_BRANCH=main
KERNEL_CONFIG=EOL-sprd_sharkle_defconfig
KERNEL_IMAGE_NAME=Image.gz-dtb
ARCH=arm64

# Clang配置
USE_CUSTOM_CLANG=false
CLANG_BRANCH=android10-release
CLANG_VERSION=r353983c

# GCC配置
ENABLE_GCC_ARM64=true
ENABLE_GCC_ARM32=true

# KernelSU配置
ENABLE_KERNELSU=false
KERNELSU_TAG=v0.9.5

# 编译选项
DISABLE_LTO=false
DISABLE_CC_WERROR=false
ENABLE_CCACHE=true
```

### 内核配置文件

内核配置文件位于 `configs/arch/` 目录下：

- `configs/arch/arm64/defconfig` - ARM64内核配置
- `configs/arch/arm/defconfig` - ARM内核配置
- `configs/arch/x86_64/defconfig` - x86_64内核配置

自定义配置：
```bash
# 复制默认配置
cp configs/arch/arm64/defconfig my_defconfig

# 编辑配置
make menuconfig

# 保存配置
cp .config my_defconfig

# 使用自定义配置编译
./scripts/build.sh -a arm64 -c my_defconfig
```

## CI/CD集成

### GitHub Actions

项目包含完整的GitHub Actions工作流配置，支持：

- 自动触发构建（push、PR）
- 多架构并行构建
- 手动触发构建
- 构建产物自动上传
- 自动创建Release
- 构建状态通知

手动触发构建：
1. 进入GitHub仓库的Actions页面
2. 选择 "Android Kernel Build CI/CD" 工作流
3. 点击 "Run workflow"
4. 选择参数（架构、设备等）
5. 点击 "Run workflow"

### Docker Hub

Docker镜像自动构建并推送到Docker Hub：

```bash
# 拉取最新镜像
docker pull android-kernel-builder:latest

# 使用镜像编译
docker run -it --rm -v $(pwd):/workspace android-kernel-builder:latest
```

## 版本控制策略

### 分支策略

- `main` - 主分支，稳定版本
- `develop` - 开发分支，最新功能
- `feature/*` - 功能分支
- `bugfix/*` - 修复分支
- `release/*` - 发布分支

### 版本号规则

版本号格式：`MAJOR.MINOR.PATCH`

- `MAJOR` - 重大版本更新
- `MINOR` - 新功能添加
- `PATCH` - Bug修复

示例：
- `1.0.0` - 初始版本
- `1.1.0` - 添加新功能
- `1.1.1` - 修复bug

### 发布流程

1. 创建发布分支：`git checkout -b release/1.0.0`
2. 更新版本号和变更日志
3. 提交并推送：`git push origin release/1.0.0`
4. 创建Pull Request到main分支
5. 合并后自动创建GitHub Release

## 常见问题排查

### 编译失败

**问题**: 编译过程中出现错误

**解决方案**:
1. 查看详细日志：`cat output/logs/build_*.log`
2. 运行错误诊断：`./scripts/error_handler.sh --log output/logs/build_*.log`
3. 清理后重新编译：`./scripts/build.sh -a arm64 --clean`
4. 减少并行任务数：`./scripts/build.sh -a arm64 -j 4`

### 内存不足

**问题**: 编译过程中出现 "Killed" 或内存错误

**解决方案**:
1. 增加swap空间：
```bash
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```
2. 减少并行任务数：`./scripts/build.sh -a arm64 -j 2`
3. 关闭其他占用内存的程序

### 磁盘空间不足

**问题**: 编译过程中出现 "No space left on device"

**解决方案**:
1. 清理临时文件：
```bash
sudo apt-get clean
sudo journalctl --vacuum-time=7d
```
2. 清理编译产物：`./scripts/build.sh -a arm64 --clean`
3. 删除旧的源码：`rm -rf kernel_source`
4. 扩展磁盘空间

### 交叉编译器未找到

**问题**: 提示交叉编译器未找到

**解决方案**:
1. 安装交叉编译器：
```bash
sudo apt-get install gcc-aarch64-linux-gnu
sudo apt-get install gcc-arm-linux-gnueabihf
```
2. 检查PATH环境变量
3. 使用Docker容器编译

### 依赖缺失

**问题**: 提示缺少某些依赖

**解决方案**:
1. 运行环境设置脚本：`./scripts/setup.sh`
2. 手动安装依赖：
```bash
sudo apt-get install build-essential libncurses-dev libssl-dev libelf-dev bc bison flex
```

## 贡献指南

我们欢迎任何形式的贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详细信息。

### 贡献流程

1. Fork本仓库
2. 创建功能分支：`git checkout -b feature/AmazingFeature`
3. 提交更改：`git commit -m 'Add some AmazingFeature'`
4. 推送到分支：`git push origin feature/AmazingFeature`
5. 创建Pull Request

### 代码规范

- 遵循现有代码风格
- 添加适当的注释
- 编写清晰的提交信息
- 确保所有测试通过

## 许可证

本项目采用 GPL-2.0 许可证。详见 [LICENSE](LICENSE) 文件。

## 致谢

感谢所有为本项目做出贡献的开发者！

## 联系方式

- 问题反馈: [GitHub Issues](https://github.com/yourusername/android-kernel-build/issues)
- 功能建议: [GitHub Discussions](https://github.com/yourusername/android-kernel-build/discussions)
- 邮件: your.email@example.com

## 相关链接

- [Android Open Source Project](https://source.android.com/)
- [Linux Kernel](https://www.kernel.org/)
- [Docker](https://www.docker.com/)
- [GitHub Actions](https://github.com/features/actions)

---

**注意**: 本项目仅用于学习和研究目的。使用本工具编译的内核可能不适合生产环境使用。
