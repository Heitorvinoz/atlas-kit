#!/usr/bin/env bash
# Compara CHAVES de .env.example e .env sem expor valores. Uso: env-check.sh [--sync]
# --sync: cria .env a partir do .env.example se não existir e acrescenta chaves faltantes (com o valor de exemplo).
set -u
ROOT="${CLAUDE_PROJECT_DIR:-.}"; EX="$ROOT/.env.example"; ENVF="$ROOT/.env"
[ -f "$EX" ] || { echo "ENV: sem .env.example — nada a verificar"; exit 0; }
keys(){ grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$1" 2>/dev/null | cut -d= -f1 | sort -u; }
if [ ! -f "$ENVF" ]; then
  if [ "${1:-}" = "--sync" ]; then cp "$EX" "$ENVF"; echo "ENV: .env criado a partir do .env.example"; else echo "ENV: .env não existe"; fi
fi
MISSING=$(comm -23 <(keys "$EX") <(keys "$ENVF"))
PLACEHOLDER=""
for k in $(keys "$ENVF"); do
  v=$(grep -E "^$k=" "$ENVF" | head -1 | cut -d= -f2-)
  [ -z "$v" ] || echo "$v" | grep -qiE '^(changeme|xxx+|your[-_]|<.*>|todo|replace)' && PLACEHOLDER="$PLACEHOLDER $k"
done
if [ -n "$MISSING" ] && [ "${1:-}" = "--sync" ]; then
  { echo; echo "# adicionado pelo Atlas (env-check --sync) — preencha:"; for k in $MISSING; do grep -E "^$k=" "$EX" | head -1; done; } >> "$ENVF"
  echo "ENV: chaves adicionadas ao .env (preencha): $(echo $MISSING | tr '\n' ' ')"
elif [ -n "$MISSING" ]; then echo "ENV: faltam no .env: $(echo $MISSING | tr '\n' ' ')"; fi
[ -n "$PLACEHOLDER" ] && echo "ENV: valores ainda de exemplo (preencha):$PLACEHOLDER"
EXTRA=$(comm -13 <(keys "$EX") <(keys "$ENVF"))
[ -n "$EXTRA" ] && echo "ENV: no .env mas não documentadas no .env.example (docs deve adicionar): $(echo $EXTRA | tr '\n' ' ')"
[ -z "$MISSING$PLACEHOLDER$EXTRA" ] && echo "ENV: ok"
exit 0
