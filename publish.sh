#!/usr/bin/env bash
# Publica este kit no seu GitHub como repositório TEMPLATE. Uso: ./publish.sh [nome-do-repo] [--private]
# Requer: git, gh autenticado (gh auth login).
set -euo pipefail
NAME="${1:-atlas-kit}"; VIS="--public"; [ "${2:-}" = "--private" ] && VIS="--private"
cd "$(dirname "$0")"
gh auth status >/dev/null 2>&1 || { echo "Rode 'gh auth login' primeiro."; exit 1; }
[ -d .git ] || { git init -q -b main; }
git add -A && git -c user.name="${GIT_AUTHOR_NAME:-atlas}" -c user.email="${GIT_AUTHOR_EMAIL:-atlas@local}" commit -qm "chore: Atlas kit" || true
if gh repo view "$NAME" >/dev/null 2>&1; then git remote get-url origin >/dev/null 2>&1 || git remote add origin "$(gh repo view "$NAME" --json url -q .url).git"; git push -u origin main
else gh repo create "$NAME" $VIS --source=. --push --description "Atlas — orquestrador de desenvolvimento para Claude Code"; fi
gh repo edit "$NAME" --template
echo
echo "Pronto: $(gh repo view "$NAME" --json url -q .url)  (marcado como template)"
echo "Para um projeto novo: gh repo create meu-projeto --template $NAME --private --clone && cd meu-projeto && claude"
