#!/bin/bash
# publish-gate.sh — 开源发布前的独立闸门（可公开版本）
#
# 用法: build/publish-gate.sh <要发布的目录>
# 退出码: 0 = 无 BLOCK（仍可能有人工 REVIEW 项）; 1 = 有 BLOCK，禁止推送; 2 = 用法错误
#
# 设计原则:
#   1. 仓库里只放通用规则；个人标识（真实姓名、设备名、账号）放在仓库外的
#      CRIS_PRIVATE_RULES 指定的仓库外文件，仓库只放 .example。
#   2. 本脚本扫描自己，不排除自身。
#   3. 命中凭据时只输出「位置 + 长度」，不输出任何字符。
set -uo pipefail

DIR="${1:-}"
MODE="${2:---mode=draft}"
[ "$MODE" = "--mode=draft" ] || [ "$MODE" = "--mode=final" ] || { echo "无效模式" >&2; exit 2; }
[ "$#" -le 2 ] && [ -n "$DIR" ] && [ -d "$DIR" ] || { echo "用法: $0 <目录> [--mode=draft|--mode=final]"; exit 2; }
cd "$DIR" || exit 2
if [ "$MODE" = "--mode=draft" ]; then echo 'DRAFT 模式退出码不能作为任何发布依据'; fi

BLOCK=0; REVIEW=0
block()  { BLOCK=$((BLOCK+1));  printf 'BLOCK   %-22s %s\n' "$1" "$2"; }
review() { REVIEW=$((REVIEW+1)); printf 'REVIEW  %-22s %s\n' "$1" "$2"; }
ok()     { printf 'OK      %-22s %s\n' "$1" "$2"; }
say()    { printf '\n== %s ==\n' "$1"; }

# 由片段拼接，避免脚本自身出现完整字面量而被自己命中
SLASH_USERS="/Us"; SLASH_USERS="${SLASH_USERS}ers/"
WIN_USERS='C:\\\\Us'; WIN_USERS="${WIN_USERS}ers\\\\"

# ---------- 规则 ----------
KEY_RULE='sk-[A-Za-z0-9_-]{20,}|tvly-[A-Za-z0-9]{12,}|AIza[0-9A-Za-z_-]{20,}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|Bearer +[A-Za-z0-9._-]{20,}'
PATH_RULE="${SLASH_USERS}[A-Za-z0-9._-]+|${WIN_USERS}[A-Za-z0-9._-]+"
PRIV_RULE='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|1[3-9][0-9]{9}'
FORBID_RULE='(^|/)state\.json$|^sessions/|^bot/memory|^attachments/|^storages/|\.sqlite$|(^|/)\.env$|\.bak$|(^|/)node_modules/|^dist/|\.dmg$|\.p12$|(^|/)\.ssh/|\.rules\.local$'

# 个人规则（仓库外，可选）
LOCAL_RULES="${CRIS_PRIVATE_RULES:-}"
[ -n "$LOCAL_RULES" ] && [ -f "$LOCAL_RULES" ] && [ -r "$LOCAL_RULES" ] || { echo "BLOCK   个人规则文件缺失或不可读取" >&2; exit 1; }
python3 - "$LOCAL_RULES" <<'PY' || { echo "BLOCK   个人规则须放在仓库外" >&2; exit 1; }
import os, sys
root = os.path.realpath('.')
rule = os.path.realpath(sys.argv[1])
sys.exit(1 if os.path.commonpath([root, rule]) == root else 0)
PY
PERSONAL_RULE=$(grep -vE '^[[:space:]]*(#|$)' "$LOCAL_RULES" | paste -sd'|' -)
[ -n "$PERSONAL_RULE" ] || { echo "BLOCK   个人规则为空" >&2; exit 1; }
grep -Eq "$PERSONAL_RULE" /dev/null 2>/dev/null
[ "$?" -ne 2 ] || { echo "BLOCK   个人规则解析失败" >&2; exit 1; }

scan() {  # scan <label> <regex> <block|review>
  local label="$1" re="$2" level="$3" n=0 hit file rest line
  [ -n "$re" ] || return 0
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    n=$((n+1))
    file=${hit%%:*}; rest=${hit#*:}; line=${rest%%:*}
    if [ "$level" = "block" ]; then block "$label" "$file:$line"; else review "$label" "$file:$line"; fi
  done < <(grep -rInE "$re" . --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=dist 2>/dev/null | head -40)
  [ "$n" -eq 0 ] && ok "$label" "0"
  return 0
}

say "0. 目标"
printf '目录: %s\n' "$(pwd)"
printf '文件数: %s\n' "$(find . -type f ! -path './.git/*' 2>/dev/null | wc -l | tr -d ' ')"
printf '个人规则: 已加载\n'

say "1. 禁止路径"
FORBID_N=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  FORBID_N=$((FORBID_N+1)); block "禁止路径" "$f"
done < <(find . -type f ! -path './.git/*' | sed 's|^\./||' | grep -Ei "$FORBID_RULE" | head -40)
[ "$FORBID_N" -eq 0 ] && ok "禁止路径" "0"

say "2. 凭据形态（只报位置与长度）"
CRED_N=0
while IFS= read -r hit; do
  [ -z "$hit" ] && continue
  CRED_N=$((CRED_N+1))
  file=${hit%%:*}; rest=${hit#*:}; line=${rest%%:*}; content=${rest#*:}
  m=$(printf '%s' "$content" | grep -Eo "$KEY_RULE" | head -1)
  block "凭据命中" "$file:$line len=${#m}"
done < <(grep -rInE "$KEY_RULE" . --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=dist 2>/dev/null | head -40)
[ "$CRED_N" -eq 0 ] && ok "凭据形态" "0"

say "3. 本机绝对路径"
scan "本机路径" "$PATH_RULE" block

say "4. 邮箱与手机号"
scan "邮箱/手机号" "$PRIV_RULE" review

say "5. 个人标识（仓库外规则）"
if [ "${CRIS_PUBLIC_URLS+x}" != x ]; then
  scan "个人标识" "$PERSONAL_RULE" block
else
  if PERSONAL_HITS=$(CRIS_GATE_PERSONAL_RULE="$PERSONAL_RULE" python3 - "${CRIS_PUBLIC_URLS}" <<'PY'
import json, os, re, subprocess, sys
from pathlib import Path, PurePosixPath
from urllib.parse import urlsplit

try:
    root = Path('.').resolve(strict=True)
    config_path = Path(sys.argv[1]).resolve(strict=True)
    if not config_path.is_file() or os.path.commonpath((str(root), str(config_path))) == str(root):
        raise ValueError('invalid config location')
    def unique_object(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError('duplicate key')
            result[key] = value
        return result
    with config_path.open('r', encoding='utf-8') as f:
        config = json.load(f, object_pairs_hook=unique_object)
    if not isinstance(config, dict):
        raise ValueError('invalid config')
    compiled = {}
    for name, urls in config.items():
        if (not isinstance(name, str) or not name or PurePosixPath(name).is_absolute()
                or str(PurePosixPath(name)) != name or any(p in ('.', '..') for p in name.split('/'))
                or any(ord(ch) < 32 or ord(ch) == 127 for ch in name) or ':' in name):
            raise ValueError('invalid relative path')
        if not isinstance(urls, list) or not urls or len(urls) != len(set(urls)):
            raise ValueError('invalid URL list')
        checks = []
        for url in urls:
            if not isinstance(url, str) or not url.isascii() or any(ch.isspace() or ord(ch) < 32 for ch in url):
                raise ValueError('invalid URL')
            parsed = urlsplit(url)
            if parsed.scheme != 'https' or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
                raise ValueError('invalid URL')
            # Match only a complete URL, never a prefix of another URL or a longer token.
            checks.append(re.compile(rb'(?<![A-Za-z0-9._~%+/@:-])' + re.escape(url.encode('ascii')) + rb'(?=$|[\s)\]}>"\x27])'))
        compiled[name] = checks
    rule = os.environ['CRIS_GATE_PERSONAL_RULE']
    for directory, dirs, files in os.walk(root, followlinks=False, onerror=lambda _: (_ for _ in ()).throw(OSError('scan error'))):
        dirs[:] = [d for d in dirs if d not in ('.git', 'node_modules', 'dist')]
        for name in sorted(files):
            path = Path(directory) / name
            if path.is_symlink():
                raise ValueError('symlink in scan')
            relative = path.relative_to(root).as_posix()
            data = path.read_bytes()
            for pattern in compiled.get(relative, ()):
                data = pattern.sub(b'[PUBLIC-URL]', data)
            result = subprocess.run(['grep', '-I', '-n', '-E', '--', rule], input=data, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            if result.returncode not in (0, 1):
                raise OSError('grep failed')
            for hit in result.stdout.splitlines():
                number = hit.split(b':', 1)[0]
                if not number.isdigit():
                    raise ValueError('invalid grep output')
                print(f'./{relative}:{number.decode("ascii")}')
except (OSError, ValueError, TypeError, UnicodeError, json.JSONDecodeError):
    print('BLOCK   公共 URL 配置或个人标识扫描失败', file=sys.stderr)
    sys.exit(1)
PY
  ); then
    if [ -n "$PERSONAL_HITS" ]; then
      while IFS= read -r hit; do block "个人标识" "$hit"; done <<< "$PERSONAL_HITS"
    else
      ok "个人标识" "0"
    fi
  else
    block "个人标识" "公共 URL 配置或扫描失败"
  fi
fi

say "6. git 历史"
if git rev-parse --show-toplevel >/dev/null 2>&1 && git rev-parse --verify HEAD >/dev/null 2>&1; then
  if HISTORY=$(git log -p --all 2>/dev/null) && COUNT=$(git rev-list --count HEAD 2>/dev/null) && TRACKED=$(git ls-files 2>/dev/null); then
    printf '提交数: %s\n' "$COUNT"
    HIST=$(printf '%s\n' "$HISTORY" | grep -E '^\+' | grep -Ec "$KEY_RULE|$PATH_RULE" || true)
    if [ "${HIST:-0}" -gt 0 ]; then block "git 历史" "历史提交含凭据或本机路径，需重建仓库"; else ok "git 历史" "0"; fi
    T=$(printf '%s\n' "$TRACKED" | grep -Ec "$FORBID_RULE" || true)
    if [ "${T:-0}" -gt 0 ]; then block "已跟踪文件" "有 ${T} 个禁止路径被跟踪"; else ok "已跟踪文件" "0"; fi
  else
    block "git 历史" "历史读取失败"
  fi
elif [ "$MODE" = "--mode=final" ]; then
  block "git 历史" "不是有效的已提交 Git 仓库"
else
  review "git 历史" "当前没有可审查的提交"
fi

say "7. 必含文件与许可"
for f in README.md LICENSE SECURITY.md CONTRIBUTING.md THIRD_PARTY_NOTICES.md .gitignore build/build-cris.sh build/verify-artifact.sh build/publish-gate.sh build/publish-gate.rules.example profile-template/cordis.patch.yml profile-template/package.json docs/BUILD.md docs/UPSTREAM.md docs/licenses/dsh-MIT.txt docs/licenses/desktop-MIT.txt; do
  if [ -f "$f" ]; then ok "必含文件" "$f"; elif [ "$MODE" = "--mode=final" ]; then block "必含文件" "$f 缺失"; else review "必含文件" "$f 缺失"; fi
done
if [ -f LICENSE ]; then
  if grep -qi "Anywhere Labs" LICENSE; then ok "上游声明" "保留"; else review "上游声明" "未见上游版权声明，若含其代码需补"; fi
fi
if grep -q 'rules\.local' .gitignore 2>/dev/null; then ok ".gitignore" "已挡 rules.local"; else review ".gitignore" "未挡 *.rules.local，个人规则可能被提交"; fi

say "结果"
printf 'BLOCK=%d REVIEW=%d\n' "$BLOCK" "$REVIEW"
if [ "$BLOCK" -gt 0 ]; then
  echo "RESULT=FAIL（BLOCK 未清零，禁止推送）"
  exit 1
fi
echo "RESULT=PASS（仍需：独立审查 BLOCK=0 + 必含文件齐全 + 提交 SHA 一致）"
exit 0
