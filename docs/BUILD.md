# 构建说明

本工具链对已构建的 macOS `.app` 做后处理并生成 DMG。它不获取上游源码，也不执行 electron-builder 的完整构建流程。默认构建时通过 npm registry 安装模板 pin 的 DS Bot 依赖。

## 输入

- 已构建的 Cris/DSH Desktop `.app`，其资源目录应含桌面应用文件。
- macOS 命令行环境：Bash、Python 3、Node.js/npm、`ditto`、`codesign`、`hdiutil` 及脚本调用的标准系统工具。
- 可选：作为依赖覆盖项传入、同时包含 `ds-bot/` 与 `deep-view/` 的本地 `node_modules` 目录。

具体系统与工具版本支持范围未验证。输入应用版本及来源应依据 [UPSTREAM.md](UPSTREAM.md) 记录。

## 构建

```bash
bash build/build-cris.sh \
  --src-app "/path/to/Cris.app" \
  --out "./dist"
```

默认从 npm registry 安装 `ds-bot@0.2.7` 及其依赖。可用 `--ds-bot-src "/path/to/node_modules"` 指定本地覆盖目录，也可用 `--name` 设置输出应用名。脚本会在输出目录生成应用及 DMG，并对应用资源做复制与补丁修改；请对输入应用和输出目录做好备份。完整参数校验与操作顺序见脚本自身。

`ds-bot@0.2.7` 是本项目实际测试并固定的版本；npm registry 当前 latest 为 `0.3.2`，升级不在本次发布范围。使用者可以自行决定是否升级，但升级后须重新验证依赖解析、应用行为和许可证。版本详情见 [../THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)。

## 校验

```bash
bash build/verify-artifact.sh "./dist/Cris.app"
```

校验器只覆盖脚本列出的结构和配置检查，不代表完整功能、安装、隐私、凭据、签名、公证或第三方许可证验收。

## 版本信息与可重现性

要使构建可重现，应记录输入应用版本、上游源码/产物校验值、DS Bot 与 Deep View 版本、macOS 版本和脚本版本。当前流程通过 npm 安装依赖，尚未使用锁文件固定完整传递依赖图；目标上游归档哈希也未记录，因此不能声称构建完全可重现。

生成的 `.app` / `.dmg` 含有上游运行组件时，分发方须按实际安装版本履行许可证义务。Apache-2.0 依赖要求随分发提供许可证文本、标明对原文件的修改，并保留其实际附带且适用的 NOTICE 内容；本说明文档不能代替应用包内随附的许可文件。分发前应检查实际产物并补齐对应文件。
