#!/usr/bin/env bash
# PostToolUse hook (matcher: Edit|Write). Formata o arquivo editado com commands.format_file, se configurado.
# Nunca bloqueia (exit 0). Mantém o código sempre formatado sem gastar contexto do agente.
set -u
INPUT=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE" ] && exit 0
CFG="${CLAUDE_PROJECT_DIR:-.}/atlas.config.json"
[ -f "$CFG" ] || exit 0
FMT=$(jq -r '.commands.format_file // empty' "$CFG")
[ -z "$FMT" ] && exit 0
case "$FILE" in *.md|*.json|*.yml|*.yaml|*.env*|*.lock) exit 0;; esac
CMD="${FMT//\{file\}/$FILE}"
( cd "${CLAUDE_PROJECT_DIR:-.}" && eval "$CMD" ) >/dev/null 2>&1 || true
exit 0
