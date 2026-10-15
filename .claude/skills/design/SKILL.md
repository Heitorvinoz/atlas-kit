---
name: design
description: Fluxo de design. "/design brief N" gera um brief para o Claude Design; "/design apply N" aplica o handoff bundle salvo em design/handoffs/N/ ao frontend; "/design system" (re)constrói o design system a partir do código; "/design spec N" só a spec + wireframe.
arguments: [action, issue]
---

Ação: `$action` · Issue: `$issue`

- **brief**: delegue ao `designer` a tarefa `brief` para a issue. Entregue ao usuário o caminho do brief e as instruções:
  1) abra claude.ai/design, 2) se for a primeira vez, aponte o Claude Design para este repositório para ele montar o
  design system a partir do código (ou cole `design/DESIGN_SYSTEM.md`), 3) cole o brief, itere, 4) exporte o handoff
  bundle para Claude Code e salve em `design/handoffs/<issue>/`, 5) diga "/design apply <issue>" ou só "aplica o design".
- **apply**: confira que `design/handoffs/<issue>/` existe (senão peça o bundle). Branch: se a issue ainda está aberta,
  use a branch dela; se já foi mergeada, abra issue `chore(ui): apply design handoff for #<issue>` e branch nova.
  Delegue ao `designer` (`apply-handoff`) → ao `frontend` (implementar exatamente o diff listado, tokens primeiro) →
  `qa` + `reviewer` em paralelo → `docs` (atualiza DESIGN_SYSTEM.md se mudou) → PR → merge (conforme `autonomy.mode`) →
  `dev-up.sh --restart` → relatório de entrega com a URL.
- **system**: delegue ao `designer` a tarefa `system`. Se houver frontend, extraia do código; senão proponha. Commit em
  branch `chore/<n>-design-system` via issue, PR, merge. Depois diga ao usuário que o Claude Design pode importar o repo.
- **spec**: delegue ao `designer` a tarefa `spec` para a issue e mostre os caminhos da spec e do mockup
  (abra o mockup: é um HTML, `file://<caminho>`).
