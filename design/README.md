# design/

| Pasta / arquivo | O que é | Quem escreve |
|---|---|---|
| `DESIGN_SYSTEM.md` | tokens, componentes, princípios — fonte de verdade visual | `designer` |
| `specs/<issue>-<slug>.md` | spec de UI de cada feature (fluxo, telas, estados, copy, critérios) | `designer` |
| `mockups/<issue>-<slug>.html` | wireframe navegável, abre no browser | `designer` |
| `briefs/<issue>-<slug>.md` | brief pronto para colar no Claude Design | `designer` |
| `handoffs/<issue>/` | handoff bundle exportado do Claude Design para o Claude Code | você |

Fluxo com Claude Design: `/feature` gera spec + mockup + brief sem te interromper → você refina no Claude Design
quando quiser → exporta o bundle em `handoffs/<issue>/` → `/design apply <issue>` → o frontend ajusta → localhost.
