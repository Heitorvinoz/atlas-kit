---
name: status
description: Visão geral do projeto: branch atual, issues e PRs abertas, última release, itens em Unreleased, ADRs recentes e pendências. Use quando o usuário perguntar "onde estamos" ou no início de uma sessão.
---

Monte um painel curto (sem logs brutos):
- `git branch --show-current`, `git status --short | wc -l` arquivos modificados, `git log develop..HEAD --oneline | wc -l` commits à frente.
- `gh issue list --state open --limit 15` agrupadas por label `type:` e `area:`.
- `gh pr list --state open`.
- Última release: `git describe --tags --abbrev=0` e `gh release list --limit 3`.
- `CHANGELOG.md` → itens em `[Unreleased]` (isso é o que a próxima release vai conter).
- 3 ADRs mais recentes de `docs/adr/README.md`.
- `bash .claude/scripts/metrics.sh report 5` → tempo médio por entrega, ciclos de review, agentes mais usados, últimas releases.
- Deploy: `deploy.url.staging|prod` e última versão publicada (da sua memória / `metrics.sh`).
- `docs/IDEAS.md`: quantas ideias estacionadas, as 3 mais recentes.
- Da sua memória: pendências, dívidas conhecidas, decisões em aberto.
Termine com: "sugestão de próximo passo" em 1 linha (ex.: "3 features em Unreleased e nenhuma PR aberta: bom momento para `/release minor`").
