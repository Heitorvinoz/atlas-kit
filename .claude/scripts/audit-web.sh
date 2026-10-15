#!/usr/bin/env bash
# Acessibilidade (axe) e performance (Lighthouse) de rotas do localhost contra os orçamentos de atlas.config.json.
# Uso: audit-web.sh <rota> [<rota> ...]. Saída resumida; detalhes em .atlas/audit/. Exit 1 se algum orçamento estourar.
set -u
ROOT="${CLAUDE_PROJECT_DIR:-.}"; cd "$ROOT"; mkdir -p .atlas/audit
read -r URL PERF A11Y BP <<<"$(python3 -c "import json;c=json.load(open('atlas.config.json'));b=c.get('quality',{}).get('budgets',{});print(c.get('dev',{}).get('url','http://localhost:3000'),b.get('lighthouse_perf_min',70),b.get('lighthouse_a11y_min',90),b.get('lighthouse_best_practices_min',80))")"
command -v npx >/dev/null || { echo "AUDIT: npx ausente"; exit 0; }
FAIL=0
for r in "$@"; do
  f=$(echo "$r" | sed 's#^/##; s#/#_#g; s#^$#index#')
  echo "== $r"
  if npx -y @axe-core/cli "$URL$r" --save ".atlas/audit/$f.axe.json" >/dev/null 2>&1; then
    V=$(python3 -c "import json;d=json.load(open('.atlas/audit/$f.axe.json'));v=d[0]['violations'] if isinstance(d,list) else d.get('violations',[]);print(len(v));[print('  a11y',x['impact'],x['id'],'-',x['help']) for x in v if x['impact'] in ('critical','serious')]")
    echo "  axe: $(echo "$V"|head -1) violações"; echo "$V" | grep -q 'a11y critical\|a11y serious' && FAIL=1
  else echo "  axe: não rodou"; fi
  if npx -y lighthouse "$URL$r" --quiet --output=json --output-path=".atlas/audit/$f.lh.json" --chrome-flags="--headless --no-sandbox" --only-categories=performance,accessibility,best-practices >/dev/null 2>&1; then
    python3 - "$f" "$PERF" "$A11Y" "$BP" <<'PY' || FAIL=1
import json,sys
f,perf,a11y,bp=sys.argv[1],*map(int,sys.argv[2:5])
c=json.load(open(f".atlas/audit/{f}.lh.json"))["categories"]
s={k:round(c[k]["score"]*100) for k in ("performance","accessibility","best-practices")}
ok=s["performance"]>=perf and s["accessibility"]>=a11y and s["best-practices"]>=bp
print(f"  lighthouse: perf {s['performance']} (min {perf}) · a11y {s['accessibility']} (min {a11y}) · bp {s['best-practices']} (min {bp}) → {'ok' if ok else 'ESTOUROU'}")
sys.exit(0 if ok else 1)
PY
  else echo "  lighthouse: não rodou (precisa de Chrome)"; fi
done
exit $FAIL
