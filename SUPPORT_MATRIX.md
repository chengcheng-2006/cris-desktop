# 支持矩阵与验收状态

这是本仓库对外支持声明的统一依据。README、安装说明和变更记录不得将支持范围扩大到此表之外。状态更新应同时说明环境、具体行为与证据，不能用构建成功代替运行成功。

**核对日期：2026-11-14。** 本次文档补全的代码基线为 `9fa5e9d19318d52876ff771f4ddba0879f07d803`；后续文档提交不表示运行时修复已合并。

## 状态含义

| 标记 | 含义 |
| --- | --- |
| PASS | 指定环境中的指定行为已有实际通过记录 |
| PARTIAL | 只完成其中一部分，或能力带有明确限制 |
| BLOCKED | 已确认的故障或外部权限阻碍该项验收 |
| NOT_VERIFIED | 证据不足，不能判断是否正常 |
| NOT_IMPLEMENTED | 当前公开仓库没有相应实现 |

## 证据来源与范围

本表综合代码基线的只读核对、维护者本机构建记录和另一台 Mac mini 的执行者回传报告。后两者的原始日志可能含个人数据，不随仓库公开；因此这些条目是有限范围的验证记录，不是公共 CI 或第三方认证。命令及各层判断方法见[验证指南](docs/VERIFICATION.md)。

## 平台与构建环境

| 对象 | 状态 | 实际范围 |
| --- | --- | --- |
| macOS 15.3.1 / Apple Silicon | PASS：构建 | Mac mini 的独立构建生成应用与约 912 MiB 的 DMG；不代表 DS Bot 运行通过 |
| Node.js 24.22.2 / npm 11.19.1 | PASS：构建工具 | 上述环境实际使用；不是所有 Node/npm 版本的支持承诺 |
| DSH Desktop v2.0.18 universal | PASS：输入结构 | 指定发行包能匹配现有补丁锚点；内嵌相关 DSH 包为 0.2.1-rc.2 |
| macOS Intel | NOT_VERIFIED | 上游输入为 universal，尚无本项目 Intel 机器运行验收 |
| 其他 macOS / Node 版本 | NOT_VERIFIED | 不以版本号更高推定兼容 |
| Windows / Linux 构建 | NOT_IMPLEMENTED | 公开脚本使用 macOS 专用工具，没有对应安装包流水线 |
| 更新到其他 DSH Desktop 版本 | NOT_VERIFIED | 内部文件名、锚点与 API 可能变化，须逐版本适配 |

## 当前公开代码

| 能力 | 状态 | 边界与证据 |
| --- | --- | --- |
| 复制应用、注入首次启动模板 | PASS：结构 | 构建日志、资源目录和挂载后目录检查通过 |
| 从 npm 安装 DS Bot 0.2.7 / Deep View 0.1.0 | PARTIAL | 包可获取；默认 npm peer 安装存在已确认的宿主依赖遮蔽问题 |
| DS Bot 实际激活 | BLOCKED | 已复现 profile 中旧 `dsh-llm@0.0.1-rc.5` 缺少 `createSystemMessage`，导致插件导入失败 |
| DS Bot 入口、创建 Bot、真实聊天 | NOT_VERIFIED：公开构建 | 文件存在、bundle 声明和模块可解析都不能替代真实界面验收 |
| 空白模型配置种子 | PASS：结构 | 默认不预置 provider、key 或本地网关；上游首次设置可能再写入桌面相关条目 |
| 自填模型设置页 | PARTIAL | 上游已有设置界面；未对所有 provider、凭据存储或真实对话做验收 |
| 生成、挂载并检查 DMG | PASS：构建 | 真实生成并读取镜像内模板；不是安装包安全或许可证终审 |
| 残留挂载情况下重复打包 | PASS：已测场景 | 有同目录重复构建和预先挂载同名卷后的通过记录；当前会尝试强制卸载同名卷，使用前须自行确认 |
| 严格嵌套签名验证 | BLOCKED：已测公开产物 | 有嵌套 framework 严格校验失败记录；构建脚本只尝试外层 ad-hoc 签名，失败不阻断 |
| Apple Developer ID / 公证 | NOT_IMPLEMENTED | 未提供证书、公证提交或 stapling 流程；当前不计划为此购买服务 |
| 改名后独立 bundle identifier | NOT_IMPLEMENTED | `--name` 控制输出名称，不自动重写应用身份、可执行文件名或数据目录 |
| 旧 profile 自动迁移及隔离 | NOT_VERIFIED | 不能把首次初始化补丁当成已有数据迁移；没有完整迁移器 |
| Cris 自有自动更新 | NOT_IMPLEMENTED | 脚本禁用上游更新并写入占位地址；不是可用的更新源 |
| 完整锁文件 / 字节级可重现构建 | NOT_IMPLEMENTED | 固定直接包版本不等于锁定完整依赖闭包；DMG 压缩输出也未证明逐字节一致 |
| 安装包公开 Release | NOT_IMPLEMENTED：截至核对日 | GitHub 当前只有工具链与文档，没有已发布安装包 Release |

## 独立 Mac mini 修复试验

以下来自另一台机器的执行报告，**不在上述公开代码基线内**，不是可下载的正式修复版本。

| 项目 | 状态 |
| --- | --- |
| 针对 DS Bot / Deep View 的宿主依赖解析修复 | PARTIAL：本地实现，尚未合并 |
| 新旧 profile 模块导入、移动后解析 | PASS：报告中的模块级试验 |
| 修复副本 `codesign --verify --deep --strict` | PASS：指定副本的本机 ad-hoc 校验 |
| 实际启动隔离、DS Bot 激活、界面入口 | NOT_VERIFIED；桌面控制访问授权被拒绝 |
| 其他插件真实桌面功能、模型对话 | NOT_VERIFIED |
| 提交、独立脱敏与公开发布 | NOT_IMPLEMENTED：尚未接收该修复代码 |

## 更新状态的要求

1. 用实际命令、退出码、环境和文件版本支持结论；原始日志留在仓库外，公开只摘录脱敏结果。
2. 将结构检查、模块导入、插件激活、UI 操作和模型对话分别记录。
3. 若缺少权限，记录 BLOCKED 或 NOT_VERIFIED，不将其记为功能不存在。
4. 若发现确定故障，更新本表并链接到[排障说明](docs/TROUBLESHOOTING.md)。
5. 功能通过后仍需独立完成源码公开审查；安装包分发还需要单独审查。
