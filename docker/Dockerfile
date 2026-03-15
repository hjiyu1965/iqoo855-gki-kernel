# Android内核编译环境Docker镜像
# 包含完整的交叉编译工具链和依赖库
# 支持ARM64、ARM、x86_64架构
# 作者: Android Kernel Build System
# 版本: 1.0.0

FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV CCACHE_DIR=/workspace/.ccache
ENV CCACHE_MAXSIZE=50G
ENV PATH="/opt/clang/bin:/opt/gcc-arm64/bin:/opt/gcc-arm/bin:$PATH"

# 设置工作目录
WORKDIR /workspace

# 安装基础依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基础工具
    git curl wget ca-certificates gnupg lsb-release software-properties-common \
    # 构建工具
    build-essential make cmake ninja-build ccache \
    # 内核编译依赖
    libncurses-dev libssl-dev libelf-dev bc bison flex \
    # 压缩工具
    xz-utils lz4 lzop zstd gzip bzip2 \
    # 其他工具
    cpio kmod device-tree-compiler u-boot-tools \
    # Python支持
    python3 python3-pip python3-dev python3-setuptools \
    # 其他依赖
    jq rsync file patch diffutils \
    # 清理缓存
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装repo工具
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# 下载并安装Clang/LLVM 14
RUN wget -q https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang+llvm-14.0.6-x86_64-linux-gnu-ubuntu-18.04.tar.xz \
    && tar -xf clang+llvm-14.0.6-x86_64-linux-gnu-ubuntu-18.04.tar.xz -C /opt \
    && mv /opt/clang+llvm-14.0.6-x86_64-linux-gnu-ubuntu-18.04 /opt/clang \
    && rm clang+llvm-14.0.6-x86_64-linux-gnu-ubuntu-18.04.tar.xz

# 下载并安装ARM64 GCC交叉编译器 (Android NDK r25c)
RUN wget -q https://dl.google.com/android/repository/android-ndk-r25c-linux.zip \
    && unzip -q android-ndk-r25c-linux.zip \
    && mv android-ndk-r25c/toolchains/llvm/prebuilt/linux-x86_64 /opt/ndk \
    && rm -rf android-ndk-r25c android-ndk-r25c-linux.zip

# 下载并安装ARM64 GCC工具链 (Linaro 7.5)
RUN wget -q https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz \
    && tar -xf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz -C /opt \
    && mv /opt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu /opt/gcc-arm64 \
    && rm gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz

# 下载并安装ARM32 GCC工具链 (Linaro 7.5)
RUN wget -q https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-linux-gnueabihf/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz \
    && tar -xf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz -C /opt \
    && mv /opt/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf /opt/gcc-arm \
    && rm gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz

# 配置ccache
RUN mkdir -p /workspace/.ccache \
    && echo "max_size = 50G" > /workspace/.ccache/ccache.conf \
    && echo "compression = true" >> /workspace/.ccache/ccache.conf \
    && echo "compression_level = 6" >> /workspace/.ccache/ccache.conf

# 创建必要的目录
RUN mkdir -p /workspace/kernel_source \
    /workspace/output/images \
    /workspace/output/modules \
    /workspace/output/dtbs \
    /workspace/output/packages \
    /workspace/output/logs

# 复制脚本到容器
COPY scripts/ /workspace/scripts/
RUN chmod +x /workspace/scripts/*.sh

# 设置默认命令
CMD ["/bin/bash"]

# 标签信息
LABEL maintainer="Android Kernel Build System"
LABEL version="1.0.0"
LABEL description="Complete Android kernel build environment with cross-compilers"
