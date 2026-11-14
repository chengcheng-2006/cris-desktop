# 支持与问题报告

## 先选对入口

- 使用与构建问题：先查[从零开始](docs/GETTING_STARTED.md)、[排障](docs/TROUBLESHOOTING.md)和[FAQ](docs/FAQ.md)。
- 缺陷与文档改进：使用 [GitHub Issues](https://github.com/chengcheng-2006/cris-desktop/issues)。
- 私密安全问题：遵循[安全政策](SECURITY.md)，不要把细节先发到公开 Issue。
- 支持范围：[支持矩阵](SUPPORT_MATRIX.md)。没有商业 SLA 或固定响应时限承诺。

## 报告里写什么

```text
工具链提交 SHA：
操作系统和架构：
Node / npm 版本：
输入 DSH Desktop 版本与文件摘要：
DS Bot / Deep View / 实际宿主包版本：
场景：下载 / 构建 / 结构检查 / 启动 / 插件 / UI / 模型
期望行为：
实际行为：
最少复现步骤：
关键错误类型与缺失符号：
命令退出码：
是否有旧安装或旧 profile（不写私人路径）：
哪些检查通过、哪些未执行：
```

可以用 `~`、`<app>` 等说明路径。不要发送完整环境变量、配置、日志、数据库或用户状态。如果错误包含 key、身份信息或会话正文，删去这些内容后只保留包名和异常类型。

## 当前最相关的已知问题

- 默认 npm peer 依赖可能引入旧 `dsh-llm`，DS Bot 因缺少 `createSystemMessage` 无法导入。
- 公开脚本尝试 ad-hoc 签名但失败不阻断，结构校验 PASS 不代表严格签名有效。
- `--name` 不隔离 bundle identifier 或数据目录；不能靠改名保证并排安装互不影响。

详见[排障](docs/TROUBLESHOOTING.md)。独立 Mac mini 修复还未并入公开代码，提交问题时不要假定本地报告与当前 main 是同一份实现。

## 遇到权限或沙箱拒绝

报告原始错误类别和受阻步骤。Computer Use 应用访问授权、macOS 自动化权限、Codex 执行沙箱和应用自身签名是不同层。不要因此禁用全局安全设置或删除已有 profile；能继续做的只读检查可以继续，无法验证的 UI 标为未验证。

## 提出功能需求

说明你要完成的任务、现有流程哪里阻塞、希望如何验收。平台适配、更新服务和安装器都应以实际场景为依据，不只列功能名。当前优先级见[路线图](docs/ROADMAP.md)。
