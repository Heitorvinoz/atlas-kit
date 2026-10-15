# Atlas — orquestrador de desenvolvimento para Claude Code

Atlas transforma uma sessão do Claude Code em uma equipe de engenharia organizada. Você conversa com o **Atlas**;
ele vira seu pedido em issue no GitHub, escreve o contrato (dados, API, telas), dispara agentes especialistas em
paralelo, cobra testes, revisão, segurança e documentação, mergeia em `develop`, sobe o resultado no localhost e
volta com um relatório de entrega. Quando você pede, promove `develop` para `main` como release versionada depois
de um gate completo. Funciona com qualquer stack.

```
você ──"quero X"──▶ Atlas ──issue + contrato──▶ GitHub
                      │
   onda 1 (paralelo)  ├─▶ database · backend · frontend · designer · security (threat model)
   onda 2 (paralelo)  ├─▶ qa (testes, navega no localhost, screenshots, a11y/perf) · reviewer · security (audit)
   onda 3 (paralelo)  ├─▶ correções · docs (README, arquitetura, changelog, ADRs, OpenAPI) · deploy (preview)
                      └─▶ PR → merge em develop → localhost atualizado → notificação → relatório de entrega
                                                  └──/release──▶ gate completo → main + tag + GitHub Release → staging
```

**Índice**
1. [Pré-requisitos](#1-pré-requisitos)
2. [Instalação](#2-instalação)
3. [Primeiro uso: `/atlas-init`](#3-primeiro-uso-atlas-init)
4. [Dia a dia: pedindo features](#4-dia-a-dia-pedindo-features)
5. [Todos os comandos](#5-todos-os-comandos)
6. [Os agentes](#6-os-agentes)
7. [`atlas.config.json`, campo a campo](#7-atlasconfigjson-campo-a-campo)
8. [Modo de autonomia: quando ele te interrompe](#8-modo-de-autonomia-quando-ele-te-interrompe)
9. [Git: branches, commits, PRs, releases](#9-git-branches-commits-prs-releases)
10. [Localhost, `.env` e segredos](#10-localhost-env-e-segredos)
11. [Design com o Claude Design](#11-design-com-o-claude-design)
12. [Notificações](#12-notificações)
13. [Deploy](#13-deploy)
14. [Métricas, retro e manutenção](#14-métricas-retro-e-manutenção)
15. [Hooks e permissões: o que é bloqueado](#15-hooks-e-permissões-o-que-é-bloqueado)
16. [Estrutura do repositório](#16-estrutura-do-repositório)
17. [Personalização](#17-personalização)
18. [Problemas comuns](#18-problemas-comuns)

---

## 1. Pré-requisitos

| Ferramenta | Para quê | Obrigatório |
|---|---|---|
| [Claude Code](https://code.claude.com/docs) | roda o Atlas | sim |
| `git` | fluxo de branches | sim |
| `gh` ([GitHub CLI](https://cli.github.com)) autenticado (`gh auth login`) | issues, PRs, releases | sim |
| `jq` | hooks e scripts leem `atlas.config.json` | sim (alguns scripts têm fallback em Python) |
| `python3` | scripts de métricas/notificação | sim (vem no macOS/Linux; no Windows instale) |
| `curl` | checagem de saúde do localhost, notificações | sim |
| Node (`npx`) + Chrome | QA visual: Playwright, axe, Lighthouse | não — sem eles o `qa` marca essas etapas como SKIPPED |
| `gitleaks`, `semgrep` | scan de segredos e SAST no gate de release | não — sem eles o release marca SKIPPED e pergunta se pode seguir |

Instalação rápida das opcionais:
```bash
# macOS
brew install gh jq gitleaks semgrep node
# Ubuntu/Debian
sudo apt install gh jq nodejs npm && pip install semgrep   # gitleaks: https://github.com/gitleaks/gitleaks/releases
```
**Windows**: use WSL ou Git Bash — os hooks e scripts são `bash`.

## 2. Instalação

### Opção A — usar como template no GitHub (recomendado para projeto novo)
1. Publique este kit uma vez no seu GitHub como template:
   ```bash
   ./publish.sh atlas-kit            # cria o repo, faz push e marca como template (use --private se quiser)
   ```
2. Para cada projeto novo:
   ```bash
   gh repo create meu-projeto --template SEU_USUARIO/atlas-kit --private --clone
   cd meu-projeto
   claude                            # .claude/settings.json já sobe o Atlas como agente principal
   /atlas-init
   ```
   (ou pelo site: botão **Use this template** no repositório.)

### Opção B — repositório existente
```bash
./install.sh /caminho/do/seu/projeto   # copia .claude/, docs, design, templates; não sobrescreve nada que já exista
cd /caminho/do/seu/projeto && claude
/atlas-init
```
Se o projeto ainda não está no GitHub: `gh repo create --source=. --private --push` antes do `/atlas-init`.

## 3. Primeiro uso: `/atlas-init`

Rode uma vez por projeto. Ele:
1. **Detecta a stack** (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `Gemfile`, `composer.json`, `*.csproj`…). Repo vazio → pergunta qual stack você quer, com opções.
2. **Preenche `atlas.config.json`** com comandos reais de install, lint, format, typecheck, test, cobertura, build, migrations, seed, segurança — verificados, não chutados. O que não existe fica `null` (= etapa pulada e reportada).
3. **Configura o localhost** (`dev.command`, `dev.url`, `dev.health_path`, `docker compose` se houver) e testa com `dev-up.sh`.
4. **Design**: se há frontend, o `designer` extrai o design system do código para `design/DESIGN_SYSTEM.md`. Pergunta se você vai usar o Claude Design.
5. **Notificação**: pergunta o canal (desktop não precisa de nada).
6. **Git/GitHub**: cria `develop`, `.gitignore`, labels (`type:*`, `area:*`, `security`, `hotfix`), sugere proteger `main`/`develop`.
7. **Docs iniciais**: README do projeto (este guia vai para `docs/ATLAS.md`), `docs/adr/0001-adopt-atlas-workflow.md`, `ARCHITECTURE.md`, `.env.example`.
8. Commit `chore: bootstrap Atlas workflow` e relatório: o que configurou, o que ficou `null`, ferramentas faltando.

Depois dele, **reinicie o Claude Code** (os agentes novos carregam no início da sessão) e o Atlas está pronto.

## 4. Dia a dia: pedindo features

Fale normalmente. Não precisa de slash command; o Atlas identifica o modo pela conversa.

| Você diz | O que acontece |
|---|---|
| "quero que o usuário consiga exportar o relatório em PDF" | pipeline de feature completo (abaixo) |
| "tem um bug: o total do carrinho dobra quando removo um item" | pipeline em modo `fix/`, exige teste de regressão que falha antes e passa depois |
| "sobe pra main" / "fecha a versão" / "lança" | `/release` |
| "como funciona o login?" | `/explain` → resposta com arquivos e linhas |
| "onde estamos?" | `/status` |

### O que o Atlas faz com um pedido
1. Reescreve o pedido com critérios de aceite, fora do escopo e premissas → **issue no GitHub**.
2. Escreve o **contrato**: schema, rotas/payloads/erros, telas. É o que permite paralelizar.
3. Branch `feat/<issue>-<slug>` a partir de `develop`.
4. **Onda 1** (ao mesmo tempo, cada um no próprio worktree): `database` (migration + seed), `backend` (contra o contrato de dados), `frontend` (contra o contrato de API, com mock até o backend terminar), `designer` (spec + wireframe), `security` (threat model, se há superfície de ataque). Merge das sub-branches, suíte roda.
5. **Onda 2**: `qa` (suíte, testes faltantes, navega no localhost, screenshots, a11y/perf, regressão visual) + `reviewer` + `security` (audit do diff, confere o threat model). Problemas voltam ao implementador, até `quality.max_review_cycles`.
6. **Onda 3**: correções + `docs` (README, ARCHITECTURE, CHANGELOG, `.env.example`, ADRs, OpenAPI, links) + `deploy` (preview, se configurado).
7. Gate curto (lint, typecheck, test) → PR com `Closes #N` → **merge em `develop`** (squash) → `develop` atualizada → screenshots viram baseline → **localhost reiniciado** → métricas → notificação → relatório.

### O relatório de entrega (única mensagem que você recebe se nada bloquear)
```
✅ #42 Exportar relatório em PDF — mergeado em develop (PR #43)
🌐 Teste em: http://localhost:3000/reports   (log: .atlas/dev.log)
🔑 Ambiente: preencha no .env: PDF_SERVICE_KEY
🔗 Preview: https://meu-projeto-git-feat-42.vercel.app
📸 Screenshots: design/screenshots/42/ (/reports, /reports/42, desktop + mobile)
O que foi feito: botão "Exportar PDF" na tela de relatório; geração no servidor com fila; download com nome do período.
Como testar: 1) abra /reports 2) escolha um período 3) clique "Exportar PDF" 4) confira o arquivo baixado.
Premissas que assumi: PDF em A4 retrato; relatórios de até 500 linhas síncronos, acima disso por e-mail (fora do escopo).
Decisões registradas: ADR-0007 Usar <lib> para PDF — mantida no servidor por fidelidade de layout.
Qualidade: 128/128 testes · cobertura 84% · review approve · security PASS · a11y/perf ok · regressão visual nenhuma
🛡️ Threat model: docs/security/threat-models/42-pdf-export.md — 4/4 mitigações implementadas (inclui IDOR em /reports/:id)
Docs atualizadas: README (seção Relatórios), docs/api/openapi.yaml, CHANGELOG [Unreleased]
🎨 Design: spec e mockup em design/specs|mockups/42-*; brief para Claude Design em design/briefs/42-pdf-export.md
Paralelismo: onda 1: 5 agentes · onda 2: 3 · ~22 min
Ficou de fora / próximos passos: envio por e-mail para relatórios grandes (#44 sugerida)
Para reverter: git revert a1b2c3d em develop
```
Se algo bloqueou, o relatório vira `⛔ #42 bloqueado em <etapa>` com o achado exato e o que ele precisa de você.

## 5. Todos os comandos

| Comando | Quando usar | O que faz | Precisa de |
|---|---|---|---|
| `/atlas-init` | uma vez por projeto | detecta stack, preenche config, cria develop/labels/docs | gh autenticado |
| `/feature <pedido>` | algo novo, mudança ou bug (ou só fale) | pipeline completo até merge em develop + localhost | config preenchido |
| `/status` | "onde estamos?" | branch, issues, PRs, última release, Unreleased, ADRs recentes, métricas | — |
| `/adr <tema>` | decisão não óbvia | registra em `docs/adr/NNNN-*.md` com contexto, opções, decisão, consequências | — |
| `/design spec N` | ver a spec/mockup de uma feature | `designer` escreve spec + wireframe HTML | — |
| `/design brief N` | vai polir no Claude Design | gera brief pronto para colar em `design/briefs/` | — |
| `/design apply N` | salvou o handoff bundle em `design/handoffs/N/` | converte em spec, frontend aplica, qa/review, merge, localhost | bundle salvo |
| `/design system` | (re)extrair o design system do código | atualiza `design/DESIGN_SYSTEM.md` | frontend existente |
| `/release [major\|minor\|patch]` | "sobe pra main" | gate completo → `release/vX.Y.Z` → PR em main → tag → GitHub Release → back-merge → staging | develop limpa |
| `/hotfix <problema>` | urgência em produção | branch de `main`, correção mínima, gate reduzido com segurança, tag patch, back-merge | — |
| `/deploy setup` | antes do primeiro deploy | escolhe provedor (ADR), preenche `deploy.*`, te dá os comandos de login e segredos | CLI do provedor |
| `/deploy preview` | ver a branch publicada | publica a branch atual, URL na PR | setup feito |
| `/deploy staging` / `prod` | publicar a última release | deploy + saúde + smoke test + rollback automático se falhar | setup; prod só com seu pedido |
| `/deploy rollback` | voltar a versão anterior | roda `deploy.commands.rollback` | — |
| `/explain <pergunta>` | entender o que foi construído | `scout` responde com arquivo:linha, ADRs, divergências código×docs | — |
| `/retro [versão]` | depois de um release | análise de métricas/bloqueios, `docs/retros/`, issues, PR de melhoria nas regras (nunca mergeada sozinha) | — |
| `/maintain` | semanalmente | dependências, auditoria, código morto, testes frágeis, docs; PR do seguro, issues do resto | — |

Os comandos sensíveis (`/release`, `/hotfix`, `/deploy`, `/retro`, `/maintain`, `/atlas-init`) só rodam quando **você** os invoca; o Atlas não os dispara sozinho.

## 6. Os agentes

Todos em `.claude/agents/`. Cada um tem ferramentas restritas ao papel, relatório em formato fixo que o Atlas valida, e memória persistente em `.claude/agent-memory/<nome>/` (versionada, para aprenderem o projeto entre sessões).

| Agente | Papel | Pode editar código? | Quando entra |
|---|---|---|---|
| `atlas` | orquestrador; conversa, issue, contrato, ondas, merge, relatório | não | sempre (agente principal) |
| `database` | schema, migrations reversíveis, índices, **seeds de demonstração** | sim (`paths.database`) | onda 1 |
| `backend` | APIs, regras de negócio, integrações; contrato primeiro | sim (`paths.backend`) | onda 1 |
| `frontend` | telas, estado, integração; segue spec do designer e design system (preloaded) | sim (`paths.frontend`) | onda 1 |
| `designer` | spec de UI, wireframe HTML, design system, briefs e handoffs do Claude Design | não (só `design/`) | onda 1, `/design` |
| `security` | threat model (STRIDE) antes; audit (scanners + OWASP) depois; veredito PASS/BLOCK | não | onda 1 e 2, release |
| `qa` | suíte, testes faltantes, cobertura, navegação no localhost (Playwright), screenshots, a11y/perf, regressão visual | só testes | onda 2, release |
| `reviewer` | code review do diff contra develop | não | onda 2 |
| `docs` | README, ARCHITECTURE, CHANGELOG, ADRs, `.env.example`, OpenAPI, links — **verificados** | só docs | onda 3, release |
| `deploy` | preview por PR, staging, prod, saúde, smoke, rollback | não | onda 3, `/deploy`, release |
| `scout` | leitura rápida do repo para `/explain` e pesquisa do Atlas | não | `/explain` |

Chame um diretamente quando quiser: `@designer` ou "use o scout para…".

## 7. `atlas.config.json`, campo a campo

É a fonte de verdade: nenhum agente inventa comando, todos leem daqui. `null` = etapa pulada e reportada como SKIPPED.

```jsonc
{
  "project":   { "name": "", "description": "" },
  "stack":     { "backend": null, "frontend": null, "database": null, "package_manager": null },
  "paths":     { "backend": [], "frontend": [], "database": [], "shared": [], "docs": [...] },   // escopo de cada agente
  "branches":  { "main": "main", "develop": "develop" },
  "commands": {
    "install", "dev", "build", "lint", "format", "format_file" /* {file} */, "typecheck",
    "test", "test_coverage", "e2e", "migrate", "migrate_check", "seed", "load_test",
    "api_spec", "api_spec_check", "db_backup",
    "security": { "deps_audit", "sast", "secrets" }
  },
  "quality": {
    "coverage_min": 70, "max_review_cycles": 3, "visual_regression": true,
    "budgets": { "lighthouse_perf_min": 70, "lighthouse_a11y_min": 90, "lighthouse_best_practices_min": 80, "api_p95_ms": 300 }
  },
  "release":   { "tag_prefix": "v", "changelog": "CHANGELOG.md", "version_files": [] },
  "autonomy":  { "mode": "full" | "confirm", "always_ask_when": [...] },
  "dev":       { "command", "url", "health_path", "services_up", "ready_timeout_s", "seed_on_start" },
  "design":    { "mode": "claude-design" | "spec", "system_file", "tokens_in_code": [] },
  "parallelism": { "max_parallel": 4, "contract_first": true },
  "deploy":    { "provider", "preview_per_pr", "auto_prod_after_release", "run_migrations", "commands": {...}, "url": {...}, "health_path", "required_env": [] },
  "notify":    { "channels": ["desktop"], "on": ["delivery","release","blocked","needs_input"] },
  "metrics":   { "enabled": true, "file": ".atlas/metrics.jsonl" }
}
```
Presets de comandos por stack (Node, Python, Go, Rust, Java, Rails, Laravel, .NET) em `.claude/skills/atlas-init/presets.md`.

## 8. Modo de autonomia: quando ele te interrompe

`autonomy.mode`:
- **`full`** (padrão): executa tudo e volta só com o relatório. Interrompe apenas em: ambiguidade que muda o resultado;
  decisão que mexe com **dinheiro, autenticação, exclusão de dados ou custo recorrente**; `security BLOCK` não resolvido
  após os ciclos de review; release com etapa SKIPPED por ferramenta ausente.
- **`confirm`**: confirma o entendimento antes de começar e pede OK antes de cada merge.

Independente do modo, **nunca sozinho**: deploy de produção; merge de PR que altera `.claude/`, `CLAUDE.md` ou
`atlas.config.json` (as regras do próprio Atlas, incluindo as PRs da `/retro`).

Controle depois do fato: toda decisão está numa issue, num ADR ou numa PR, e o relatório traz o `git revert` pronto.

## 9. Git: branches, commits, PRs, releases

| Branch | De | Para | Quem |
|---|---|---|---|
| `main` | — | produção; só recebe `release/*` e `hotfix/*` | `/release`, `/hotfix` |
| `develop` | `main` | integração; recebe `feat/*`, `fix/*`, `chore/*`, `refactor/*` por PR (squash) | `/feature` |
| `feat/<issue>-<slug>` | `develop` | `develop` | `/feature` |
| `hotfix/<issue>-<slug>` | `main` | `main` + back-merge | `/hotfix` |
| `release/vX.Y.Z` | `develop` | `main` (merge commit) + tag + back-merge | `/release` |

Commits em [Conventional Commits](https://www.conventionalcommits.org/) com scope de área e footer `Refs #N`
(`feat(api): add order checkout`). Versionamento SemVer: `Added` → minor, só `Fixed` → patch, `!` → major.
PR título = commit do squash; uma PR = uma issue. Detalhes em `docs/CONVENTIONS.md`.

### O gate de release (`/release`)
Tudo abaixo, ou não sai: install limpo · lint · format · typecheck · suíte · cobertura ≥ mínimo · e2e · build ·
migrate_check · a11y/perf nas rotas principais · regressão visual · load test (se houver) · `deps_audit` ·
SAST (semgrep) · segredos (gitleaks) · revisão OWASP do repositório inteiro pelo `security` · `.env` fora do git ·
`.env.example` completo. Depois: CHANGELOG fechado, bump de versão, PR em `main`, tag, GitHub Release com notas em
linguagem de usuário, back-merge em `develop`, localhost no checkout de `main`, staging se configurado.

## 10. Localhost, `.env` e segredos

Ao fim de toda feature (e release), `.claude/scripts/dev-up.sh --restart`:
1. `env-check.sh --sync`: cria `.env` a partir do `.env.example` se não existir; acrescenta chaves novas com o valor de exemplo; avisa quais ainda estão com placeholder (`changeme`, `your-…`); avisa chaves no `.env` que não estão documentadas.
2. `dev.services_up` (ex.: `docker compose up -d`), `commands.migrate`, `commands.seed` (se `dev.seed_on_start`).
3. Inicia `dev.command` em background (log em `.atlas/dev.log`, pid em `.atlas/dev.pid`) e espera `dev.url + health_path` responder.

Regras: **ninguém lê o `.env`** (está em `permissions.deny`); só o script compara chaves. Toda variável nova vai no
`.env.example` com comentário. Segredos de notificação ficam em `~/.atlas/notify.env`, fora do repo. Segredos de
deploy você seta no provedor com o comando que o `deploy` te dá.

## 11. Design com o Claude Design

Toda feature com UI passa pelo `designer` antes do `frontend`: spec (fluxo, telas, estados, copy, critérios de UI) em
`design/specs/`, wireframe navegável em `design/mockups/<issue>-*.html` (abra no browser), seguindo
`design/DESIGN_SYSTEM.md`, que o `frontend` recebe preloaded. Nada disso interrompe o pipeline.

Para polir no [Claude Design](https://claude.com/product/design):
1. **Uma vez**: no onboarding do Claude Design, aponte para o repositório (ou cole `design/DESIGN_SYSTEM.md`). Ele monta o
   design system do time a partir do código — o mesmo que o `frontend` usa. Um sistema só, dos dois lados.
2. **A cada tela nova**: o relatório de entrega aponta o brief em `design/briefs/<issue>-*.md` (produto, job, telas,
   estados, conteúdo real, tokens, o que não mudar). Cole no Claude Design e refine (comentários inline, sliders).
3. Exporte o **handoff bundle para Claude Code** e salve em `design/handoffs/<issue>/`.
4. `/design apply <issue>` (ou "aplica o design"): o `designer` converte o bundle em diff de spec, o `frontend` aplica,
   `qa` + `reviewer` validam, `docs` atualiza o design system se surgiu token/componente, merge, localhost.

**Design primeiro, código depois**: dá para desenhar o app inteiro no Claude Design antes de existir qualquer código. Exporte o
handoff bundle para `design/handoffs/initial/`, rode `/atlas-init` (o design não define a stack) e depois `/design import`:
o `designer` extrai o design system e um inventário de telas, e o Atlas transforma as telas em um roadmap de issues pequenas,
ordenadas, e começa pela primeira. Cada feature seguinte usa as telas do bundle como referência obrigatória.

Não vai usar o Claude Design? `design.mode: "spec"` pula o brief.

## 12. Notificações

`notify.channels` em `atlas.config.json`; o Atlas avisa nos eventos de `notify.on` (entrega, release, bloqueio, precisa de você)
e o hook `Notification` do Claude Code avisa quando ele está parado esperando sua resposta.

| Canal | Configuração |
|---|---|
| `desktop` | nada (macOS `osascript`, Linux `notify-send`, Windows PowerShell) |
| `ntfy` | instale o app [ntfy](https://ntfy.sh) no celular, escolha um tópico, e em `~/.atlas/notify.env`: `NTFY_TOPIC=meu-topico-secreto` |
| `telegram` | crie um bot no @BotFather; `~/.atlas/notify.env`: `TELEGRAM_BOT_TOKEN=...` e `TELEGRAM_CHAT_ID=...` |
| `slack` | webhook de entrada; `~/.atlas/notify.env`: `SLACK_WEBHOOK_URL=...` |

Teste: `bash .claude/scripts/notify.sh "Atlas" "funcionando"`.

## 13. Deploy

1. `/deploy setup`: o `deploy` propõe 3 provedores para a sua stack; o Atlas registra a escolha em ADR (pergunta se houver
   custo mensal), preenche `deploy.*` e te dá os comandos de login (`vercel login`, `railway login`, `fly auth login`…) e de
   segredos (`vercel env add NOME`, …) — ele nunca define segredos.
2. A partir daí: **preview por PR** automático (URL no comentário da PR e no relatório), `/release` publica em **staging**,
   **produção** só com `/deploy prod` ou `deploy.auto_prod_after_release: true`. Saúde e smoke test após cada deploy;
   rollback automático se a saúde falhar; `deploy.run_migrations` controla migrations em prod (exige `commands.db_backup`).

## 14. Métricas, retro e manutenção

- **Métricas**: hooks gravam cada subagente em `.atlas/metrics.jsonl`; o Atlas grava cada entrega/release/deploy.
  `bash .claude/scripts/metrics.sh report` (ou `/status`): tempo médio por entrega, ciclos de review, agentes mais usados.
  Custo em tokens: `/cost` do Claude Code na sessão.
- **`/retro vX.Y.Z`**: lê métricas, issues, PRs, achados de segurança e as memórias dos agentes; escreve `docs/retros/vX.Y.Z.md`
  ("3 que funcionaram, 3 para mudar", ações com dono e issue); abre PR com mudanças nos próprios prompts/config, explicada
  linha a linha, **para você aprovar**.
- **`/maintain`**: atualiza dependências minor/patch com a suíte verde, auditoria, código morto, testes frágeis (roda a suíte 3x),
  docs vivas; PR do que é seguro, issues `chore` priorizadas do resto.

## 14b. Memória: por que você nunca precisa "apagar" o Atlas
O contexto de uma sessão enche e o Claude Code compacta (ou você abre outra sessão). O Atlas é desenhado para isso não custar nada:
- **Memória por agente** (`.claude/agent-memory/<nome>/MEMORY.md`, versionada): o que vale entre features — estrutura, convenções, armadilhas.
- **Estado do trabalho** (`.atlas/STATE.md`): a cada etapa do pipeline o Atlas grava onde está. O hook `PreCompact` o obriga a salvar
  antes de compactar; o hook `SessionStart` injeta o estado e o último relatório ao abrir/retomar/compactar. Ele retoma de onde parou.
- **Tudo o mais está no repositório**: issues, PRs, ADRs, CHANGELOG, threat models, retros, métricas. A conversa é descartável.
- **Memória de conversa** (`claude-mem`, ligada por padrão; `/atlas-init` instala): grava o teor das sessões e o Atlas consulta ao abrir
  a sessão, quando você cita algo antigo, ao iniciar uma feature e na retro. Feita para quem **pensa com o Atlas**: ideias meio prontas,
  preferências, rejeições ("não quero modo escuro") voltam quando importam.
- **Ideias estacionadas** (`docs/IDEAS.md`, versionado): tudo que você mencionou e não virou issue, com status (estacionada / descartada
  com motivo / virou #N). Mesmo se o claude-mem cair, as ideias ficam. `/status` mostra as recentes; `/retro` cobra as antigas.
Papéis: claude-mem = o que foi dito · IDEAS.md = o que foi estacionado · MEMORY.md = como o projeto funciona · STATE.md = onde o trabalho
parou · ADRs = o que foi decidido. Em conflito, código e ADRs mandam. Para desligar o claude-mem: `memory.conversational: null`.
Dicas: `claude --continue` retoma a última sessão; `/compact` compacta na hora que você escolher (ex.: entre features);
`/rewind` volta a um ponto anterior.

## 15. Hooks e permissões: o que é bloqueado

`.claude/settings.json` define `defaultMode: acceptEdits`, uma lista de comandos liberados (git, gh, gerenciadores de pacote,
scanners, CLIs de deploy) e `deny` para force push, push em `main`/`develop` e leitura de `.env`/chaves.

`.claude/hooks/guard-git.sh` (roda antes de todo comando) bloqueia e explica ao agente:
- commit ou push direto em `main`/`develop` (merges só por `gh pr merge`); de `main`/`develop` só sobem tags;
- `git push --force` em qualquer branch; `--no-verify`;
- branch fora do padrão `<tipo>/<issue>-<slug>`;
- mensagem fora do Conventional Commits ou vaga (`wip`, `update`, `fix stuff`);
- `git add .env`, `.env.local`, `id_rsa`, `*.pem`, `credentials.json`.
Única válvula: `ATLAS_ALLOW_PROTECTED=1` no commit de bootstrap do `/atlas-init`.

`post-edit.sh` formata cada arquivo editado com `commands.format_file`. `SubagentStart/Stop` → métricas. `Notification` → aviso.

Se ainda aparecer prompt de permissão para algum comando da sua stack: adicione em `permissions.allow`, ou rode
`claude --permission-mode bypassPermissions` (os hooks continuam valendo). Proteja também o remoto: GitHub → Settings →
Branches → require PR em `main` e `develop`.

## 16. Estrutura do repositório

```
.claude/
  settings.json            agente padrão = atlas, permissões, hooks
  agents/                  atlas, database, backend, frontend, designer, security, qa, reviewer, docs, deploy, scout
  skills/                  atlas-init, feature, release, hotfix, adr, status, design, deploy, explain, retro, maintain, design-system
  hooks/                   guard-git.sh, post-edit.sh
  scripts/                 dev-up.sh, env-check.sh, screenshot.sh, audit-web.sh, metrics.sh, notify.sh, session-state.sh
  agent-memory/            memória de cada agente (versionada)
CLAUDE.md                  regras lidas por todos os agentes
atlas.config.json          fonte de verdade de comandos e comportamento
design/                    DESIGN_SYSTEM.md, specs/, mockups/, briefs/, handoffs/, screenshots/ (+ baseline/)
docs/
  CONVENTIONS.md           branches, commits, PRs, versionamento
  ARCHITECTURE.md          mapa do sistema (mantido pelo docs)
  adr/                     decisões (template + índice)
  IDEAS.md                 ideias estacionadas (o que você falou e ainda não pediu)
  api/                     OpenAPI
  security/threat-models/  STRIDE por feature
  retros/                  retrospectivas
CHANGELOG.md               Keep a Changelog
.github/                   templates de issue e PR
.env.example               documentação das variáveis
.atlas/                    (ignorado) dev.log, dev.pid, metrics.jsonl, audit/
install.sh · publish.sh    só do kit; /atlas-init remove do projeto
```

## 17. Personalização

- **Custo**: `model: sonnet` em `backend/frontend/database/docs`, `haiku` em `reviewer/scout`. `scout` já usa Sonnet.
  `effort: low|medium|high` por agente também funciona.
- **Rigor**: `quality.coverage_min`, `max_review_cycles`, `budgets`, `visual_regression`.
- **Paralelismo**: `parallelism.max_parallel` (quantos implementadores ao mesmo tempo).
- **Monorepo**: `paths.*` com os diretórios de cada área; cada agente só edita o próprio escopo.
- **Mais controle**: `autonomy.mode: "confirm"`.
- **Prompts**: edite `.claude/agents/*.md` e `.claude/skills/*/SKILL.md` — o Claude Code recarrega sem reiniciar
  (exceto diretório `agents/` novo). Ou deixe a `/retro` propor.
- **Caminhos sensíveis, feature flags, `/undo`, `/roadmap`, `/incident`**: não vêm no kit; peça ao Atlas para criá-los
  seguindo o padrão dos existentes.

## 18. Problemas comuns

| Sintoma | Causa / solução |
|---|---|
| "agent atlas not found" ou agentes não aparecem | reinicie o Claude Code após `/atlas-init` ou após criar `.claude/agents/` |
| `ATLAS BLOCK: …` no meio de um comando | o hook impediu algo fora do fluxo; a mensagem diz o quê. Não contorne: ajuste a branch/mensagem |
| `DEV: dev.command não configurado` | preencha `dev.command` e `dev.url` em `atlas.config.json` |
| `DEV: não respondeu em 90s` | veja `.atlas/dev.log`; ajuste `dev.health_path` para uma rota que responde 200 rápido ou aumente `ready_timeout_s` |
| Etapas `SKIPPED` no release | ferramenta ausente (gitleaks, semgrep, Chrome, Node). Instale ou aceite o risco quando ele perguntar |
| Muitos prompts de permissão | adicione o comando em `permissions.allow` ou use `--permission-mode bypassPermissions` |
| Aviso "agent descriptions over 15,000 tokens" | encurte os `description:` dos agentes (o corpo pode ficar longo; a descrição não) |
| Subagentes usando o modelo errado | o campo `model:` do agente manda; `CLAUDE_CODE_SUBAGENT_MODEL` é só o padrão |
| Agente editou fora do escopo | o Atlas deve devolver; se recorrente, aperte `paths.*` e rode `/retro` |
| Windows: hooks falham | use WSL ou Git Bash; os scripts são `bash` |

---

Licença MIT. Feito para ser modificado: a `/retro` existe exatamente para o Atlas evoluir com o seu projeto.
