# 贡献指南

感谢帮助 Cris 从实验性工具链走向可靠应用交付。先读[公开范围](PUBLIC_RELEASE_BOUNDARY.md)、[支持矩阵](SUPPORT_MATRIX.md)和[架构](docs/ARCHITECTURE.md)，确认改动针对的是当前仓库实现。

## 可贡献的内容

- 修复有复现的构建、宿主依赖解析或启动问题。
- 改进输出路径检查、挂载清理和严格签名失败处理。
- 补充真实环境下的验证记录，明确未执行项。
- 更清楚的文档、脱敏问题模板和可复现指引。

当前优先级见[路线图](docs/ROADMAP.md)。没有独立首启向导、Windows 构建或更新服务的完成承诺；不要把未来计划标成已支持。

## 工作方式

1. 克隆仓库并建立自己的变更分支，阅读现有实现后再编辑。
2. 源应用、构建产物、日志与词表放在仓库外；先备份需保留的本地数据。
3. 若改构建逻辑，使用专用新输出目录；不要从现有个人 profile 制作公开模板。
4. 新公开文件需在 `.gitignore` 中精确放行；不要使用 `git add -f` 绕过拒绝。
5. 不覆盖已有应用，不批量替换其他插件依赖，不关闭安全检查来获得“通过”。

构建环境与命令见[构建参考](docs/BUILD.md)。默认安装仍存在已知 peer 导出故障，请先读[排障](docs/TROUBLESHOOTING.md)。本地目录覆盖选项不会自动保证依赖版本或闭包正确。

## 验证应与变更相称

文档修改检查相对链接、命令参数、版本、状态与空白错误。不要为了改一段文字重复构建数 GB 的应用。

```bash
git diff --check
bash -n build/build-cris.sh
bash -n build/verify-artifact.sh
bash -n build/publish-gate.sh
```

实现修改须增加对结论有意义的验证：例如依赖解析需分别验证新旧 profile 与移动后的应用，签名需严格验证，插件修复需真实激活和界面验收。测试环境不允许 GUI 时，可以继续模块检查，但最后必须写 UI 未验证。

`verify-artifact.sh` 只是有限结构检查；签名项只记录，不因严格校验失败而失败。不能用它的 PASS 数量当作功能测试总数。更多说明见[验证方法](docs/VERIFICATION.md)。

## 隐私与审查

不得提交私人身份、联系方式、带实际用户目录的路径、凭据、会话/记忆、运行数据、完整日志、依赖树或应用包。[公开内容规则](PUBLICATION_HYGIENE.md)适用于文件和提交元数据。

准备推送的最终提交必须运行：

```bash
CRIS_PRIVATE_RULES="$HOME/.config/cris-review/private.rules" \
  bash build/publish-gate.sh . --mode=final
```

词表须在仓库外自行准备，不使用无关文件伪造审核。如有经独立批准的公共项目 URL 误报，可另传仓库外 `CRIS_PUBLIC_URLS` 精确清单，不能豁免私人资料；配置方法见[发布流程](RELEASING.md)。final 是必要条件，仍需独立审查完整历史、对象、索引和元数据，对确切 SHA 给出 BLOCK=0。修改提交后旧结论失效。详细步骤见[发布流程](RELEASING.md)。

## Pull Request 内容

- 描述具体触发条件、之前的问题和现在的行为。
- 说明影响的文件、依赖版本与新旧 profile 范围。
- 列出实际命令和退出码，明确未执行、未验证及外部授权阻塞。
- 如果涉及用户数据，说明备份、隔离与回滚。
- 如果修改上游内容，保留许可与适用声明，见[第三方说明](THIRD_PARTY_NOTICES.md)。

不要上传完整运行配置来帮助评审。问题报告使用[支持指南](SUPPORT.md)；私密安全问题按[SECURITY](SECURITY.md)处理。参与协作请遵守[行为准则](CODE_OF_CONDUCT.md)。
