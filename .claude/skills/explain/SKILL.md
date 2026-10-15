---
name: explain
description: Explica como algo funciona neste projeto ("como funciona o login?", "onde fica a regra de desconto?", "o que acontece quando o pedido é cancelado?") a partir do código, ADRs e docs, com arquivos e linhas. Use quando o usuário quiser entender o que foi construído.
---

Pergunta: $ARGUMENTS

Delegue ao `scout` com a pergunta exata e o contexto que você já tem (issues e ADRs relacionados pelo que lembra).
Devolva a resposta dele ao usuário sem reescrever a parte técnica. Se o `scout` reportar divergência entre código e
docs, abra issue `docs: <o que diverge>` (`gh issue create --label type:chore`) e mencione no fim da resposta.
Se a pergunta revelar que falta documentação de algo importante, sugira "/feature documentar X" em uma linha.
