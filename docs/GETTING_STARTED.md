# 入门指南

本指南从一台没有项目上下文的 Mac 开始，说明如何取得工具链和上游输入、构建、检查与试用。**当前公开代码有 DS Bot 导入故障**，适合诊断和开发，不是稳定安装器。先读[支持矩阵](../SUPPORT_MATRIX.md)。

## 准备环境

需要 macOS、Git、Bash、Python 3、Node.js/npm，以及 `ditto`、`codesign`、`hdiutil`、`xattr` 等系统工具。实测构建组合为 macOS 15.3.1 / arm64、Node 24.22.2、npm 11.19.1；没有完整兼容矩阵。

```bash
sw_vers -productVersion
uname -m
node -v
npm -v
command -v git bash python3 ditto codesign hdiutil xattr
df -h "$HOME"
```

没有 Node/npm 时，先从 [Node.js 官方渠道](https://nodejs.org/en/download)或自己信任的包管理器安装，并确认当前终端 PATH 已更新。模型 key 不属于构建前置条件。应用及多份暂存副本占数 GiB，建议预留至少 12 GiB；这只是估计，残留和依赖会继续占空间。

获取工具链，若同名目录存在先检查，不覆盖：

```bash
git clone https://github.com/chengcheng-2006/cris-desktop.git
cd cris-desktop
git rev-parse HEAD
```

## 获取并验证上游应用

使用固定的 dsh-desktop v2.0.18 universal DMG：

- [发行页](https://github.com/anywhere-labs/dsh-desktop/releases/tag/v2.0.18)
- [下载文件](https://github.com/anywhere-labs/dsh-desktop/releases/download/v2.0.18/DSH.Desktop-2.0.18-universal.dmg)
- [上游摘要清单](https://github.com/anywhere-labs/dsh-desktop/releases/download/v2.0.18/SHA256SUMS.txt)
- 记录 SHA-256：`a3aad3ac11ba3cd6cbf295809a32fff907152332800a21a0910034ba95379f08`

下载链接里使用 `DSH.Desktop`；上游摘要清单显示名称可能含空格。以字节摘要为准，不能只比文件名。不要悄悄换成另一个版本或 latest。

## 完整构建与静态检查

从**克隆后的仓库根目录**运行下面的 Bash 块。它创建新的仓库外工作目录，先检查下载摘要，复制源应用后才卸载输入镜像，最后执行结构和严格签名检查。关键命令失败时停止，不以 `tee` 的成功掩盖失败。

当前严格验签可能失败，DS Bot 也有已知导入问题。失败后保留工作目录检查，**不要绕过错误继续安装**。不要把日志直接贴到公开 Issue。

```bash
bash <<'BASH'
set -euo pipefail
for tool in git python3 node npm ditto codesign hdiutil xattr; do
  command -v "$tool" >/dev/null
done
test -f build/build-cris.sh
WORK="$(mktemp -d "$HOME/cris-work.XXXXXX")"
OUT="$WORK/out"
SRC_APP="$WORK/source/DSH Desktop.app"
SOURCE_MNT="$WORK/source-mount"
SOURCE_ATTACHED=0
cleanup() {
  if [ "$SOURCE_ATTACHED" -eq 1 ]; then
    hdiutil detach "$SOURCE_MNT" >/dev/null || true
  fi
}
trap cleanup EXIT
printf 'WORK=%s\nOUT=%s\n' "$WORK" "$OUT"

curl --fail --location --show-error --output "$WORK/upstream.dmg" \
  'https://github.com/anywhere-labs/dsh-desktop/releases/download/v2.0.18/DSH.Desktop-2.0.18-universal.dmg'
EXPECTED='a3aad3ac11ba3cd6cbf295809a32fff907152332800a21a0910034ba95379f08'
ACTUAL="$(shasum -a 256 "$WORK/upstream.dmg" | awk '{print $1}')"
[ "$ACTUAL" = "$EXPECTED" ] || { echo '输入摘要不符；停止'; exit 1; }

mkdir -p "$SOURCE_MNT" "$WORK/source"
hdiutil attach -readonly -nobrowse -mountpoint "$SOURCE_MNT" "$WORK/upstream.dmg"
SOURCE_ATTACHED=1
APP_FROM_SOURCE="$(python3 - "$SOURCE_MNT" <<'PY'
from pathlib import Path
import sys
apps = [p for p in Path(sys.argv[1]).iterdir() if p.is_dir() and p.suffix == '.app']
if len(apps) != 1:
    raise SystemExit('挂载根目录不是唯一 app；停止并人工检查实际布局')
print(apps[0])
PY
)"
ditto "$APP_FROM_SOURCE" "$SRC_APP"
hdiutil detach "$SOURCE_MNT"
SOURCE_ATTACHED=0
python3 - "$SRC_APP/Contents/Resources/app/package.json" <<'PY'
import json, sys
version = json.load(open(sys.argv[1]))['version']
print('Source desktop version:', version)
if version != '2.0.18':
    raise SystemExit('源应用版本不符；停止')
PY

if [ -e /Volumes/Cris ]; then
  echo '同名卷已存在，停止以避免脚本强制卸载其他任务的卷'
  exit 1
fi
bash build/build-cris.sh --src-app "$SRC_APP" --out "$OUT" 2>&1 | tee "$WORK/build.log"
bash build/verify-artifact.sh "$OUT/Cris.app"
codesign --verify --deep --strict --verbose=2 "$OUT/Cris.app"
printf '静态检查结束；OUT=%s\n' "$OUT"
BASH
```

这段代码只接受挂载根目录有唯一 `.app` 的布局；若上游变化，不自动猜选其他应用。输入是复制到本地再构建，源 DMG 可以先卸载。工作目录不会自动删除，便于复核和回滚。

脚本默认安装 `ds-bot@0.2.7` 和依赖 `deep-view@0.1.0`，没有完整 lockfile。可选本地覆盖仅检查两个目录存在，不验证版本或依赖闭包。详见[构建参考](BUILD.md)。

## 理解结果

- 构建退出 0：只说明执行到了结尾。
- `verify-artifact.sh` PASS：只覆盖其局部结构、模板和更新入口；签名项仅记录。
- 严格签名退出 0：指定副本通过此次代码签名检查，不代表 Apple 公证。
- DS Bot 激活与 UI：仍需实际运行和打开入口，不能用上述三项替代。

当前默认安装的旧 peer 可能缺少 `createSystemMessage`。Mac mini 独立修复通过了模块、移动后解析和指定副本严格验签，但代码未并入公开仓库，UI 验收也未完成，见[排障](TROUBLESHOOTING.md)。

## 从 DMG 复制安装

仅当静态检查通过、你理解已知功能故障并希望继续测试时操作。先把构建输出打印的真实路径填入 `OUT`。`INSTALLED_APP` 必须是核实过的目标；示例使用用户 Applications，不覆盖任何已有目标。

```bash
OUT="/absolute/path/printed/as/OUT"
INSTALLED_APP="$HOME/Applications/Cris.app"
bash -euo pipefail -s -- "$OUT" "$INSTALLED_APP" <<'BASH'
OUT="$1"
INSTALLED_APP="$2"
test -f "$OUT/Cris-2.0.18.dmg"
[ ! -e "$INSTALLED_APP" ] || { echo '目标已存在；停止，不覆盖'; exit 1; }
INSTALL_MNT="$(mktemp -d "${TMPDIR:-/tmp}/cris-install.XXXXXX")"
ATTACHED=0
cleanup() {
  if [ "$ATTACHED" -eq 1 ]; then hdiutil detach "$INSTALL_MNT" >/dev/null || true; fi
}
trap cleanup EXIT
hdiutil attach -readonly -nobrowse -mountpoint "$INSTALL_MNT" "$OUT/Cris-2.0.18.dmg"
ATTACHED=1
APP_FROM_DMG="$INSTALL_MNT/Cris.app"
test -d "$APP_FROM_DMG/Contents/Resources/app"
codesign --verify --deep --strict --verbose=2 "$APP_FROM_DMG"
mkdir -p "$(dirname "$INSTALLED_APP")"
[ ! -e "$INSTALLED_APP" ] || { echo '目标已经出现；停止'; exit 1; }
ditto "$APP_FROM_DMG" "$INSTALLED_APP"
codesign --verify --deep --strict --verbose=2 "$INSTALLED_APP"
printf '已复制并严格验签；尚未启动：%s\n' "$INSTALLED_APP"
BASH
```

这里检查的是刚复制的最终安装副本，不用另一位置的旧应用代替。如果用了 `--name`，镜像和内部应用名会不同，需按实际路径修改，不能直接照抄本例。

## 首次启动与隔离条件

**优先在独立测试账户或虚拟机试用。** 其他方式必须先验证完整隔离：应用身份、Electron `appData` / `userData`、DSH 数据根目录、单实例锁及跨发行版状态路径都需要核对。仅新建 profile、修改应用文件名或设置 `DSH_HOME`，均不是完整隔离证明。

无法确认时停在静态检查，**不要执行 Finder 打开、`open` 或从终端直接运行应用**。有旧数据的机器先做仓库外可恢复备份。当前仓库没有保证安全的旧 profile 自动迁移器。

确认隔离和签名条件后，才在 Finder 打开核实过的 `INSTALLED_APP`。验收目标是窗口出现、DS Bot 激活、入口可打开并能进入创建/配置界面；真实聊天是另一层，需要用户授权及有效模型服务。

## 配置模型 provider

模板有效配置为空列表 `[]`，不预填 provider、API key 或本地网关。不需要 Magpie。上游首次设置可能继续写入桌面或市场条目，这不等于配置了模型。

在实际运行的桌面应用中进入“设置 → 模型”，按服务填写 provider、baseURL、模型 ID 和凭据。当前公开 DS Bot 导入缺陷没有靠填 key 修好的捷径；先完成插件/界面验收。具体字段与凭据存储以实际组件为准，见[配置参考](CONFIGURATION.md)。

## Gatekeeper 签名与公证

当前构建脚本尝试 ad-hoc 签名，失败只告警继续；DMG 未签名、未公证。已测本地产物没有 quarantine，但传输方式可能改变属性，不保证免提示。

只有在上述隔离条件、来源核对与最终副本严格签名检查均满足后，才考虑 Finder 中“打开”。系统提示处理取决于 macOS 版本。若明确决定清除可信副本的隔离属性，命令必须指向**同一 `INSTALLED_APP`**：

```bash
bash -euo pipefail -s -- "${INSTALLED_APP:?先设置实际安装路径}" <<'BASH'
INSTALLED_APP="$1"
test -d "$INSTALLED_APP"
codesign --verify --deep --strict --verbose=2 "$INSTALLED_APP"
xattr -dr com.apple.quarantine "$INSTALLED_APP"
BASH
```

这不能修复签名失效，不适用于来源不明软件。Developer ID 与 Apple 公证属于独立发行资格及流程；当前仓库不提供，也不要求为了模块排障购买服务。

## 回滚与报告

仅退出本次测试应用，保留测试数据，重新打开原安装即可；不要删除原 `~/.dsh` 或其他个人数据。新安装只有在确认路径和归属后才移入废纸篓。报告只提供版本、SHA、失败阶段、退出码和脱敏异常，见[支持指南](../SUPPORT.md)。
