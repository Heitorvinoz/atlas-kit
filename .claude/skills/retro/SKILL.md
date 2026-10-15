---
name: retro
description: Retrospectiva após uma release (ou quando pedido). Analisa métricas, ciclos de review, bloqueios e achados de segurança, escreve docs/retros/<versão>.md e propõe melhorias nos próprios prompts e config do Atlas via PR (que nunca é mergeada sozinha).
disable-model-invocation: true
arguments: [version]
---

Versão: `$version` (vazio = última tag).

1. **Dados**: `bash .claude/scripts/metrics.sh report 20`; issues fechadas desde a release anterior
   (`gh issue list --state closed --search "closed:>=<data>"`); PRs e número de ciclos de review nos comentários;
   relatórios de `security` (achados por categoria) e de `qa` (falhas recorrentes, testes frágeis); memórias dos agentes
   em `.claude/agent-memory/*/MEMORY.md` (procure "armadilha", "recorrente", "falhou").
2. **Análise** — responda com evidência:
   - O que mais custou tempo? (ondas lentas, retrabalho, agente que mais devolveu)
   - O que o gate pegou que deveria ter sido pego antes? (→ mover regra para o agente certo)
   - Que decisões (ADRs) se provaram boas/ruins? Alguma precisa de revisão?
   - Que pergunta o Atlas fez ao usuário que poderia ter decidido sozinho — ou o contrário?
   - Débitos abertos: issues `chore` acumuladas, SKIPPEDs repetidos, cobertura caindo.
   - `docs/IDEAS.md` + claude-mem: ideias estacionadas há muito tempo — propor virar issue ou descartar com motivo.
3. **Escreva `docs/retros/<versão>.md`**: 5 linhas de resumo, tabela de métricas, "3 coisas que funcionaram", "3 para mudar",
   ações com dono (agente ou usuário) e issue criada para cada ação.
4. **Melhore o Atlas**: para cada ação que seja ajuste de prompt/config, edite `.claude/agents/*.md`, `.claude/skills/*`,
   `CLAUDE.md` ou `atlas.config.json` em branch `chore/<n>-retro-<versão>`, commit `chore(atlas): retro <versão>`,
   PR para `develop` com o diff explicado linha a linha. **Nunca mergeie esta PR sozinho**, mesmo em modo `full`:
   mudanças nas suas próprias regras exigem olhos humanos. Diga isso no relatório.
5. Atualize sua memória com os padrões identificados. `bash .claude/scripts/notify.sh "Atlas: retro <versão>" "<1 linha>"`.

Relatório ao usuário: resumo, link da retro, link da PR de melhorias, issues abertas.
