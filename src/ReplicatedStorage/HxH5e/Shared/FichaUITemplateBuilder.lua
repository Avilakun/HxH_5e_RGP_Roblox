--[[
    HxH5e FichaUITemplateBuilder (server, roda 1x no boot)

    Formato HIBRIDO pedido pelo Lucas: as 3 colunas da aba FICHA
    (Identidade / Meta / Atributos) NAO sao mais montadas inteiras em
    codigo toda vez que o LocalScript roda -- sao um TEMPLATE de
    verdade (ReplicatedStorage.HxH5e.FichaUITemplates.FichaTabRow),
    com Frames/TextLabels reais, editaveis no Explorer (tamanho,
    posicao, fonte, cor) sem tocar em nenhum script. FichaUIClient.lua
    so CLONA esse molde e preenche o texto.

    v3 (seguindo BRIEF-FichaUI.md, doc entregue pelo Design apos ver a
    v2 rodando): a v2 tinha cor propria por atributo (FOR vermelho,
    DES verde etc, referencia GUI_v2 pedida pelo Lucas antes) -- o
    Design corrigiu isso: os 6 atributos usam a MESMA cor, a da
    categoria de Nen, e a sigla e cinza por ser ROTULO. Reescrito
    seguindo as medidas EXATAS do brief:
    - 3 colunas lado a lado, 340px de altura: Identidade (252),
      Meta (236), Atributos (resto).
    - Identidade: retrato 124x124, nome, card Jogador (fundo proprio,
      ENTRE nome e nivel), nivel com botoes -/+ 28x28, XP com barra.
    - Meta em 3 BLOCOS reais (nao lista solta): card Perfil (118px,
      3 linhas: Categoria/Tendencia/Proficiencia), grade 2x2 de
      numeros via UIGridLayout (108px: Desl/CA/RDM/Inic), card
      Equipado (96px, 3 linhas fixas mao-principal/torso/costas,
      cada uma so fica Visible se houver item de verdade).
    - Atributos: 2 fileiras rotuladas (FISICOS: FOR/DES/CON,
      MENTAIS E SOCIAIS: INT/SAB/PRE), cards de 150px FIXOS via
      UIFlexItem Fill, cor UNICA do tema (nao mais por atributo).

    Este arquivo e o "codigo fonte" desse template, pra 2 propositos:
    1) Documentar exatamente como ele foi construido (pra reconstruir
       do zero se algum dia se perder, ou pra quem clonar o repo sem
       o .rbxl ja populado).
    2) SEED inicial -- roda automaticamente no boot do servidor, mas
       SO CRIA a pasta se ela ainda nao existir. Depois da primeira
       vez, o Lucas/Design edita os objetos DIRETO no Explorer, e
       este script NUNCA MAIS toca neles (nao ha um "reset"
       automatico -- rodar de novo com a pasta ja existindo e um
       no-op, ver a guarda logo no comeco de Build()).

    ⚠️ IMPORTANTE pra quem for editar isso ou criar templates parecidos
    no Explorer manualmente: todo UIListLayout precisa ter
    SortOrder = Enum.SortOrder.LayoutOrder explicitamente -- o padrao
    do Roblox e Enum.SortOrder.Name (ordem alfabetica dos nomes dos
    objetos), NAO LayoutOrder. Bug real que ja aconteceu aqui (v2):
    os atributos apareciam em ordem alfabetica porque esse campo foi
    esquecido -- corrigido com um helper (listLayout) que sempre seta
    isso, usado em todo o arquivo.

    ⚠️ Se precisar VOLTAR ao layout original por engano ter estragado
    tudo, apague a pasta FichaUITemplates manualmente no Explorer e
    rode este builder de novo (ou reinicie o servidor).
]]

local FichaUITemplateBuilder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ALTURA_BLOCO = 340

local function corner(inst: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = inst
	return c
end

-- UIStroke nomeado "ThemeStroke": FichaUIClient.lua procura esse nome
-- especifico pra tingir com a cor da categoria de Nen via
-- Theme.register -- qualquer UIStroke com outro nome fica com a cor
-- fixa que voce der no Explorer.
local function themeStroke(inst: Instance, thickness: number?, transparency: number?)
	local s = Instance.new("UIStroke")
	s.Name = "ThemeStroke"
	s.Thickness = thickness or 1
	if transparency then
		s.Transparency = transparency
	end
	s.Parent = inst
	return s
end

-- Todo UIListLayout criado por este builder PRECISA de SortOrder =
-- LayoutOrder (ver aviso no topo do arquivo) -- centralizado aqui
-- pra nunca mais esquecer.
local function listLayout(parent: Instance, padding: number?, horizontal: boolean?)
	local l = Instance.new("UIListLayout")
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, padding or 0)
	if horizontal then
		l.FillDirection = Enum.FillDirection.Horizontal
	end
	l.Parent = parent
	return l
end

-- ImageLabel placeholder: Image="" (id 0) -- "o espaco fica vazio e
-- nada quebra" (brief §6). Cor tingida via Theme.register no client.
local function icone(parent: Instance, nome: string, tamanho: number, ordem: number?): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = nome
	icon.Image = ""
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset(tamanho, tamanho)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	if ordem then
		icon.LayoutOrder = ordem
	end
	icon.Parent = parent
	return icon
end

-- ================= COLUNA 1: IDENTIDADE (252 x 340) =================

local function buildIdentidade(root: Instance)
	local ident = Instance.new("Frame")
	ident.Name = "Identidade"
	ident.Size = UDim2.new(0, 252, 1, 0)
	ident.LayoutOrder = 1
	ident.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- tema 9%, tingido no client
	ident.Parent = root
	corner(ident, 10)
	themeStroke(ident, 1, 0.55)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 15)
	pad.PaddingBottom = UDim.new(0, 15)
	pad.PaddingLeft = UDim.new(0, 15)
	pad.PaddingRight = UDim.new(0, 15)
	pad.Parent = ident

	local col = Instance.new("Frame")
	col.Name = "Col"
	col.Size = UDim2.new(1, 0, 1, 0)
	col.BackgroundTransparency = 1
	col.Parent = ident
	listLayout(col, 10).HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- 1) Retrato 124x124
	local retrato = Instance.new("Frame")
	retrato.Name = "Retrato"
	retrato.Size = UDim2.fromOffset(124, 124)
	retrato.LayoutOrder = 1
	retrato.BackgroundTransparency = 1
	retrato.Parent = col
	themeStroke(retrato, 2)
	corner(retrato, 1000)
	local vpf = Instance.new("ViewportFrame")
	vpf.Name = "Avatar"
	vpf.Size = UDim2.new(1, 0, 1, 0)
	vpf.BackgroundTransparency = 1
	vpf.Parent = retrato

	-- 2) Nome
	local nomeLbl = Instance.new("TextLabel")
	nomeLbl.Name = "Nome"
	nomeLbl.Text = "Nome"
	nomeLbl.Font = Enum.Font.GothamBold
	nomeLbl.TextSize = 28
	nomeLbl.TextColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
	nomeLbl.TextXAlignment = Enum.TextXAlignment.Center
	nomeLbl.BackgroundTransparency = 1
	nomeLbl.Size = UDim2.new(1, 0, 0, 34)
	nomeLbl.LayoutOrder = 2
	nomeLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nomeLbl.Parent = col

	-- 3) Card Jogador (fundo proprio, ENTRE nome e nivel)
	local jog = Instance.new("Frame")
	jog.Name = "JogadorRow"
	jog.Size = UDim2.new(1, 0, 0, 34)
	jog.LayoutOrder = 3
	jog.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	jog.BackgroundTransparency = 0.98
	jog.Parent = col
	corner(jog, 8)
	local jogStroke = Instance.new("UIStroke")
	jogStroke.Color = Color3.fromRGB(255, 255, 255)
	jogStroke.Transparency = 0.91
	jogStroke.Parent = jog
	local jogPad = Instance.new("UIPadding")
	jogPad.PaddingTop = UDim.new(0, 8)
	jogPad.PaddingBottom = UDim.new(0, 8)
	jogPad.PaddingLeft = UDim.new(0, 10)
	jogPad.PaddingRight = UDim.new(0, 10)
	jogPad.Parent = jog
	local jogRow = Instance.new("Frame")
	jogRow.Name = "Row"
	jogRow.Size = UDim2.new(1, 0, 1, 0)
	jogRow.BackgroundTransparency = 1
	jogRow.Parent = jog
	local jogList = listLayout(jogRow, 8, true)
	jogList.VerticalAlignment = Enum.VerticalAlignment.Center
	icone(jogRow, "Icon", 16, 1)
	local jogLab = Instance.new("TextLabel")
	jogLab.Text = "JOGADOR"
	jogLab.Font = Enum.Font.Gotham
	jogLab.TextSize = 10
	jogLab.TextColor3 = Color3.fromRGB(150, 160, 156)
	jogLab.BackgroundTransparency = 1
	jogLab.Size = UDim2.fromOffset(70, 14)
	jogLab.TextXAlignment = Enum.TextXAlignment.Left
	jogLab.LayoutOrder = 2
	jogLab.Parent = jogRow
	local jogVal = Instance.new("TextLabel")
	jogVal.Name = "Jogador"
	jogVal.Text = "Jogador_01"
	jogVal.Font = Enum.Font.GothamBold
	jogVal.TextSize = 14
	jogVal.TextColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
	jogVal.BackgroundTransparency = 1
	jogVal.Size = UDim2.new(1, -94, 1, 0)
	jogVal.TextXAlignment = Enum.TextXAlignment.Right
	jogVal.TextTruncate = Enum.TextTruncate.AtEnd
	jogVal.LayoutOrder = 3
	jogVal.Parent = jogRow

	-- 4) Nivel: botao "-" 28x28, rotulo+valor, botao "+" 28x28
	local nivelRow = Instance.new("Frame")
	nivelRow.Name = "NivelRow"
	nivelRow.Size = UDim2.new(1, 0, 0, 28)
	nivelRow.BackgroundTransparency = 1
	nivelRow.LayoutOrder = 4
	nivelRow.Parent = col
	local nivelList = listLayout(nivelRow, 6, true)
	nivelList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	nivelList.VerticalAlignment = Enum.VerticalAlignment.Center

	local function botaoNivel(nome: string, texto: string, ordem: number)
		local b = Instance.new("TextButton")
		b.Name = nome
		b.Text = texto
		b.Font = Enum.Font.GothamBold
		b.TextSize = 16
		b.TextColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
		b.BackgroundTransparency = 0.85
		b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		b.AutoButtonColor = false
		b.Size = UDim2.fromOffset(28, 28)
		b.LayoutOrder = ordem
		b.Parent = nivelRow
		corner(b, 7)
		themeStroke(b)
		return b
	end
	-- ⚠️ Sem acao conectada ainda -- nivel sobe por XP (LevelUpService),
	-- nao existe um remote pra "forcar" nivel manualmente.
	botaoNivel("Menos", "-", 1)

	local nivelCol = Instance.new("Frame")
	nivelCol.Name = "NivelCol"
	nivelCol.Size = UDim2.fromOffset(90, 28)
	nivelCol.BackgroundTransparency = 1
	nivelCol.LayoutOrder = 2
	nivelCol.Parent = nivelRow
	listLayout(nivelCol).HorizontalAlignment = Enum.HorizontalAlignment.Center
	local nivelLab = Instance.new("TextLabel")
	nivelLab.Text = "NÍVEL"
	nivelLab.Font = Enum.Font.Gotham
	nivelLab.TextSize = 12
	nivelLab.TextColor3 = Color3.fromRGB(150, 160, 156)
	nivelLab.BackgroundTransparency = 1
	nivelLab.Size = UDim2.new(1, 0, 0, 14)
	nivelLab.TextXAlignment = Enum.TextXAlignment.Center
	nivelLab.LayoutOrder = 1
	nivelLab.Parent = nivelCol
	local nivelVal = Instance.new("TextLabel")
	nivelVal.Name = "Nivel"
	nivelVal.Text = "6/12"
	nivelVal.Font = Enum.Font.Code
	nivelVal.TextSize = 16
	nivelVal.TextColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
	nivelVal.BackgroundTransparency = 1
	nivelVal.Size = UDim2.new(1, 0, 0, 18)
	nivelVal.TextXAlignment = Enum.TextXAlignment.Center
	nivelVal.LayoutOrder = 2
	nivelVal.Parent = nivelCol

	botaoNivel("Mais", "+", 3)

	-- 5) XP: label esq + valor dir, barra abaixo
	local xpHolder = Instance.new("Frame")
	xpHolder.Name = "XPRow"
	xpHolder.Size = UDim2.new(1, 0, 0, 26)
	xpHolder.BackgroundTransparency = 1
	xpHolder.LayoutOrder = 5
	xpHolder.Parent = col
	listLayout(xpHolder, 4)

	local xpTop = Instance.new("Frame")
	xpTop.Name = "Top"
	xpTop.Size = UDim2.new(1, 0, 0, 14)
	xpTop.BackgroundTransparency = 1
	xpTop.LayoutOrder = 1
	xpTop.Parent = xpHolder
	listLayout(xpTop, 0, true)
	local xpLab = Instance.new("TextLabel")
	xpLab.Text = "XP"
	xpLab.Font = Enum.Font.Gotham
	xpLab.TextSize = 11
	xpLab.TextColor3 = Color3.fromRGB(150, 160, 156)
	xpLab.BackgroundTransparency = 1
	xpLab.Size = UDim2.new(0.5, 0, 1, 0)
	xpLab.TextXAlignment = Enum.TextXAlignment.Left
	xpLab.LayoutOrder = 1
	xpLab.Parent = xpTop
	local xpVal = Instance.new("TextLabel")
	xpVal.Name = "XP"
	xpVal.Text = "300 / 1500"
	xpVal.Font = Enum.Font.Code
	xpVal.TextSize = 11
	xpVal.TextColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
	xpVal.BackgroundTransparency = 1
	xpVal.Size = UDim2.new(0.5, 0, 1, 0)
	xpVal.TextXAlignment = Enum.TextXAlignment.Right
	xpVal.LayoutOrder = 2
	xpVal.Parent = xpTop

	local xpBarBg = Instance.new("Frame")
	xpBarBg.Name = "BarBg"
	xpBarBg.Size = UDim2.new(1, 0, 0, 6)
	xpBarBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	xpBarBg.BackgroundTransparency = 0.93
	xpBarBg.LayoutOrder = 2
	xpBarBg.Parent = xpHolder
	corner(xpBarBg, 3)
	local xpFill = Instance.new("Frame")
	xpFill.Name = "Fill"
	xpFill.Size = UDim2.new(0.2, 0, 1, 0)
	xpFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
	xpFill.BorderSizePixel = 0
	xpFill.Parent = xpBarBg
	corner(xpFill, 3)
end

-- ================= COLUNA 2: META (236 x 340) =================

local function linhaPerfil(perfilCol: Instance, nome: string, rotulo: string, valor: string, ordem: number)
	local row = Instance.new("Frame")
	row.Name = nome
	row.Size = UDim2.new(1, 0, 0, 30)
	row.LayoutOrder = ordem
	row.BackgroundTransparency = 1
	row.Parent = perfilCol
	local rowList = listLayout(row, 10, true)
	rowList.VerticalAlignment = Enum.VerticalAlignment.Center
	icone(row, "Icon", 18, 1)
	local col2 = Instance.new("Frame")
	col2.Name = "Col"
	col2.Size = UDim2.new(1, -26, 1, 0)
	col2.BackgroundTransparency = 1
	col2.LayoutOrder = 2
	col2.Parent = row
	listLayout(col2, 0)
	local lab = Instance.new("TextLabel")
	lab.Text = rotulo
	lab.Font = Enum.Font.Gotham
	lab.TextSize = 10
	lab.TextColor3 = Color3.fromRGB(150, 160, 156)
	lab.BackgroundTransparency = 1
	lab.Size = UDim2.new(1, 0, 0, 12)
	lab.TextXAlignment = Enum.TextXAlignment.Left
	lab.LayoutOrder = 1
	lab.Parent = col2
	local val = Instance.new("TextLabel")
	val.Name = "Valor"
	val.Text = valor
	val.Font = Enum.Font.GothamBold
	val.TextSize = 14
	val.TextColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
	val.BackgroundTransparency = 1
	val.Size = UDim2.new(1, 0, 0, 16)
	val.TextXAlignment = Enum.TextXAlignment.Left
	val.LayoutOrder = 2
	val.Parent = col2
end

local function quadroNumero(nums: Instance, nome: string, rotulo: string, valor: string, ordem: number)
	local q = Instance.new("Frame")
	q.Name = nome
	q.LayoutOrder = ordem
	q.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	q.Parent = nums
	corner(q, 10)
	themeStroke(q, 1, 0.55)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 9)
	pad.PaddingBottom = UDim.new(0, 9)
	pad.PaddingLeft = UDim.new(0, 9)
	pad.PaddingRight = UDim.new(0, 9)
	pad.Parent = q
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.Size = UDim2.new(1, 0, 1, 0)
	row.BackgroundTransparency = 1
	row.Parent = q
	local rowList = listLayout(row, 8, true)
	rowList.VerticalAlignment = Enum.VerticalAlignment.Center
	icone(row, "Icon", 16, 1)
	local col = Instance.new("Frame")
	col.Name = "Col"
	col.Size = UDim2.new(1, -24, 1, 0)
	col.BackgroundTransparency = 1
	col.LayoutOrder = 2
	col.Parent = row
	listLayout(col, 0)
	local lab = Instance.new("TextLabel")
	lab.Text = rotulo
	lab.Font = Enum.Font.Gotham
	lab.TextSize = 10
	lab.TextColor3 = Color3.fromRGB(150, 160, 156)
	lab.BackgroundTransparency = 1
	lab.Size = UDim2.new(1, 0, 0, 12)
	lab.TextXAlignment = Enum.TextXAlignment.Left
	lab.LayoutOrder = 1
	lab.Parent = col
	local val = Instance.new("TextLabel")
	val.Name = "Valor"
	val.Text = valor
	val.Font = Enum.Font.GothamBold
	val.TextSize = 14
	val.TextColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
	val.BackgroundTransparency = 1
	val.Size = UDim2.new(1, 0, 0, 16)
	val.TextXAlignment = Enum.TextXAlignment.Left
	val.LayoutOrder = 2
	val.Parent = col
end

local function linhaEquip(eqCol: Instance, nome: string, ordem: number)
	local row = Instance.new("Frame")
	row.Name = nome
	row.Size = UDim2.new(1, 0, 0, 16)
	row.LayoutOrder = ordem
	row.BackgroundTransparency = 1
	row.Parent = eqCol
	listLayout(row, 6, true)
	local n = Instance.new("TextLabel")
	n.Name = "Nome"
	n.Text = ""
	n.Font = Enum.Font.GothamBold
	n.TextSize = 12
	n.TextColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
	n.BackgroundTransparency = 1
	n.Size = UDim2.fromOffset(140, 14)
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.TextTruncate = Enum.TextTruncate.AtEnd
	n.LayoutOrder = 1
	n.Parent = row
	local stat = Instance.new("TextLabel")
	stat.Name = "Stat"
	stat.Text = ""
	stat.Font = Enum.Font.Code
	stat.TextSize = 10
	stat.TextColor3 = Color3.fromRGB(150, 160, 156)
	stat.BackgroundTransparency = 1
	stat.Size = UDim2.new(1, -146, 1, 0)
	stat.TextXAlignment = Enum.TextXAlignment.Right
	stat.LayoutOrder = 2
	stat.Parent = row
end

local function buildMeta(root: Instance)
	local meta = Instance.new("Frame")
	meta.Name = "Meta"
	meta.Size = UDim2.new(0, 236, 1, 0)
	meta.LayoutOrder = 2
	meta.BackgroundTransparency = 1
	meta.Parent = root
	listLayout(meta, 9)

	-- ===== BLOCO A: card Perfil, 118px (Categoria/Tendencia/Proficiencia) =====
	local perfil = Instance.new("Frame")
	perfil.Name = "Perfil"
	perfil.Size = UDim2.new(1, 0, 0, 118)
	perfil.LayoutOrder = 1
	perfil.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	perfil.Parent = meta
	corner(perfil, 10)
	themeStroke(perfil, 1, 0.55)
	local perfilPad = Instance.new("UIPadding")
	perfilPad.PaddingTop = UDim.new(0, 11)
	perfilPad.PaddingBottom = UDim.new(0, 11)
	perfilPad.PaddingLeft = UDim.new(0, 11)
	perfilPad.PaddingRight = UDim.new(0, 11)
	perfilPad.Parent = perfil
	local perfilCol = Instance.new("Frame")
	perfilCol.Name = "Col"
	perfilCol.Size = UDim2.new(1, 0, 1, 0)
	perfilCol.BackgroundTransparency = 1
	perfilCol.Parent = perfil
	listLayout(perfilCol, 0)

	linhaPerfil(perfilCol, "Categoria", "CATEGORIA", "Intensificação", 1)
	linhaPerfil(perfilCol, "Tendencia", "TENDÊNCIA", "Heroico", 2)
	linhaPerfil(perfilCol, "Proficiencia", "PROFICIÊNCIA", "+2", 3)

	-- ===== BLOCO B: grade 2x2 de numeros, 108px (Desl/CA/RDM/Inic) =====
	local nums = Instance.new("Frame")
	nums.Name = "Numeros"
	nums.Size = UDim2.new(1, 0, 0, 108)
	nums.LayoutOrder = 2
	nums.BackgroundTransparency = 1
	nums.Parent = meta
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(112, 50)
	grid.CellPadding = UDim2.fromOffset(9, 9)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = nums

	quadroNumero(nums, "Deslocamento", "DESL.", "9m", 1)
	quadroNumero(nums, "CA", "CA", "16", 2)
	quadroNumero(nums, "RDM", "RDM", "4", 3)
	quadroNumero(nums, "Iniciativa", "INIC.", "+2", 4)

	-- ===== BLOCO C: card Equipado, 96px =====
	local equip = Instance.new("Frame")
	equip.Name = "Equipado"
	equip.Size = UDim2.new(1, 0, 0, 96)
	equip.LayoutOrder = 3
	equip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	equip.Parent = meta
	corner(equip, 10)
	themeStroke(equip, 1, 0.55)
	local eqPad = Instance.new("UIPadding")
	eqPad.PaddingTop = UDim.new(0, 11)
	eqPad.PaddingBottom = UDim.new(0, 11)
	eqPad.PaddingLeft = UDim.new(0, 11)
	eqPad.PaddingRight = UDim.new(0, 11)
	eqPad.Parent = equip
	local eqCol = Instance.new("Frame")
	eqCol.Name = "Col"
	eqCol.Size = UDim2.new(1, 0, 1, 0)
	eqCol.BackgroundTransparency = 1
	eqCol.Parent = equip
	listLayout(eqCol, 6)
	local eqLab = Instance.new("TextLabel")
	eqLab.Name = "Titulo"
	eqLab.Text = "EQUIPADO"
	eqLab.Font = Enum.Font.Gotham
	eqLab.TextSize = 10
	eqLab.TextColor3 = Color3.fromRGB(150, 160, 156)
	eqLab.BackgroundTransparency = 1
	eqLab.Size = UDim2.new(1, 0, 0, 12)
	eqLab.TextXAlignment = Enum.TextXAlignment.Left
	eqLab.LayoutOrder = 1
	eqLab.Parent = eqCol

	-- 3 linhas fixas (mao principal/torso/costas) -- visibilidade
	-- controlada pelo cliente conforme o que estiver equipado (so
	-- itens "relevantes", ver brief §4.2 Bloco C).
	linhaEquip(eqCol, "MaoPrincipal", 2)
	linhaEquip(eqCol, "Torso", 3)
	linhaEquip(eqCol, "Costas", 4)
end

-- ================= COLUNA 3: ATRIBUTOS (resto x 340) =================
-- Cor UNICA do tema pra TODOS os 6 atributos (correcao do brief: nao
-- existe cor por atributo -- so a sigla e cinza porque e ROTULO, o
-- resto -- icones/valor/mod/TR -- segue a cor da categoria de Nen).

local function buildAttrCard(parent: Instance, sigla: string, ordem: number)
	local card = Instance.new("Frame")
	card.Name = "Attr_" .. sigla
	card.LayoutOrder = ordem
	card.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- tema 9%
	card.Parent = parent
	corner(card, 10)
	themeStroke(card, 1, 0.55)
	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = card

	local col = Instance.new("Frame")
	col.Name = "Col"
	col.Size = UDim2.new(1, 0, 1, 0)
	col.BackgroundTransparency = 1
	col.Parent = card
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 11)
	pad.PaddingBottom = UDim.new(0, 11)
	pad.PaddingLeft = UDim.new(0, 11)
	pad.PaddingRight = UDim.new(0, 11)
	pad.Parent = col
	listLayout(col, 6).HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- 1) Sigla -- CINZA, e rotulo (nao segue a cor do tema)
	local siglaLbl = Instance.new("TextLabel")
	siglaLbl.Name = "Sigla"
	siglaLbl.Text = sigla
	siglaLbl.Font = Enum.Font.GothamBold
	siglaLbl.TextSize = 15
	siglaLbl.TextColor3 = Color3.fromRGB(150, 160, 156)
	siglaLbl.BackgroundTransparency = 1
	siglaLbl.Size = UDim2.new(1, 0, 0, 18)
	siglaLbl.TextXAlignment = Enum.TextXAlignment.Center
	siglaLbl.LayoutOrder = 1
	siglaLbl.Parent = col

	-- 2) Dois icones 26px, gap 10, cor tema
	local icones = Instance.new("Frame")
	icones.Name = "Icones"
	icones.Size = UDim2.new(1, 0, 0, 26)
	icones.BackgroundTransparency = 1
	icones.LayoutOrder = 2
	icones.Parent = col
	local iconesList = listLayout(icones, 10, true)
	iconesList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	icone(icones, "Icon1", 26, 1)
	icone(icones, "Icon2", 26, 2)

	-- 3) Valor
	local valorLbl = Instance.new("TextLabel")
	valorLbl.Name = "Valor"
	valorLbl.Text = "10"
	valorLbl.Font = Enum.Font.Code
	valorLbl.TextSize = 32
	valorLbl.TextColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
	valorLbl.BackgroundTransparency = 1
	valorLbl.Size = UDim2.new(1, 0, 0, 36)
	valorLbl.TextXAlignment = Enum.TextXAlignment.Center
	valorLbl.LayoutOrder = 3
	valorLbl.Parent = col

	-- 4) Modificador
	local modLbl = Instance.new("TextLabel")
	modLbl.Name = "Mod"
	modLbl.Text = "(+0)"
	modLbl.Font = Enum.Font.Code
	modLbl.TextSize = 15
	modLbl.TextColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
	modLbl.BackgroundTransparency = 1
	modLbl.Size = UDim2.new(1, 0, 0, 18)
	modLbl.TextXAlignment = Enum.TextXAlignment.Center
	modLbl.LayoutOrder = 4
	modLbl.Parent = col

	-- 5) Linha TR
	local trRow = Instance.new("Frame")
	trRow.Name = "TRRow"
	trRow.Size = UDim2.new(1, 0, 0, 20)
	trRow.BackgroundTransparency = 1
	trRow.LayoutOrder = 5
	trRow.Parent = col
	listLayout(trRow, 4, true).HorizontalAlignment = Enum.HorizontalAlignment.Center
	icone(trRow, "Icon", 15, 1)
	local trVal = Instance.new("TextLabel")
	trVal.Name = "TR"
	trVal.Text = "+0"
	trVal.Font = Enum.Font.Code
	trVal.TextSize = 14
	trVal.TextColor3 = Color3.fromRGB(255, 255, 255) -- tingido via Theme.register
	trVal.BackgroundTransparency = 1
	trVal.Size = UDim2.fromOffset(36, 18)
	trVal.LayoutOrder = 2
	trVal.Parent = trRow
end

local function criarFileira(attrCol: Instance, nome: string, rotulo: string, ordem: number, siglas: { string })
	local head = Instance.new("TextLabel")
	head.Name = nome .. "Label"
	head.Text = rotulo
	head.Font = Enum.Font.Gotham
	head.TextSize = 10
	head.TextColor3 = Color3.fromRGB(150, 160, 156)
	head.BackgroundTransparency = 1
	head.Size = UDim2.new(1, 0, 0, 14)
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.LayoutOrder = ordem
	head.Parent = attrCol

	local row = Instance.new("Frame")
	row.Name = nome
	row.Size = UDim2.new(1, 0, 0, 150)
	row.LayoutOrder = ordem + 1
	row.BackgroundTransparency = 1
	row.Parent = attrCol
	local rowList = listLayout(row, 9, true)
	rowList.HorizontalFlex = Enum.UIFlexAlignment.Fill

	for i, sigla in ipairs(siglas) do
		buildAttrCard(row, sigla, i)
	end
end

local function buildAttrGrid(root: Instance)
	local attrCol = Instance.new("Frame")
	attrCol.Name = "AttrGrid"
	attrCol.Size = UDim2.new(1, -518, 1, 0) -- resto (252+236+2*12 gaps=512, ajustavel no Explorer)
	attrCol.LayoutOrder = 3
	attrCol.BackgroundTransparency = 1
	attrCol.Parent = root
	listLayout(attrCol, 9)

	criarFileira(attrCol, "Fisicos", "FÍSICOS", 1, { "FOR", "DES", "CON" })
	criarFileira(attrCol, "Mentais", "MENTAIS E SOCIAIS", 3, { "INT", "SAB", "PRE" })
end

-- So constroi se a pasta ainda NAO existir -- rodar de novo com ela
-- ja la e um no-op, pra nunca sobrescrever edicoes feitas no Explorer.
--
-- ⚠️ FichaUITemplates precisa ser um ScreenGui, NAO um Folder -- o
-- editor visual do Studio (o canvas onde da pra arrastar/redimensionar
-- elementos de UI) so consegue mostrar e editar objetos que estao
-- dentro de um ScreenGui. Um Folder comum (como estava antes) faz o
-- conteudo ficar "invisivel" no Studio mesmo com os objetos certos la
-- dentro -- bug real que o Lucas relatou (nao conseguia ver o
-- template no canvas pra editar). Enabled=false garante que isso
-- nunca renderiza de verdade (fica em ReplicatedStorage, so serve de
-- molde pra clonar) -- Studio edita normalmente mesmo com Enabled=false.
function FichaUITemplateBuilder.Build()
	local hxh5e = ReplicatedStorage:WaitForChild("HxH5e")
	if hxh5e:FindFirstChild("FichaUITemplates") then
		return false -- ja existe, nao mexe
	end

	local templates = Instance.new("ScreenGui")
	templates.Name = "FichaUITemplates"
	templates.Enabled = false
	templates.ResetOnSpawn = false
	templates.Parent = hxh5e

	local root = Instance.new("Frame")
	root.Name = "FichaTabRow"
	root.Size = UDim2.new(1, 0, 0, ALTURA_BLOCO)
	root.BackgroundTransparency = 1
	root.Parent = templates
	listLayout(root, 12, true)

	buildIdentidade(root)
	buildMeta(root)
	buildAttrGrid(root)

	return true
end

return FichaUITemplateBuilder
