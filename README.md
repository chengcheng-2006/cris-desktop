# Cris Desktop

Cris Desktop 是基于 dsh-desktop v2.0.18（MIT，Anywhere Labs）修改的 macOS 打包与分发工具链，提供构建脚本、配置模板和文档；它不是 DeepSeek 官方项目。模型 provider、模型名称、服务地址和 API key 均由使用者自行配置，本项目不要求 Magpie，也不附带模型或凭据。

> 仓库简介：Self-contained macOS packaging and distribution toolchain for Cris, a DSH-based desktop AI assistant. Models and API keys are supplied by the user; nothing is bundled.
>
> Topics：`macos` `electron` `packaging` `dmg` `ai-assistant` `deepseek` `self-hosted`

## 能做什么

- 将已构建的 macOS `.app` 改造成 Cris 应用，并生成 DMG。
- 在应用资源中组装首次启动 profile 模板，包含 DS Bot 和 Deep View 运行组件。
- 默认使用空的 provider 配置种子，由使用者在自己的运行环境中填写模型设置。
- 运行产物校验脚本，检查模板、更新入口及若干配置项。

这些脚本修改现成的 DSH Desktop 应用，不会从上游源码完整构建应用。Windows 构建、自动更新服务、正式签名与 Apple 公证未验证或未提供。

## 截图

> 截图占位：尚未提供可公开的产品截图。

## 安装与构建

### 前置条件

当前脚本面向 macOS，需要一份已构建的 `Cris.app`/DSH Desktop 应用，以及 Bash、Python 3、Node.js/npm 和 macOS 的 `ditto`、`codesign`、`hdiutil` 等工具。默认通过 npm registry 安装模板依赖；也可用 `--ds-bot-src` 指定本地覆盖目录。具体系统和工具版本兼容范围尚未验证。

上游桌面源码不包含在本仓库中。请从 dsh-desktop 上游获取 v2.0.18 源码或构建产物，并遵循上游许可证；不要把上游源码树或生成的应用复制进本仓库。

### 构建应用

```bash
bash build/build-cris.sh \
  --src-app "/path/to/Cris.app" \
  --out "./dist"
```

脚本默认从 npm registry 安装模板 pin 的 `ds-bot@0.2.7` 及其依赖。该版本已实际测试；npm registry 当前 latest 为 `ds-bot@0.3.2`，升级不在本次发布范围，使用者可自行决定是否升级并另行验证。可选地通过 `--ds-bot-src` 指定本地覆盖目录，该目录须包含 `ds-bot/` 与 `deep-view/`。脚本默认产出 `dist/Cris.app` 和版本化 DMG；可用 `--name` 修改应用名。详细参数及实际步骤以 [build-cris.sh](build/build-cris.sh) 为准。

校验生成的应用：

```bash
bash build/verify-artifact.sh "./dist/Cris.app"
```

脚本只检查其实现覆盖的项目，不能替代独立的隐私、凭据、恶意软件或许可证审查。

## 配置自己的模型 provider

本仓库的 [profile-template](profile-template/) 仅提供空白种子，不含 provider、API key 或本机服务地址。安装后，在 Cris/DSH 的模型设置中填写你选择的兼容 provider、API base URL、模型 ID 和凭据。可用 provider 与具体设置字段取决于所用 DSH Desktop 版本及 provider；本仓库未验证每一种 provider 的兼容性。

模型由用户自填，不需要 Magpie。不要把 key 写入本仓库、配置模板、Issue、截图或日志。请按 provider 的安全建议在本机配置凭据，并避免提交包含凭据的运行配置。

## 发布前检查

发布候选必须运行 final 模式，并提供仓库之外、可读取且含有效个人审查规则的词表文件：

```bash
CRIS_PRIVATE_RULES="/path/outside/review-rules" \
  bash build/publish-gate.sh . --mode=final || { echo "闸门未过，禁止推送"; exit 1; }
```

`CRIS_PRIVATE_RULES` 必须指向仓库目录之外的真实规则文件；不得把词表放进候选仓库。默认模式仅用于开发期提示，其退出码不能作为发布依据。final 模式通过仍只是必要条件：还必须由独立脱敏审查覆盖候选文件与 Git 全部历史，并针对准备推送的提交 SHA 给出 `BLOCK=0`；两者通过后才允许推送。闸门不替代二进制或语义审查。

## 已知限制

- 只处理已构建的 macOS 应用，不是完整 DSH fork 或源码构建系统。
- 正式代码签名和 Apple 公证未验证；当前构建可能使用 ad-hoc 签名。
- Cris 自有更新服务未建立；自动更新链路的禁用方式依赖目标应用内部文件结构。
- 全新机器的完整安装与首次启动尚未完成独立环境验收。
- Windows、其他操作系统、各 provider 的兼容情况未验证。
- 输出应用会包含上游及其他第三方组件；分发应用前需要逐组件核对其许可证与 NOTICE 要求。

## 许可与致谢

本仓库自有打包脚本采用 MIT License。上游 DSH 与 dsh-desktop 的 MIT 声明按适用情况保留。该声明不代表生成的应用或其所有依赖都采用 MIT。详见 [LICENSE](LICENSE) 与 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
