#!/usr/bin/env bash
# Envia notificação ao usuário. Uso: notify.sh "<título>" "<mensagem>"
# Canais em atlas.config.json → notify.channels (ntfy | telegram | slack | desktop). Segredos em ~/.atlas/notify.env
# (NTFY_TOPIC, TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID, SLACK_WEBHOOK_URL) — fora do repositório, nunca lidos pelos agentes.
set -u
ROOT="${CLAUDE_PROJECT_DIR:-.}"; T="${1:-Atlas}"; M="${2:-}"
[ -f "$HOME/.atlas/notify.env" ] && set -a && . "$HOME/.atlas/notify.env" && set +a
CH=$(python3 -c "import json;print(' '.join(json.load(open('$ROOT/atlas.config.json')).get('notify',{}).get('channels',[])))" 2>/dev/null)
for c in $CH; do case "$c" in
  ntfy) [ -n "${NTFY_TOPIC:-}" ] && curl -fsS -H "Title: $T" -d "$M" "https://ntfy.sh/$NTFY_TOPIC" >/dev/null 2>&1 && echo "NOTIFY: ntfy ok";;
  telegram) [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && curl -fsS "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" --data-urlencode "chat_id=${TELEGRAM_CHAT_ID:-}" --data-urlencode "text=$T
$M" >/dev/null 2>&1 && echo "NOTIFY: telegram ok";;
  slack) [ -n "${SLACK_WEBHOOK_URL:-}" ] && curl -fsS -X POST -H 'Content-type: application/json' --data "$(python3 -c "import json,sys;print(json.dumps({'text':sys.argv[1]+'\n'+sys.argv[2]}))" "$T" "$M")" "$SLACK_WEBHOOK_URL" >/dev/null 2>&1 && echo "NOTIFY: slack ok";;
  desktop) if command -v osascript >/dev/null; then osascript -e "display notification \"$M\" with title \"$T\"" 2>/dev/null; elif command -v notify-send >/dev/null; then notify-send "$T" "$M" 2>/dev/null; elif command -v powershell.exe >/dev/null; then powershell.exe -c "[reflection.assembly]::loadwithpartialname('System.Windows.Forms');[System.Windows.Forms.MessageBox]::Show('$M','$T')" >/dev/null 2>&1; fi; echo "NOTIFY: desktop";;
esac; done
exit 0
