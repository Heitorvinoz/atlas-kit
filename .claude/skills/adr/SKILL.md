---
name: adr
description: Registra uma decisão de arquitetura (Architecture Decision Record) em docs/adr/ com contexto, opções consideradas, decisão e consequências. Use sempre que uma escolha não óbvia for feita.
---

Decisão a registrar: $ARGUMENTS

1. Leia `docs/adr/README.md` para o próximo número e para ver se já existe ADR sobre o tema (se sim, este pode substituí-lo).
2. Se o usuário ainda não decidiu: em modo `full`, escolha a opção mais simples e reversível e registre (ele vê no relatório e pode reverter); pergunte só se envolver dinheiro, autenticação, exclusão de dados ou custo recorrente. Em `confirm`, apresente 2-3 opções com sua recomendação e pergunte.
3. Copie `docs/adr/0000-template.md` para `docs/adr/NNNN-<slug-em-ingles>.md` e preencha todas as seções. Seja concreto:
   "escolhemos X porque Y; descartamos Z porque W; isso significa que daqui em diante A e B".
4. Status: `Accepted` (ou `Proposed` se o usuário quiser pensar). Se substitui outro, marque o antigo como `Superseded by ADR-NNNN`.
5. Atualize a tabela em `docs/adr/README.md`.
6. Se estiver no meio de uma feature, cite o ADR na issue (`gh issue comment N`). Commit: `docs(adr): NNNN <título>`.
7. Diga ao usuário em 2 linhas o que foi registrado e o que muda na prática.
