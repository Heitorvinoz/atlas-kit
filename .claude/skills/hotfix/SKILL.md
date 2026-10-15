---
name: hotfix
description: Correção urgente em produção. Branch hotfix/ a partir de main, gate reduzido mas com segurança, merge em main com tag patch e back-merge em develop. Só rode quando o usuário pedir explicitamente.
disable-model-invocation: true
---

Problema reportado: $ARGUMENTS

Hotfix é exceção controlada, não atalho. Fluxo:
1. Entenda e confirme reprodução. `gh issue create --label type:fix --label hotfix`. Guarde `N`.
2. `git checkout main && git pull --ff-only && git checkout -b hotfix/N-<slug>`.
3. Delegue ao implementador da área com instrução explícita: mudança mínima, nada de refatoração.
4. `qa`: teste que reproduz o bug (falha antes, passa depois) + suíte completa.
5. `security` ESCOPO: diff. `BLOCK` → pare.
6. `docs`: CHANGELOG `[X.Y.Z+1]` seção Fixed, bump patch, notas curtas.
7. `gh pr create --base main`; em modo `full` `gh pr merge --merge` direto (em `confirm`, pergunte), tag `vX.Y.(Z+1)`, `gh release create`.
8. Back-merge em `develop` via PR. Confirme que o teste de regressão está em develop.
9. Abra issue `chore` se o hotfix revelou débito ou falta de teste que deveria ter pegado isso.
10. Entregue o Relatório de release (formato do `/release`) com a causa raiz do bug em 1 linha.
