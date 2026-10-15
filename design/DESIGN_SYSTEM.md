# Design System

> Fonte de verdade visual do projeto. Mantido pelo agente `designer`. Deve bater com os tokens no código
> (`atlas.config.json` → `design.tokens_in_code`). O Claude Design lê este arquivo e o código ao montar o sistema do time.
> Preenchido por `/atlas-init` ou `/design system`.

## Produto e público
<para quem é, qual o tom: sério/leve, denso/arejado, técnico/acessível>

## Cores
| Token | Hex | Uso |
|---|---|---|
| `--color-bg` | | fundo |
| `--color-surface` | | cartões, painéis |
| `--color-text` | | texto principal |
| `--color-muted` | | texto secundário |
| `--color-primary` | | ação principal (uma só) |
| `--color-danger` | | erro, destrutivo |

## Tipografia
| Papel | Família | Peso | Tamanho/linha |
|---|---|---|---|
| Display | | | |
| Corpo | | | |
| Dados/código | | | |

## Espaçamento, raio, sombra
<escala de espaçamento (ex.: 4-8-12-16-24-32-48), raios por hierarquia, sombras (poucas)>

## Componentes
| Componente | Onde está no código | Variantes | Estados |
|---|---|---|---|
| Button | | primary, secondary, ghost, danger | default, hover, focus, loading, disabled |
| Input | | | default, focus, error, disabled |

## Princípios
- <o que torna este produto reconhecível; onde está a ousadia; o que nunca fazer>

## Padrões de tela
- Lista com dados: loading (skeleton), vazio (convite à ação), erro (o que houve + como resolver), sucesso.
- Formulário: validação inline, erro ao lado do campo, CTA com o verbo da ação.
