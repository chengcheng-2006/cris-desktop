#!/usr/bin/env bash
# build-cris.sh — 把开发态 DSH 桌面应用改造成自包含 Cris 发行版（.app + .dmg）。
#
# 用法:
#   build-cris.sh --src-app <Cris.app> --out <dir> [--ds-bot-src <node_modules 目录>] [--name Cris]
#
# 产物:
#   <out>/Cris.app                 自包含应用（首次启动含 DS Bot 模板）
#   <out>/Cris-<version>.dmg       可分发磁盘镜像（含 /Applications 快捷方式）
#
# 不做: 正式签名/公证、Cris 自有更新源（环境 BLOCKED，见 README）
set -euo pipefail

SRC_APP=""; OUT=""; DS_BOT_SRC=""; APP_NAME="Cris"
usage() { echo "用法: $0 --src-app <Cris.app> --out <dir> [--ds-bot-src <node_modules 目录>] [--name Cris]" >&2; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --src-app) SRC_APP="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    --ds-bot-src) DS_BOT_SRC="$2"; shift 2;;
    --name) APP_NAME="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
[[ -n "$SRC_APP" && -d "$SRC_APP" ]] || { echo "need --src-app <Cris.app>" >&2; exit 2; }
[[ -n "$OUT" ]] || { echo "need --out <dir>" >&2; exit 2; }

RES="$SRC_APP/Contents/Resources"; APP="$RES/app"
[[ -d "$APP" ]] || { echo "无效应用：缺少 Contents/Resources/app: $SRC_APP" >&2; exit 2; }
if [[ -n "$DS_BOT_SRC" ]]; then
  [[ -d "$DS_BOT_SRC/ds-bot" && -d "$DS_BOT_SRC/deep-view" ]] || { echo "指定目录须包含 ds-bot 和 deep-view" >&2; exit 2; }
else
  command -v npm >/dev/null || { echo "默认安装需要 npm" >&2; exit 2; }
fi

mkdir -p "$OUT"
WORK="$OUT/.build-$(date +%s)"; mkdir -p "$WORK"
TARGET_APP="$OUT/$APP_NAME.app"

patch_py() { # patch_py <file> <python body；可用变量 p(路径)、s(内容)>
  python3 -c "import sys
p=sys.argv[1]; s=open(p,encoding='utf-8').read()
$2" "$1"
}

echo "== 1) 复制应用 =="
rm -rf "$TARGET_APP"; ditto "$SRC_APP" "$TARGET_APP"
TRES="$TARGET_APP/Contents/Resources"; TAPP="$TRES/app"
echo "  staged: $TARGET_APP"

echo "== 2) 组装首次启动模板 =="
TPL="$TRES/profile-template"; rm -rf "$TPL"; mkdir -p "$TPL/node_modules"
cat > "$TPL/package.json" <<'JSON'
{
  "name": "dsh-profile-desktop",
  "private": true,
  "dependencies": { "ds-bot": "0.2.7" },
  "dsh": { "profile": { "bundles": ["@deepseek-ai/dsh-base", "@deepseek-ai/dsh-web-app", "ds-bot"] } }
}
JSON
if [[ -n "$DS_BOT_SRC" ]]; then
  cp -a "$DS_BOT_SRC/ds-bot" "$TPL/node_modules/ds-bot"
  cp -a "$DS_BOT_SRC/deep-view" "$TPL/node_modules/deep-view"
else
  npm install --prefix "$TPL" --cache "$WORK/npm-cache" --ignore-scripts --omit=dev --no-package-lock --no-audit --no-fund
fi
[[ -d "$TPL/node_modules/ds-bot" && -d "$TPL/node_modules/deep-view" ]] || { echo "依赖安装不完整" >&2; exit 2; }
rm -rf "$TPL/node_modules/.pnpm" "$TPL/node_modules/.modules.yaml" "$TPL/node_modules/.pnpm-workspace-state-v1.json"
find "$TPL/node_modules" -name '.modules.yaml' -delete 2>/dev/null || true
find "$TPL/node_modules" -name '*.bak-*' -type f -delete 2>/dev/null || true
cat > "$TPL/cordis.patch.yml" <<'YAML'
# Cris profile 种子层：默认不预置任何 provider、key 或本地网关路由。
# 模型在「设置 → 模型」里由用户填写 provider / baseURL / 模型名 / 凭据。
[]
YAML
cat > "$TPL/pnpm-workspace.yaml" <<'YAML'
packages:
  - .

nodeLinker: hoisted
autoInstallPeers: false
YAML
echo "  template: $(find "$TPL" -type f | wc -l | tr -d ' ') files, ds-bot=$( [ -d "$TPL/node_modules/ds-bot" ] && echo yes || echo NO )"

echo "== 3) 注册 cris 模板 =="
patch_py "$TAPP/node_modules/@deepseek-ai/dsh-app-boot/lib/index.js" '
old="web: { bundles: [\"@deepseek-ai/dsh-base\", \"@deepseek-ai/dsh-web-app\"] },"
if "cris: { bundles:" not in s:
    assert old in s, "anchor missing in dsh-app-boot"
    s=s.replace(old, old+"\n\tcris: { bundles: [\"@deepseek-ai/dsh-base\", \"@deepseek-ai/dsh-web-app\", \"ds-bot\"] },", 1)
    open(p,"w",encoding="utf-8").write(s)
print("  cris template registered")'

echo "== 4) 首次启动拷贝模板 =="
patch_py "$TAPP/node_modules/@deepseek-ai/dsh-app-boot/lib/index.js" '
old="function initProfile(dir, bundles) {\n\tmkdirSync(dir, { recursive: true });"
if "__crisProfileTemplate" not in s:
    assert old in s, "initProfile anchor missing"
    add=old+"\n\t/* __crisProfileTemplate */\n\ttry {\n\t\tconst __tpl = process.resourcesPath ? join(process.resourcesPath, \"profile-template\") : \"\";\n\t\tif (__tpl && existsSync(__tpl)) fs.cpSync(__tpl, dir, { recursive: true });\n\t} catch (_) {}"
    s=s.replace(old, add, 1)
    open(p,"w",encoding="utf-8").write(s)
print("  initProfile template copy patched")'

echo "== 5) 桌面端首启用 cris 模板 =="
PM=$(ls "$TAPP"/lib/profile-manager-*.js | head -1)
patch_py "$PM" '
old="const template = PROFILE_TEMPLATES.web;"
if "PROFILE_TEMPLATES.cris ?? PROFILE_TEMPLATES.web" not in s:
    assert old in s, "profile-manager anchor missing"
    s=s.replace(old, "const template = PROFILE_TEMPLATES.cris ?? PROFILE_TEMPLATES.web;", 1)
    open(p,"w",encoding="utf-8").write(s)
print("  desktop first-run uses cris template")'

echo "== 6) 关闭上游更新链路 =="
patch_py "$TAPP/lib/updates.js" '
old="function apply(ctx, config) {"
if "__crisUpdatesDisabled" not in s:
    assert old in s, "updates.js anchor missing"
    s=s.replace(old, old+"\n\t/* __crisUpdatesDisabled: 正式更新源建立前禁用自动更新 */\n\treturn;", 1)
    open(p,"w",encoding="utf-8").write(s)
print("  updates plugin disabled")'
for f in "$TAPP"/lib/update-checker-*.js "$TAPP"/lib/update-download-*.js "$TAPP"/lib/update-checker-*.js.map "$TAPP"/lib/update-download-*.js.map; do
  [[ -f "$f" ]] || continue
  sed -i '' 's|https://www\.dshdesktop\.cn/api/desktop/version|https://updates.cris.invalid/api/desktop/version|g; s|https://www\.dshdesktop\.cn/api/downloads/mac|https://updates.cris.invalid/api/downloads/mac|g; s|https://www\.dshdesktop\.cn/api/downloads/windows|https://updates.cris.invalid/api/downloads/windows|g' "$f"
done
cat > "$TRES/app-update.yml" <<'YAML'
# Cris 发行版：正式更新源建立前禁用自动更新。
provider: generic
url: https://updates.cris.invalid/
YAML
UPSTREAM=$(grep -rl --binary-files=without-match "dshdesktop\.cn" "$TAPP/lib" "$TRES/app-update.yml" 2>/dev/null | wc -l | tr -d ' ' || true)
echo "  upstream update refs: ${UPSTREAM}（应为 0）"
[[ "${UPSTREAM}" == "0" ]] || { echo "FAIL: 仍引用上游更新源" >&2; exit 4; }

echo "== 6.5) 清理开发期备份文件 =="
BAKS=$(find "$TAPP" -name '*.bak-*' -type f 2>/dev/null | wc -l | tr -d ' ' || true)
find "$TAPP" -name '*.bak-*' -type f -delete 2>/dev/null || true
echo "  removed dev backups: ${BAKS}"

echo "== 7) 零绝对路径断言 =="
HITS=$(grep -rl --binary-files=without-match "/Users/" "$TPL" 2>/dev/null | wc -l | tr -d ' ' || true)
echo "  profile-template /Users/ hits: $HITS"
[[ "$HITS" == "0" ]] || { grep -rl --binary-files=without-match "/Users/" "$TPL" 2>/dev/null | sed 's/^/    /' >&2 || true; exit 3; }

echo "== 8) 签名 =="
xattr -cr "$TARGET_APP" 2>/dev/null || true
codesign --force --sign - "$TARGET_APP" >/dev/null 2>&1 || echo "  WARN: codesign 失败（不阻断构建）"
VER=$(python3 -c "import json;print(json.load(open('$TAPP/package.json')).get('version','0'))")

echo "== 9) 生成 DMG =="
DMG="$OUT/$APP_NAME-$VER.dmg"; STAGE="$WORK/dmg"
rm -rf "$STAGE"; mkdir -p "$STAGE"
ditto "$TARGET_APP" "$STAGE/$APP_NAME.app"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
echo "DMG=$DMG"
echo "DMG_SIZE=$(du -h "$DMG" | awk '{print $1}')"

echo "== 10) DMG 挂载校验 =="
MNT="$WORK/mnt"; mkdir -p "$MNT"
hdiutil attach -nobrowse -readonly -mountpoint "$MNT" "$DMG" >/dev/null
MAPP="$MNT/$APP_NAME.app"
if [[ -d "$MAPP/Contents/Resources/profile-template" ]]; then
  echo "  mounted profile-template: OK ($(find "$MAPP/Contents/Resources/profile-template" -type f | wc -l | tr -d ' ') files)"
else
  echo "FAIL: dmg 内缺少 profile-template" >&2; hdiutil detach "$MNT" >/dev/null 2>&1 || true; exit 5
fi
if [[ -d "$MAPP/Contents/Resources/profile-template/node_modules/ds-bot" ]]; then
  echo "  mounted ds-bot: OK"
else
  echo "FAIL: dmg 内缺少 ds-bot" >&2; hdiutil detach "$MNT" >/dev/null 2>&1 || true; exit 5
fi

echo "== 11) 从 DMG 拖入的副本再校验 =="
INSTALLED="$OUT/.dmg-copy/$APP_NAME.app"; rm -rf "$OUT/.dmg-copy"; mkdir -p "$OUT/.dmg-copy"
ditto "$MAPP" "$INSTALLED"
hdiutil detach "$MNT" >/dev/null 2>&1 || true
"$(dirname "$0")/verify-artifact.sh" "$INSTALLED" | tail -4 || { echo "FAIL: dmg 内应用校验未通过" >&2; exit 6; }

echo
echo "ARTIFACT=$TARGET_APP"
echo "DMG=$DMG"
echo "VERSION=$VER"
echo "SIZE=$(du -sh "$TARGET_APP" | awk '{print $1}')"
echo "OK"
