---
name: design
description: Fluxo de design. "/design import" aplica um design feito ANTES do código (bundle em design/handoffs/initial/); "/design brief N" gera um brief para o Claude Design; "/design apply N" aplica o handoff bundle salvo em design/handoffs/N/ ao frontend; "/design system" (re)constrói o design system a partir do código; "/design spec N" só a spec + wireframe.
arguments: [action, issue]
---

Ação: `$action` · Issue: `$issue`

- **brief**: delegue ao `designer` a tarefa `brief` para a issue. Entregue ao usuário o caminho do brief e as instruções:
  1) abra claude.ai/design, 2) se for a primeira vez, aponte o Claude Design para este repositório para ele montar o
  design system a partir do código (ou cole `design/DESIGN_SYSTEM.md`), 3) cole o brief, itere, 4) exporte o handoff
  bundle para Claude Code e salve em `design/handoffs/<issue>/`, 5) diga "/design apply <issue>" ou só "aplica o design".
- **import** (ou `apply` sem issue / `apply initial`): o usuário fez o design ANTES de existir código, no Claude Design, e salvou o
  handoff bundle em `design/handoffs/initial/`. Fluxo:
  1. `designer` (tarefa `apply-handoff`, escopo inicial): extrai de todo o bundle o **design system** (`design/DESIGN_SYSTEM.md`:
     cores, tipografia, espaçamento, componentes recorrentes) e um **inventário de telas** em `design/specs/initial-screens.md`:
     para cada tela, nome, propósito, elementos, estados, dados que precisa e para onde navega.
  2. Você (Atlas) transforma o inventário em um **roadmap de features**: agrupe telas em features pequenas e ordenadas por dependência
     (ex.: 1 autenticação, 2 cadastro de X, 3 listagem de X, 4 dashboard). Cada uma vira uma issue com `gh issue create` referenciando as
     telas do bundle. Registre em `docs/IDEAS.md` o que ficou para depois. Confirme a ordem com o usuário em UMA mensagem.
  3. Comece a primeira feature pelo `/feature`. Em cada feature seguinte, o `frontend` usa as telas de `design/handoffs/initial/`
     como referência obrigatória (o `designer` só adapta, não reinventa).
  Se `atlas.config.json` ainda não tem stack (`/atlas-init` não rodou), peça para rodar `/atlas-init` primeiro: o design não define a stack.
- **apply**: confira que `design/handoffs/<issue>/` existe (senão peça o bundle). Branch: se a issue ainda está aberta,
  use a branch dela; se já foi mergeada, abra issue `chore(ui): apply design handoff for #<issue>` e branch nova.
  Delegue ao `designer` (`apply-handoff`) → ao `frontend` (implementar exatamente o diff listado, tokens primeiro) →
  `qa` + `reviewer` em paralelo → `docs` (atualiza DESIGN_SYSTEM.md se mudou) → PR → merge (conforme `autonomy.mode`) →
  `dev-up.sh --restart` → relatório de entrega com a URL.
- **system**: delegue ao `designer` a tarefa `system`. Se houver frontend, extraia do código; senão proponha. Commit em
  branch `chore/<n>-design-system` via issue, PR, merge. Depois diga ao usuário que o Claude Design pode importar o repo.
- **spec**: delegue ao `designer` a tarefa `spec` para a issue e mostre os caminhos da spec e do mockup
  (abra o mockup: é um HTML, `file://<caminho>`).
