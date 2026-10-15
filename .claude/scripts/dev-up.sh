#!/usr/bin/env bash
# Sobe (ou reinicia) o ambiente local e espera ficar pronto. Lê atlas.config.json: dev.*, commands.migrate.
# Uso: dev-up.sh [--restart]. Log em .atlas/dev.log, pid em .atlas/dev.pid. Imprime a URL no fim.
set -u
ROOT="${CLAUDE_PROJECT_DIR:-.}"; cd "$ROOT"; CFG=atlas.config.json
cfg(){ # cfg <jq-path> <default>  — usa jq se existir, senão python3
  if command -v jq >/dev/null; then jq -r "$1 // \"$2\"" $CFG
  else python3 -c "import json,sys;d=json.load(open('$CFG'))
v=d
for k in '$1'.strip('.').split('.'):
    v=v.get(k) if isinstance(v,dict) else None
print(v if v not in (None,'') else '$2')"; fi; }
CMD=$(cfg .dev.command ""); URL=$(cfg .dev.url "http://localhost:3000")
HEALTH=$(cfg .dev.health_path "/"); SERVICES=$(cfg .dev.services_up "")
MIGRATE=$(cfg .commands.migrate ""); TIMEOUT=$(cfg .dev.ready_timeout_s 90)
SEED=$(cfg .commands.seed ""); SEEDON=$(cfg .dev.seed_on_start "true")
[ -z "$CMD" ] && { echo "DEV: dev.command não configurado em $CFG — rode /atlas-init ou preencha manualmente"; exit 0; }
mkdir -p .atlas; LOG=.atlas/dev.log; PID=.atlas/dev.pid
bash "$(dirname "$0")/env-check.sh" --sync
[ -n "$SERVICES" ] && { echo "DEV: subindo serviços: $SERVICES"; eval "$SERVICES" >>"$LOG" 2>&1 || echo "DEV: aviso — services_up falhou (veja $LOG)"; }
[ -n "$MIGRATE" ] && { echo "DEV: migrations"; eval "$MIGRATE" >>"$LOG" 2>&1 || echo "DEV: aviso — migrate falhou (veja $LOG)"; }
[ -n "$SEED" ] && [ "$SEEDON" = "true" ] && { echo "DEV: seed de demonstração"; eval "$SEED" >>"$LOG" 2>&1 || echo "DEV: aviso — seed falhou (veja $LOG)"; }
if [ -f "$PID" ] && kill -0 "$(cat $PID)" 2>/dev/null; then
  if [ "${1:-}" = "--restart" ]; then kill "$(cat $PID)" 2>/dev/null; sleep 1; else
    curl -fsS -o /dev/null "$URL$HEALTH" 2>/dev/null && { echo "DEV: já rodando em $URL"; exit 0; }; fi
fi
echo "DEV: iniciando: $CMD"; : > "$LOG"
nohup bash -c "$CMD" >>"$LOG" 2>&1 & echo $! > "$PID"
for i in $(seq 1 "$TIMEOUT"); do
  curl -fsS -o /dev/null "$URL$HEALTH" 2>/dev/null && { echo "DEV: pronto em $URL (log: $LOG)"; exit 0; }
  kill -0 "$(cat $PID)" 2>/dev/null || { echo "DEV: processo morreu. Últimas linhas:"; tail -20 "$LOG"; exit 1; }
  sleep 1
done
echo "DEV: não respondeu em ${TIMEOUT}s em $URL$HEALTH. Últimas linhas:"; tail -20 "$LOG"; exit 1
