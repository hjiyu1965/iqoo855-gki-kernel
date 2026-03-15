# 贡献指南

感谢您对Android Kernel Build System项目的关注！我们欢迎任何形式的贡献。

## 行为准则

### 我们的承诺

为了营造开放和友好的环境，我们承诺让每个人参与我们的项目和社区都能获得无骚扰的体验，无论其年龄、体型、残疾、民族、性别认同和表达、经验水平、教育程度、社会经济地位、国籍、个人形象、种族、宗教或性取向和认同如何。

### 我们的标准

有助于创造积极环境的行为包括：

- 使用欢迎和包容的语言
- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 关注对社区最有利的事情
- 对其他社区成员表示同理心

不可接受的行为包括：

- 使用性化语言或图像，以及不受欢迎的性关注或性挑逗
- 恶意评论、侮辱/贬损评论，以及个人或政治攻击
- 公开或私下骚扰
- 未经明确许可发布他人的私人信息，如物理或电子邮件地址
- 其他不道德或不专业的行为

## 如何贡献

### 报告Bug

如果您发现了bug，请：

1. 检查[Issues](https://github.com/yourusername/android-kernel-build/issues)以确保bug尚未被报告
2. 如果未找到，创建一个新的Issue并包含：
   - 清晰的标题和描述
   - 重现步骤
   - 预期行为
   - 实际行为
   - 环境信息（操作系统、版本等）
   - 相关的日志或截图

### 提出新功能

如果您有新功能的想法：

1. 检查[Issues](https://github.com/yourusername/android-kernel-build/issues)以确保该功能尚未被建议
2. 如果未找到，创建一个新的Feature Request Issue并包含：
   - 清晰的功能描述
   - 用例和好处
   - 可能的实现方案
   - 替代方案

### 提交代码

#### 开发流程

1. **Fork仓库**
   ```bash
   # 在GitHub上点击Fork按钮
   # 然后克隆您的fork
   git clone https://github.com/yourusername/android-kernel-build.git
   cd android-kernel-build
   ```

2. **创建分支**
   ```bash
   # 对于新功能
   git checkout -b feature/your-feature-name
   
   # 对于bug修复
   git checkout -b bugfix/your-bugfix-name
   ```

3. **进行更改**
   - 遵循代码规范（见下文）
   - 添加适当的注释
   - 更新相关文档

4. **测试您的更改**
   ```bash
   # 确保所有脚本可执行
   chmod +x scripts/*.sh
   
   # 测试功能
   ./scripts/fetch_kernel.sh -b android13-5.15
   ./scripts/build.sh -a arm64
   ```

5. **提交更改**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

6. **推送到您的fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **创建Pull Request**
   - 访问原始仓库
   - 点击"New Pull Request"
   - 选择您的分支
   - 填写PR模板
   - 等待代码审查

#### 提交信息规范

我们遵循[Conventional Commits](https://www.conventionalcommits.org/)规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type（类型）**:
- `feat`: 新功能
- `fix`: Bug修复
- `docs`: 文档更改
- `style`: 代码格式（不影响代码运行的更改）
- `refactor`: 重构（既不是新功能也不是修复）
- `perf`: 性能改进
- `test`: 添加测试
- `chore`: 构建过程或辅助工具的变动
- `ci`: CI配置文件和脚本的变动

**示例**:
```
feat(build): add support for armv7 architecture

Add support for compiling kernel for armv7 architecture.
This includes adding new defconfig and updating build scripts.

Closes #123
```

#### 代码审查

所有Pull Request都需要经过代码审查。审查者会检查：

- 代码质量和风格
- 功能正确性
- 文档完整性
- 测试覆盖
- 安全性问题

请及时回应审查者的评论，并进行必要的修改。

## 代码规范

### Shell脚本规范

- 使用4空格缩进
- 变量名使用大写字母和下划线：`MY_VARIABLE`
- 函数名使用小写字母和下划线：`my_function`
- 添加适当的注释
- 使用`set -e`确保错误时退出
- 使用引号包裹变量：`"$VARIABLE"`

**示例**:
```bash
#!/bin/bash

# Function to check system requirements
check_requirements() {
    local required_tools=("git" "make" "gcc")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "Missing tools: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}
```

### YAML规范

- 使用2空格缩进
- 在必要时使用引号
- 保持一致的键顺序
- 添加注释说明复杂配置

**示例**:
```yaml
name: Build Kernel
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
```

### 文档规范

- 使用Markdown格式
- 添加清晰的标题和子标题
- 使用代码块展示代码示例
- 保持语言简洁明了
- 更新相关文档

## 测试

### 测试要求

在提交代码之前，请确保：

1. 所有脚本可执行
2. 基本功能正常工作
3. 错误处理正确
4. 文档已更新

### 测试清单

- [ ] 脚本可以正常执行
- [ ] 功能按预期工作
- [ ] 错误处理正确
- [ ] 日志记录完整
- [ ] 文档已更新
- [ ] 代码符合规范

## 文档

### 更新文档

当您添加新功能或更改现有功能时，请更新相关文档：

- README.md
- CONTRIBUTING.md
- 代码注释
- 配置文件注释

### 文档风格

- 使用清晰简洁的语言
- 提供示例和用法
- 包含必要的截图
- 保持文档最新

## 发布流程

### 版本号

我们使用语义化版本（Semantic Versioning）：

- `MAJOR.MINOR.PATCH`
- `MAJOR`: 不兼容的API更改
- `MINOR`: 向后兼容的功能性新增
- `PATCH`: 向后兼容的问题修正

### 发布步骤

1. 更新版本号
2. 更新CHANGELOG.md
3. 创建发布分支
4. 测试发布版本
5. 创建Git标签
6. 创建GitHub Release

## 社区

### 联系方式

- GitHub Issues: [问题反馈](https://github.com/yourusername/android-kernel-build/issues)
- GitHub Discussions: [讨论](https://github.com/yourusername/android-kernel-build/discussions)
- Email: your.email@example.com

### 认可贡献者

我们会在每个版本的发布说明中感谢所有贡献者。

## 许可证

通过贡献代码，您同意您的贡献将在与项目相同的许可证下发布（GPL-2.0）。

## 额外资源

- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

---

再次感谢您的贡献！
