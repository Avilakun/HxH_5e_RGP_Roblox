# Especificação da Ficha HxH — para construir no Roblox Studio

Documento para ser entregue a quem vai montar a UI (Claude Desktop ou humano).
Toda medida está em pixels de um canvas de **1220 × 780**, escalado por um
`UIScale` único no container raiz. Não use `Scale` em elementos individuais.

---

## 1. Diagnóstico do que está errado hoje

Comparando o print atual com a especificação:

| Problema | Correção |
|---|---|
| Cada atributo com cor própria (vermelho, verde, amarelo, azul, roxo, rosa) | **Errado.** Os seis atributos usam a MESMA cor: a da categoria de Nen. Cor por atributo não existe nessa ficha. |
| Rótulos `TENDÊNCIA`, `CA`, `RDM` e os valores na mesma cor | Rótulo é cinza neutro `#96A09C`. Só o valor recebe a cor do tema. |
| Coluna 2 (tendência/CA/RDM) é uma lista vertical solta | São **três blocos**: card de perfil (3 linhas), grade 2×2 de números, card de equipado. Ver §4.2. |
| Card de atributo com altura diferente do card de identidade | Atributo tem **150px fixo**. A coluna 3 inteira tem 340px (150 + 14 + 150 + ...). |
| `TREINADAS` vazio ocupando espaço | A faixa só existe se houver perícia treinada. Altura 36px, uma linha. |
| Ícones ausentes | Dois `ImageLabel` de 26px por atributo, entre a sigla e o valor. Ver §6. |
| Sobra ~380px vazios embaixo | A ficha tem 780px de altura total. Se sobrar espaço, o `UIScale` está pequeno ou a página não está preenchendo. Ver §2. |
| HUD aparecendo por trás da ficha, duplicado | HUD é um `Frame` irmão, ancorado embaixo, `ZIndex` 1. A ficha tem `ZIndex` 10. Só existe UM HUD e UM botão "abrir ficha". |
| Dois botões "ABRIR FICHA" | Remover o duplicado. |
| Valor `9m`, `11`, `+0` grudados no rótulo | 1px de gap entre rótulo (10px) e valor (14px), dentro de um `UIListLayout` vertical. |

---

## 2. Estrutura raiz

```
PlayerGui
└── HxH5eFicha (ScreenGui, IgnoreGuiInset = true, ResetOnSpawn = false)
    ├── Hud (Frame)          -- sempre visível, ZIndex 1
    └── SheetHolder (Frame)  -- ZIndex 10, Visible alterna com M
        └── UIScale
        └── Sheet (Frame 1220×780)
```

`SheetHolder`: `AnchorPoint (0.5, 0.5)`, `Position (0.5, 0.47)`,
`Size = UDim2.fromOffset(1220, 780)`.

Escala, recalculada em `ViewportSize`:

```lua
escala.Scale = math.min(1, (vp.X - 60) / 1220, (vp.Y - 200) / 780)
```

`Sheet`: fundo `#05070A` a 4% de transparência, `UICorner` 12,
`UIStroke` na cor do tema com `Transparency = 0.78`, `UIPadding` 20 nos 4 lados.

Dentro dele, `UIListLayout` vertical, `Padding = 13`:
1. `TabBar` — 42px de altura
2. `Paginas` — `UDim2.new(1, 0, 1, -55)`

---

## 3. Barra de abas

`TabBar` (1220-40 × 42) contém um `Inner` de **700 × 42** centralizado
(`AnchorPoint (0.5, 0)`, `Position (0.5, 0)`).

`Inner`: fundo = tema a 5%, `UICorner` 8, `UIStroke` tema `Transparency 0.65`,
`UIListLayout` horizontal `Padding = 2`, `HorizontalAlignment = Center`.

Cinco `TextButton` de **138 × 42**: FICHA, BIO, NEN, TRAÇOS, INV.

| Estado | Fonte | Cor do texto | Fundo |
|---|---|---|---|
| Ativa | GothamBold 16 | tema | tema a 16% |
| Inativa | Gotham 16 | `#96A09C` | transparente |

---

## 4. Aba FICHA — três colunas

`UIListLayout` horizontal, `Padding = 12`. Larguras: **252 / 236 / resto**.

### 4.1 Coluna 1 — Identidade (252 × 340)

Card com fundo tema a 9%, `UICorner` 10, `UIStroke` tema `Transparency 0.55`,
`UIPadding` 15. `UIListLayout` vertical `Padding = 10`,
`HorizontalAlignment = Center`.

Ordem exata dos elementos:

1. **Retrato** 124 × 124 — `ViewportFrame` com o avatar, `UICorner` circular
   (`UDim.new(1,0)`), `UIStroke` 2px na cor do tema.
2. **Nome** — GothamBold 28, cor do tema, centralizado.
3. **Card Jogador** — largura total × 34px. Fundo branco a 98%, `UICorner` 8,
   stroke branco a 91%, padding 8 (10 nas laterais).
   Linha horizontal: ícone 16px · rótulo `JOGADOR` (10px, cinza, 70px) ·
   valor à direita (14px, tema).
   **Este card fica ENTRE o nome e o nível.**
4. **Nível** — linha horizontal centralizada, `Padding = 6`:
   botão `−` (28×28) · rótulo `NÍVEL` (12px cinza) · valor `6/12`
   (Code 16, tema) · botão `+` (28×28).
   Botões: `UICorner` 7, stroke tema, hover = fundo tema a 15%.
5. **XP** — bloco de 26px: linha com `XP` (11px cinza) à esquerda e
   `300 / 1500` (Code 11, tema) à direita; abaixo, barra de 6px de altura,
   trilha branca a 93%, preenchimento na cor do tema, `UICorner` 3.

### 4.2 Coluna 2 — Perfil e números (236 × 340)

`UIListLayout` vertical `Padding = 9`. Três blocos:

**Bloco A — card de perfil, 118px.** Padding 11. Três linhas de 30px, cada uma
horizontal com `Padding = 10`:
ícone 18px · coluna vertical (rótulo 10px cinza + valor 14px tema).
Linhas, nesta ordem: `CATEGORIA`, `TENDÊNCIA`, `PROFICIÊNCIA`.

**Bloco B — grade de números, 108px.** `UIGridLayout`
`CellSize = (112, 50)`, `CellPadding = (9, 9)`. Quatro cards na ordem:
`DESL.` `9m` · `CA` `16` · `RDM` `4` · `INIC.` `+2`.
Cada card: padding 9, linha horizontal com ícone 16px + coluna
(rótulo 10px / valor 14px).

**Bloco C — card Equipado, 96px.** Padding 11. Rótulo `EQUIPADO` (10px cinza),
depois uma linha por item equipado relevante (mão principal, torso, costas):
nome à esquerda (12px, tema, 140px de largura) e stat à direita
(Code 10, cinza, alinhado à direita).

### 4.3 Coluna 3 — Atributos (resto × 340)

`UIListLayout` vertical `Padding = 9`. Cinco filhos:

1. Rótulo `FÍSICOS` — 10px, cinza, 14px de altura.
2. Linha de 150px com **FOR, DES, CON**.
3. Rótulo `MENTAIS E SOCIAIS` — igual ao primeiro.
4. Linha de 150px com **INT, SAB, PRE**.
5. Faixa `TREINADAS` — 36px.

Cada linha de atributos: `UIListLayout` horizontal, `Padding = 9`,
`HorizontalFlex = Fill`. Cada card recebe um `UIFlexItem` com
`FlexMode = Fill` — as três colunas ficam iguais sozinhas, sem largura fixa.

**Card de atributo — 150px de altura, todos idênticos.**
Fundo tema a 9%, `UICorner` 10, `UIStroke` tema `Transparency 0.55`,
padding 11. `UIListLayout` vertical `Padding = 6`,
`HorizontalAlignment = Center`. Ordem:

| # | Elemento | Fonte / tamanho | Cor |
|---|---|---|---|
| 1 | Sigla (`FOR`) | GothamBold 15 | **cinza `#96A09C`** — é rótulo |
| 2 | Dois ícones 26px, gap 10 | — | tema (via `ImageColor3`) |
| 3 | Valor (`18`) | Code 32 | tema |
| 4 | Modificador (`(+4)`) | Code 15 | tema |
| 5 | Linha TR: ícone 15px + `+4` (Code 14) | — | tema |

**Perícias no hover.** Um `TextButton` transparente cobrindo o card
(`Size = (1,0,1,0)`, `ZIndex = 2`, `Text = ""`).

- `MouseEnter` → cria o popover; `MouseLeave` → destrói.
- Popover: **230px de largura**, altura `34 + nº de perícias × 18`.
  Fundo `#0A0F0D` opaco, `UICorner` 9, stroke tema, padding 11, `ZIndex 50`.
- Filho de `Sheet`, não do card, para não ser cortado.
- Posição: `card.AbsolutePosition - sheet.AbsolutePosition`, deslocado
  `+card.AbsoluteSize.Y + 6` na linha de cima e `-altura - 6` na linha de
  baixo (senão o popover sai da tela).
- Conteúdo: rótulo `PERÍCIAS DE FORÇA` (9px cinza), depois uma linha de 16px
  por perícia — nome à esquerda (12px; treinadas ganham prefixo `● ` e a cor
  do tema, não treinadas ficam cinzas) e bônus à direita (Code 12, tema).
- CON não tem perícia: mostrar a frase "Sem perícias — entra em TR de veneno,
  exaustão e afogamento." com `TextWrapped`.

**Faixa TREINADAS.** Card de 36px, padding 9 (12 nas laterais), linha
horizontal `Padding = 12`, `VerticalAlignment = Center`: rótulo `TREINADAS`
(10px cinza, 78px) e uma etiqueta por perícia treinada (12px, tema, 118px).
Se não houver nenhuma treinada, **não criar a faixa.**

---

## 5. Regras de cor — a parte que mais erra

```lua
Categorias = {
    ["Intensificação"] = Color3.fromRGB(0, 255, 157),
    ["Emissão"]        = Color3.fromRGB(0, 200, 255),
    ["Transmutação"]   = Color3.fromRGB(180, 120, 255),
    ["Materialização"] = Color3.fromRGB(255, 196, 0),
    ["Manipulação"]    = Color3.fromRGB(255, 95, 245),
    ["Especialização"] = Color3.fromRGB(255, 59, 59),
}
```

Três classes, sem exceção:

1. **Rótulo** → `#96A09C` fixo. Nunca muda de cor.
   Exemplos: `FOR`, `TENDÊNCIA`, `CA`, `XP`, `JOGADOR`, `TREINADAS`,
   `FÍSICOS`, `PERÍCIAS DE FORÇA`.
2. **Descrição / valor** → cor da categoria de Nen.
   Exemplos: `Kairo`, `Heroico`, `18`, `(+4)`, `+4`, `9m`, `16`,
   `Jogador_01`, `300 / 1500`, nome de perícia treinada e todos os bônus.
3. **Vitais** → cor própria, **imune ao tema**, e vivem no HUD:
   PV `#FF4D4D` · Aura `#00C8FF` · Sanidade `#B478FF` · Reações `#FFC400`.
   Negativos, condições e avisos: âmbar `#FFD766`.

Para imitar `color-mix(cor N%, transparent)` do mockup:

```lua
function Theme.mix(alpha, cor)
    return Color3.fromRGB(7, 10, 12):Lerp(cor or Theme.Accent, alpha)
end
```

Todo elemento colorido deve se registrar num `Theme.register(inst, prop, alpha)`
para que trocar a categoria recolora tudo de uma vez.

**Não existe box-shadow no Roblox.** O glow neon do mockup vira
`UIStroke` + fundo com tint. Não tente simular sombra com frames empilhados.

---

## 6. Ícones

Dois por atributo, 26px, entre a sigla e o valor:

| Atributo | Ícone 1 | Ícone 2 |
|---|---|---|
| FOR | punho fechado | halter |
| DES | seta circular | tênis |
| CON | corpo de braços abertos | cruz médica |
| INT | livro aberto | frasco |
| SAB | olho | figura meditando |
| PRE | balão de fala | silhueta com foco |

Mais: `JOGADOR` (pessoa), `TENDÊNCIA` (balança), `PROFICIÊNCIA` (mira),
`DESL.` (tênis), `CA` (escudo), `RDM` (escudo com galão), `INIC.` (raio),
`TR` (escudo com check), e um por aba.

Regras:
- Todos os ids num único módulo `FichaUIIcons.lua`.
- **PNG branco com fundo transparente** — a cor vem de `ImageColor3`, então o
  ícone acompanha a categoria automaticamente.
- `ScaleType = Fit`.
- Id `0` → `Image = ""`: o espaço fica vazio e nada quebra.
- Cada `ImageLabel` com nome próprio (`Icon_FOR_1`, `Icon_CA`) para troca
  direta no Explorer.

---

## 7. HUD fixo — fora da ficha

`Frame` de `(1, -40) × 92`, `Position (0, 20, 1, -112)`.
Fundo `#0A0D10` a 8%, `UICorner` 10, stroke branco a 88%, padding 14.
`UIListLayout` horizontal `Padding = 22`, `VerticalAlignment = Center`.

Quatro grupos, nesta ordem:

1. **Barras** (300 × 64) — três linhas de 16px. Cada linha: rótulo (11px cinza,
   42px) · trilha 170 × 11 com `UICorner` 5 (fundo = a própria cor a 88%,
   preenchimento opaco) · texto `42/52` (Code 11, na cor do vital, 56px,
   alinhado à direita). Ordem: PV, AURA, SAN.
2. **Reações** (140 × 46) — rótulo + 7 pips de 15 × 13, `UICorner` 3, gap 4.
   Gastas ficam a 85% de transparência. Cor âmbar, nunca o tema.
3. **Condições** (240 × 46) — rótulo + tags âmbar de 24px de altura com
   `AutomaticSize = X`. **Só aparecem quando existem.**
4. **Atalhos** — um card 76 × 52 por princípio desbloqueado: sigla
   (GothamBold 14, tema) e `1 · 0%` (Code 10, cinza). Fundo tema a 8%,
   `UICorner` 8, stroke tema.

Botão "FICHA (M)" no canto direito do HUD, 96 × 24. **Um só.**

Abrir/fechar: `M` alterna, `Esc` fecha. Ignore quando
`InputBegan` vier com `gameProcessed = true`.

---

## 8. Vocabulário de componentes

Construa cinco helpers e use só eles — é o que mantém a ficha coerente:

| Helper | O que faz |
|---|---|
| `card(parent, size)` | fundo branco a 98%, `UICorner` 10, stroke tema `Transparency 0.78` |
| `cardAccent(parent, size)` | fundo tema a 9%, `UICorner` 10, stroke tema `Transparency 0.55` |
| `label(parent, texto, px)` | Gotham, cinza `#96A09C`, alinhado à esquerda/topo |
| `value(parent, texto, px)` | GothamBold, cor do tema (registrado no Theme) |
| `mono(parent, texto, px)` | `Enum.Font.Code`, cor do tema por padrão |

Fontes: `GothamBold` para títulos, `Gotham` para corpo, `Code` para números.
Chakra Petch e IBM Plex Mono não existem no Studio — se quiser as originais,
suba como asset de fonte.

---

## 9. Checklist de aceitação

Antes de considerar pronto, confira:

- [ ] Os seis atributos têm a **mesma** cor, e ela muda junto ao trocar a categoria
- [ ] Siglas `FOR`/`DES`/`CON`/`INT`/`SAB`/`PRE` estão **cinzas**, não coloridas
- [ ] Os seis cards de atributo têm exatamente 150px de altura
- [ ] O card Jogador está entre o nome e o nível
- [ ] Hover em cada atributo abre o popover de perícias, e CON mostra a nota
- [ ] Popover da linha de baixo abre **para cima**, sem sair da tela
- [ ] Nenhum bloco vazio ocupando espaço (sem perícia treinada, sem faixa)
- [ ] Ficha preenche os 780px; nada de faixa morta embaixo
- [ ] Um HUD, um botão de abrir
- [ ] HUD atrás da ficha (`ZIndex` 1 contra 10), sem sobreposição de texto
- [ ] Barras de PV/Aura/Sanidade não mudam de cor ao trocar a categoria
- [ ] Redimensionar a janela reescala a ficha inteira, sem quebrar o layout
