#!/usr/bin/env bash
# Estado do trabalho em andamento, para o Atlas retomar de onde parou após compactação ou nova sessão.
# Uso:
#   session-state.sh set "<texto>"      grava .atlas/STATE.md (o Atlas chama a cada etapa do pipeline)
#   session-state.sh clear               limpa (fim de feature/release)
#   session-state.sh inject              hook SessionStart: injeta STATE.md + último relatório como contexto
#   session-state.sh precompact          hook PreCompact: lembra o Atlas de salvar o estado antes de compactar
set -u
ROOT="${CLAUDE_PROJECT_DIR:-.}"; mkdir -p "$ROOT/.atlas"; F="$ROOT/.atlas/STATE.md"; R="$ROOT/.atlas/LAST_REPORT.md"
case "${1:-}" in
  set) shift; { echo "# Estado do Atlas — $(date -u +%Y-%m-%dT%H:%MZ)"; echo; echo "$*"; } > "$F"; echo "STATE: salvo";;
  clear) rm -f "$F"; echo "STATE: limpo";;
  inject)
    CTX=""
    [ -f "$F" ] && CTX="$CTX\n\n<atlas_state>\n$(cat "$F")\n</atlas_state>"
    [ -f "$R" ] && CTX="$CTX\n\n<atlas_last_report>\n$(cat "$R")\n</atlas_last_report>"
    BR=$(git -C "$ROOT" branch --show-current 2>/dev/null); ST=$(git -C "$ROOT" status --short 2>/dev/null | wc -l | tr -d ' ')
    CTX="$CTX\n\n<atlas_git>branch: $BR · arquivos modificados: $ST</atlas_git>"
    [ -n "$CTX" ] && printf "$CTX" | python3 -c "import json,sys;print(json.dumps({'hookSpecificOutput':{'hookEventName':'SessionStart','additionalContext':'ATLAS — contexto restaurado automaticamente. Se houver <atlas_state>, retome DE ONDE PAROU sem repetir etapas concluídas; confira com git status e gh antes de agir.\n'+sys.stdin.read()}}))"
    exit 0;;
  precompact)
    python3 -c "import json;print(json.dumps({'systemMessage':'ATLAS: o contexto vai ser compactado. Antes, grave o estado atual com: bash .claude/scripts/session-state.sh set \"issue #N · onda X · feito: ... · falta: ... · decisões pendentes: ...\" e atualize sua memória (MEMORY.md) com o que aprendeu nesta sessão.'}))"
    exit 0;;
  *) echo "uso: session-state.sh set|clear|inject|precompact"; exit 1;;
esac
