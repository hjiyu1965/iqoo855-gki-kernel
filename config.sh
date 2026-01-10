#!/bin/bash
# ============================================
# iQOO 855 (SM8150) GKI 内核构建配置
# 用于 GitHub Actions 工作流
# ============================================

# 1. 【设备与版本信息 - 必须准确！】
# 你的手机型号
export DEVICE_NAME="IQOO 855 (Neo 855)"
export DEVICE_CODENAME="v1936a"  # iQOO 855的型号代码，可在设置-关于手机中查找

# 【核心】Android 版本 - 通过以下命令在手机中确认：
#     adb shell getprop ro.build.version.release
# 例如：显示 "13" 则填 "android13"
export ANDROID_VERSION="android13"

# 【核心】内核主版本 - 通过以下命令确认：
#     adb shell uname -r
# 例如：显示 "4.14.199-gki-..." 则主版本为 "4.14"
export KERNEL_VERSION="4.14"

# 【核心】内核子版本 - 从 uname -r 输出中获取
# 例如："4.14.199-gki-..." 中的 199
export KERNEL_SUBLEVEL="199"

# 【核心】安全补丁级别 - 在手机设置-关于手机-Android版本中查看
# 格式必须为：YYYY-MM-DD
export SECURITY_PATCH="2024-01-05"

# 2. 【GKI 源码分支 - 通常自动生成】
# 基于上述版本，GKI 源码分支通常为以下格式：
export GKI_BRANCH="common-${ANDROID_VERSION}-${KERNEL_VERSION}"

# 3. 【功能选择】
# KernelSU 变体：Official, Next, MKSU, SukiSU
export KERNELSU_VARIANT="SukiSU"
# 是否启用 SUSFS (SukiSU 文件系统)
export WITH_SUSFS="true"
# 是否启用 KPM (内核模块管理)
export WITH_KPM="true"
# 是否启用 ZRAM 增强算法 (首次建议关闭)
export WITH_ZRAM="false"
# 是否为一加设备 (iQOO 必须为 false)
export SUPPORT_ONEPLUS="false"
# 是否启用 Baseband-guard
export WITH_BBG="false"

# 4. 【构建选项】
# 同时运行的编译任务数 (GitHub Actions 机器通常为 2 核)
export MAKE_JOBS="2"
# 构建输出目录名称
export OUTPUT_DIR="output"1
