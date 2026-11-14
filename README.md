# Cris Desktop

[English](README.en.md) · [文档中心](docs/index.md) · [支持矩阵](SUPPORT_MATRIX.md) · [问题反馈](https://github.com/chengcheng-2006/cris-desktop/issues)

Cris 是基于 dsh-desktop v2.0.18 修改的桌面 AI 助手发行方案。本仓库只发布 macOS 打包与分发工具链、空 profile 模板和文档；它不是 DeepSeek 官方项目，也不是 DSH 的完整源码 fork。应用主体来自上游已构建的桌面应用，DS Bot 通过模板固定的 npm 版本安装。模型 provider、模型名、服务地址和 API key 由使用者自填，不需要 Magpie，本仓库不包含模型或凭据。

Cris 的愿景是让使用者在自己的桌面 DSH 环境中启用 DS Bot，并自行连接所选择的模型服务。**当前公开 main 构建存在已知的 DS Bot 导入阻断问题**：npm 安装会解析旧 peer `dsh-llm@0.0.1-rc.5`，其中缺少 `createSystemMessage`，导致 DS Bot 导入失败。因此不能将公开 main 描述为开箱即用或已完成端到端验证。详情见[已知状态](#当前状态与支持范围)。

## 快速导航

- [快速开始与构建](#快速开始)
- [安装与首次启动](docs/GETTING_STARTED.md)
- [模型 provider 设置](docs/GETTING_STARTED.md#配置模型-provider)
- [构建、输入与输出安全](docs/BUILD.md)
- [常见故障](docs/TROUBLESHOOTING.md)
- [支持矩阵](SUPPORT_MATRIX.md) · [支持政策](SUPPORT.md) · [架构](docs/ARCHITECTURE.md)
- [配置参考](docs/CONFIGURATION.md) · [FAQ](docs/FAQ.md) · [路线图](docs/ROADMAP.md)
- [文档索引](docs/index.md) · [变更记录](CHANGELOG.md) · [发布流程](RELEASING.md)
- [安全问题报告](SECURITY.md) · [贡献指南](CONTRIBUTING.md) · [第三方声明](THIRD_PARTY_NOTICES.md)

## 本仓库包含什么

- `build/build-cris.sh`：对一份已构建的 macOS `.app` 注入 Cris profile 逻辑，组装首启模板并生成 DMG。
- `build/verify-artifact.sh`：检查产物中的模板、更新入口、部分配置和签名状态；签名状态仅记录，不做严格验签。
- `build/publish-gate.sh`：源码候选的发布检查之一；不能代替独立脱敏审查。
- `profile-template/`：固定 `ds-bot@0.2.7` 的空白配置模板，不包含 API key 或 provider 配置。
- 文档：构建、安装、故障排查、支持边界及许可证说明。

本仓库不含 DSH 或 dsh-desktop 上游源码、`node_modules`、生成的 `.app`/`.dmg`、运行会话、profile 数据或模型。构建脚本修改的是输入应用的副本；构建输入、安装包和运行数据都应放在仓库之外。

## 当前状态与支持范围

| 项目 | 当前状态 | 说明 |
|---|---|---|
| 上游输入 | dsh-desktop v2.0.18 | 需要已构建的 macOS 应用；本仓库不从源码构建 DSH。 |
| 依赖版本 | `ds-bot@0.2.7`，依赖 `deep-view@0.1.0` | 固定在模板；不使用 latest。传递依赖未由锁文件固定。 |
| 公开 main 的 DS Bot 启动 | **已知失败** | 默认 npm 解析旧 peer `dsh-llm@0.0.1-rc.5`，缺少 `createSystemMessage`，DS Bot 导入失败。 |
| Mini 上的修复试验 | 未合入当前公开仓库 | 本地模块解析、移动后解析和严格 ad-hoc 签名检查通过；桌面界面/插件入口验证受 Computer Use 访问授权阻挡，不能据此宣称修复版端到端通过。 |
| 首次启动 | 脚本注入模板复制逻辑 | 不能据此承诺已有 profile 会迁移、修复或保留所有内容；先备份并使用专用测试 profile。 |
| 签名 | 脚本尝试 ad-hoc 签名 | 失败时只输出警告并继续；不执行 `codesign --verify --deep --strict`。 |
| DMG | 脚本生成并做结构性挂载校验 | DMG 未签名、未公证。结构检查通过不等于应用功能、签名或许可证审核通过。 |
| 平台与 provider | macOS 目标 | Windows、其他平台和所有 provider 的兼容性未验证。 |

这些状态针对当前公开 main 的仓库代码及已报告的试验范围。修复未进入公开仓库前，公开 main 不等于 Mini 本地修复版。详见[支持矩阵](SUPPORT_MATRIX.md)及[排障指南](docs/TROUBLESHOOTING.md)。

## 快速开始

### 0. 获取工具链

```bash
git clone https://github.com/chengcheng-2006/cris-desktop.git
cd cris-desktop
git rev-parse HEAD
```

需要 macOS、Bash、Python 3、Node.js/npm 和系统打包工具。实测构建环境为 macOS 15.3.1 / arm64、Node.js 24.22.2、npm 11.19.1；不代表只要能构建就能运行 DS Bot。若没有 Node/npm，先从 [Node.js 官方渠道](https://nodejs.org/en/download)或自己信任的包管理器安装。完整预检见[入门指南](docs/GETTING_STARTED.md)。

### 1. 获取上游桌面应用

本仓库不包含输入 `.app`。上游 v2.0.18 universal DMG 下载地址：

<https://github.com/anywhere-labs/dsh-desktop/releases/download/v2.0.18/DSH.Desktop-2.0.18-universal.dmg>

预期 SHA-256：

```text
a3aad3ac11ba3cd6cbf295809a32fff907152332800a21a0910034ba95379f08
```

下载后核对：

```bash
shasum -a 256 "$HOME/Downloads/DSH.Desktop-2.0.18-universal.dmg"
```

只有结果与上述摘要完全一致才继续；不匹配时停止，不要挂载或运行该文件。安装/挂载和查找 `.app` 的完整步骤见[入门指南](docs/GETTING_STARTED.md)。

### 2. 在仓库之外构建

构建输出必须位于仓库目录之外。先确认输出目录及目标 `.app`，因为脚本会删除同名目标 `.app`、旧 DMG、临时 staging 目录，并可能强制摘除同名挂载卷。不要将输入 `.app` 与输出目标设为同一路径。

```bash
bash <<'BASH'
set -euo pipefail
SRC_APP="$HOME/Applications/DSH Desktop.app"
OUT="$(mktemp -d "$HOME/cris-out.XXXXXX")"
test -d "$SRC_APP/Contents/Resources/app"
bash build/build-cris.sh \
  --src-app "$SRC_APP" \
  --out "$OUT" 2>&1 | tee "$OUT/build.log"
printf 'OUT=%s\n' "$OUT"
BASH
```

这里的输入路径只是示例；实际 `.app` 路径必须从你挂载的上游 DMG 中查找。`--name` 只影响输出文件名、卷名和应用显示文件名，不会改应用 bundle identifier。构建脚本默认从 npm registry 安装 `ds-bot@0.2.7` 及其依赖；也可用 `--ds-bot-src` 提供本地覆盖目录，但脚本仅检查 `ds-bot/` 与 `deep-view/` 目录存在，不验证覆盖目录版本或依赖闭包。

**目前公开 main 的构建包含上述旧 peer 冲突，可能成功产出 DMG，但 DS Bot 导入仍失败。** 构建成功或 DMG 内结构检查通过，不代表 DS Bot 能加载。详细步骤、覆盖目录安全和输出清理行为见[构建说明](docs/BUILD.md)。

### 3. 理解失败与安装风险

执行 `verify-artifact.sh` 后请阅读每一项结果；它不是功能集成测试，也不做严格签名验证。未完成 peer 修复及桌面界面验收前，不要把该 DMG 当成可供普通用户直接使用的稳定发行版。安装指引、profile 备份原则及 Gatekeeper 状态见[入门指南](docs/GETTING_STARTED.md)。

## 模型 provider

种子配置 `cordis.patch.yml` 为空列表 `[]`，不预置 provider、API key 或本机网关路由。模型由用户在运行中的 DSH/Cris 模型设置中填写。实际界面入口和兼容字段取决于上游桌面版本；由于公开 main 当前 DS Bot 导入失败，不能保证 Bot 可访问模型设置或成功发起请求。不要将密钥写进仓库、Issue、截图、日志或公开配置。设置细节见[入门指南](docs/GETTING_STARTED.md#配置模型-provider)与[配置参考](docs/CONFIGURATION.md)。

## Gatekeeper、签名与公证

当前构建脚本尝试 ad-hoc 签名，失败只告警继续；没有严格验签。DMG 未签名、未公证。macOS 可能阻止从网络下载的应用打开。本次本机构建产物未带 `com.apple.quarantine`，但其他下载或传输方式可能添加隔离标记，不能保证所有用户环境相同。

首次打开前应确认来源可信、最终安装副本严格验签通过，并使用独立测试账户或虚拟机，或证明完整隔离。只新建 profile 或改应用名不足以隔离 Electron 和跨发行版状态；无法确认时停在静态检查。符合条件后才可在 Finder 中选择实际安装的副本“打开”。隔离属性处理只针对你确认的 `INSTALLED_APP`，见[入门指南](docs/GETTING_STARTED.md)；不要对另一位置的旧应用执行清理，该操作也不能修复严格代码签名失败。面向公众降低 Gatekeeper 提示需要 Developer ID 正式签名和 Apple 公证；这依赖 Apple Developer Program 会员，年费价格因地区和时间而异（美国通常为 99 美元/年）。本项目当前不提供证书或公证。

## 架构概览

```mermaid
flowchart LR
    A[上游桌面 app] --> B[构建脚本与补丁]
    B --> C[应用与 profile 模板]
    C --> D[DSH 插件加载器]
    D --> E[DS Bot 界面]
    E --> F[用户配置的模型服务]
```

这条预期链路目前在插件导入处有已知缺陷。实现关系与加载边界见[架构](docs/ARCHITECTURE.md)，每一层的验收含义见[验证方法](docs/VERIFICATION.md)。本仓库没有安装包 Release；从 GitHub 下载 ZIP 得到的是工具链源码，不是可直接打开的应用。

## 协作与后续

优先解决依赖解析、真实界面验收、输出安全和严格签名，再扩展其他平台。[路线图](docs/ROADMAP.md)给出完成条件；[变更记录](CHANGELOG.md)区分已入仓内容与未合并试验。

报告缺陷时请包含提交 SHA、环境、异常类型和最小复现，按[支持指南](SUPPORT.md)脱敏。贡献流程见[CONTRIBUTING](CONTRIBUTING.md)，社区约定见[行为准则](CODE_OF_CONDUCT.md)。

## 安全与许可证

不要提交 API key、token、cookie、运行 profile、会话、记忆、数据库、个人信息或本机用户名路径。发布候选须通过 final 发布闸门和独立脱敏审查，并针对最终提交 SHA 复核；规则见[安全报告](SECURITY.md)与[贡献指南](CONTRIBUTING.md)。

本仓库自有工具链采用 MIT；上游组件保留各自许可证。生成 `.app`/`.dmg` 会包含运行依赖，分发方必须对实际包内组件履行许可证义务；文档中的说明不能替代包内许可证和适用 NOTICE。详见 [LICENSE](LICENSE) 与 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。