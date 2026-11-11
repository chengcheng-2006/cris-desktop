# 贡献指南

## 开发环境

本项目提供 macOS 打包脚本，不包含 DSH Desktop 上游源码或完整应用构建环境。实际构建需要 macOS、Bash、Python 3、Node.js/npm、Apple 命令行工具，以及已构建的目标 `.app`。默认从 npm registry 安装固定版本依赖；也可传入包含 `ds-bot` 和 `deep-view` 的本地目录作为覆盖。工具版本矩阵尚未验证，贡献时请在变更说明中记录你实际使用的 macOS 与依赖版本。

## 修改与构建

先在本地准备符合要求的上游应用，再按脚本参数运行。默认从 npm registry 安装 `ds-bot@0.2.7`；本地依赖覆盖是可选的：

```bash
bash build/build-cris.sh \
  --src-app "/path/to/Cris.app" \
  --out "./dist"
bash build/verify-artifact.sh "./dist/Cris.app"
```

当前测试固定在 `ds-bot@0.2.7`；latest `0.3.2` 的升级不在本次发布范围。

`publish-gate.sh` 用于发布候选检查，不是完整测试套件。构建和校验覆盖范围以脚本实际实现为准；未覆盖的行为请明确标为未验证。

## 提交前必须执行脱敏检查

提交前必须运行 final 模式的独立发布闸门，并由独立审查覆盖候选文件与 Git 历史。`CRIS_PRIVATE_RULES` 必须指向仓库外可读且含有效个人审查规则的文件：

```bash
CRIS_PRIVATE_RULES="/path/outside/review-rules" \
  bash build/publish-gate.sh . --mode=final
```

默认 draft 模式仅供开发期提示，其退出码不能作为发布依据。只有 final 模式退出码为 0，且独立脱敏审查针对准备提交/推送的确切提交 SHA 给出 `BLOCK=0`，候选才可进入发布流程。任何变更都会使既有 SHA 绑定结果失效，需要重新检查。检查中如发现密钥或隐私内容，先从工作树和待提交内容移除并调查是否进入历史；不要用改写历史掩盖已公开的敏感提交。

贡献内容不得包含真实姓名、私人邮箱、个人手机号、会话或记忆正文、含真实用户名的绝对路径、访问凭据或运行数据。不得提交 `dist/`、上游源码树、`node_modules/`、`.env`、备份文件或应用运行数据库。

## Pull Request

说明变更目的、影响的构建步骤、实际执行的命令及结果。没有执行的检查应标注“未运行”；未验证的平台或行为应标注“未验证”。不要在 PR 或 Issue 中附带密钥、完整运行配置或未经脱敏的日志。
