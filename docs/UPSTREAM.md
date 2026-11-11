# 上游来源

## dsh-desktop

本工具链以已构建的 dsh-desktop v2.0.18 应用为输入，并对其应用资源中的文件做发行改造。上游源码与构建产物不包含在本仓库中。

- 项目：dsh-desktop
- 版本：v2.0.18
- 上游项目地址：<https://github.com/anywhere-labs/dsh-desktop>
- 许可证：MIT，Copyright (c) 2026 Anywhere Labs
- 许可证副本：[`licenses/desktop-MIT.txt`](licenses/desktop-MIT.txt)
- 源码校验值：尚未在本仓库记录；发布具体构建时应补充对应源码归档的 SHA-256。

## DeepSeek Harness（DSH）

目标桌面应用基于 DeepSeek Harness。DSH 上游项目声明采用 MIT；本仓库不包含其源码树。

- 项目：DeepSeek Harness
- 上游项目地址：<https://github.com/deepseek-ai/deepseek-harness>
- 许可证：MIT；适用文本见 [`licenses/dsh-MIT.txt`](licenses/dsh-MIT.txt)
- 上游源码版本及校验值：应以目标 dsh-desktop 版本实际锁定的 DSH 版本为准；本仓库目前未验证并记录该版本/校验值。

## 变更范围

打包脚本向目标应用注入 profile 模板逻辑、注册 Cris profile、调整首次启动模板选择，并禁用或替换上游更新入口。具体改动以 [`../build/build-cris.sh`](../build/build-cris.sh) 当前内容为准。它不是完整源码 fork，也不会自动重建上游应用。
