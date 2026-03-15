# Android内核编译管理与自动化构建系统

[![Build Status](https://github.com/your-username/android-kernel-build/actions/workflows/kernel-build.yml/badge.svg)](https://github.com/your-username/android-kernel-build/actions/workflows/kernel-build.yml)
[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://hub.docker.com/)

一个完整的Android内核编译管理与自动化构建系统，支持多架构并行构建、Docker容器化编译环境、GitHub Actions CI/CD自动化。

## 功能特性

- **多架构支持**: 支持 arm64-v8a、armeabi-v7a、x86_64 架构
- **自动化源码获取**: 支持从AOSP官方仓库和第三方仓库自动拉取内核源码
- **Docker容器化**: 提供标准化的Docker编译环境，确保构建一致性
- **预配置文件**: 针对主流Android设备架构的优化内核配置
- **增量编译**: 支持增量编译，加速开发迭代
- **错误处理**: 详细的错误捕获、日志记录和解决方案建议
- **CI/CD集成**: GitHub Actions工作流实现自动化构建和发布
- **产物管理**: 标准化的编译产物输出和打包

## 目录结构

```
.
├── .github/workflows/      # GitHub Actions CI/CD配置
├── configs/               # 内核配置文件
│   └── arch/             # 架构特定配置
│       ├── arm64/        # ARM64配置
│       ├── arm/          # ARM配置
│       └── x86_64/       # x86_64配置
├── docker/               # Docker编译环境
│   ├── Dockerfile        # Docker镜像定义
│   ├── docker-compose.yml
│   └── build-docker.sh   # Docker镜像构建脚本
├── docs/                 # 文档
├── output/               # 编译输出目录
│   ├── images/          # 内核镜像
│   ├── modules/         # 内核模块
│   ├── dtbs/            # 设备树文件
│   ├── packages/        # 打包产物
│   └── logs/            # 编译日志
├── scripts/              # 构建脚本
│   ├── fetch_kernel.sh  # 内核源码获取
│   ├── build.sh         # 主编译脚本
│   └── error_handler.sh # 错误处理
├── tools/                # 辅助工具
├── CONTRIBUTING.md       # 贡献指南
├── LICENSE              # 许可证
└── README.md            # 本文件
```

## 快速开始

### 环境要求

- **操作系统**: Linux (Ubuntu 20.04+ 推荐)
- **内存**: 至少 4GB RAM (推荐 8GB+)
- **磁盘空间**: 至少 50GB 可用空间
- **Docker**: 20.10+ (可选，用于容器化编译)

### 基础依赖安装

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    git curl wget \
    build-essential libncurses-dev \
    bison flex libssl-dev libelf-dev \
    bc cpio kmod \
    device-tree-compiler \
    python3 python3-pip

# 安装交叉编译器
sudo apt-get install -y \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabihf

# 安装Clang/LLVM (可选但推荐)
sudo apt-get install -y clang llvm lld
```

### 1. 克隆本仓库

```bash
git clone https://github.com/your-username/android-kernel-build.git
cd android-kernel-build
```

### 2. 获取内核源码

```bash
# 获取AOSP官方内核 (默认: android13-5.15)
./scripts/fetch_kernel.sh

# 获取特定分支
./scripts/fetch_kernel.sh -b android13-5.15

# 获取第三方内核
./scripts/fetch_kernel.sh \
    -r https://github.com/LineageOS/android_kernel_qcom_sm8150 \
    -b lineage-20

# 使用repo工具获取 (AOSP官方)
./scripts/fetch_kernel.sh -b android13-5.15 -v
```

### 3. 编译内核

```bash
# 使用默认配置编译 (ARM64)
./scripts/build.sh

# 为特定设备编译
./scripts/build.sh -d pixel6

# 使用自定义配置
./scripts/build.sh -c my_custom_defconfig

# 指定架构
./scripts/build.sh -a arm64

# 清理后重新编译
./scripts/build.sh --clean

# 启动配置界面
./scripts/build.sh --menuconfig

# 编译并打包
./scripts/build.sh --pack
```

### 4. 使用Docker编译 (推荐)

```bash
# 构建Docker镜像
./docker/build-docker.sh

# 启动编译环境
docker-compose up -d kernel-builder

# 进入编译容器
docker-compose exec kernel-builder bash

# 在容器内编译
/workspace/scripts/build.sh

# 一键编译
docker-compose run --rm kernel-builder \
    /workspace/scripts/build.sh -a arm64 --pack
```

## 详细使用说明

### 内核源码获取脚本

```bash
./scripts/fetch_kernel.sh [选项]

选项:
    -h, --help              显示帮助信息
    -r, --repo URL          指定内核仓库URL
    -b, --branch BRANCH     指定分支/标签/提交哈希
    -d, --directory DIR     指定源码存放目录
    -c, --clean             清理现有目录后重新获取
    -v, --verify            启用代码完整性校验
    -s, --shallow           使用浅克隆
    -j, --jobs N            并行下载任务数
    --mr-proper             下载后执行mrproper清理
```

### 编译脚本

```bash
./scripts/build.sh [选项]

选项:
    -h, --help              显示帮助信息
    -a, --arch ARCH         目标架构 (arm64|arm|x86_64)
    -d, --device DEVICE     目标设备型号
    -c, --config CONFIG     指定defconfig配置文件
    -j, --jobs N            并行编译任务数
    --clean                 清理后重新编译
    --mrproper              执行make mrproper清理
    --menuconfig            启动menuconfig配置界面
    --no-modules            不编译内核模块
    --no-dtbs               不编译设备树
    --pack                  编译完成后打包产物
    -v, --verbose           显示详细输出
```

### 支持的设备

| 设备 | 架构 | 配置 |
|------|------|------|
| Google Pixel 6/6 Pro | arm64 | gs101_defconfig |
| Google Pixel 7/7 Pro | arm64 | gs201_defconfig |
| Samsung Galaxy S22 | arm64 | exynos2200_defconfig |
| Samsung Galaxy S23 | arm64 | snapdragon8gen2_defconfig |
| Xiaomi 13/13 Pro | arm64 | snapdragon8gen2_defconfig |
| OnePlus 11 | arm64 | snapdragon8gen2_defconfig |
| 通用ARM64 | arm64 | defconfig |
| 通用ARM | arm | defconfig |
| 通用x86_64 | x86_64 | x86_64_defconfig |

## CI/CD自动化

本仓库包含完整的GitHub Actions工作流配置：

### 自动触发条件

- **Push到main分支**: 自动触发多架构构建
- **Pull Request**: 验证构建是否通过
- **手动触发**: 支持自定义参数的手动构建

### 构建矩阵

| 架构 | 状态 | 产物 |
|------|------|------|
| ARM64 | ✅ | Image.gz, modules, dtbs |
| ARM | ✅ | zImage, modules, dtbs |
| x86_64 | ✅ | bzImage, modules |

### 使用GitHub Actions

1. Fork本仓库
2. 在Settings > Secrets中添加必要的密钥
3. 推送代码或手动触发工作流
4. 在Actions标签页查看构建状态
5. 下载构建产物或查看自动发布的Release

## 常见问题

### Q: 编译失败，提示缺少依赖

A: 运行以下命令安装依赖：
```bash
sudo apt-get update
sudo apt-get install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev
```

### Q: 交叉编译器未找到

A: 安装交叉编译器：
```bash
sudo apt-get install -y gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf
```

### Q: 内存不足导致编译失败

A: 减少并行任务数：
```bash
./scripts/build.sh -j2  # 使用2个并行任务
```

### Q: 如何添加新的设备支持

A: 
1. 在 `configs/arch/<arch>/` 目录添加设备配置文件
2. 在 `scripts/build.sh` 的 `DEVICE_CONFIGS` 数组中添加设备映射
3. 提交Pull Request

### Q: Docker编译速度较慢

A: 
1. 启用ccache缓存
2. 使用本地Docker镜像
3. 增加Docker容器的CPU和内存限制

## 故障排查

### 查看详细日志

```bash
# 查看最新编译日志
tail -f output/logs/build_*.log

# 分析错误日志
./scripts/error_handler.sh analyze output/logs/build_*.log

# 诊断环境
./scripts/error_handler.sh diagnose
```

### 清理构建环境

```bash
# 清理编译产物
make clean

# 完全清理
make mrproper

# 删除输出目录
rm -rf output/*

# 使用脚本清理
./scripts/build.sh --clean
```

## 版本控制策略

- **主分支**: `main` - 稳定版本
- **开发分支**: `develop` - 开发中的功能
- **功能分支**: `feature/*` - 新功能开发
- **修复分支**: `hotfix/*` - 紧急修复

版本号格式: `v主版本.次版本.修订号`

## 贡献指南

我们欢迎所有形式的贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详细信息。

### 提交Issue

- 使用清晰的标题描述问题
- 提供详细的复现步骤
- 附上相关的日志文件
- 说明环境信息(操作系统、架构等)

### 提交Pull Request

1. Fork本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

## 许可证

本项目采用 [GPL-2.0](LICENSE) 许可证。

内核源码遵循其各自的许可证(通常为GPL-2.0)。

## 致谢

- [Android Open Source Project](https://source.android.com/)
- [LineageOS](https://lineageos.org/)
- [Kernel.org](https://www.kernel.org/)

## 联系方式

- 项目主页: https://github.com/your-username/android-kernel-build
- Issue追踪: https://github.com/your-username/android-kernel-build/issues
- 邮件: your-email@example.com

---

**注意**: 本项目和编译的内核仅供学习和研究使用。使用编译的内核可能导致设备保修失效，请自行承担风险。
