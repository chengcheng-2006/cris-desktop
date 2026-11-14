# 文档导航

新读者先阅读 [README](../README.md) 和[支持矩阵](../SUPPORT_MATRIX.md)：当前仓库是实验性 macOS 打包工具链，公开默认构建存在 DS Bot 宿主依赖导入故障，没有已验收的安装包 Release。

## 我想安装或试用

1. [从零开始](GETTING_STARTED.md)：获取输入应用、校验、构建、并排安装与退出条件。
2. [构建参考](BUILD.md)：参数、操作范围、输出和版本约束。
3. [配置与本地数据](CONFIGURATION.md)：模型设置、profile、数据备份。
4. [排障](TROUBLESHOOTING.md)：旧 peer、签名、锚点、权限等问题。
5. [常见问题](FAQ.md)：项目定位、费用、支持平台与安装包获取。

## 我想理解实现

- [架构](ARCHITECTURE.md)：应用、模板、profile 与插件加载关系。
- [上游来源](UPSTREAM.md)：版本、下载来源、摘要和许可副本。
- [第三方说明](../THIRD_PARTY_NOTICES.md)：仓库与生成应用的许可边界。
- [验证方法](VERIFICATION.md)：每一种 PASS 的具体含义。
- [安全模型](SECURITY_MODEL.md)：信任、数据、网络与隔离边界。

## 我想贡献或报告问题

- [贡献指南](../CONTRIBUTING.md)
- [支持与问题报告](../SUPPORT.md)
- [安全政策](../SECURITY.md)
- [行为准则](../CODE_OF_CONDUCT.md)
- [路线图](ROADMAP.md)

## 我负责维护和发布

- [公开交付边界](../PUBLIC_RELEASE_BOUNDARY.md)
- [公开内容卫生](../PUBLICATION_HYGIENE.md)
- [发布流程](../RELEASING.md)
- [变更记录](../CHANGELOG.md)
- [支持矩阵](../SUPPORT_MATRIX.md)

中文是主要维护语言；[English overview](../README.en.md)提供入口与关键限制。若两者有遗漏或不一致，以代码事实及支持矩阵核对并修正文档，不用翻译差异扩大支持声明。

## 文档组织参考

本轮组织方式参考了 [PAIOS CE](https://github.com/chengcheng-2006/paios-ce) 的中文入口、支持矩阵、专题文档及发布边界分工。这里重新按 Cris 的实际脚本和执行证据编写，没有沿用其产品能力、测试数字、CI 状态或许可证。
