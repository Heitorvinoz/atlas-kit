---
name: atlas-init
description: Configura o Atlas em um repositório novo ou existente. Detecta a stack, preenche atlas.config.json, cria branches, labels e documentação inicial. Rode uma vez por projeto.
disable-model-invocation: true
---

Você vai preparar este repositório para ser operado pelo Atlas. Execute em ordem e reporte cada etapa.

## 1. Detectar stack
Procure na raiz (e em até 2 níveis, para monorepos): `package.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`,
`pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle*`, `Gemfile`, `composer.json`,
`*.csproj`, `mix.exs`, `Dockerfile`, `docker-compose*.yml`, `prisma/`, `alembic/`, `migrations/`, `supabase/`.
Leia a tabela de presets em `.claude/skills/atlas-init/presets.md` e escolha os comandos. Se o repo está vazio,
pergunte ao usuário (uma pergunta, com 3-4 opções) qual stack quer usar e sugira a mais simples para o objetivo dele.

## 2. Preencher `atlas.config.json`
Preencha `project`, `stack`, `paths` (onde fica backend/frontend/db neste repo) e `commands` com comandos
REAIS que você verificou (rode `--help` ou o próprio comando em modo dry-run quando possível). O que não existir fica `null`.
Verifique ferramentas de segurança: `which gitleaks semgrep`. Para `deps_audit` use o auditor nativo da stack (preset).
Se gitleaks/semgrep não estiverem instalados, mantenha os comandos no config e avise o usuário como instalar
(`brew install gitleaks semgrep` / `pip install semgrep` / binários do GitHub). O gate de release vai marcar SKIPPED até lá.

## 2b. Ambiente local e design
- Preencha `dev.command` (ex.: `npm run dev`, `uv run uvicorn app:app --reload`, `go run ./cmd/server`), `dev.url`,
  `dev.health_path` (uma rota que responde 200 rapidamente) e `dev.services_up` (ex.: `docker compose up -d`) se houver.
  Teste: `bash .claude/scripts/dev-up.sh` deve terminar em "DEV: pronto". Depois `bash .claude/scripts/env-check.sh`.
- Se houver frontend: delegue ao `designer` a tarefa `system` para extrair `design/DESIGN_SYSTEM.md` do código e preencha
  `design.tokens_in_code`. Sem frontend ainda: deixe o template e avise que `/design system` monta quando a UI nascer.
- Pergunte (uma vez) se o usuário vai usar o Claude Design; se não, mude `design.mode` para `spec`.
- Preencha `commands.seed` (seed de demonstração) e, se houver API, `commands.api_spec`/`api_spec_check` (presets em `presets.md`).
- Ferramentas de QA visual: `node`/`npx` (Playwright, axe, Lighthouse) e Chrome. Faltando → avise; o `qa` marca SKIPPED.
- Notificação: pergunte o canal (desktop é o padrão e não precisa de nada; ntfy é o mais simples para celular). Se for ntfy/telegram/slack,
  mostre como criar `~/.atlas/notify.env` (fora do repo) com a variável certa. Teste: `bash .claude/scripts/notify.sh "Atlas" "configurado"`.
- Deploy: não configure agora; diga que `/deploy setup` faz isso quando o usuário quiser publicar.
- Memória de conversa (padrão ligada, `memory.conversational: "claude-mem"`): instale o plugin claude-mem seguindo as instruções
  atuais do projeto dele (`npx claude-mem install` ou o marketplace — verifique a documentação em vez de assumir), confirme que o serviço
  sobe e adicione a pasta que ele criar ao `.gitignore`. Se a instalação falhar, avise e deixe `memory.conversational: null`; o Atlas
  continua funcionando com as outras camadas. Explique em 2 linhas: claude-mem = conversa; MEMORY.md = projeto; STATE.md = trabalho em
  andamento; docs/IDEAS.md = ideias estacionadas (versionado).

## 3. Git e GitHub
- `git init` se necessário. Garanta `.gitignore` adequado à stack (inclua `.env`, `.claude/agent-memory-local/`).
- Crie `develop` a partir de `main` se não existir: `git checkout -b develop && git push -u origin develop`.
- `gh auth status`. Se não autenticado, pare e peça `gh auth login`.
- Crie labels (ignore erro se já existem):
  `gh label create area:backend --color 0E8A16; gh label create area:frontend --color 1D76DB; gh label create area:database --color FBCA04;`
  `gh label create type:feat --color 5319E7; gh label create type:fix --color D93F0B; gh label create type:chore --color BFD4F2; gh label create security --color B60205`
- Sugira (não force) proteger `main` e `develop` no GitHub (Settings → Branches → require PR).

## 4. Documentação inicial
- Se o `README.md` atual for o guia do Atlas (começa com "# Atlas"), mova-o para `docs/ATLAS.md` (é a referência do fluxo)
  e crie o README do PROJETO: título, descrição em 1 parágrafo, "Como rodar", "Como testar", "Estrutura", "Variáveis de ambiente",
  "Documentação" (links para docs/, incluindo docs/ATLAS.md). Se o README já for do projeto, só complete o que faltar.
- Remova `publish.sh` e `install.sh` do projeto (são do kit, não do produto): `git rm -q publish.sh install.sh` se existirem.
- Crie `docs/adr/0001-adopt-atlas-workflow.md` (status Accepted) descrevendo: fluxo de branches, Conventional Commits,
  gate de release e stack escolhida. Atualize `docs/adr/README.md`.
- Se o usuário escolheu stack agora, crie também `docs/adr/0002-stack-choice.md` com o porquê.
- Garanta `.env.example` existe.
- `docs/ARCHITECTURE.md`: esqueleto com as áreas detectadas.

## 5. Commit inicial
Na branch `develop` isso é exceção permitida (primeiro setup): rode o commit com `ATLAS_ALLOW_PROTECTED=1 git commit -m "chore: bootstrap Atlas workflow"`
e depois `ATLAS_ALLOW_PROTECTED=1 git push`. Não use essa variável em nenhum outro momento.

## 6. Relatório
Mostre ao usuário: stack detectada, comandos configurados (e os `null`), ferramentas de segurança faltando,
a URL do localhost, e os próximos passos: "reinicie o Claude Code para carregar o agente, depois rode `/feature <o que você quer>`".
Se `design.mode` = `claude-design`: "abra claude.ai/design uma vez e aponte para este repositório para ele aprender o design system".
