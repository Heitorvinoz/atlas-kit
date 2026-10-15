#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Bloqueia operações de git que quebram o fluxo do Atlas.
# Exit 2 = bloqueia e devolve a mensagem (stderr) para o agente. Exit 0 = permite.
set -u
INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
else
  CMD=$(printf '%s' "$INPUT" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)
fi
[ -z "$CMD" ] && exit 0
case "$CMD" in *git*) ;; *) exit 0;; esac

CFG="${CLAUDE_PROJECT_DIR:-.}/atlas.config.json"
MAIN=main; DEVELOP=develop
if [ -f "$CFG" ] && command -v jq >/dev/null 2>&1; then
  MAIN=$(jq -r '.branches.main // "main"' "$CFG"); DEVELOP=$(jq -r '.branches.develop // "develop"' "$CFG")
fi
block() { echo "ATLAS BLOCK: $1" >&2; exit 2; }

# Válvula de escape só para o bootstrap (/atlas-init)
case "$CMD" in *ATLAS_ALLOW_PROTECTED=1*) exit 0;; esac

# 1. Nunca --no-verify, nunca force push
echo "$CMD" | grep -qE -- '--no-verify' && block "--no-verify não é permitido. Corrija o que o hook reclamou."
echo "$CMD" | grep -qE 'git push.*(--force|-f\b|--force-with-lease)' && block "force push não é permitido em nenhuma branch."

# 2. Nunca push direto em main/develop (merges acontecem via gh pr merge)
if echo "$CMD" | grep -qE 'git push'; then
  echo "$CMD" | grep -qE "git push[^|&;]*\b(origin\s+)?($MAIN|$DEVELOP)(:|\s|$)" && block "push direto em $MAIN/$DEVELOP não é permitido. Abra PR com gh pr create e mergeie com gh pr merge."
  CUR=$(git -C "${CLAUDE_PROJECT_DIR:-.}" branch --show-current 2>/dev/null || true)
  if [ "$CUR" = "$MAIN" ] || [ "$CUR" = "$DEVELOP" ]; then
    echo "$CMD" | grep -qE 'git push[[:space:]]+origin[[:space:]]+v[0-9]' || block "você está em '$CUR'. Só tags (git push origin vX.Y.Z) podem ser pushadas daqui."
  fi
fi

# 3. Nunca commit direto em main/develop; mensagem em Conventional Commits
if echo "$CMD" | grep -qE 'git commit'; then
  CUR=$(git -C "${CLAUDE_PROJECT_DIR:-.}" branch --show-current 2>/dev/null || true)
  [ "$CUR" = "$MAIN" ] || [ "$CUR" = "$DEVELOP" ] && block "commit direto em '$CUR' não é permitido. Crie uma branch feat/<issue>-<slug> a partir de $DEVELOP."
  case "$CUR" in
    feat/*|fix/*|chore/*|refactor/*|docs/*|test/*|hotfix/*|release/*) ;;
    "") ;;
    *) block "branch '$CUR' fora do padrão <tipo>/<issue>-<slug> (feat|fix|chore|refactor|docs|test|hotfix|release).";;
  esac
  MSG=$(printf '%s' "$CMD" | sed -nE "s/.*-m[[:space:]]+[\"']([^\"']+)[\"'].*/\1/p" | head -1)
  if [ -n "$MSG" ]; then
    echo "$MSG" | grep -qE '^(feat|fix|chore|docs|refactor|test|perf|ci|build|style|revert)(\([a-zA-Z0-9._/-]+\))?!?: .{1,72}$' \
      || block "mensagem de commit fora do Conventional Commits: '$MSG'. Use <tipo>(<escopo>): <descrição ≤72 chars>."
    echo "$MSG" | grep -qiE '^(wip|fix stuff|update|changes|misc)' && block "mensagem vaga ('$MSG'). Diga o que mudou."
  fi
fi

# 4. Nunca commitar arquivos de segredo
echo "$CMD" | grep -qE 'git add[^|&;]*(\.env([[:space:]]|$)|\.env\.(local|dev|development|prod|production|staging|test)\b|id_rsa|\.pem\b|credentials\.json)' && block "tentativa de adicionar arquivo de segredo ao git."
exit 0
