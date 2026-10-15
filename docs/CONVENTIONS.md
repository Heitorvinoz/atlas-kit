# Convenções do projeto

## Branches
| Branch | Origem | Destino | Quem cria |
|---|---|---|---|
| `main` | — | produção; só recebe `release/*` e `hotfix/*` | — |
| `develop` | `main` | integração; recebe `feat/*`, `fix/*`, `chore/*`, `refactor/*` | `/atlas-init` |
| `feat/<issue>-<slug>` | `develop` | `develop` via PR (squash) | `/feature` |
| `fix/<issue>-<slug>` | `develop` | `develop` via PR (squash) | `/feature` |
| `hotfix/<issue>-<slug>` | `main` | `main` + back-merge em `develop` | `/hotfix` |
| `release/vX.Y.Z` | `develop` | `main` (merge commit) + tag + back-merge | `/release` |

Exemplo: `feat/42-order-checkout`. Slug em inglês, kebab-case, ≤ 5 palavras.

## Commits (Conventional Commits)
```
<tipo>(<escopo>): <descrição no imperativo, ≤ 72 chars>

<corpo opcional: o porquê, não o quê>

Refs #<issue>
```
Tipos: `feat` `fix` `chore` `docs` `refactor` `test` `perf` `ci` `build` `style` `revert`.
Escopos sugeridos: `api` `web` `db` `auth` `infra` `deps` `adr` ou o nome do módulo.
`!` após o escopo = breaking change (força bump major): `feat(api)!: drop v1 endpoints`.

## Pull Requests
- Título = mensagem do squash commit: `feat(api): add order checkout (#42)`.
- Corpo pelo template; `Closes #42`; checklist completo.
- Uma PR = uma issue. PR grande (> 40 arquivos) é sinal de issue mal quebrada.
- Merge em `develop`: squash. Merge em `main`: merge commit (preserva histórico).

## Versionamento (SemVer)
- `[Unreleased]` com `Added` → minor · só `Fixed` → patch · qualquer `!` → major.
- Tag `vX.Y.Z` anotada, GitHub Release com notas em linguagem de usuário.

## Issues
- Labels: `type:feat|fix|chore`, `area:backend|frontend|database`, `security`, `hotfix`.
- Toda issue tem critérios de aceite verificáveis. Sem critério, sem implementação.

## Decisões
- Não óbvio = ADR em `docs/adr/`. Pequeno = comentário na issue. Nunca só na cabeça.
