# 上游来源、版本与完整性

## 桌面输入

当前脚本按已构建的 **dsh-desktop v2.0.18** 内部布局编写，相关 DSH 包实际核对为 `0.2.1-rc.2`。输入发行包为 universal；本项目的 Mac mini 构建记录为 Apple Silicon，不等于 Intel 已实机通过。

- 项目：<https://github.com/anywhere-labs/dsh-desktop>
- 固定发行页：<https://github.com/anywhere-labs/dsh-desktop/releases/tag/v2.0.18>
- macOS 资产下载：<https://github.com/anywhere-labs/dsh-desktop/releases/download/v2.0.18/DSH.Desktop-2.0.18-universal.dmg>
- 上游摘要清单：<https://github.com/anywhere-labs/dsh-desktop/releases/download/v2.0.18/SHA256SUMS.txt>
- 许可证：MIT，Copyright (c) 2026 Anywhere Labs；副本见[desktop-MIT.txt](licenses/desktop-MIT.txt)。

已核对发行包 SHA-256：

```text
a3aad3ac11ba3cd6cbf295809a32fff907152332800a21a0910034ba95379f08
```

记录对应 macOS universal 2.0.18 镜像；下载 URL 的文件名为 `DSH.Desktop-2.0.18-universal.dmg`，上游摘要清单中的显示名称可能含空格。应按实际字节摘要核对，不能只比文件名。下载失败、摘要不符或版本不符时停止，不悄悄换用 latest。

该值是输入**二进制镜像**摘要，不是源码归档摘要；当前没有在此记录源码归档摘要。摘要一致证明与记录来源一致，不替代上游软件安全审查。

## DeepSeek Harness

- 项目：<https://github.com/deepseek-ai/deepseek-harness>
- 目标桌面发行的相关包版本：`0.2.1-rc.2`。
- 上游许可：MIT，适用版权及全文见[dsh-MIT.txt](licenses/dsh-MIT.txt)。

Cris 不复制完整上游源码树。将来变更桌面输入时，应重新核对该发行实际内嵌内核，而不是把桌面版本号和内核版本号视为相同。

## npm 组件

| 包 | 当前直接/已核对依赖版本 | 来源与许可 |
| --- | --- | --- |
| `ds-bot` | `0.2.7` | [npm 元数据](https://registry.npmjs.org/ds-bot/0.2.7)，Apache-2.0 |
| `deep-view` | `0.1.0`，由上述 DS Bot 声明 | [npm 元数据](https://registry.npmjs.org/deep-view/0.1.0)，Apache-2.0 |

固定这些版本不等于固定 npm 自动补装的 peer 与完整传递树。已确认旧宿主 peer 遮蔽问题，参阅[支持矩阵](../SUPPORT_MATRIX.md)。本地 `--ds-bot-src` 覆盖同样需要核对来源、版本和完整依赖闭包。

## 后处理范围

脚本修改应用资源中的模板选择、初始化复制和上游更新链路，并尝试签名与打包。名称参数不完整改写品牌身份和数据目录。完整步骤见[架构](ARCHITECTURE.md)和[构建参考](BUILD.md)。

## 分发前的责任

原有上游许可、随附组件、适用 NOTICE 与潜在源码提供义务不会因“从 npm 下载”或“重新改名”而消失。源代码工具链与包含依赖的应用属于不同交付面，见[第三方说明](../THIRD_PARTY_NOTICES.md)和[发布流程](../RELEASING.md)。
