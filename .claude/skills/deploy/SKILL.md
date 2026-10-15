---
name: deploy
description: Deploy. "/deploy setup" escolhe e configura o provedor; "/deploy preview" publica a branch atual; "/deploy staging" e "/deploy prod" publicam a última release; "/deploy rollback" volta a anterior. Prod só quando o usuário pedir explicitamente.
disable-model-invocation: true
arguments: [env]
---

Ambiente: `$env`

- **setup**: delegue ao `deploy` com tarefa "propor provedor" (ele lê a stack e devolve 3 opções). Em modo `full`, escolha
  a opção mais simples que atenda a stack e registre com `/adr` ("Deploy provider"); isso mexe com custo recorrente, então
  se qualquer opção tiver custo mensal > 0, PERGUNTE (uma vez, com as 3 opções e preços). Preencha `deploy.*` em `atlas.config.json`
  (comandos reais, URLs, `required_env`). Peça ao usuário para autenticar o CLI (`vercel login`, `railway login`, `fly auth login`...)
  e setar os segredos com os comandos que o `deploy` listar. Teste com `/deploy preview`. Documente no README seção "Deploy".
- **preview**: branch atual deve ter PR aberta. Delegue ao `deploy` (`preview`). Poste a URL na PR e devolva ao usuário.
- **staging**: `git checkout main && git pull --ff-only`, confira a última tag, delegue `staging`. Smoke test. Relatório com URL e versão.
- **prod**: só se o usuário pediu explicitamente nesta conversa (ou `deploy.auto_prod_after_release`). Mesmas checagens de
  staging + confirme que staging está saudável nessa versão. Delegue `prod`. Se a saúde pós-deploy falhar, o `deploy` já faz
  rollback; reporte como incidente e abra issue `fix` com `hotfix` label.
- **rollback**: delegue `rollback` para o ambiente indicado (padrão prod). Reporte versão anterior restaurada.

Após qualquer deploy: `bash .claude/scripts/notify.sh "Atlas: deploy <env>" "<url> · <versão> · saúde ok"` e
`bash .claude/scripts/metrics.sh log deploy env=<env> version=<v> status=<status>`.
