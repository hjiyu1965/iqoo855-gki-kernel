#!/bin/bash

# Docker镜像构建脚本
# 用于构建Android内核编译环境的Docker镜像
# 作者: Android Kernel Build System
# 版本: 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
IMAGE_NAME="android-kernel-builder"
IMAGE_TAG="latest"
DOCKERFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(dirname "$DOCKERFILE_DIR")"

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 使用说明
usage() {
    cat << EOF
Docker镜像构建脚本

用法: $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -n, --name NAME         指定镜像名称 (默认: ${IMAGE_NAME})
    -t, --tag TAG           指定镜像标签 (默认: ${IMAGE_TAG})
    -p, --platform PLATFORM  指定目标平台 (默认: linux/amd64)
                           支持多平台: linux/amd64,linux/arm64
    --no-cache              不使用缓存构建
    --push                  构建后推送到Docker Hub
    --multi-arch            构建多架构镜像

示例:
    $0
    $0 --no-cache
    $0 -n my-kernel-builder -t v1.0
    $0 --multi-arch --push

EOF
}

# 参数解析
NO_CACHE=false
PUSH=false
MULTI_ARCH=false
PLATFORM="linux/amd64"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --multi-arch)
            MULTI_ARCH=true
            shift
            ;;
        *)
            log_error "未知选项: $1"
            usage
            exit 1
            ;;
    esac
done

FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# 检查Docker是否安装
check_docker() {
    log_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker守护进程未运行，请启动Docker"
        exit 1
    fi
    
    log_info "Docker环境检查通过"
}

# 构建镜像
build_image() {
    log_info "======================================"
    log_info "开始构建Docker镜像"
    log_info "======================================"
    log_info "镜像名称: $FULL_IMAGE_NAME"
    log_info "构建目录: $DOCKERFILE_DIR"
    
    cd "$DOCKERFILE_DIR"
    
    local build_args=""
    if [ "$NO_CACHE" = true ]; then
        build_args="--no-cache"
    fi
    
    if [ "$MULTI_ARCH" = true ]; then
        log_info "构建多架构镜像..."
        
        # 检查buildx插件
        if ! docker buildx version &> /dev/null; then
            log_error "Docker buildx插件未安装"
            log_info "请启用buildx: docker buildx create --use"
            exit 1
        fi
        
        # 创建并使用builder
        docker buildx create --name kernel-builder --use --bootstrap 2>/dev/null || true
        
        # 构建多架构镜像
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -t "$FULL_IMAGE_NAME" \
            --progress=plain \
            $build_args \
            --load \
            .
        
        if [ "$PUSH" = true ]; then
            log_info "推送镜像到Docker Hub..."
            docker buildx build \
                --platform linux/amd64,linux/arm64 \
                -t "$FULL_IMAGE_NAME" \
                --progress=plain \
                $build_args \
                --push \
                .
        fi
    else
        log_info "构建单架构镜像 ($PLATFORM)..."
        
        docker build \
            --platform "$PLATFORM" \
            -t "$FULL_IMAGE_NAME" \
            --progress=plain \
            $build_args \
            .
    fi
    
    if [ $? -eq 0 ]; then
        log_info "======================================"
        log_info "镜像构建成功!"
        log_info "镜像: $FULL_IMAGE_NAME"
        log_info "======================================"
        
        # 显示镜像信息
        docker images | grep "$IMAGE_NAME"
    else
        log_error "镜像构建失败"
        exit 1
    fi
}

# 验证镜像
verify_image() {
    log_info "验证镜像..."
    
    if docker image inspect "$FULL_IMAGE_NAME" &> /dev/null; then
        log_info "镜像验证通过"
        
        # 显示镜像详细信息
        log_info "镜像信息:"
        docker image inspect "$FULL_IMAGE_NAME" --format='
镜像ID: {{.Id}}
创建时间: {{.Created}}
大小: {{.Size}}
架构: {{.Architecture}}
系统: {{.Os}}
'
    else
        log_error "镜像验证失败"
        exit 1
    fi
}

# 显示使用说明
show_usage() {
    cat << EOF

镜像构建完成!

使用方法:

1. 启动容器:
   docker run -it --rm -v $(pwd):/workspace $FULL_IMAGE_NAME

2. 使用docker-compose:
   cd $WORK_DIR
   docker-compose up -d kernel-builder
   docker-compose exec kernel-builder bash

3. 在容器中编译内核:
   cd /workspace
   ./scripts/fetch_kernel.sh -b android13-5.15
   ./scripts/build.sh -a arm64

EOF
}

# 主函数
main() {
    log_info "======================================"
    log_info "Docker镜像构建脚本 v1.0.0"
    log_info "======================================"
    
    check_docker
    build_image
    verify_image
    show_usage
}

# 执行主函数
main "$@"
