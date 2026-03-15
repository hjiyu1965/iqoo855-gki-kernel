#!/bin/bash

# Android内核源码获取脚本
# 支持自动拉取指定版本Android内核源码，包含代码完整性校验
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
DEFAULT_KERNEL_REPO="https://android.googlesource.com/kernel/common"
DEFAULT_BRANCH="android13-5.15"
DEFAULT_MANIFEST_REPO="https://android.googlesource.com/kernel/manifest"
WORK_DIR="$(pwd)"
KERNEL_DIR="${WORK_DIR}/kernel_source"
MANIFEST_DIR="${WORK_DIR}/.repo/manifests"
LOG_FILE="${WORK_DIR}/output/logs/fetch_kernel.log"

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1" | tee -a "$LOG_FILE"
}

# 使用说明
usage() {
    cat << EOF
Android内核源码获取脚本

用法: $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -r, --repo URL          指定内核仓库URL (默认: ${DEFAULT_KERNEL_REPO})
    -b, --branch BRANCH     指定分支/标签/提交哈希 (默认: ${DEFAULT_BRANCH})
    -m, --manifest URL      指定manifest仓库URL (默认: ${DEFAULT_MANIFEST_REPO})
    -d, --directory DIR     指定源码存放目录 (默认: ${KERNEL_DIR})
    -c, --clean             清理现有源码目录后重新获取
    -v, --verify            启用代码完整性校验
    -s, --shallow           使用浅克隆(节省空间，但无法查看完整历史)
    -j, --jobs N            并行下载任务数 (默认: 4)
    --mr-proper             下载后执行 mrproper 清理

示例:
    $0 -b android13-5.15 -v
    $0 -r https://github.com/LineageOS/android_kernel_qcom_sm8150 -b lineage-20
    $0 -c -b android13-5.15-r1 --mr-proper

支持的内核版本:
    - android13-5.15
    - android13-5.10
    - android12-5.10
    - android12-5.4
    - android11-5.4
    - android-4.19-stable
    - android-4.14-stable

EOF
}

# 参数解析
KERNEL_REPO="$DEFAULT_KERNEL_REPO"
BRANCH="$DEFAULT_BRANCH"
MANIFEST_REPO="$DEFAULT_MANIFEST_REPO"
CLEAN=false
VERIFY=false
SHALLOW=false
MRPROPER=false
JOBS=4

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -r|--repo)
            KERNEL_REPO="$2"
            shift 2
            ;;
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        -m|--manifest)
            MANIFEST_REPO="$2"
            shift 2
            ;;
        -d|--directory)
            KERNEL_DIR="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -v|--verify)
            VERIFY=true
            shift
            ;;
        -s|--shallow)
            SHALLOW=true
            shift
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        --mr-proper)
            MRPROPER=true
            shift
            ;;
        *)
            log_error "未知选项: $1"
            usage
            exit 1
            ;;
    esac
done

# 检查依赖
check_dependencies() {
    log_info "检查依赖环境..."
    
    local deps=("git" "curl" "sha256sum" "tar")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少以下依赖: ${missing_deps[*]}"
        log_info "请安装缺失的依赖后重试"
        
        # 提供安装建议
        if command -v apt-get &> /dev/null; then
            log_info "Debian/Ubuntu系统运行: sudo apt-get install -y ${missing_deps[*]}"
        elif command -v yum &> /dev/null; then
            log_info "RHEL/CentOS系统运行: sudo yum install -y ${missing_deps[*]}"
        elif command -v pacman &> /dev/null; then
            log_info "Arch Linux系统运行: sudo pacman -S ${missing_deps[*]}"
        fi
        
        exit 1
    fi
    
    log_info "依赖检查通过"
}

# 清理现有目录
clean_directory() {
    if [ "$CLEAN" = true ] && [ -d "$KERNEL_DIR" ]; then
        log_warn "清理现有内核源码目录: $KERNEL_DIR"
        rm -rf "$KERNEL_DIR"
    fi
}

# 使用repo工具获取源码(适用于AOSP官方内核)
fetch_with_repo() {
    log_info "使用repo工具获取内核源码..."
    
    if ! command -v repo &> /dev/null; then
        log_warn "repo工具未安装，尝试安装..."
        
        # 下载repo工具
        mkdir -p ~/bin
        curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
        chmod a+x ~/bin/repo
        export PATH="$HOME/bin:$PATH"
        
        if ! command -v repo &> /dev/null; then
            log_error "repo工具安装失败，请手动安装"
            exit 1
        fi
    fi
    
    mkdir -p "$KERNEL_DIR"
    cd "$KERNEL_DIR"
    
    # 初始化repo
    log_info "初始化repo，分支: $BRANCH"
    repo init -u "$MANIFEST_REPO" -b "$BRANCH" --partial-clone --clone-filter=blob:limit=10M
    
    # 同步源码
    log_info "开始同步源码(使用$JOBS个并行任务)..."
    repo sync -c -j$JOBS --current-branch --no-tags --optimized-fetch --prune
    
    if [ $? -eq 0 ]; then
        log_info "Repo同步完成"
    else
        log_error "Repo同步失败"
        exit 1
    fi
}

# 使用git直接克隆(适用于第三方内核)
fetch_with_git() {
    log_info "使用git克隆内核源码..."
    log_info "仓库: $KERNEL_REPO"
    log_info "分支/标签: $BRANCH"
    
    mkdir -p "$(dirname "$KERNEL_DIR")"
    
    local git_opts=""
    if [ "$SHALLOW" = true ]; then
        git_opts="--depth 1"
        log_info "使用浅克隆模式"
    fi
    
    # 克隆仓库
    git clone $git_opts -b "$BRANCH" --single-branch "$KERNEL_REPO" "$KERNEL_DIR"
    
    if [ $? -eq 0 ]; then
        log_info "Git克隆完成"
    else
        log_error "Git克隆失败"
        exit 1
    fi
    
    cd "$KERNEL_DIR"
    
    # 显示克隆信息
    log_info "克隆的内核版本信息:"
    git log -1 --oneline
    git describe --tags --always 2>/dev/null || log_warn "无标签信息"
}

# 代码完整性校验
verify_source() {
    if [ "$VERIFY" = false ]; then
        return 0
    fi
    
    log_info "开始代码完整性校验..."
    cd "$KERNEL_DIR"
    
    # 检查Git仓库完整性
    log_info "检查Git仓库完整性..."
    if git fsck --full --strict 2>&1 | tee -a "$LOG_FILE"; then
        log_info "Git仓库完整性检查通过"
    else
        log_warn "Git仓库完整性检查发现问题"
    fi
    
    # 生成源码校验和
    log_info "生成源码文件校验和..."
    find . -type f -name "*.c" -o -name "*.h" -o -name "*.S" -o -name "Kconfig" -o -name "Makefile" 2>/dev/null | \
        sort | xargs sha256sum > "${WORK_DIR}/output/source_checksums.txt"
    
    local file_count=$(wc -l < "${WORK_DIR}/output/source_checksums.txt")
    log_info "已生成 $file_count 个文件的校验和"
    
    # 验证关键文件存在
    log_info "验证关键内核文件..."
    local required_files=("Makefile" "Kconfig" "arch" "drivers" "fs" "include" "kernel" "mm")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -e "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        log_info "关键文件验证通过"
    else
        log_error "缺少关键文件: ${missing_files[*]}"
        exit 1
    fi
}

# 执行mrproper清理
run_mrproper() {
    if [ "$MRPROPER" = false ]; then
        return 0
    fi
    
    log_info "执行 make mrproper 清理..."
    cd "$KERNEL_DIR"
    
    # 检查是否有Makefile
    if [ ! -f "Makefile" ]; then
        log_warn "未找到Makefile，跳过mrproper"
        return 0
    fi
    
    make mrproper 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log_info "mrproper 清理完成"
    else
        log_warn "mrproper 执行失败(可能是正常情况，源码尚未配置)"
    fi
}

# 生成源码信息报告
generate_source_info() {
    log_info "生成源码信息报告..."
    cd "$KERNEL_DIR"
    
    local info_file="${WORK_DIR}/output/source_info.txt"
    
    cat > "$info_file" << EOF
Android内核源码信息报告
========================
生成时间: $(date)

仓库信息:
  - 仓库URL: $KERNEL_REPO
  - 分支/标签: $BRANCH
  - 本地路径: $KERNEL_DIR

Git信息:
EOF

    if [ -d ".git" ]; then
        echo "  - 提交哈希: $(git rev-parse HEAD)" >> "$info_file"
        echo "  - 提交日期: $(git log -1 --format=%cd)" >> "$info_file"
        echo "  - 提交作者: $(git log -1 --format=%an)" >> "$info_file"
        echo "  - 提交信息: $(git log -1 --format=%s)" >> "$info_file"
        
        if git describe --tags --exact-match HEAD &>/dev/null; then
            echo "  - 标签: $(git describe --tags --exact-match HEAD)" >> "$info_file"
        fi
    fi
    
    cat >> "$info_file" << EOF

源码统计:
  - 总文件数: $(find . -type f | wc -l)
  - C文件数: $(find . -name "*.c" | wc -l)
  - 头文件数: $(find . -name "*.h" | wc -l)
  - Makefile数: $(find . -name "Makefile" | wc -l)
  - Kconfig数: $(find . -name "Kconfig" | wc -l)

目录结构:
$(ls -la | head -20)
EOF
    
    log_info "源码信息报告已保存到: $info_file"
}

# 主函数
main() {
    log_info "======================================"
    log_info "Android内核源码获取脚本 v1.0.0"
    log_info "======================================"
    
    # 检查依赖
    check_dependencies
    
    # 清理目录
    clean_directory
    
    # 判断使用repo还是git
    if [[ "$KERNEL_REPO" == *"android.googlesource.com"* ]] || [[ "$KERNEL_REPO" == *"googlesource.com/kernel"* ]]; then
        fetch_with_repo
    else
        fetch_with_git
    fi
    
    # 代码校验
    verify_source
    
    # 执行mrproper
    run_mrproper
    
    # 生成信息报告
    generate_source_info
    
    log_info "======================================"
    log_info "内核源码获取完成!"
    log_info "源码位置: $KERNEL_DIR"
    log_info "======================================"
    
    # 输出下一步操作建议
    cat << EOF

下一步操作:
  1. 配置内核: ./scripts/build.sh --configure
  2. 编译内核: ./scripts/build.sh --build
  3. 查看帮助: ./scripts/build.sh --help

EOF
}

# 执行主函数
main "$@"
