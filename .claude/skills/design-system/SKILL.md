---
name: design-system
description: Design system do projeto (tokens, tipografia, componentes, princípios). Preloaded nos agentes designer e frontend. Fonte: design/DESIGN_SYSTEM.md.
user-invocable: false
---

Leia `design/DESIGN_SYSTEM.md` antes de desenhar ou implementar qualquer interface. Ele é a fonte de verdade visual
do projeto e deve bater com os tokens no código (`atlas.config.json` → `design.tokens_in_code`).

Regras curtas que valem sempre:
- Use os tokens; nunca valores soltos de cor, fonte, espaçamento ou raio.
- Reutilize componentes existentes; componente novo só com justificativa na spec.
- Toda tela com dados tem estados loading, vazio, erro e sucesso.
- Copy em voz ativa, sentence case; o botão diz o que acontece.
- Acessível por padrão: semântica, foco visível, contraste, reduced motion.
- Uma coisa memorável por tela; o resto quieto e disciplinado.
