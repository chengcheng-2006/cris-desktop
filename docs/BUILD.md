# 构建说明

本工具链只对已构建的 macOS `.app` 做后处理并生成 DMG；它不构建 DSH 源码，也不负责取得或验证上游源码归档。脚本改动的是输入应用的副本。开始前请先读完本页，因为构建脚本会删除或卸载与目标名称冲突的已有资源。

## 构建前条件

需要：

- macOS；支持的最低版本和完整版本矩阵尚未确定。
- dsh-desktop v2.0.18 的已构建应用，并确认内部资源布局与脚本 patch 锚点兼容。
- Bash、Python 3、Node.js/npm，以及系统命令 `ditto`、`codesign`、`hdiutil`、`xattr`、`mount` 等。
- 如走默认依赖安装，构建时需能访问 npm registry。
- 如选择 `--ds-bot-src` 覆盖，目录中应有 `ds-bot/` 与 `deep-view/`。脚本只检查目录存在，不校验版本、包签名、完整依赖闭包或许可证。

上游输入 DMG 下载地址和 SHA-256 见[入门指南](GETTING_STARTED.md#获取并验证上游应用)。校验摘要不匹配时停止，不要挂载或运行文件。

## 输出目录与破坏性操作

请选择仓库之外的专用输出目录。建议每次使用新的空目录，并在执行前确认该目录、其父目录和目标名称都正确。脚本会：

1. 删除 `$OUT/$APP_NAME.app` 同名目标后再复制输入应用；
2. 清理/替换输出中的 DMG、临时 staging 和 `.dmg-copy`；
3. 检查同名 `/Volumes/$APP_NAME` 挂载，并尝试强制卸载；
4. 生成应用、DMG，并将 DMG 中的应用复制到临时位置做结构校验。

不要将输入 `.app` 路径设置为 `$OUT/$APP_NAME.app`，否则清理步骤可能删除输入。`--name` 只影响文件名、卷名及输出名称，不修改 `CFBundleIdentifier`，也不保证改动应用在系统中的身份。不要让输出路径指向包含个人资料或其他重要文件的目录。

## 构建命令

从仓库根目录运行。示例中的路径需替换为你检查过的实际路径；输出放在仓库外：

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

Bash 的 `set -euo pipefail` 使关键失败停止并避免管道掩盖错误；管道返回最右侧失败命令的状态，不保证一定是构建脚本的原始退出码。后续命令中的 `OUT` 必须重新设为上面实际打印的路径。若复用输出，脚本可能删除已有同名目标，请勿用于已有安装。

默认依赖行为：脚本在 profile 模板中固定 `ds-bot@0.2.7`，然后运行 npm 安装，传递依赖按 registry 当时解析，且不生成 package lock。已知其运行时依赖包含 `deep-view@0.1.0`。本地覆盖可用：

```bash
bash <<'BASH'
set -euo pipefail
SRC_APP="$HOME/Applications/DSH Desktop.app"
OUT="$(mktemp -d "$HOME/cris-local-out.XXXXXX")"
LOCAL_DEPS="$HOME/path/to/node_modules"
test -d "$SRC_APP/Contents/Resources/app"
test -d "$LOCAL_DEPS/ds-bot"
test -d "$LOCAL_DEPS/deep-view"
bash build/build-cris.sh \
  --src-app "$SRC_APP" --out "$OUT" \
  --ds-bot-src "$LOCAL_DEPS" 2>&1 | tee "$OUT/build.log"
printf 'OUT=%s\n' "$OUT"
BASH
```

本地覆盖没有版本验证。两种方式都不能保证依赖图可重现。当前公开 main 的默认 npm 解析会带入旧 peer `dsh-llm@0.0.1-rc.5`，缺少 `createSystemMessage`，导致 DS Bot 导入失败；产出 DMG 不代表该问题消失。

## 结构校验与签名

构建脚本会自动挂载新 DMG、确认其中有 profile-template 与 DS Bot，并调用 `verify-artifact.sh` 检查复制出的应用。也可以手动运行：

先将 `OUT` 设为本次构建实际打印的输出目录，不要用另一份旧应用代替。

```bash
bash build/verify-artifact.sh "${OUT:?先设置本次实际输出目录}/Cris.app"
```

该检查器对签名仅打印状态，**不做** `codesign --verify --deep --strict`，也不验证应用界面、插件导入、模型调用、用户数据迁移、恶意软件或第三方许可证。`PASS` 只表示其代码覆盖的结构检查通过。

脚本尝试执行 ad-hoc 签名；若 `codesign` 失败只打印 `WARN`，构建继续。它不申请 Developer ID、不签名 DMG，也不做 Apple 公证。需要独立检查应用签名时可执行：

```bash
codesign --verify --deep --strict --verbose=2 "${OUT:?先设置本次实际输出目录}/Cris.app"
```

该命令的退出码和完整诊断由本机 `codesign` 给出；检查通过也不等于 Developer ID 签名或公证。DMG 本身未签名。Gatekeeper 处理方式见[入门指南](GETTING_STARTED.md#gatekeeper-签名与公证)。

## Profile 与首次启动边界

构建脚本将模板放进应用资源，并改动上游的 profile 初始化逻辑以尝试复制模板。实现中复制错误会被捕获并忽略；已有 profile 的升级、覆盖、迁移和数据保留没有端到端验收。不要对正在使用的旧 profile 直接覆盖、删除依赖目录或运行未经验证的迁移。首次试用优先使用独立 macOS 测试账户或虚拟机；其他方案须先核实应用身份、Electron appData/userData、DSH 根目录和跨发行版状态的完整隔离。新 profile 或改应用名不能代替这种证明。无法确认时仅做静态检查，不打开应用；不要把 profile、日志或会话内容上传到 Issue。

## 许可证与发布安装包

生成的 `.app`/`.dmg` 会带入第三方运行组件。工具链仓库的许可证说明不等于应用包内已履行全部义务；在向他人分发前，应从实际产物检查所有包版本、许可证文本、源码修改说明及上游实际附带的适用 NOTICE。DS Bot 声明 Apache-2.0。分发义务详见 [`../THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)。
