---
name: maintain
description: Manutenção periódica: atualiza dependências com segurança, roda auditorias, procura código morto, testes frágeis e docs desatualizadas, e abre issues chore. Rode semanalmente ou antes de um release grande.
disable-model-invocation: true
---

Branch `chore/<n>-maintenance-<AAAA-MM-DD>` via issue `chore: maintenance <data>`. Em paralelo:
- `security` (full): `deps_audit` + `secrets`; vulnerabilidades → lista por severidade.
- `backend`/`frontend`: atualize dependências minor/patch (`npm update`, `uv lock --upgrade`, `cargo update`, etc. — leia a stack);
  major só com issue própria. Rode a suíte. Código morto: ferramenta da stack (`knip`, `vulture`, `deadcode`, `cargo-udeps`) se disponível.
- `qa`: testes frágeis (rode a suíte 3x; o que oscila é frágil), tempo da suíte, cobertura vs mínimo.
- `docs`: docs vivas completas (API, arquitetura, links), README passo a passo.
Depois: PR com o que foi seguro mudar; issues `chore` para o resto (majors, refactors, testes frágeis), priorizadas.
Relatório: o que mudou, o que ficou em issue, risco encontrado. `metrics.sh log maintain ...`.
