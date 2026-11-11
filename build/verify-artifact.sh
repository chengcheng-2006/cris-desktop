#!/usr/bin/env bash
# verify-artifact.sh — 校验 Cris 发行产物满足「自包含 / 无绝对路径 / 首次带 DS Bot」。
# 用法: verify-artifact.sh <Cris.app>
set -uo pipefail
APP="${1:-}"
[[ -n "$APP" && -d "$APP" ]] || { echo "usage: verify-artifact.sh <Cris.app>" >&2; exit 2; }
RES="$APP/Contents/Resources"
TAPP="$RES/app"
TPL="$RES/profile-template"
PASS=0; FAIL=0
ok()  { printf 'PASS  %-38s %s\n' "$1" "${2:-}"; PASS=$((PASS+1)); }
bad() { printf 'FAIL  %-38s %s\n' "$1" "${2:-}"; FAIL=$((FAIL+1)); }

echo "== verify artifact =="
echo "APP=$APP"
echo

# 1 模板存在且含 ds-bot
if [[ -d "$TPL/node_modules/ds-bot" ]]; then
  n=$(find "$TPL" -type f | wc -l | tr -d ' ')
  ok "profile-template ds-bot" "files=$n"
else
  bad "profile-template ds-bot" "缺失"
fi

# 2 模板清单把 ds-bot 列为 bundle
if python3 -c "
import json,sys
d=json.load(open('$TPL/package.json'))
sys.exit(0 if 'ds-bot' in d['dsh']['profile']['bundles'] else 1)" 2>/dev/null; then
  ok "template bundles include ds-bot"
else
  bad "template bundles include ds-bot" "未列出"
fi

# 3 种子配置：0 provider / 0 key / 0 本地路由
if [[ -f "$TPL/cordis.patch.yml" ]]; then
  ROUTES=$(grep -cE '127\.0\.0\.1|localhost' "$TPL/cordis.patch.yml" 2>/dev/null || true)
  PROV=$(grep -cE '^\s*providers:|apiKeyEnv:|apiKey:' "$TPL/cordis.patch.yml" 2>/dev/null || true)
  if [[ "${ROUTES:-0}" == "0" && "${PROV:-0}" == "0" ]]; then
    ok "seed no provider/route" "routes=0 providers=0"
  else
    bad "seed no provider/route" "routes=${ROUTES:-?} providers=${PROV:-?}"
  fi
else
  bad "seed cordis.patch.yml" "缺失"
fi

# 4 产物关键文件零绝对路径
HITS=0
for f in "$TAPP/package.json" "$TPL/package.json" "$TPL/pnpm-workspace.yaml" "$TPL/cordis.patch.yml" \
         "$TAPP/node_modules/@deepseek-ai/dsh-app-boot/lib/index.js"; do
  [[ -f "$f" ]] || continue
  if grep -q --binary-files=without-match "/Users/" "$f" 2>/dev/null; then
    bad "no abs path: $(basename "$f")" "命中 /Users/"; HITS=$((HITS+1))
  fi
done
[[ $HITS -eq 0 ]] && ok "no abs path in config/boot" "0 hits"

# 5 安装元数据未随包（.modules.yaml / storeDir）
MD=$(find "$TPL" -name '.modules.yaml' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$MD" == "0" ]]; then ok "no pnpm install metadata" "0 files"; else bad "no pnpm install metadata" "$MD"; fi

# 6 cris 模板与首次启动补丁存在
if grep -qE 'cris: \{ bundles:' "$TAPP/node_modules/@deepseek-ai/dsh-app-boot/lib/index.js" 2>/dev/null; then
  ok "cris template registered"
else
  bad "cris template registered" "未找到"
fi
if grep -q '__crisProfileTemplate' "$TAPP/node_modules/@deepseek-ai/dsh-app-boot/lib/index.js" 2>/dev/null; then
  ok "first-run template copy patched"
else
  bad "first-run template copy patched" "未找到"
fi

# 7 上游更新链路已关闭
if [[ -f "$RES/app-update.yml" ]] && ! grep -qE 'anywhere-labs|dshdesktop\.cn' "$RES/app-update.yml"; then
  ok "update feed neutral" "$(grep -c 'url:' "$RES/app-update.yml" 2>/dev/null || echo 0) url line"
else
  bad "update feed neutral" "仍指向上游"
fi
UP=$(grep -rl --binary-files=without-match "dshdesktop\.cn" "$TAPP/lib" 2>/dev/null | wc -l | tr -d ' ' || true)
[[ "$UP" == "0" ]] && ok "no upstream endpoint in lib" "0 hits" || bad "no upstream endpoint in lib" "$UP files"
grep -q '__crisUpdatesDisabled' "$TAPP/lib/updates.js" 2>/dev/null && ok "updates plugin disabled" || bad "updates plugin disabled" "未禁用"

# 8 签名状态（仅记录，不判失败）
SIG=$(codesign -dv --verbose=2 "$APP" 2>&1 | awk -F= '/^Signature=/{print $2}')
ok "signature state" "${SIG:-unknown}（正式签名/公证为环境 BLOCKED）"

echo
echo "PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]] && { echo "RESULT=OK"; exit 0; } || { echo "RESULT=FAIL"; exit 1; }
