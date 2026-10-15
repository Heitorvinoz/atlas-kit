---
name: feature
description: Pipeline completo de uma feature ou bug: entender → issue no GitHub → plano → branch → delegar (database/backend/frontend) → qa → review → security → docs → PR em develop. Use quando o usuário pedir algo novo, uma mudança ou uma correção.
---

Pedido do usuário: $ARGUMENTS

Execute o **Pipeline de feature** definido no seu prompt (agente `atlas`), sem pular etapas obrigatórias.
Resumo operacional:

1. Reescreva o pedido + critérios de aceite + fora do escopo + premissas. Em modo `full` (ver `autonomy.mode`) isso
   vai direto para a issue, sem confirmar. Só pergunte se a ambiguidade muda o resultado.
   Se for bug: se não houver passos de reprodução, tente reproduzir você mesmo via `qa` antes de perguntar.
2. Decisões não óbvias → em `full`, escolha a mais simples/reversível e registre com `/adr`; pergunte só se envolver
   dinheiro, autenticação, exclusão de dados ou custo recorrente. Pequenas → corpo da issue.
3. (a partir daqui, grave o estado a cada etapa: `session-state.sh set "..."`) `gh issue create --title "<tipo>: <título>" --label "type:<feat|fix>" --label "area:<...>" --body-file -`
   usando o template de `.github/ISSUE_TEMPLATE/`. Guarde `N`.
4. Contrato (dados, API, UI) escrito por você + ondas de execução; `gh issue comment N`; `TodoWrite`.
5. `git checkout develop && git pull --ff-only && git checkout -b <feat|fix>/N-<slug>`.
6. Onda 1 — dispare juntos, cada um em `isolation: worktree` / sub-branch: `database`, `backend`, `frontend`
   (se houver UI, `designer` primeiro, depois `frontend`, dentro da mesma onda) e `security` (`threat-model`) se houver superfície de ataque. Passe sempre: issue, branch, objetivo,
   critérios, escopo de paths, ADRs, o CONTRATO do plano, comandos do `atlas.config.json`. Merge das sub-branches na
   branch da feature; `commands.test`.
7. Onda 2 — juntos: `qa` (suíte + navegação no localhost + screenshots + a11y/perf; antes dele rode `dev-up.sh --restart` na branch)
   + `reviewer` + `security` (`audit`, ESCOPO: diff, conferindo o threat model). `request-changes`, `fail` ou `BLOCK` → onda 3 com
   as correções (paralelas por área) e re-rode só a verificação afetada. Máximo `quality.max_review_cycles`; estourou, pare e reporte.
8. Onda 3 — `docs` (inclui docs vivas: OpenAPI, arquitetura, links) em paralelo com as correções e, se configurado, `deploy` (`preview`).
   Passe os relatórios (contratos, decisões, env vars).
9. Gate curto na branch: `commands.lint`, `commands.typecheck`, `commands.test`. Tudo verde ou não abre PR.
10. `gh pr create --base develop --title "<tipo>(<escopo>): <título>" --body-file -` com o template de PR, `Closes #N` e checklist marcado.
11. `gh pr merge --squash --delete-branch --subject "<tipo>(<escopo>): <título> (#N)"` (em `confirm`, pergunte antes).
12. `git checkout develop && git pull --ff-only`, promova screenshots a baseline, `bash .claude/scripts/dev-up.sh --restart`.
    Confirme fechamento da issue, `metrics.sh log feature ...`, `notify.sh`, atualize sua memória e entregue o **Relatório de entrega**
    (formato no seu prompt, com URL, passos de teste e status do .env). É a única mensagem que o usuário recebe num pipeline sem bloqueios.
