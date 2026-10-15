#!/usr/bin/env bash
# Instala o kit Atlas em um repositório. Uso: ./install.sh /caminho/do/seu/projeto
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-.}"
mkdir -p "$TARGET"; TARGET="$(cd "$TARGET" && pwd)"
echo "Instalando Atlas em $TARGET"

copy() { # copy <origem relativa> ; não sobrescreve arquivo existente
  src="$KIT/$1"; dst="$TARGET/$1"
  if [ -e "$dst" ]; then echo "  skip (já existe): $1"; else mkdir -p "$(dirname "$dst")"; cp -r "$src" "$dst"; echo "  + $1"; fi
}
copy .claude/agents; copy .claude/skills; copy .claude/hooks; copy .claude/scripts; copy .claude/settings.json
copy design; copy docs/security; copy docs/retros; copy docs/api
copy CLAUDE.md; copy atlas.config.json; copy CHANGELOG.md; copy .env.example
copy docs/CONVENTIONS.md; copy docs/ARCHITECTURE.md; copy docs/adr
copy .github/ISSUE_TEMPLATE; copy .github/pull_request_template.md
if [ -e "$TARGET/.gitignore" ]; then
  grep -q 'agent-memory-local' "$TARGET/.gitignore" || cat "$KIT/.gitignore" >> "$TARGET/.gitignore"
else copy .gitignore; fi
chmod +x "$TARGET"/.claude/hooks/*.sh "$TARGET"/.claude/scripts/*.sh

cd "$TARGET"
[ -d .git ] || { git init -q -b main; echo "  git init (branch main)"; }
for t in gh jq; do command -v $t >/dev/null || echo "  ATENÇÃO: '$t' não encontrado (obrigatório). Instale antes de usar."; done
for t in node npx; do command -v $t >/dev/null || echo "  aviso: '$t' não encontrado (QA visual: Playwright/axe/Lighthouse marcarão SKIPPED)."; done
for t in gitleaks semgrep; do command -v $t >/dev/null || echo "  aviso: '$t' não encontrado (gate de segurança marcará SKIPPED)."; done
echo
echo "Pronto. Próximos passos:"
echo "  cd $TARGET && claude            # settings.json já define agent: atlas"
echo "  /atlas-init                      # detecta stack, cria develop, labels, docs iniciais"
echo "  /feature <o que você quer>       # e o Atlas assume"
