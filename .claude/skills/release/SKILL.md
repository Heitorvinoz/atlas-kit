---
name: release
description: Promove develop para main como uma release versionada. Roda o gate completo (testes, cobertura, lint, build, auditoria de dependências, SAST, segredos, revisão de segurança) e só então mergeia, cria tag semver, CHANGELOG e GitHub Release. Só rode quando o usuário pedir explicitamente.
disable-model-invocation: true
arguments: [bump]
---

Tipo de bump pedido: `$bump` (major | minor | patch | vazio = você sugere a partir do CHANGELOG `[Unreleased]`:
Added → minor, só Fixed → patch, mudança incompatível/`!` → major).

Este é o único caminho para `main`. Nada aqui é opcional. Se qualquer etapa falhar, PARE, reporte e não avance.

## 0. Pré-condições
- `git status --porcelain` vazio. `git checkout develop && git pull --ff-only`.
- `gh pr list --base develop --state open` → se houver PRs abertas, liste e pergunte se a release deve esperar.
- Leia `atlas.config.json`. Determine a versão: última tag `git describe --tags --abbrev=0` (ou `v0.0.0`) + bump.
  Em modo `full`, siga com a versão calculada (o usuário já pediu a release; isso basta). Em `confirm`, confirme a versão.
- Crie `release/vX.Y.Z` a partir de `develop`.

## 1. Gate de qualidade (delegue ao `qa`, escopo full)
`commands.install` (limpo), `lint`, `format` (check), `typecheck`, `test`, `test_coverage` ≥ `coverage_min`, `e2e` se existir,
`build`, `migrate_check` se existir. Com UI: `dev-up.sh` + `audit-web.sh` nas rotas principais (orçamentos `quality.budgets`) +
regressão visual contra baseline. Com API: `commands.load_test` vs `api_p95_ms`. Cada comando `null` é listado como SKIPPED no relatório.

## 2. Gate de segurança (delegue ao `security`, ESCOPO: full)
`security.deps_audit`, `security.sast`, `security.secrets` + revisão manual OWASP do repositório inteiro, com foco em
autenticação, autorização, fronteiras de entrada e dados sensíveis. Verifique também: `.env` não versionado,
`.env.example` completo, dependências com versões fixadas, nenhum `TODO security`/`FIXME` crítico.
`BLOCK` → pare. Mostre os achados ao usuário. Correções seguem o fluxo normal (`/feature` tipo fix em develop) e a release recomeça.
Ferramenta faltando → SKIPPED. Pergunte ao usuário se aceita liberar sem ela; registre a resposta no corpo da release.

## 3. Documentação de release (delegue ao `docs`)
CHANGELOG `[Unreleased]` → `[X.Y.Z] - data`; notas de release em linguagem de usuário; revisão do README; bump da versão
nos arquivos da stack (`package.json`, `pyproject.toml`, `Cargo.toml`, etc. — leia `atlas.config.json` e os presets).
Commit: `chore(release): vX.Y.Z`.

## 4. Merge e tag
- `gh pr create --base main --head release/vX.Y.Z --title "release: vX.Y.Z" --body "<notas + resumo do gate com cada etapa e resultado>"`.
- Em modo `full`: se o gate passou sem SKIPPED e sem BLOCK, `gh pr merge --merge` direto (merge commit, preserva histórico).
  Se houve SKIPPED por ferramenta ausente, pare e pergunte se aceita publicar assim (isso está em `always_ask_when`).
  Em `confirm`: mostre a tabela do gate e pergunte "publicar vX.Y.Z em main?".
- `git checkout main && git pull --ff-only && git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z`.
- `gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <notas>`.
- Back-merge: `gh pr create --base develop --head main --title "chore: back-merge vX.Y.Z"` e merge, para develop ter a tag e o bump.
- `git branch -d release/vX.Y.Z`.

## 4b. Localhost na versão publicada
`git checkout main && bash .claude/scripts/dev-up.sh --restart` — o usuário testa exatamente o que foi lançado.
Depois volte para `develop`.

## 4c. Staging, retro e métricas
- Se `deploy.provider` configurado: delegue ao `deploy` (`staging`). Prod só se `deploy.auto_prod_after_release` ou pedido explícito.
- `bash .claude/scripts/metrics.sh log release version=vX.Y.Z gate=<PASS|BLOCK> skipped=<n> duration_s=<s>`.
- `bash .claude/scripts/notify.sh "Atlas: vX.Y.Z publicada" "<link>"`.
- Sugira `/retro vX.Y.Z` ao usuário (não rode sozinho: ela abre PR nas suas próprias regras).

## 5. Encerramento — Relatório de release
```
🚀 vX.Y.Z publicada — <link da GitHub Release>
🌐 Rodando em: <dev.url> (checkout de main) · staging: <url ou "não configurado">
Inclui: <itens do CHANGELOG em linguagem de usuário>
Gate: testes <n/n> · cobertura X% · lint ✓ · typecheck ✓ · build ✓ · deps audit ✓ · SAST ✓ · segredos ✓ · revisão OWASP PASS
SKIPPED: <etapas e motivo> (ou "nenhuma")
Débitos encontrados → issues abertas: <#a, #b> (ou "nenhum")
Para reverter: `git revert -m 1 <hash do merge>` em main + nova release patch
```
Reporte isso ao usuário. Atualize sua memória com o que o gate pegou
(para prevenir na próxima). Sugira issues `chore` para débitos encontrados.
