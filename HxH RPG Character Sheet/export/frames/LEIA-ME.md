# Molduras PNG para o Roblox Studio

Cinco PNG com **fundo vazado** e linhas brancas com glow. Só geometria: nenhum
texto, nenhum ícone, nenhum valor. Tudo que é conteúdo entra como `TextLabel` /
`ImageLabel` por cima.

## Arquivos

| Arquivo | Tamanho do PNG (2×) | Medida de design (1×) |
|---|---|---|
| `ficha.png`  | 2440 × 994  | **1220 × 497** |
| `bio.png`    | 2440 × 1266 | **1220 × 633** |
| `nen.png`    | 2440 × 1048 | **1220 × 524** |
| `tracos.png` | 2440 × 1664 | **1220 × 832** |
| `inv.png`    | 2440 × 1200 | **1220 × 600** |

Os `preview-*.png` são só conferência (mesma imagem sobre fundo escuro) —
**não suba esses**, eles não têm alpha.

Exportei em 2× para a borda não serrilhar em telas grandes. No Studio use
sempre a medida de design: `Size = UDim2.fromOffset(1220, 497)`. A imagem
reduz sozinha e fica mais nítida.

**As alturas são diferentes de propósito** — é a altura real de cada aba no
mockup. Duas formas de usar:

- **Painel que acompanha a aba** (recomendado): ao trocar de aba, ajuste
  `Size` do painel para a medida daquela aba. Cada uma fica sem faixa morta.
- **Painel fixo**: use 1220 × 832 (a maior, TRAÇOS) e ancore a moldura no topo
  com `AnchorPoint = (0.5, 0)`. As abas menores deixam espaço vazio embaixo.

## Como aplicar

Um `ImageLabel` por aba, atrás de tudo:

```lua
local moldura = Instance.new("ImageLabel")
moldura.Name = "Moldura_FICHA"
moldura.BackgroundTransparency = 1          -- o vazado é a imagem
moldura.Size = UDim2.fromOffset(1220, 497)  -- medida de design, não a do PNG
moldura.Image = "rbxassetid://SEU_ID_AQUI"
moldura.ScaleType = Enum.ScaleType.Stretch
moldura.ImageColor3 = Theme.Accent          -- cor da categoria de Nen
moldura.ZIndex = 0
moldura.Parent = paginaFicha
```

As linhas são **brancas puras**, então `ImageColor3` tinge a moldura inteira na
cor da categoria — verde para Reforço, ciano para Emissão, e assim por diante.
Basta incluir cada `ImageLabel` no seu `Theme.register(inst, "ImageColor3")`
que a troca de categoria recolore tudo junto.

Não use `ScaleType.Slice` aqui: o conteúdo interno da moldura não é repetível,
e o slice deformaria os cards. `Stretch` com o `UIScale` do painel já resolve.

## Sistema de coordenadas

O canto superior esquerdo do PNG é `(0, 0)` do painel. Como a imagem foi
exportada exatamente no tamanho de design, **os offsets do brief valem
direto**, sem conversão:

- padding do painel: 20px nos quatro lados
- barra de abas: 700 × 42 centralizada, em `y = 20`
- início do conteúdo: `y = 75` (20 de padding + 42 da aba + 13 de gap)

Ou seja, um `TextLabel` em `Position = UDim2.fromOffset(x, y)` cai no lugar
certo usando os números do `BRIEF-FichaUI.md`. Coloque os labels como filhos do
mesmo `Frame` da moldura, com `ZIndex` maior.

## O que está desenhado em cada moldura

**ficha.png** — pílula de abas com 4 divisórias · card de identidade com
círculo de retrato 124px, card do jogador, dois botões de nível 28×28 e trilha
de XP · card de perfil com 3 linhas e 2 divisórias · grade 2×2 de números ·
card de equipado com 3 linhas guia · seis cards de atributo de 150px com dois
quadros de ícone 26px e a divisória do TR · faixa de treinadas.

**bio.png** — duas sub-abas · dois campos de texto com sublinha de rótulo ·
card de gostos/desgostos dividido ao meio, com os contornos das tags · campo de
história · três campos de relações.

**nen.png** — duas sub-abas + caixa de P.N à direita · card de categorias com
6 trilhas de barra e dois quadros de rolagem · fundamentais com 3 trilhas de
pip (3 pips de 24×9 cada) · avançados em grade 4×2, o oitavo tracejado ·
faixa de atalhos com 5 pílulas.

**tracos.png** — duas colunas · badges de 42px por seção · cards com o acento
de 2px na borda esquerda (positivas e negativas usam o mesmo contorno; a
diferença é a cor que você aplica no texto) · última seção tracejada, para o
estado vazio do Shingen-Ryu.

**inv.png** — cabeçalho com trilha de espaço · card de equipamento com 4 slots
à esquerda, caixa do avatar 124 × 280 no centro e 4 slots à direita · card de
carregando com 4 linhas de item, cada uma com os dois botões de quantidade
22×22 à direita.

Os contornos de slot do INV **são parte da moldura**, como você pediu — o item
equipado entra como um `Frame`/`ImageLabel` cobrindo o slot.

## Dois detalhes

1. **O glow externo é cortado na borda.** A imagem tem exatamente 1220 de
   largura, então o brilho que se espalharia para fora do retângulo não cabe.
   Se quiser bloom para fora, adicione um `UIStroke` no `Frame` do painel ou
   uma segunda imagem maior por baixo.
2. **Nada de texto na imagem, de propósito.** Rótulos são cinzas e valores
   ficam na cor da categoria — se estivessem gravados no PNG, receberiam o
   mesmo tint do `ImageColor3` e você perderia essa distinção. Por isso todo
   texto é `TextLabel`.

## Se precisar de outra medida

O arquivo `Frames para Roblox.dc.html` no projeto gera essas molduras. Peça e
eu re-exporto em 1×, 3×, com linha mais grossa, sem glow, ou com o painel numa
altura fixa única.
