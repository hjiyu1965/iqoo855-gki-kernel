#!/bin/bash

# Android内核编译错误处理脚本
# 实现详细的错误捕获、日志记录和用户友好的错误提示
# 包含常见编译问题的解决方案建议
# 作者: Android Kernel Build System
# 版本: 1.0.0

# 错误代码定义
ERR_SUCCESS=0
ERR_GENERAL=1
ERR_MISSING_DEPENDENCY=2
ERR_COMPILER_NOT_FOUND=3
ERR_CONFIG_ERROR=4
ERR_COMPILE_ERROR=5
ERR_DISK_SPACE=6
ERR_MEMORY=7
ERR_TIMEOUT=8
ERR_PERMISSION=9
ERR_NETWORK=10

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志文件
LOG_DIR="$(pwd)/output/logs"
ERROR_LOG="${LOG_DIR}/error_handler_$(date +%Y%m%d_%H%M%S).log"
DEBUG_LOG="${LOG_DIR}/debug_$(date +%Y%m%d_%H%M%S).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 错误信息数据库
declare -A ERROR_SOLUTIONS=(
    ["make: command not found"]="缺少make工具，请安装: sudo apt-get install build-essential"
    ["gcc: command not found"]="缺少gcc编译器，请安装: sudo apt-get install gcc"
    ["clang: command not found"]="缺少clang编译器，请安装: sudo apt-get install clang"
    ["aarch64-linux-gnu-gcc: command not found"]="缺少ARM64交叉编译器，请安装: sudo apt-get install gcc-aarch64-linux-gnu"
    ["arm-linux-gnueabihf-gcc: command not found"]="缺少ARM交叉编译器，请安装: sudo apt-get install gcc-arm-linux-gnueabihf"
    ["flex: command not found"]="缺少flex工具，请安装: sudo apt-get install flex"
    ["bison: command not found"]="缺少bison工具，请安装: sudo apt-get install bison"
    ["ncurses.h: No such file"]="缺少ncurses开发库，请安装: sudo apt-get install libncurses-dev"
    ["openssl/ssl.h: No such file"]="缺少OpenSSL开发库，请安装: sudo apt-get install libssl-dev"
    ["elf.h: No such file"]="缺少elf开发库，请安装: sudo apt-get install libelf-dev"
    ["bc: command not found"]="缺少bc计算器，请安装: sudo apt-get install bc"
    ["No space left on device"]="磁盘空间不足，请清理磁盘空间"
    ["Cannot allocate memory"]="内存不足，请增加交换空间或关闭其他程序"
    ["Permission denied"]="权限不足，请使用sudo或检查文件权限"
    ["Connection refused"]="网络连接被拒绝，请检查网络连接"
    ["timeout"]="操作超时，请增加超时时间或检查网络"
    ["make: ***"]="编译错误，请检查源码或配置"
    ["error:"]="编译错误，请查看详细日志"
    ["warning:"]="编译警告，可能影响功能"
    ["undefined reference"]="链接错误，缺少符号定义"
    ["multiple definition"]="重复定义错误"
    ["relocation truncated"]="重定位错误，可能是内存布局问题"
    ["section type conflict"]="段类型冲突"
    ["overflow"]="溢出错误"
    ["segmentation fault"]="段错误，程序崩溃"
    ["bus error"]="总线错误，内存访问问题"
    ["Killed"]="进程被杀死，通常是内存不足"
)

# 常见问题解决方案
declare -A COMMON_SOLUTIONS=(
    ["编译失败"]="1. 检查依赖是否完整\n2. 清理编译产物: make clean\n3. 尝试减少并行任务数\n4. 检查磁盘空间"
    ["内存不足"]="1. 增加swap空间\n2. 减少并行编译任务数\n3. 关闭其他占用内存的程序"
    ["磁盘空间不足"]="1. 清理临时文件\n2. 删除旧的编译产物\n3. 扩展磁盘空间"
    ["权限错误"]="1. 检查文件和目录权限\n2. 使用sudo执行命令\n3. 检查用户组权限"
    ["网络错误"]="1. 检查网络连接\n2. 尝试使用代理\n3. 检查防火墙设置"
    ["配置错误"]="1. 检查内核配置文件\n2. 运行 make olddefconfig\n3. 查看配置冲突"
    ["交叉编译错误"]="1. 检查交叉编译器路径\n2. 验证ARCH和CROSS_COMPILE设置\n3. 检查工具链版本"
)

# 日志函数
log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" | tee -a "$ERROR_LOG"
}

log_warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$ERROR_LOG"
}

log_info() {
    local message="$1"
    echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$ERROR_LOG"
}

log_debug() {
    local message="$1"
    echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$DEBUG_LOG"
}

# 错误捕获函数
capture_error() {
    local exit_code=$?
    local line_number=$1
    local command_name=$2
    
    if [ $exit_code -ne 0 ]; then
        log_error "命令执行失败: $command_name"
        log_error "退出码: $exit_code"
        log_error "行号: $line_number"
        log_error "时间: $(date)"
        
        # 记录系统状态
        log_system_status
        
        # 尝试分析错误
        analyze_error "$exit_code" "$command_name"
        
        return $exit_code
    fi
}

# 记录系统状态
log_system_status() {
    log_debug "=== 系统状态 ==="
    log_debug "操作系统: $(uname -a)"
    log_debug "CPU信息: $(lscpu | grep 'Model name' | head -1)"
    log_debug "内存使用: $(free -h | grep Mem)"
    log_debug "磁盘使用: $(df -h . | tail -1)"
    log_debug "当前目录: $(pwd)"
    log_debug "环境变量:"
    env | sort >> "$DEBUG_LOG"
    log_debug "================"
}

# 分析错误
analyze_error() {
    local exit_code=$1
    local command_name=$2
    
    log_info "正在分析错误..."
    
    # 检查日志文件
    local log_files=("$ERROR_LOG" "$(pwd)/output/logs/build_*.log")
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            analyze_log_file "$log_file"
        fi
    done
    
    # 根据退出码提供解决方案
    case $exit_code in
        1)
            suggest_solution "general_error"
            ;;
        2)
            suggest_solution "missing_dependency"
            ;;
        3)
            suggest_solution "compiler_not_found"
            ;;
        4)
            suggest_solution "config_error"
            ;;
        5)
            suggest_solution "compile_error"
            ;;
        6)
            suggest_solution "disk_space"
            ;;
        7)
            suggest_solution "memory"
            ;;
        8)
            suggest_solution "timeout"
            ;;
        9)
            suggest_solution "permission"
            ;;
        10)
            suggest_solution "network"
            ;;
        *)
            suggest_solution "unknown_error"
            ;;
    esac
}

# 分析日志文件
analyze_log_file() {
    local log_file=$1
    
    log_debug "分析日志文件: $log_file"
    
    # 查找错误模式
    local error_patterns=(
        "error:"
        "fatal error:"
        "undefined reference"
        "multiple definition"
        "relocation truncated"
        "segmentation fault"
        "bus error"
        "Killed"
        "No space left on device"
        "Cannot allocate memory"
        "Permission denied"
        "Connection refused"
        "timeout"
        "make: \*\*\*"
    )
    
    for pattern in "${error_patterns[@]}"; do
        if grep -q "$pattern" "$log_file"; then
            log_error "发现错误模式: $pattern"
            local error_line=$(grep -n "$pattern" "$log_file" | head -1)
            log_error "错误位置: $error_line"
            
            # 查找解决方案
            find_solution "$pattern"
        fi
    done
}

# 查找解决方案
find_solution() {
    local error_pattern=$1
    
    # 在错误信息数据库中查找
    for key in "${!ERROR_SOLUTIONS[@]}"; do
        if [[ "$error_pattern" == *"$key"* ]]; then
            log_info "找到解决方案:"
            echo -e "${CYAN}${ERROR_SOLUTIONS[$key]}${NC}" | tee -a "$ERROR_LOG"
            return 0
        fi
    done
    
    return 1
}

# 建议解决方案
suggest_solution() {
    local solution_type=$1
    
    log_info "建议的解决方案:"
    
    case $solution_type in
        general_error)
            echo -e "${CYAN}1. 检查命令语法和参数${NC}"
            echo -e "${CYAN}2. 查看详细错误日志${NC}"
            echo -e "${CYAN}3. 检查系统环境${NC}"
            ;;
        missing_dependency)
            echo -e "${CYAN}1. 安装缺失的依赖包${NC}"
            echo -e "${CYAN}2. 运行: sudo apt-get update${NC}"
            echo -e "${CYAN}3. 运行: sudo apt-get install build-essential libncurses-dev libssl-dev libelf-dev${NC}"
            ;;
        compiler_not_found)
            echo -e "${CYAN}1. 安装编译器: sudo apt-get install gcc clang${NC}"
            echo -e "${CYAN}2. 安装交叉编译器: sudo apt-get install gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf${NC}"
            echo -e "${CYAN}3. 检查PATH环境变量${NC}"
            ;;
        config_error)
            echo -e "${CYAN}1. 检查内核配置文件${NC}"
            echo -e "${CYAN}2. 运行: make olddefconfig${NC}"
            echo -e "${CYAN}3. 运行: make menuconfig 查看配置${NC}"
            echo -e "${CYAN}4. 清理配置: make mrproper${NC}"
            ;;
        compile_error)
            echo -e "${CYAN}1. 清理编译产物: make clean${NC}"
            echo -e "${CYAN}2. 减少并行任务数: make -j$(($(nproc)/2))${NC}"
            echo -e "${CYAN}3. 检查源码完整性${NC}"
            echo -e "${CYAN}4. 查看详细编译日志${NC}"
            ;;
        disk_space)
            echo -e "${CYAN}1. 清理临时文件: sudo apt-get clean${NC}"
            echo -e "${CYAN}2. 删除旧的编译产物: make clean${NC}"
            echo -e "${CYAN}3. 清理系统日志: sudo journalctl --vacuum-time=7d${NC}"
            echo -e "${CYAN}4. 扩展磁盘空间${NC}"
            ;;
        memory)
            echo -e "${CYAN}1. 增加swap空间${NC}"
            echo -e "${CYAN}2. 减少并行编译任务数${NC}"
            echo -e "${CYAN}3. 关闭其他占用内存的程序${NC}"
            echo -e "${CYAN}4. 重启系统释放内存${NC}"
            ;;
        timeout)
            echo -e "${CYAN}1. 增加超时时间${NC}"
            echo -e "${CYAN}2. 检查网络连接${NC}"
            echo -e "${CYAN}3. 使用代理加速下载${NC}"
            ;;
        permission)
            echo -e "${CYAN}1. 检查文件权限: ls -la${NC}"
            echo -e "${CYAN}2. 修改权限: chmod +x script.sh${NC}"
            echo -e "${CYAN}3. 使用sudo执行命令${NC}"
            echo -e "${CYAN}4. 检查用户组: groups${NC}"
            ;;
        network)
            echo -e "${CYAN}1. 检查网络连接: ping google.com${NC}"
            echo -e "${CYAN}2. 检查DNS配置: cat /etc/resolv.conf${NC}"
            echo -e "${CYAN}3. 检查防火墙设置${NC}"
            echo -e "${CYAN}4. 使用代理: export http_proxy=http://proxy:port${NC}"
            ;;
        unknown_error)
            echo -e "${CYAN}1. 查看详细错误日志${NC}"
            echo -e "${CYAN}2. 搜索错误信息: https://www.google.com/search?q=error+message${NC}"
            echo -e "${CYAN}3. 查看项目文档${NC}"
            echo -e "${CYAN}4. 提交Issue到GitHub${NC}"
            ;;
    esac
}

# 系统资源检查
check_system_resources() {
    log_info "检查系统资源..."
    
    # 检查磁盘空间
    local disk_usage=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $disk_usage -gt 90 ]; then
        log_warn "磁盘空间不足: ${disk_usage}%"
        suggest_solution "disk_space"
        return $ERR_DISK_SPACE
    fi
    
    # 检查内存
    local mem_available=$(free -m | grep Mem | awk '{print $7}')
    if [ $mem_available -lt 1024 ]; then
        log_warn "可用内存不足: ${mem_available}MB"
        suggest_solution "memory"
        return $ERR_MEMORY
    fi
    
    # 检查CPU
    local cpu_count=$(nproc)
    log_info "CPU核心数: $cpu_count"
    
    log_info "系统资源检查通过"
    return $ERR_SUCCESS
}

# 依赖检查
check_dependencies() {
    log_info "检查依赖..."
    
    local required_tools=("git" "make" "gcc" "clang" "flex" "bison" "bc")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "缺少以下工具: ${missing_tools[*]}"
        suggest_solution "missing_dependency"
        return $ERR_MISSING_DEPENDENCY
    fi
    
    # 检查开发库
    local required_libs=("ncurses.h" "openssl/ssl.h" "elf.h")
    local missing_libs=()
    
    for lib in "${required_libs[@]}"; do
        if ! find /usr/include -name "$lib" &> /dev/null; then
            missing_libs+=("$lib")
        fi
    done
    
    if [ ${#missing_libs[@]} -ne 0 ]; then
        log_error "缺少以下开发库: ${missing_libs[*]}"
        suggest_solution "missing_dependency"
        return $ERR_MISSING_DEPENDENCY
    fi
    
    log_info "依赖检查通过"
    return $ERR_SUCCESS
}

# 编译器检查
check_compiler() {
    log_info "检查编译器..."
    
    local arch=${1:-arm64}
    local cross_compile=""
    
    case $arch in
        arm64)
            cross_compile="aarch64-linux-gnu-"
            ;;
        arm)
            cross_compile="arm-linux-gnueabihf-"
            ;;
        x86_64)
            cross_compile=""
            ;;
    esac
    
    if [ -n "$cross_compile" ]; then
        if ! command -v "${cross_compile}gcc" &> /dev/null; then
            log_error "交叉编译器未找到: ${cross_compile}gcc"
            suggest_solution "compiler_not_found"
            return $ERR_COMPILER_NOT_FOUND
        fi
    fi
    
    if ! command -v "clang" &> /dev/null; then
        log_error "Clang编译器未找到"
        suggest_solution "compiler_not_found"
        return $ERR_COMPILER_NOT_FOUND
    fi
    
    log_info "编译器检查通过"
    return $ERR_SUCCESS
}

# 生成错误报告
generate_error_report() {
    local exit_code=$1
    local report_file="${LOG_DIR}/error_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
Android内核编译错误报告
========================
生成时间: $(date)
退出码: $exit_code

系统信息:
$(uname -a)

CPU信息:
$(lscpu)

内存信息:
$(free -h)

磁盘信息:
$(df -h)

错误日志:
$(cat "$ERROR_LOG" 2>/dev/null || echo "无错误日志")

调试日志:
$(cat "$DEBUG_LOG" 2>/dev/null || echo "无调试日志")

环境变量:
$(env | sort)

EOF
    
    log_info "错误报告已生成: $report_file"
}

# 使用说明
usage() {
    cat << EOF
Android内核编译错误处理脚本

用法: $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -c, --check             检查系统资源和依赖
    -a, --arch ARCH         检查指定架构的编译器 (arm64, arm, x86_64)
    -l, --log FILE          分析指定的日志文件
    -r, --report            生成错误报告
    --debug                 启用调试模式

示例:
    $0 --check
    $0 --check --arch arm64
    $0 --log output/logs/build.log
    $0 --report

EOF
}

# 主函数
main() {
    local check_only=false
    local check_arch=""
    local analyze_log=""
    local generate_report_only=false
    
    # 参数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -c|--check)
                check_only=true
                shift
                ;;
            -a|--arch)
                check_arch="$2"
                shift 2
                ;;
            -l|--log)
                analyze_log="$2"
                shift 2
                ;;
            -r|--report)
                generate_report_only=true
                shift
                ;;
            --debug)
                set -x
                shift
                ;;
            *)
                log_error "未知选项: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    log_info "======================================"
    log_info "Android内核编译错误处理脚本 v1.0.0"
    log_info "======================================"
    
    if [ "$generate_report_only" = true ]; then
        generate_error_report $?
        exit 0
    fi
    
    if [ -n "$analyze_log" ]; then
        if [ -f "$analyze_log" ]; then
            analyze_log_file "$analyze_log"
        else
            log_error "日志文件不存在: $analyze_log"
            exit 1
        fi
        exit 0
    fi
    
    if [ "$check_only" = true ]; then
        check_system_resources
        check_dependencies
        
        if [ -n "$check_arch" ]; then
            check_compiler "$check_arch"
        fi
        
        exit 0
    fi
    
    # 默认行为：检查所有
    check_system_resources
    check_dependencies
    
    if [ -n "$check_arch" ]; then
        check_compiler "$check_arch"
    fi
    
    log_info "======================================"
    log_info "检查完成!"
    log_info "======================================"
}

# 设置错误捕获
trap 'capture_error ${LINENO} "$BASH_COMMAND"' ERR

# 执行主函数
main "$@"
