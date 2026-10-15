#!/usr/bin/env bash
# Tira screenshots de rotas do localhost. Uso: screenshot.sh <issue-ou-nome> <rota> [<rota> ...]
# Gera design/screenshots/<nome>/<rota>.png (desktop 1280x800) e <rota>.mobile.png (390x844). Requer node (npx playwright).
set -u
ROOT="${CLAUDE_PROJECT_DIR:-.}"; cd "$ROOT"
NAME="${1:?nome}"; shift
URL=$(python3 -c "import json;print(json.load(open('atlas.config.json')).get('dev',{}).get('url','http://localhost:3000'))")
OUT="design/screenshots/$NAME"; mkdir -p "$OUT"
command -v npx >/dev/null || { echo "SHOT: npx ausente (precisa de Node para o Playwright)"; exit 0; }
for r in "$@"; do
  f=$(echo "$r" | sed 's#^/##; s#/#_#g; s#^$#index#')
  npx -y playwright screenshot --full-page --viewport-size=1280,800 "$URL$r" "$OUT/$f.png" >/dev/null 2>&1 && echo "SHOT: $OUT/$f.png" || echo "SHOT: falhou $r (desktop)"
  npx -y playwright screenshot --full-page --viewport-size=390,844 --device="iPhone 13" "$URL$r" "$OUT/$f.mobile.png" >/dev/null 2>&1 && echo "SHOT: $OUT/$f.mobile.png" || echo "SHOT: falhou $r (mobile)"
done
