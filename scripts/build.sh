#!/bin/bash

# Android内核编译脚本
# 实现完整的编译流程自动化
# 支持配置加载、增量编译、多线程编译优化
# 作者: Android Kernel Build System
# 版本: 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认配置
WORK_DIR="$(pwd)"
KERNEL_DIR="${WORK_DIR}/kernel_source"
OUTPUT_DIR="${WORK_DIR}/output"
CONFIG_DIR="${WORK_DIR}/configs"
LOG_DIR="${OUTPUT_DIR}/logs"
BUILD_LOG="${LOG_DIR}/build_$(date +%Y%m%d_%H%M%S).log"
ERROR_LOG="${LOG_DIR}/error_$(date +%Y%m%d_%H%M%S).log"

# 编译配置
ARCH=""
CROSS_COMPILE=""
CC=""
CLANG_TRIPLE=""
DEFCONFIG=""
DEVICE=""
JOBS=$(nproc)
INCREMENTAL=false
PACK=false
CLEAN=false
MRPROPER=false
USE_CCACHE=false
VERBOSE=false

# 支持的设备配置
declare -A DEVICE_CONFIGS=(
    ["pixel6"]="arch/arm64/defconfig"
    ["pixel5"]="arch/arm64/defconfig"
    ["pixel4"]="arch/arm64/defconfig"
    ["pixel3"]="arch/arm64/defconfig"
    ["samsung_s21"]="arch/arm64/defconfig"
    ["samsung_s20"]="arch/arm64/defconfig"
    ["xiaomi_mi11"]="arch/arm64/defconfig"
    ["xiaomi_mi10"]="arch/arm64/defconfig"
    ["oneplus_9"]="arch/arm64/defconfig"
    ["oneplus_8"]="arch/arm64/defconfig"
    ["generic_arm64"]="arch/arm64/defconfig"
    ["generic_arm"]="arch/arm/defconfig"
    ["generic_x86_64"]="arch/x86_64/defconfig"
)

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$BUILD_LOG"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$BUILD_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$BUILD_LOG" | tee -a "$ERROR_LOG"
}

log_debug() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" | tee -a "$BUILD_LOG"
    fi
}

# 使用说明
usage() {
    cat << EOF
Android内核编译脚本

用法: $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -a, --arch ARCH         指定目标架构 (arm64, arm, x86_64)
    -d, --device DEVICE     指定目标设备 (pixel6, samsung_s21, xiaomi_mi11等)
    -c, --config CONFIG     指定内核配置文件路径
    -j, --jobs N            并行编译任务数 (默认: $(nproc))
    -i, --incremental       启用增量编译
    -p, --pack              打包编译产物
    --clean                 清理编译产物
    --mrproper              执行 make mrproper
    --ccache                使用ccache加速编译
    -v, --verbose           详细输出模式
    --kernel-dir DIR        指定内核源码目录 (默认: ${KERNEL_DIR})
    --output-dir DIR        指定输出目录 (默认: ${OUTPUT_DIR})

示例:
    $0 -a arm64 -d pixel6 --pack
    $0 -a arm64 -c arch/arm64/defconfig -j 8
    $0 -a arm64 --incremental --ccache
    $0 --clean

支持的架构:
    - arm64   (64位ARM，适用于现代Android设备)
    - arm     (32位ARM，适用于传统Android设备)
    - x86_64  (64位x86，适用于Android模拟器)

支持的设备:
    - Google Pixel系列: pixel6, pixel5, pixel4, pixel3
    - Samsung系列: samsung_s21, samsung_s20
    - Xiaomi系列: xiaomi_mi11, xiaomi_mi10
    - OnePlus系列: oneplus_9, oneplus_8
    - 通用设备: generic_arm64, generic_arm, generic_x86_64

EOF
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -a|--arch)
            ARCH="$2"
            shift 2
            ;;
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -c|--config)
            DEFCONFIG="$2"
            shift 2
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -i|--incremental)
            INCREMENTAL=true
            shift
            ;;
        -p|--pack)
            PACK=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --mrproper)
            MRPROPER=true
            shift
            ;;
        --ccache)
            USE_CCACHE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --kernel-dir)
            KERNEL_DIR="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            log_error "未知选项: $1"
            usage
            exit 1
            ;;
    esac
done

# 创建输出目录
mkdir -p "$OUTPUT_DIR"/{images,modules,dtbs,packages,logs}

# 检查内核源码目录
check_kernel_source() {
    log_info "检查内核源码目录..."
    
    if [ ! -d "$KERNEL_DIR" ]; then
        log_error "内核源码目录不存在: $KERNEL_DIR"
        log_info "请先运行: ./scripts/fetch_kernel.sh"
        exit 1
    fi
    
    if [ ! -f "$KERNEL_DIR/Makefile" ]; then
        log_error "未找到内核Makefile，目录可能不是有效的内核源码"
        exit 1
    fi
    
    log_info "内核源码目录检查通过"
}

# 设置编译环境
setup_build_env() {
    log_info "设置编译环境..."
    
    case "$ARCH" in
        arm64)
            ARCH="arm64"
            CROSS_COMPILE="aarch64-linux-gnu-"
            CC="clang"
            CLANG_TRIPLE="aarch64-linux-gnu-"
            ;;
        arm)
            ARCH="arm"
            CROSS_COMPILE="arm-linux-gnueabihf-"
            CC="clang"
            CLANG_TRIPLE="arm-linux-gnueabihf-"
            ;;
        x86_64)
            ARCH="x86_64"
            CROSS_COMPILE=""
            CC="clang"
            CLANG_TRIPLE="x86_64-linux-gnu-"
            ;;
        *)
            log_error "不支持的架构: $ARCH"
            log_info "支持的架构: arm64, arm, x86_64"
            exit 1
            ;;
    esac
    
    # 检查交叉编译器
    if [ -n "$CROSS_COMPILE" ]; then
        if ! command -v "${CROSS_COMPILE}gcc" &> /dev/null; then
            log_warn "交叉编译器 ${CROSS_COMPILE}gcc 未找到"
            log_info "尝试使用Clang编译器..."
        fi
    fi
    
    # 检查Clang
    if ! command -v "$CC" &> /dev/null; then
        log_warn "编译器 $CC 未找到"
        log_info "尝试使用gcc..."
        CC="gcc"
        if ! command -v "$CC" &> /dev/null; then
            log_error "未找到可用的编译器"
            exit 1
        fi
    fi
    
    # 设置ccache
    if [ "$USE_CCACHE" = true ]; then
        if command -v ccache &> /dev/null; then
            export CC="ccache $CC"
            log_info "已启用ccache加速"
        else
            log_warn "ccache未安装，跳过ccache"
        fi
    fi
    
    # 设置环境变量
    export ARCH
    export CROSS_COMPILE
    export CC
    export CLANG_TRIPLE
    export KBUILD_OUTPUT="${OUTPUT_DIR}/build"
    
    log_info "编译环境配置:"
    log_info "  架构: $ARCH"
    log_info "  交叉编译器: $CROSS_COMPILE"
    log_info "  编译器: $CC"
    log_info "  Clang Triple: $CLANG_TRIPLE"
    log_info "  并行任务数: $JOBS"
}

# 清理编译产物
clean_build() {
    log_info "清理编译产物..."
    cd "$KERNEL_DIR"
    
    if [ "$MRPROPER" = true ]; then
        log_info "执行 make mrproper..."
        make mrproper 2>&1 | tee -a "$BUILD_LOG"
    elif [ "$CLEAN" = true ]; then
        log_info "执行 make clean..."
        make clean 2>&1 | tee -a "$BUILD_LOG"
    fi
    
    # 清理输出目录
    rm -rf "${OUTPUT_DIR}/build"
    rm -rf "${OUTPUT_DIR}/images"/*
    rm -rf "${OUTPUT_DIR}/modules"/*
    rm -rf "${OUTPUT_DIR}/dtbs"/*
    
    log_info "清理完成"
}

# 配置内核
configure_kernel() {
    log_info "配置内核..."
    cd "$KERNEL_DIR"
    
    # 确定使用的配置文件
    if [ -n "$DEFCONFIG" ]; then
        # 使用指定的配置文件
        if [ -f "$DEFCONFIG" ]; then
            log_info "使用配置文件: $DEFCONFIG"
            cp "$DEFCONFIG" .config
        elif [ -f "$CONFIG_DIR/$DEFCONFIG" ]; then
            log_info "使用配置文件: $CONFIG_DIR/$DEFCONFIG"
            cp "$CONFIG_DIR/$DEFCONFIG" .config
        else
            log_error "配置文件不存在: $DEFCONFIG"
            exit 1
        fi
    elif [ -n "$DEVICE" ]; then
        # 使用设备预设配置
        if [ -n "${DEVICE_CONFIGS[$DEVICE]}" ]; then
            DEFCONFIG="${DEVICE_CONFIGS[$DEVICE]}"
            log_info "使用设备配置: $DEVICE -> $DEFCONFIG"
            
            if [ -f "$CONFIG_DIR/$DEFCONFIG" ]; then
                cp "$CONFIG_DIR/$DEFCONFIG" .config
            else
                log_warn "设备配置文件不存在，使用默认配置"
                make defconfig 2>&1 | tee -a "$BUILD_LOG"
            fi
        else
            log_error "不支持的设备: $DEVICE"
            log_info "支持的设备: ${!DEVICE_CONFIGS[@]}"
            exit 1
        fi
    else
        # 使用默认配置
        log_info "使用默认配置"
        make defconfig 2>&1 | tee -a "$BUILD_LOG"
    fi
    
    # 更新配置
    log_info "更新内核配置..."
    make olddefconfig 2>&1 | tee -a "$BUILD_LOG"
    
    log_info "内核配置完成"
}

# 编译内核
build_kernel() {
    log_info "======================================"
    log_info "开始编译内核"
    log_info "======================================"
    cd "$KERNEL_DIR"
    
    # 编译内核镜像
    log_info "编译内核镜像..."
    make -j"$JOBS" 2>&1 | tee -a "$BUILD_LOG"
    
    if [ $? -eq 0 ]; then
        log_info "内核镜像编译成功"
    else
        log_error "内核镜像编译失败"
        exit 1
    fi
    
    # 编译模块
    log_info "编译内核模块..."
    make -j"$JOBS" modules 2>&1 | tee -a "$BUILD_LOG"
    
    if [ $? -eq 0 ]; then
        log_info "内核模块编译成功"
    else
        log_warn "内核模块编译失败(可能是正常情况)"
    fi
    
    # 编译设备树
    log_info "编译设备树..."
    make -j"$JOBS" dtbs 2>&1 | tee -a "$BUILD_LOG"
    
    if [ $? -eq 0 ]; then
        log_info "设备树编译成功"
    else
        log_warn "设备树编译失败(可能是正常情况)"
    fi
    
    log_info "======================================"
    log_info "内核编译完成!"
    log_info "======================================"
}

# 复制编译产物
copy_artifacts() {
    log_info "复制编译产物..."
    
    # 创建输出目录
    mkdir -p "${OUTPUT_DIR}/images"
    mkdir -p "${OUTPUT_DIR}/modules"
    mkdir -p "${OUTPUT_DIR}/dtbs"
    
    # 复制内核镜像
    case "$ARCH" in
        arm64)
            if [ -f "${OUTPUT_DIR}/build/arch/arm64/boot/Image.gz" ]; then
                cp "${OUTPUT_DIR}/build/arch/arm64/boot/Image.gz" "${OUTPUT_DIR}/images/"
                log_info "已复制: Image.gz"
            fi
            if [ -f "${OUTPUT_DIR}/build/arch/arm64/boot/Image.gz-dtb" ]; then
                cp "${OUTPUT_DIR}/build/arch/arm64/boot/Image.gz-dtb" "${OUTPUT_DIR}/images/"
                log_info "已复制: Image.gz-dtb"
            fi
            ;;
        arm)
            if [ -f "${OUTPUT_DIR}/build/arch/arm/boot/zImage" ]; then
                cp "${OUTPUT_DIR}/build/arch/arm/boot/zImage" "${OUTPUT_DIR}/images/"
                log_info "已复制: zImage"
            fi
            ;;
        x86_64)
            if [ -f "${OUTPUT_DIR}/build/arch/x86/boot/bzImage" ]; then
                cp "${OUTPUT_DIR}/build/arch/x86/boot/bzImage" "${OUTPUT_DIR}/images/"
                log_info "已复制: bzImage"
            fi
            ;;
    esac
    
    # 复制模块
    if [ -d "${OUTPUT_DIR}/build/lib/modules" ]; then
        cp -r "${OUTPUT_DIR}/build/lib/modules"/* "${OUTPUT_DIR}/modules/"
        log_info "已复制内核模块"
    fi
    
    # 复制设备树
    if [ -d "${OUTPUT_DIR}/build/arch/$ARCH/boot/dts" ]; then
        find "${OUTPUT_DIR}/build/arch/$ARCH/boot/dts" -name "*.dtb" -exec cp {} "${OUTPUT_DIR}/dtbs/" \;
        log_info "已复制设备树文件"
    fi
    
    log_info "编译产物复制完成"
}

# 打包编译产物
pack_artifacts() {
    if [ "$PACK" = false ]; then
        return 0
    fi
    
    log_info "打包编译产物..."
    
    # 生成版本信息
    local version=$(cd "$KERNEL_DIR" && git describe --tags --always 2>/dev/null || echo "unknown")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local package_name="kernel_${ARCH}_${version}_${timestamp}"
    
    # 创建打包目录
    local package_dir="${OUTPUT_DIR}/packages/${package_name}"
    mkdir -p "$package_dir"
    
    # 复制文件到打包目录
    cp -r "${OUTPUT_DIR}/images"/* "$package_dir/" 2>/dev/null || true
    cp -r "${OUTPUT_DIR}/modules"/* "$package_dir/" 2>/dev/null || true
    cp -r "${OUTPUT_DIR}/dtbs"/* "$package_dir/" 2>/dev/null || true
    
    # 复制配置文件
    cp "$KERNEL_DIR/.config" "$package_dir/kernel.config"
    
    # 生成编译信息
    cat > "$package_dir/build_info.txt" << EOF
Android内核编译信息
==================
编译时间: $(date)
架构: $ARCH
设备: ${DEVICE:-generic}
版本: $version
并行任务数: $JOBS
增量编译: $INCREMENTAL
使用ccache: $USE_CCACHE

编译器信息:
$(cd "$KERNEL_DIR" && make kernelversion 2>/dev/null || echo "unknown")

Git信息:
$(cd "$KERNEL_DIR" && git log -1 --oneline 2>/dev/null || echo "not a git repository")
EOF
    
    # 创建压缩包
    cd "${OUTPUT_DIR}/packages"
    tar -czf "${package_name}.tar.gz" "$package_name"
    
    log_info "打包完成: ${OUTPUT_DIR}/packages/${package_name}.tar.gz"
}

# 生成编译报告
generate_report() {
    log_info "生成编译报告..."
    
    local report_file="${OUTPUT_DIR}/build_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
Android内核编译报告
==================
编译时间: $(date)
工作目录: $WORK_DIR
内核目录: $KERNEL_DIR
输出目录: $OUTPUT_DIR

编译配置:
  架构: $ARCH
  设备: ${DEVICE:-generic}
  配置文件: ${DEFCONFIG:-default}
  并行任务数: $JOBS
  增量编译: $INCREMENTAL
  使用ccache: $USE_CCACHE

编译产物:
EOF
    
    # 列出编译产物
    if [ -d "${OUTPUT_DIR}/images" ]; then
        echo "  内核镜像:" >> "$report_file"
        ls -lh "${OUTPUT_DIR}/images" 2>/dev/null | grep -v "^total" | awk '{print "    " $9 " (" $5 ")"}' >> "$report_file"
    fi
    
    if [ -d "${OUTPUT_DIR}/modules" ]; then
        local module_count=$(find "${OUTPUT_DIR}/modules" -name "*.ko" 2>/dev/null | wc -l)
        echo "  内核模块: $module_count 个" >> "$report_file"
    fi
    
    if [ -d "${OUTPUT_DIR}/dtbs" ]; then
        local dtb_count=$(find "${OUTPUT_DIR}/dtbs" -name "*.dtb" 2>/dev/null | wc -l)
        echo "  设备树: $dtb_count 个" >> "$report_file"
    fi
    
    if [ -d "${OUTPUT_DIR}/packages" ]; then
        echo "  打包文件:" >> "$report_file"
        ls -lh "${OUTPUT_DIR}/packages"/*.tar.gz 2>/dev/null | awk '{print "    " $9 " (" $5 ")"}' >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

编译日志:
  详细日志: $BUILD_LOG
  错误日志: $ERROR_LOG

EOF
    
    log_info "编译报告已保存: $report_file"
}

# 主函数
main() {
    log_info "======================================"
    log_info "Android内核编译脚本 v1.0.0"
    log_info "======================================"
    
    # 检查架构参数
    if [ -z "$ARCH" ] && [ -z "$DEVICE" ]; then
        log_error "必须指定架构或设备"
        usage
        exit 1
    fi
    
    # 检查内核源码
    check_kernel_source
    
    # 设置编译环境
    setup_build_env
    
    # 清理
    if [ "$CLEAN" = true ] || [ "$MRPROPER" = true ]; then
        clean_build
        exit 0
    fi
    
    # 配置内核
    configure_kernel
    
    # 编译内核
    build_kernel
    
    # 复制编译产物
    copy_artifacts
    
    # 打包
    pack_artifacts
    
    # 生成报告
    generate_report
    
    log_info "======================================"
    log_info "编译成功完成!"
    log_info "======================================"
    
    # 输出下一步操作建议
    cat << EOF

编译产物位置:
  内核镜像: ${OUTPUT_DIR}/images/
  内核模块: ${OUTPUT_DIR}/modules/
  设备树: ${OUTPUT_DIR}/dtbs/
  打包文件: ${OUTPUT_DIR}/packages/

下一步操作:
  1. 查看编译产物: ls -la ${OUTPUT_DIR}/images/
  2. 查看编译报告: cat ${OUTPUT_DIR}/build_report_*.txt
  3. 打包产物: ./scripts/build.sh -a $ARCH --pack

EOF
}

# 执行主函数
main "$@"
