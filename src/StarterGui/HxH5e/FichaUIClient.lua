--!strict
-- FichaUIClient — monta o HUD fixo e a ficha com as cinco abas.
-- LocalScript. Abrir/fechar a ficha: tecla M (ou toque no botão do HUD).
--
-- Regras de cor:
--   rótulo   -> Theme.Muted (neutro, nunca muda)
--   descrição-> cor da categoria de Nen (Theme.register)
--   vitais   -> cor própria, imune ao tema, e vivem no HUD, fora da ficha

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.FichaUITheme)
local Icons = require(script.Parent.FichaUIIcons)
local W = require(script.Parent.FichaUIWidgets)
local Data = require(script.Parent.FichaUIData)
local HxH5e = ReplicatedStorage:WaitForChild("HxH5e")

local player = Players.LocalPlayer
local ficha, doServidor = Data.carregar()
Theme.setCategory(ficha.Categoria)
local v = ficha.Vitals -- usado em varios lugares (aba FICHA, popovers, etc) --
-- antes vinha do bloco do Hud (removido: o Lucas monta a barra
-- inferior manualmente agora), movido pra ca pra continuar acessivel.

local DESIGN_W, DESIGN_H = 1220, 780 -- brief do Design (BRIEF-FichaUI.md): canvas 1220x780. Voltou de 660 porque a aba FICHA agora tem 340px de altura de novo (identidade+atributos), seguindo as medidas exatas do brief.

local gui = Instance.new("ScreenGui")
gui.Name = "HxH5eFicha"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

------------------------------------------------------------------------ FICHA

local sheetHolder = W.frame(gui, UDim2.fromOffset(DESIGN_W, DESIGN_H), "SheetHolder")
sheetHolder.AnchorPoint = Vector2.new(0.5, 0.5)
sheetHolder.Position = UDim2.fromScale(0.5, 0.47)
sheetHolder.Visible = false

local escala = Instance.new("UIScale")
escala.Parent = sheetHolder

local function ajustarEscala()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	-- Antes: math.min(1, ...) travava a ficha no tamanho "real" de 1220x780px,
	-- que fica minusculo numa tela grande (bug reportado pelo Lucas). Agora
	-- a ficha ocupa ~92% da largura e ~88% da altura disponiveis, com um teto
	-- de 2x pra nao ficar gigante/borrada em telas muito grandes (4K etc).
	local escalaX = (vp.X * 0.92) / DESIGN_W
	local escalaY = (vp.Y * 0.88) / DESIGN_H
	escala.Scale = math.clamp(math.min(escalaX, escalaY), 0.5, 2.0)
end
ajustarEscala()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarEscala)
end

local sheet = W.frame(sheetHolder, UDim2.new(1, 0, 1, 0), "Sheet")
sheet.BackgroundColor3 = Theme.Panel
sheet.BackgroundTransparency = 0.04
W.corner(sheet, 12)
W.stroke(sheet, 0.22)
W.pad(sheet, 20)

local sheetCol = W.frame(sheet, UDim2.new(1, 0, 1, 0), "Col")
W.list(sheetCol, 13)

-- Barra de abas
local tabBar = W.frame(sheetCol, UDim2.new(1, 0, 0, 42), "TabBar")
tabBar.LayoutOrder = 1
local tabInner = W.frame(tabBar, UDim2.fromOffset(700, 42), "Inner")
tabInner.AnchorPoint = Vector2.new(0.5, 0)
tabInner.Position = UDim2.fromScale(0.5, 0)
Theme.register(tabInner, "BackgroundColor3", 0.05)
tabInner.BackgroundTransparency = 0
W.corner(tabInner, 8)
W.stroke(tabInner, 0.35)
W.list(tabInner, 2, Enum.FillDirection.Horizontal).HorizontalAlignment = Enum.HorizontalAlignment.Center

local paginas = W.frame(sheetCol, UDim2.new(1, 0, 1, -55), "Paginas")
paginas.LayoutOrder = 2

local abas = { "FICHA", "BIO", "NEN", "TRAÇOS", "INV" }
local botoesAba: { [string]: TextButton } = {}
local frames: { [string]: Frame } = {}
local abaAtual = "FICHA"

local function mostrarAba(nome: string)
	abaAtual = nome
	for chave, frame in pairs(frames) do
		frame.Visible = (chave == nome)
	end
	for chave, botao in pairs(botoesAba) do
		local ativo = (chave == nome)
		botao.BackgroundTransparency = if ativo then 0 else 1
		botao.TextColor3 = if ativo then Theme.Accent else Theme.Muted
		botao.Font = if ativo then Theme.FontTitle else Theme.FontBody
	end
end

for i, nome in ipairs(abas) do
	local b = Instance.new("TextButton")
	b.Name = "Tab" .. nome
	b.Size = UDim2.fromOffset(138, 42)
	b.LayoutOrder = i
	b.Text = nome
	b.Font = Theme.FontBody
	b.TextSize = 16
	b.TextColor3 = Theme.Muted
	b.AutoButtonColor = false
	b.BackgroundTransparency = 1
	Theme.register(b, "BackgroundColor3", 0.16)
	b.Parent = tabInner
	b.MouseButton1Click:Connect(function() mostrarAba(nome) end)
	botoesAba[nome] = b

	local pag = W.frame(paginas, UDim2.new(1, 0, 1, 0), "Pagina" .. nome)
	pag.Visible = false
	frames[nome] = pag
end

------------------------------------------------------------------- ABA: FICHA
-- Formato hibrido (pedido do Lucas): as 3 colunas (Identidade / Meta /
-- Atributos) vem de um TEMPLATE real, editavel no Explorer
-- (ReplicatedStorage.HxH5e.FichaUITemplates.FichaTabRow) -- tamanho,
-- posicao, fonte e cor de cada peca dao pra ajustar la direto, sem
-- mexer em codigo. Esse script so CLONA o molde e PREENCHE os valores
-- reais do personagem nos elementos ja nomeados dentro dele.
-- Medidas e regras de cor seguem o brief do Design (BRIEF-FichaUI.md):
-- 252 / 236 / resto de largura, 340px de altura, os 6 atributos usam a
-- MESMA cor (a da categoria de Nen) -- nao cor propria por atributo.

do
	local pag = frames.FICHA
	local col = W.frame(pag, UDim2.new(1, 0, 1, 0), "Col")
	W.list(col, 12)

	local templateFolder = ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("FichaUITemplates")
	local row = templateFolder.FichaTabRow:Clone()
	row.LayoutOrder = 1
	row.Parent = col

	-- Tinge com a cor da categoria de Nen TUDO que tiver o UIStroke
	-- "ThemeStroke" e todo fundo/texto marcado como "valor" -- os 6
	-- atributos incluidos, de proposito (brief: "os seis atributos
	-- usam a MESMA cor: a da categoria de Nen").
	for _, desc in ipairs(row:GetDescendants()) do
		if desc:IsA("UIStroke") and desc.Name == "ThemeStroke" then
			Theme.register(desc, "Color")
		end
	end
	Theme.register(row.Identidade, "BackgroundColor3", 0.09)
	Theme.register(row.Identidade.Col.Nome, "TextColor3")
	Theme.register(row.Identidade.Col.JogadorRow.Row.Jogador, "TextColor3")
	Theme.register(row.Identidade.Col.JogadorRow.Row.Icon, "ImageColor3")
	Theme.register(row.Identidade.Col.NivelRow.NivelCol.Nivel, "TextColor3")
	Theme.register(row.Identidade.Col.NivelRow.Menos, "TextColor3")
	Theme.register(row.Identidade.Col.NivelRow.Mais, "TextColor3")
	Theme.register(row.Identidade.Col.XPRow.Top.XP, "TextColor3")
	Theme.register(row.Identidade.Col.XPRow.BarBg.Fill, "BackgroundColor3")

	row.Identidade.Col.Nome.Text = ficha.Nome
	row.Identidade.Col.JogadorRow.Row.Jogador.Text = ficha.Jogador
	row.Identidade.Col.NivelRow.NivelCol.Nivel.Text = string.format("%d/12", ficha.Nivel)
	row.Identidade.Col.XPRow.Top.XP.Text = string.format("%d / %d", ficha.XP, ficha.XPProximo)
	row.Identidade.Col.XPRow.BarBg.Fill.Size = UDim2.fromScale(math.clamp(ficha.XP / math.max(1, ficha.XPProximo), 0, 1), 1)
	-- Botoes -/+ de nivel: sem acao ainda -- nivel sobe por XP (LevelUpService),
	-- nao existe um remote pra "forcar" nivel manualmente.

	-- ================= META: 3 blocos =================
	local perfilCol = row.Meta.Perfil.Col
	Theme.register(perfilCol.Categoria.Col.Valor, "TextColor3")
	Theme.register(perfilCol.Categoria.Icon, "ImageColor3")
	Theme.register(perfilCol.Tendencia.Col.Valor, "TextColor3")
	Theme.register(perfilCol.Tendencia.Icon, "ImageColor3")
	Theme.register(perfilCol.Proficiencia.Col.Valor, "TextColor3")
	Theme.register(perfilCol.Proficiencia.Icon, "ImageColor3")
	perfilCol.Categoria.Col.Valor.Text = ficha.Categoria
	perfilCol.Tendencia.Col.Valor.Text = ficha.Tendencia
	perfilCol.Proficiencia.Col.Valor.Text = string.format("+%d", ficha.Proficiencia)

	for _, nomeQuadro in ipairs({ "Deslocamento", "CA", "RDM", "Iniciativa" }) do
		local q = row.Meta.Numeros[nomeQuadro]
		Theme.register(q.Row.Col.Valor, "TextColor3")
		Theme.register(q.Row.Icon, "ImageColor3")
	end
	row.Meta.Numeros.Deslocamento.Row.Col.Valor.Text = ficha.Deslocamento
	row.Meta.Numeros.CA.Row.Col.Valor.Text = tostring(v.CA)
	row.Meta.Numeros.RDM.Row.Col.Valor.Text = tostring(v.RDM)
	row.Meta.Numeros.Iniciativa.Row.Col.Valor.Text = string.format("%+d", v.Iniciativa)

	-- Equipado: so mostra as linhas que tem item de verdade (mao
	-- principal / torso / costas) -- o resto some (brief: "uma linha
	-- por item equipado relevante").
	local eqCol = row.Meta.Equipado.Col
	local eqMap = { MaoPrincipal = "maoPrincipal", Torso = "torso", Costas = "costas" }
	for nomeLinha, chave in pairs(eqMap) do
		local item = ficha.Equipado[chave]
		local linha = eqCol[nomeLinha]
		if item then
			local def = ficha.Itens[item] or {}
			linha.Visible = true
			linha.Nome.Text = item
			linha.Stat.Text = def.detalhe or ""
			Theme.register(linha.Nome, "TextColor3")
		else
			linha.Visible = false
		end
	end

	-- ================= ATRIBUTOS (cor UNICA do tema, sigla cinza) =================
	local popover: Frame? = nil
	local function fecharPopover()
		if popover then popover:Destroy() end
		popover = nil
	end

	for _, attr in ipairs(ficha.Atributos) do
		local linha = if attr.grupo == "fisico" then row.AttrGrid.Fisicos else row.AttrGrid.Mentais
		local card = linha:FindFirstChild("Attr_" .. attr.sigla)
		if card then
			Theme.register(card.Col.Valor, "TextColor3")
			Theme.register(card.Col.Mod, "TextColor3")
			Theme.register(card.Col.TRRow.TR, "TextColor3")
			Theme.register(card.Col.TRRow.Icon, "ImageColor3")
			Theme.register(card.Col.Icones.Icon1, "ImageColor3")
			Theme.register(card.Col.Icones.Icon2, "ImageColor3")
			card.Col.Valor.Text = tostring(attr.valor)
			card.Col.Mod.Text = string.format("(%+d)", attr.mod)
			card.Col.TRRow.TR.Text = string.format("%+d", attr.tr)

			-- Pericias no hover, como antes
			local hit = Instance.new("TextButton")
			hit.BackgroundTransparency = 1
			hit.Text = ""
			hit.Size = UDim2.new(1, 0, 1, 0)
			hit.ZIndex = 2
			hit.Parent = card
			hit.MouseEnter:Connect(function()
				fecharPopover()
				local lista = ficha.Pericias[attr.sigla] or {}
				local altura = 34 + math.max(1, #lista) * 18
				local p = W.frame(sheet, UDim2.fromOffset(230, altura), "Popover")
				p.BackgroundColor3 = Theme.Popover
				p.BackgroundTransparency = 0
				p.ZIndex = 50
				W.corner(p, 9)
				W.stroke(p, 0.45)
				W.pad(p, 11)
				local pcol = W.frame(p, UDim2.new(1, 0, 1, 0), "Col")
				W.list(pcol, 5)
				W.label(pcol, "PERÍCIAS DE " .. string.upper(attr.nome), 9)
				if #lista == 0 then
					local nota = W.label(pcol, "Sem perícias — entra em TR de veneno, exaustão e afogamento.", 12)
					nota.Size = UDim2.new(1, 0, 0, 34)
					nota.TextWrapped = true
				else
					for _, per in ipairs(lista) do
						local prow = W.frame(pcol, UDim2.new(1, 0, 0, 16), per[1])
						W.list(prow, 4, Enum.FillDirection.Horizontal)
						local treinada = per[3]
						local n = W.label(prow, (if treinada then "● " else "") .. per[1], 12)
						n.Size = UDim2.fromOffset(150, 14)
						if treinada then Theme.register(n, "TextColor3") end
						local b = W.mono(prow, string.format("%+d", per[2]), 12)
						b.Size = UDim2.fromOffset(46, 14)
						b.TextXAlignment = Enum.TextXAlignment.Right
					end
				end
				local abs = card.AbsolutePosition - sheet.AbsolutePosition
				local acimaDoCard = (linha == row.AttrGrid.Mentais)
				local y = if acimaDoCard then abs.Y - altura - 6 else abs.Y + card.AbsoluteSize.Y + 6
				p.Position = UDim2.fromOffset(abs.X, y)
				popover = p
			end)
			hit.MouseLeave:Connect(fecharPopover)
		end
	end

	-- Faixa TREINADAS: so existe se houver ao menos 1 pericia treinada
	-- (brief: "Se nao houver nenhuma treinada, nao criar a faixa").
	local algumaTreinada = false
	for _, lista in pairs(ficha.Pericias) do
		for _, per in ipairs(lista) do
			if per[3] then algumaTreinada = true break end
		end
		if algumaTreinada then break end
	end
	if algumaTreinada then
		local treinadas = W.card(col, UDim2.new(1, 0, 0, 36), "Treinadas")
		treinadas.LayoutOrder = 2
		W.pad(treinadas, 9, { left = 12, right = 12 })
		local trRow = W.frame(treinadas, UDim2.new(1, 0, 1, 0), "Row")
		W.list(trRow, 12, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
		local trLab = W.label(trRow, "TREINADAS", 10)
		trLab.Size = UDim2.fromOffset(78, 12)
		for sigla, lista in pairs(ficha.Pericias) do
			for _, per in ipairs(lista) do
				if per[3] then
					local t = W.value(trRow, string.format("%s %+d", per[1], per[2]), 12)
					t.Size = UDim2.fromOffset(118, 14)
				end
			end
		end
	end
end

--------------------------------------------------------------------- ABA: NEN

do
	local pag = frames.NEN
	local col = W.frame(pag, UDim2.new(1, 0, 1, 0), "Col")
	W.list(col, 12)

	-- Sub-abas
	local subBar = W.frame(col, UDim2.new(1, 0, 0, 32), "SubBar")
	subBar.LayoutOrder = 1
	W.list(subBar, 7, Enum.FillDirection.Horizontal)

	local corpo = W.frame(col, UDim2.new(1, 0, 1, -44), "Corpo")
	corpo.LayoutOrder = 2

	local pgPrincipios = W.frame(corpo, UDim2.new(1, 0, 1, 0), "Principios")
	local pgHatsus = W.frame(corpo, UDim2.new(1, 0, 1, 0), "Hatsus")
	pgHatsus.Visible = false

	local subBotoes: { [string]: TextButton } = {}
	local function mostrarSub(nome: string)
		pgPrincipios.Visible = (nome == "PRINCÍPIOS")
		pgHatsus.Visible = (nome == "HATSUS")
		for chave, b in pairs(subBotoes) do
			b.BackgroundTransparency = if chave == nome then 0 else 1
		end
	end
	for i, nome in ipairs({ "PRINCÍPIOS", "HATSUS" }) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(150, 32)
		b.LayoutOrder = i
		b.Text = nome
		b.Font = Theme.FontTitle
		b.TextSize = 12
		b.AutoButtonColor = false
		b.BackgroundTransparency = 1
		Theme.register(b, "TextColor3")
		Theme.register(b, "BackgroundColor3", 0.16)
		W.corner(b, 7)
		W.stroke(b, 0.35)
		b.Parent = subBar
		b.MouseButton1Click:Connect(function() mostrarSub(nome) end)
		subBotoes[nome] = b
	end

	local pnInfo = W.frame(subBar, UDim2.fromOffset(280, 32), "PN")
	pnInfo.LayoutOrder = 3
	Theme.register(pnInfo, "BackgroundColor3", 0.05)
	pnInfo.BackgroundTransparency = 0
	W.corner(pnInfo, 7)
	W.stroke(pnInfo, 0.3)
	W.pad(pnInfo, 8, { left = 12, right = 12 })
	local pnRow = W.frame(pnInfo, UDim2.new(1, 0, 1, 0), "Row")
	W.list(pnRow, 8, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
	local pnLab = W.label(pnRow, "P.N NÍVEL " .. ficha.Nivel, 10)
	pnLab.Size = UDim2.fromOffset(110, 12)
	local total = Data.pnTotal(ficha.Nivel)
	local pnVal = W.mono(pnRow, string.format("%d totais", total), 12)
	pnVal.Size = UDim2.fromOffset(130, 14)
	pnVal.TextXAlignment = Enum.TextXAlignment.Right

	-- PRINCÍPIOS
	local pcols = W.frame(pgPrincipios, UDim2.new(1, 0, 1, 0), "Cols")
	W.list(pcols, 12, Enum.FillDirection.Horizontal)

	-- Roda de categorias: sem SVG no Roblox. Aqui vai a leitura em lista
	-- (afinidade × efeitos comprados). Para o hexágono, suba a grade como
	-- imagem e posicione dois polígonos por cima, ou use EditableImage.
	local roda = W.card(pcols, UDim2.fromOffset(340, 300), "Categorias")
	roda.LayoutOrder = 1
	W.pad(roda, 13)
	local rodaCol = W.frame(roda, UDim2.new(1, 0, 1, 0), "Col")
	W.list(rodaCol, 8)
	W.label(rodaCol, "AFINIDADE × EFEITOS COMPRADOS", 10)

	local maxEfeitos = 1
	for _, c in ipairs(ficha.Nen.Categorias) do
		maxEfeitos = math.max(maxEfeitos, c.efeitos)
	end
	for i, c in ipairs(ficha.Nen.Categorias) do
		local row = W.frame(rodaCol, UDim2.new(1, 0, 0, 30), c.nome)
		row.LayoutOrder = i + 1
		W.list(row, 6)
		local top = W.frame(row, UDim2.new(1, 0, 0, 13), "Top")
		W.list(top, 6, Enum.FillDirection.Horizontal)
		local n = W.label(top, c.nome, 11)
		n.Size = UDim2.fromOffset(150, 13)
		if c.nome == ficha.Categoria then
			Theme.register(n, "TextColor3")
			n.Font = Theme.FontTitle
		end
		local st = W.mono(top, string.format("%d efeitos · %d%%", c.efeitos, c.afinidade), 10)
		st.Size = UDim2.fromOffset(140, 13)
		st.TextXAlignment = Enum.TextXAlignment.Right
		local _, fill = W.themedBar(row, 7)
		fill.Size = UDim2.fromScale(c.efeitos / maxEfeitos, 1)
	end

	local rodaExtra = W.frame(rodaCol, UDim2.new(1, 0, 0, 34), "Rolagens")
	rodaExtra.LayoutOrder = 20
	W.list(rodaExtra, 10, Enum.FillDirection.Horizontal)
	local af = W.mono(rodaExtra, string.format("Afinidade %s (%d)", ficha.Nen.Afinidade.nome, ficha.Nen.Afinidade.rolagem), 11)
	af.Size = UDim2.fromOffset(150, 14)
	local ge = W.mono(rodaExtra, string.format("Genialidade %s (%d)", ficha.Nen.Genialidade.nome, ficha.Nen.Genialidade.rolagem), 11)
	ge.Size = UDim2.fromOffset(160, 14)

	local pdir = W.frame(pcols, UDim2.new(1, -352, 1, 0), "Dominio")
	pdir.LayoutOrder = 2
	W.list(pdir, 11)

	local fund = W.card(pdir, UDim2.new(1, 0, 0, 118), "Fundamentais")
	fund.LayoutOrder = 1
	W.pad(fund, 12)
	local fcol = W.frame(fund, UDim2.new(1, 0, 1, 0), "Col")
	W.list(fcol, 8)
	W.label(fcol, "FUNDAMENTAIS", 10)
	for i, p in ipairs(ficha.Nen.Fundamentais) do
		local row = W.frame(fcol, UDim2.new(1, 0, 0, 20), p.sigla)
		row.LayoutOrder = i
		W.list(row, 10, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
		local s = W.label(row, p.sigla, 14)
		s.Font = Theme.FontTitle
		s.Size = UDim2.fromOffset(60, 16)
		local pipsHolder = W.frame(row, UDim2.fromOffset(88, 9), "Pips")
		W.pips(pipsHolder, 3, p.nivel, 24, 9)
		local e = W.value(row, p.efeito .. "  ", 12)
		e.Size = UDim2.new(1, -240, 0, 15)
		local c = W.mono(row, "custo " .. p.custo, 11, false)
		c.TextColor3 = Theme.Muted
		c.Size = UDim2.fromOffset(80, 14)
		c.TextXAlignment = Enum.TextXAlignment.Right
	end

	local avan = W.card(pdir, UDim2.new(1, 0, 0, 168), "Avancados")
	avan.LayoutOrder = 2
	W.pad(avan, 12)
	local acol = W.frame(avan, UDim2.new(1, 0, 1, 0), "Col")
	W.list(acol, 9)
	W.label(acol, "AVANÇADOS", 10)
	local agrid = W.frame(acol, UDim2.new(1, 0, 1, -20), "Grid")
	W.grid(agrid, 194, 62, 8)
	for i, p in ipairs(ficha.Nen.Avancados) do
		local card = if p.desbloqueado then W.cardAccent(agrid, UDim2.fromOffset(194, 62), p.sigla) else W.card(agrid, UDim2.fromOffset(194, 62), p.sigla)
		card.LayoutOrder = i
		if p.travado then card.BackgroundTransparency = 0.99 end
		W.pad(card, 9)
		local cc = W.frame(card, UDim2.new(1, 0, 1, 0), "Col")
		W.list(cc, 3)
		local top = W.frame(cc, UDim2.new(1, 0, 0, 16), "Top")
		W.list(top, 6, Enum.FillDirection.Horizontal)
		local s = W.label(top, p.sigla, 13)
		s.Font = Theme.FontTitle
		s.Size = UDim2.fromOffset(60, 15)
		local estado = if p.desbloqueado then "ATIVO" elseif p.travado then "TRAVADO" else "1 P.N"
		local e = W.mono(top, estado, 9, not p.travado)
		if p.travado then e.TextColor3 = Theme.Muted end
		e.Size = UDim2.fromOffset(110, 14)
		e.TextXAlignment = Enum.TextXAlignment.Right
		local ef = W.label(cc, p.efeito, 11)
		if p.desbloqueado then Theme.register(ef, "TextColor3") end
		local req = W.mono(cc, string.format("custo %s · requer %s", p.custo, p.requisito), 10, false)
		req.TextColor3 = Theme.Muted
	end

	-- HATSUS
	local hgrid = W.frame(pgHatsus, UDim2.new(1, 0, 1, 0), "Grid")
	W.list(hgrid, 12, Enum.FillDirection.Horizontal)
	for i, h in ipairs(ficha.Nen.Hatsus) do
		local doTema = (h.categoria == ficha.Categoria)
		local card = if doTema then W.cardAccent(hgrid, UDim2.new(0.5, -6, 0, 300), h.nome) else W.card(hgrid, UDim2.new(0.5, -6, 0, 300), h.nome)
		card.LayoutOrder = i
		W.pad(card, 13)
		local c = W.frame(card, UDim2.new(1, 0, 1, 0), "Col")
		W.list(c, 9)

		local top = W.frame(c, UDim2.new(1, 0, 0, 40), "Top")
		top.LayoutOrder = 1
		W.list(top, 6)
		local n = W.value(top, h.nome, 18)
		local meta = W.mono(top, string.format("%s · %s · %d P.N", string.upper(h.categoria), string.upper(h.natureza), h.pn), 10, false)
		meta.TextColor3 = Theme.Muted

		local desc = W.label(c, h.descricao, 12)
		desc.LayoutOrder = 2
		desc.Size = UDim2.new(1, 0, 0, 50)
		desc.TextWrapped = true

		W.label(c, "EFEITOS", 9).LayoutOrder = 3
		local efRow = W.frame(c, UDim2.new(1, 0, 0, 58), "Efeitos")
		efRow.LayoutOrder = 4
		local efLayout = W.list(efRow, 5, Enum.FillDirection.Horizontal)
		efLayout.Wraps = true
		for _, ef in ipairs(h.efeitos) do
			W.tag(efRow, ef.nome, ef.origem == "Gerais")
		end

		W.label(c, "RESTRIÇÕES", 9).LayoutOrder = 5
		local rRow = W.frame(c, UDim2.new(1, 0, 0, 54), "Restricoes")
		rRow.LayoutOrder = 6
		local rLayout = W.list(rRow, 5, Enum.FillDirection.Horizontal)
		rLayout.Wraps = true
		for _, r in ipairs(h.restricoes) do
			W.tag(rRow, string.format("%s (%s)", r.nome, r.peso), true)
		end

		local acoes = W.frame(c, UDim2.new(1, 0, 0, 26), "Acoes")
		acoes.LayoutOrder = 7
		W.list(acoes, 6, Enum.FillDirection.Horizontal)
		W.button(acoes, "EDITAR", UDim2.fromOffset(80, 26), function() end)
		W.button(acoes, "EVOLUIR", UDim2.fromOffset(80, 26), function() end)
	end
end

------------------------------------------------------------------ ABA: TRAÇOS

do
	local pag = frames["TRAÇOS"]
	local cols = W.frame(pag, UDim2.new(1, 0, 1, 0), "Cols")
	W.list(cols, 14, Enum.FillDirection.Horizontal)

	local esq = W.frame(cols, UDim2.new(0.5, -7, 1, 0), "Esq")
	esq.LayoutOrder = 1
	W.list(esq, 14)
	local dir = W.frame(cols, UDim2.new(0.5, -7, 1, 0), "Dir")
	dir.LayoutOrder = 2
	W.list(dir, 14)

	local function secao(parent: Instance, titulo: string, subtitulo: string, iconId: number, ordem: number): Frame
		local holder = W.frame(parent, UDim2.new(1, 0, 0, 0), titulo)
		holder.AutomaticSize = Enum.AutomaticSize.Y
		holder.LayoutOrder = ordem
		W.list(holder, 9)

		local head = W.frame(holder, UDim2.new(1, 0, 0, 44), "Head")
		head.LayoutOrder = 1
		W.list(head, 11, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
		local badge = W.cardAccent(head, UDim2.fromOffset(42, 42), "Badge")
		badge.LayoutOrder = 1
		W.icon(badge, iconId, 21).Position = UDim2.fromOffset(11, 11)
		local col = W.frame(head, UDim2.new(1, -54, 1, 0), "Col")
		col.LayoutOrder = 2
		W.list(col, 2)
		local t = W.value(col, titulo, 17)
		t.Size = UDim2.new(1, 0, 0, 20)
		W.label(col, subtitulo, 10)
		return holder
	end

	local function cardTraco(parent: Instance, nome: string, texto: string, ordem: number, badge: string?, warn: boolean?)
		local card = W.card(parent, UDim2.new(1, 0, 0, 0), nome)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.LayoutOrder = ordem
		W.pad(card, 11)
		-- borda de acento à esquerda, como na referência
		local acento = W.frame(card, UDim2.new(0, 2, 1, 0), "Acento")
		acento.Position = UDim2.fromOffset(-11, 0)
		acento.BackgroundTransparency = 0
		if warn then acento.BackgroundColor3 = Theme.Warn else Theme.register(acento, "BackgroundColor3") end

		local col = W.frame(card, UDim2.new(1, 0, 0, 0), "Col")
		col.AutomaticSize = Enum.AutomaticSize.Y
		W.list(col, 5)
		local top = W.frame(col, UDim2.new(1, 0, 0, 18), "Top")
		W.list(top, 8, Enum.FillDirection.Horizontal)
		local n = W.value(top, nome, 14)
		n.Size = UDim2.new(1, -80, 0, 16)
		if warn then
			n.TextColor3 = Theme.Warn
		end
		if badge then
			local b = W.mono(top, badge, 10, not warn)
			if warn then b.TextColor3 = Theme.Warn end
			b.Size = UDim2.fromOffset(72, 14)
			b.TextXAlignment = Enum.TextXAlignment.Right
		end
		local t = W.label(col, texto, 12)
		t.Size = UDim2.new(1, 0, 0, 0)
		t.AutomaticSize = Enum.AutomaticSize.Y
		t.TextWrapped = true
	end

	local s1 = secao(esq, string.upper(ficha.Raca), "CARACTERÍSTICAS RACIAIS", Icons.Racial, 1)
	for i, tr in ipairs(ficha.Tracos.Raciais) do
		cardTraco(s1, tr.nome, tr.texto, i + 1)
	end

	local s2 = secao(esq, string.upper(ficha.Antecedente), "ANTECEDENTE", Icons.Antecedente, 2)
	for i, tr in ipairs(ficha.Tracos.Antecedente) do
		cardTraco(s2, tr.nome, tr.texto, i + 1)
	end
	local prof = W.card(s2, UDim2.new(1, 0, 0, 34), "Proficiencias")
	prof.LayoutOrder = 10
	W.pad(prof, 9, { left = 12 })
	local pRow = W.frame(prof, UDim2.new(1, 0, 1, 0), "Row")
	W.list(pRow, 10, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
	local pl = W.label(pRow, "PROFICIÊNCIAS", 10)
	pl.Size = UDim2.fromOffset(100, 12)
	W.value(pRow, table.concat(ficha.Tracos.ProficienciasAntecedente, " · "), 12).Size = UDim2.fromOffset(220, 14)

	local s3 = secao(esq, "OUTROS TREINAMENTOS", "EQUIPAMENTOS, LINGUAGENS E FERRAMENTAS", Icons.Treinamentos, 3)
	for i, par in ipairs({
		{ "EQUIPAMENTO INICIAL", ficha.Tracos.Equipamento },
		{ "LINGUAGENS", ficha.Tracos.Linguagens },
		{ "FERRAMENTAS E KITS", ficha.Tracos.Ferramentas },
	}) do
		local card = W.card(s3, UDim2.new(1, 0, 0, 42), par[1])
		card.LayoutOrder = i + 1
		W.pad(card, 9, { left = 12 })
		local col = W.frame(card, UDim2.new(1, 0, 1, 0), "Col")
		W.list(col, 3)
		W.label(col, par[1], 10)
		W.value(col, par[2], 12)
	end

	local s4 = secao(dir, "INCLINAÇÕES GERAIS", "POSITIVAS E NEGATIVAS", Icons.Inclinacoes, 1)
	local posLab = W.label(s4, "POSITIVAS", 10)
	posLab.LayoutOrder = 2
	Theme.register(posLab, "TextColor3")
	for i, inc in ipairs(ficha.Tracos.InclinacoesPositivas) do
		cardTraco(s4, inc.nome, inc.texto, i + 2, string.format("%d pts", inc.custo))
	end
	local negLab = W.label(s4, "NEGATIVAS", 10)
	negLab.LayoutOrder = 20
	negLab.TextColor3 = Theme.Warn
	for i, inc in ipairs(ficha.Tracos.InclinacoesNegativas) do
		cardTraco(s4, inc.nome, inc.texto, i + 20, string.format("+%d pts", inc.valor), true)
	end

	local pc = ficha.Tracos.PontosCombate
	local s5 = secao(dir, "INCLINAÇÕES DE COMBATE", string.format("%d / %d PONTOS USADOS", pc.usados, pc.total), Icons.Combate, 2)
	for i, inc in ipairs(ficha.Tracos.InclinacoesCombate) do
		cardTraco(s5, inc.nome, inc.texto, i + 1, "Tier " .. inc.tier)
	end

	local s6 = secao(dir, "INSTÂNCIA SHINGEN-RYU", if #ficha.Tracos.Shingen == 0 then "NENHUMA INSTÂNCIA APRENDIDA" else "APRENDIDAS", Icons.Shingen, 3)
	if #ficha.Tracos.Shingen == 0 then
		local vazio = W.card(s6, UDim2.new(1, 0, 0, 44), "Vazio")
		vazio.LayoutOrder = 2
		W.pad(vazio, 11)
		local t = W.label(vazio, "As instâncias aparecem aqui conforme forem aprendidas, no mesmo formato das inclinações de combate.", 12)
		t.Size = UDim2.new(1, 0, 1, 0)
		t.TextWrapped = true
	else
		for i, inc in ipairs(ficha.Tracos.Shingen) do
			cardTraco(s6, inc.nome, inc.texto, i + 1)
		end
	end
end

--------------------------------------------------------------------- ABA: BIO

do
	local pag = frames.BIO
	local col = W.frame(pag, UDim2.new(1, 0, 1, 0), "Col")
	W.list(col, 12)

	local subBar = W.frame(col, UDim2.new(1, 0, 0, 32), "SubBar")
	subBar.LayoutOrder = 1
	W.list(subBar, 7, Enum.FillDirection.Horizontal)

	local corpo = W.frame(col, UDim2.new(1, 0, 1, -44), "Corpo")
	corpo.LayoutOrder = 2
	local pgPerfil = W.frame(corpo, UDim2.new(1, 0, 1, 0), "Perfil")
	local pgOrgs = W.frame(corpo, UDim2.new(1, 0, 1, 0), "Orgs")
	pgOrgs.Visible = false

	local subBotoes: { [string]: TextButton } = {}
	local function mostrarSub(nome: string)
		pgPerfil.Visible = (nome == "PERFIL")
		pgOrgs.Visible = (nome == "ORGANIZAÇÕES")
		for chave, b in pairs(subBotoes) do
			b.BackgroundTransparency = if chave == nome then 0 else 1
		end
	end
	for i, nome in ipairs({ "PERFIL", "ORGANIZAÇÕES" }) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(160, 32)
		b.LayoutOrder = i
		b.Text = nome
		b.Font = Theme.FontTitle
		b.TextSize = 12
		b.AutoButtonColor = false
		b.BackgroundTransparency = 1
		Theme.register(b, "TextColor3")
		Theme.register(b, "BackgroundColor3", 0.16)
		W.corner(b, 7)
		W.stroke(b, 0.35)
		b.Parent = subBar
		b.MouseButton1Click:Connect(function() mostrarSub(nome) end)
		subBotoes[nome] = b
	end

	-- PERFIL: campos de texto livre (2000 caracteres) + tags de Sanidade
	local perfilCol = W.frame(pgPerfil, UDim2.new(1, 0, 1, 0), "Col")
	W.list(perfilCol, 11)

	local function campoTexto(parent: Instance, rotulo: string, chave: string, altura: number, ordem: number)
		local card = W.card(parent, UDim2.new(1, 0, 0, altura), rotulo)
		card.LayoutOrder = ordem
		W.pad(card, 11)
		local c = W.frame(card, UDim2.new(1, 0, 1, 0), "Col")
		W.list(c, 6)
		local top = W.frame(c, UDim2.new(1, 0, 0, 13), "Top")
		W.list(top, 6, Enum.FillDirection.Horizontal)
		local l = W.label(top, rotulo, 10)
		l.Size = UDim2.new(1, -90, 0, 12)
		local contador = W.mono(top, "", 10, false)
		contador.TextColor3 = Theme.Muted
		contador.Size = UDim2.fromOffset(84, 12)
		contador.TextXAlignment = Enum.TextXAlignment.Right

		local box = Instance.new("TextBox")
		box.Name = "Input"
		box.Size = UDim2.new(1, 0, 1, -19)
		box.BackgroundTransparency = 1
		box.Font = Theme.FontBody
		box.TextSize = 13
		box.TextWrapped = true
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextYAlignment = Enum.TextYAlignment.Top
		box.MultiLine = true
		box.ClearTextOnFocus = false
		box.Text = ficha.Bio[chave] or ""
		Theme.register(box, "TextColor3")
		box.Parent = c

		local function atualizar()
			if #box.Text > 2000 then box.Text = string.sub(box.Text, 1, 2000) end
			contador.Text = string.format("%d / 2000", #box.Text)
			ficha.Bio[chave] = box.Text
		end
		atualizar()
		box:GetPropertyChangedSignal("Text"):Connect(atualizar)
		-- Salva de verdade no servidor ao perder o foco -- antes esses
		-- campos so ficavam em ficha.Bio (memoria local do cliente),
		-- perdidos ao fechar/recarregar a ficha. SetBioField ja existia
		-- no backend, so nunca tinha sido chamado daqui.
		box.FocusLost:Connect(function()
			HxH5e.SetBioField:InvokeServer(ficha.Id, chave, box.Text)
		end)
	end

	local row1 = W.frame(perfilCol, UDim2.new(1, 0, 0, 92), "Row1")
	row1.LayoutOrder = 1
	W.list(row1, 11, Enum.FillDirection.Horizontal)
	local r1a = W.frame(row1, UDim2.new(0.5, -6, 1, 0), "A")
	r1a.LayoutOrder = 1
	local r1b = W.frame(row1, UDim2.new(0.5, -6, 1, 0), "B")
	r1b.LayoutOrder = 2
	campoTexto(r1a, "PERSONALIDADE", "Personality", 92, 1)
	campoTexto(r1b, "OBJETIVOS", "Goals", 92, 1)

	-- Foco de Caça + Ação Protagonista: diferente dos campos de bio
	-- acima (que ainda so ficam em memoria local, SetBioField nunca e
	-- chamado), este daqui SALVA de verdade -- o backend ja existe e
	-- ja foi testado (SetFocoDeCaca/UsarAcaoProtagonista). A Acao
	-- Protagonista so pode ser usada se houver um Foco definido (regra
	-- do servidor, checada de novo aqui so pra UI nao deixar clicar
	-- errado).
	local focoCard = W.card(perfilCol, UDim2.new(1, 0, 0, 170), "FocoCaca")
	focoCard.LayoutOrder = 2
	W.pad(focoCard, 11)
	local focoCol = W.frame(focoCard, UDim2.new(1, 0, 1, 0), "Col")
	W.list(focoCol, 6)

	local focoTop = W.frame(focoCol, UDim2.new(1, 0, 0, 13), "Top")
	W.list(focoTop, 6, Enum.FillDirection.Horizontal)
	local focoLbl = W.label(focoTop, "FOCO DE CAÇA", 10)
	focoLbl.Size = UDim2.new(1, -90, 0, 12)
	local focoContador = W.mono(focoTop, "", 10, false)
	focoContador.TextColor3 = Theme.Muted
	focoContador.Size = UDim2.fromOffset(84, 12)
	focoContador.TextXAlignment = Enum.TextXAlignment.Right

	local focoBox = Instance.new("TextBox")
	focoBox.Name = "Input"
	focoBox.Size = UDim2.new(1, 0, 0, 46)
	focoBox.BackgroundTransparency = 1
	focoBox.Font = Theme.FontBody
	focoBox.TextSize = 13
	focoBox.TextWrapped = true
	focoBox.TextXAlignment = Enum.TextXAlignment.Left
	focoBox.TextYAlignment = Enum.TextYAlignment.Top
	focoBox.MultiLine = true
	focoBox.ClearTextOnFocus = false
	focoBox.PlaceholderText = "O que motiva seu personagem nessa caçada/missão? (ex: vingar minha família, provar meu valor...)"
	focoBox.Text = ficha.FocoDeCaca or ""
	Theme.register(focoBox, "TextColor3")
	focoBox.Parent = focoCol

	local focoAcaoRow = W.frame(focoCol, UDim2.new(1, 0, 0, 30), "AcaoRow")
	W.list(focoAcaoRow, 10, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
	local focoBtn = Instance.new("TextButton")
	focoBtn.Size = UDim2.fromOffset(220, 30)
	focoBtn.Font = Theme.FontTitle
	focoBtn.TextSize = 12
	focoBtn.AutoButtonColor = false
	Theme.register(focoBtn, "BackgroundColor3", 0.1)
	focoBtn.BackgroundTransparency = 0
	W.corner(focoBtn, 7)
	W.stroke(focoBtn, 0.3)
	focoBtn.Parent = focoAcaoRow

	local focoStatus = W.mono(focoCol, "", 11, false)
	focoStatus.Size = UDim2.new(1, 0, 0, 32)
	focoStatus.TextXAlignment = Enum.TextXAlignment.Left
	focoStatus.TextYAlignment = Enum.TextYAlignment.Top
	focoStatus.TextWrapped = true

	local acaoDisponivel = ficha.AcaoProtagonistaDisponivel

	local function atualizarFocoUI()
		if #focoBox.Text > 500 then focoBox.Text = string.sub(focoBox.Text, 1, 500) end
		focoContador.Text = string.format("%d / 500", #focoBox.Text)
		local temFoco = focoBox.Text ~= ""
		if not temFoco then
			focoBtn.Text = "DEFINA UM FOCO PRIMEIRO"
			focoStatus.Text = ""
		elseif acaoDisponivel then
			focoBtn.Text = "USAR AÇÃO PROTAGONISTA"
			focoStatus.Text = "Disponível"
			Theme.register(focoStatus, "TextColor3")
		else
			focoBtn.Text = "AÇÃO JÁ USADA"
			focoStatus.Text = "Volta no início da próxima sessão"
			focoStatus.TextColor3 = Theme.Muted
		end
	end
	atualizarFocoUI()

	focoBox:GetPropertyChangedSignal("Text"):Connect(atualizarFocoUI)
	focoBox.FocusLost:Connect(function()
		ficha.FocoDeCaca = focoBox.Text
		HxH5e.SetFocoDeCaca:InvokeServer(ficha.Id, focoBox.Text)
	end)

	focoBtn.Activated:Connect(function()
		if focoBox.Text == "" or not acaoDisponivel then return end
		local result = HxH5e.UsarAcaoProtagonista:InvokeServer()
		if result and result.success then
			acaoDisponivel = false
		end
		atualizarFocoUI()
		if result and (result.message or result.error) then
			-- Mensagem tem as 3 opcoes de efeito pro jogador escolher
			-- com o mestre -- comprida de proposito, por isso vai no
			-- proprio status desse card (nao um toast pequeno), pra
			-- dar tempo de ler com calma.
			focoStatus.Text = tostring(result.message or result.error)
			focoStatus.TextWrapped = true
		end
	end)

	-- Gostos e desgostos: tags do SanityTagsDB, não texto livre
	local tags = W.card(perfilCol, UDim2.new(1, 0, 0, 150), "Tags")
	tags.LayoutOrder = 3
	W.pad(tags, 12)
	local tagsCol = W.frame(tags, UDim2.new(1, 0, 1, 0), "Col")
	W.list(tagsCol, 9)
	W.label(tagsCol, "GOSTOS E DESGOSTOS — ligados à Sanidade", 10)

	local tagsRow = W.frame(tagsCol, UDim2.new(1, 0, 1, -22), "Row")
	W.list(tagsRow, 14, Enum.FillDirection.Horizontal)

	local function colunaTags(titulo: string, tipo: string, selecionadas: { string }, nota: string, ordem: number)
		local c = W.frame(tagsRow, UDim2.new(0.5, -7, 1, 0), titulo)
		c.LayoutOrder = ordem
		W.list(c, 7)
		local head = W.frame(c, UDim2.new(1, 0, 0, 13), "Head")
		W.list(head, 7, Enum.FillDirection.Horizontal)
		local h = W.label(head, titulo, 10)
		h.Size = UDim2.fromOffset(88, 12)
		if tipo == "gosto" then Theme.register(h, "TextColor3") else h.TextColor3 = Theme.Warn end
		local n = W.mono(head, nota, 10, false)
		n.TextColor3 = Theme.Muted
		n.Size = UDim2.new(1, -95, 0, 12)

		local chips = W.frame(c, UDim2.new(1, 0, 1, -20), "Chips")
		local layout = W.list(chips, 6, Enum.FillDirection.Horizontal)
		layout.Wraps = true

		local function estaSelecionada(id: string): boolean
			for _, s in ipairs(selecionadas) do
				if s == id then return true end
			end
			return false
		end

		for _, t in ipairs(Data.TagsSanidade) do
			if t.tipo == tipo then
				local on = estaSelecionada(t.id)
				local chip = Instance.new("TextButton")
				chip.Name = t.id
				chip.Text = " " .. t.nome .. " "
				chip.Font = Theme.FontBody
				chip.TextSize = 12
				chip.AutomaticSize = Enum.AutomaticSize.X
				chip.Size = UDim2.new(0, 0, 0, 24)
				chip.AutoButtonColor = false
				chip.BackgroundTransparency = if on then 0 else 1
				W.corner(chip, 6)
				local stroke = W.stroke(chip, if on then 0.5 else 0.12, tipo == "gosto")
				if tipo == "gosto" then
					Theme.register(chip, "BackgroundColor3", 0.16)
					if on then Theme.register(chip, "TextColor3") else chip.TextColor3 = Theme.Muted end
				else
					chip.BackgroundColor3 = Theme.mix(0.1, Theme.Warn)
					chip.TextColor3 = if on then Theme.Warn else Theme.Muted
					stroke.Color = if on then Theme.Warn else Color3.fromRGB(255, 255, 255)
				end
				chip.Parent = chips
				chip.MouseButton1Click:Connect(function()
					local agora = chip.BackgroundTransparency > 0.5
					chip.BackgroundTransparency = if agora then 0 else 1
					if tipo == "gosto" then
						chip.TextColor3 = if agora then Theme.Accent else Theme.Muted
					else
						chip.TextColor3 = if agora then Theme.Warn else Theme.Muted
					end
					stroke.Transparency = if agora then 0.5 else 0.88
				end)
			end
		end
	end
	colunaTags("GOSTOS", "gosto", ficha.GostosEscolhidos, "recupera 2d6+INT de Sanidade", 1)
	colunaTags("DESGOSTOS", "desgosto", ficha.DesgostosEscolhidos, "1 de Estresse, acumula", 2)

	campoTexto(perfilCol, "HISTÓRIA", "Historia", 120, 3)

	local row3 = W.frame(perfilCol, UDim2.new(1, 0, 0, 96), "Row3")
	row3.LayoutOrder = 4
	W.list(row3, 11, Enum.FillDirection.Horizontal)
	for i, par in ipairs({ { "ALIADOS", "Aliados" }, { "INIMIGOS", "Inimigos" }, { "VÍNCULOS", "Organizacoes" } }) do
		local c = W.frame(row3, UDim2.new(1 / 3, -8, 1, 0), par[1])
		c.LayoutOrder = i
		campoTexto(c, par[1], par[2], 96, 1)
	end

	-- ORGANIZAÇÕES: mecânica estruturada, sem controle de reputação pelo jogador
	local orgCol = W.frame(pgOrgs, UDim2.new(1, 0, 1, 0), "Col")
	W.list(orgCol, 11)

	local aviso = W.label(orgCol, "Reputação e promoção são alteradas pelo servidor (missões e penalidades) — o jogador não edita aqui.", 11)
	aviso.LayoutOrder = 1

	for i, org in ipairs(ficha.Organizacoes) do
		local titulo, nivel, proximo = Data.tituloOrg(org)
		local card = if org.especial then W.card(orgCol, UDim2.new(1, 0, 0, 96), org.nome) else W.cardAccent(orgCol, UDim2.new(1, 0, 0, 130), org.nome)
		card.LayoutOrder = i + 1
		W.pad(card, 13)
		local c = W.frame(card, UDim2.new(1, 0, 1, 0), "Col")
		W.list(c, 9)

		local top = W.frame(c, UDim2.new(1, 0, 0, 42), "Top")
		top.LayoutOrder = 1
		W.list(top, 10, Enum.FillDirection.Horizontal)
		local ident = W.frame(top, UDim2.new(1, -220, 1, 0), "Ident")
		ident.LayoutOrder = 1
		W.list(ident, 3)
		W.value(ident, org.nome, 17)
		local sub = W.mono(ident, string.format("%s · %s", string.upper(org.tipo), string.upper(org.status)), 10, false)
		sub.TextColor3 = Theme.Muted
		local tit = W.frame(top, UDim2.fromOffset(200, 42), "Titulo")
		tit.LayoutOrder = 2
		W.list(tit, 3)
		local tl = W.label(tit, if org.especial then "TÍTULO" else string.format("TÍTULO · NÍVEL %d", nivel), 10)
		tl.TextXAlignment = Enum.TextXAlignment.Right
		local tv = W.value(tit, titulo, 15)
		tv.TextXAlignment = Enum.TextXAlignment.Right

		if org.especial then
			local nota = W.label(c, org.especial .. " — os cinco níveis usam o mesmo título.", 12)
			nota.LayoutOrder = 2
		else
			-- Trilha dos 5 títulos
			local trilha = W.frame(c, UDim2.new(1, 0, 0, 26), "Trilha")
			trilha.LayoutOrder = 2
			local layout = W.list(trilha, 4, Enum.FillDirection.Horizontal)
			layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
			for idx, nomeTitulo in ipairs(org.titulos) do
				local pip = W.frame(trilha, UDim2.new(0, 0, 1, 0), "T" .. idx)
				pip.LayoutOrder = idx
				local flex = Instance.new("UIFlexItem")
				flex.FlexMode = Enum.UIFlexMode.Fill
				flex.Parent = pip
				W.corner(pip, 5)
				local atual = (idx == nivel)
				local conquistado = (idx < nivel)
				if atual or conquistado then
					Theme.register(pip, "BackgroundColor3", if atual then 0.3 else 0.14)
					pip.BackgroundTransparency = 0
					if atual then W.stroke(pip, 1) end
				else
					pip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					pip.BackgroundTransparency = 0.97
				end
				local t = W.label(pip, nomeTitulo, 11)
				t.Size = UDim2.new(1, 0, 1, 0)
				t.TextXAlignment = Enum.TextXAlignment.Center
				t.TextYAlignment = Enum.TextYAlignment.Center
				if atual or conquistado then Theme.register(t, "TextColor3") end
			end

			local repHolder = W.frame(c, UDim2.new(1, 0, 0, 30), "Reputacao")
			repHolder.LayoutOrder = 3
			W.list(repHolder, 5)
			local repTop = W.frame(repHolder, UDim2.new(1, 0, 0, 13), "Top")
			W.list(repTop, 6, Enum.FillDirection.Horizontal)
			local rl = W.label(repTop, "REPUTAÇÃO", 11)
			rl.Size = UDim2.fromOffset(90, 12)
			local rv = W.mono(repTop, string.format("%d · %s", org.reputacao, proximo), 11)
			rv.Size = UDim2.new(1, -96, 0, 12)
			rv.TextXAlignment = Enum.TextXAlignment.Right

			local base = if nivel >= 2 then Data.LimiaresReputacao[nivel] else 0
			local alvo = Data.LimiaresReputacao[nivel + 1]
			local pct = if alvo == nil then 1 else math.clamp((org.reputacao - base) / (alvo - base), 0, 1)
			local _, fill = W.themedBar(repHolder, 8)
			fill.Size = UDim2.fromScale(pct, 1)
		end
	end
end

--------------------------------------------------------------------- ABA: INV

do
	local pag = frames.INV
	local col = W.frame(pag, UDim2.new(1, 0, 1, 0), "Col")
	W.list(col, 12)

	-- Cabeçalho: dinheiro, espaço, ataque (com acuidade resolvida)
	local head = W.cardAccent(col, UDim2.new(1, 0, 0, 62), "Head")
	head.LayoutOrder = 1
	W.pad(head, 12, { left = 14, right = 14 })
	local hRow = W.frame(head, UDim2.new(1, 0, 1, 0), "Row")
	W.list(hRow, 14, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center

	local dinBox = W.frame(hRow, UDim2.fromOffset(230, 40), "Dinheiro")
	dinBox.LayoutOrder = 1
	W.list(dinBox, 10, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
	W.icon(dinBox, Icons.Dinheiro, 22).LayoutOrder = 1
	local dinCol = W.frame(dinBox, UDim2.fromOffset(180, 40), "Col")
	dinCol.LayoutOrder = 2
	W.list(dinCol, 2)
	W.label(dinCol, "DINHEIRO", 10)
	local dinVal = W.mono(dinCol, "$ " .. tostring(ficha.Dinheiro), 19)

	local espBox = W.frame(hRow, UDim2.new(1, -560, 0, 44), "Espaco")
	espBox.LayoutOrder = 2
	W.list(espBox, 5)
	local espTop = W.frame(espBox, UDim2.new(1, 0, 0, 13), "Top")
	W.list(espTop, 6, Enum.FillDirection.Horizontal)
	local espLab = W.label(espTop, "ESPAÇO OCUPADO", 11)
	espLab.Size = UDim2.fromOffset(130, 12)
	local espVal = W.mono(espTop, "", 11)
	espVal.Size = UDim2.new(1, -136, 0, 12)
	espVal.TextXAlignment = Enum.TextXAlignment.Right
	local _, espFill = W.themedBar(espBox, 9)
	local espNota = W.mono(espBox, "", 10, false)
	espNota.TextColor3 = Theme.Muted

	local atkBox = W.frame(hRow, UDim2.fromOffset(280, 40), "Ataque")
	atkBox.LayoutOrder = 3
	W.list(atkBox, 2)
	local atkLab = W.label(atkBox, "ATAQUE", 10)
	atkLab.TextXAlignment = Enum.TextXAlignment.Right
	local atkVal = W.mono(atkBox, "", 14)
	atkVal.TextXAlignment = Enum.TextXAlignment.Right

	local corpo = W.frame(col, UDim2.new(1, 0, 1, -74), "Corpo")
	corpo.LayoutOrder = 2
	W.list(corpo, 12, Enum.FillDirection.Horizontal)

	-- Quadro de equipamento
	local eqCard = W.card(corpo, UDim2.new(0.5, -6, 1, 0), "Equipamento")
	eqCard.LayoutOrder = 1
	W.pad(eqCard, 13)
	local eqCol = W.frame(eqCard, UDim2.new(1, 0, 1, 0), "Col")
	W.list(eqCol, 11)
	local eqHead = W.frame(eqCol, UDim2.new(1, 0, 0, 18), "Head")
	eqHead.LayoutOrder = 1
	W.list(eqHead, 8, Enum.FillDirection.Horizontal)
	W.icon(eqHead, Icons.Equipamento, 16).LayoutOrder = 1
	local eqLab = W.label(eqHead, "EQUIPAMENTO", 10)
	eqLab.Size = UDim2.new(1, -180, 0, 12)
	eqLab.LayoutOrder = 2
	local eqCA = W.mono(eqHead, string.format("CA %d · RDM %d", v.CA, v.RDM), 10, false)
	eqCA.TextColor3 = Theme.Muted
	eqCA.Size = UDim2.fromOffset(140, 12)
	eqCA.TextXAlignment = Enum.TextXAlignment.Right
	eqCA.LayoutOrder = 3

	local slotsRow = W.frame(eqCol, UDim2.new(1, 0, 1, -28), "Slots")
	slotsRow.LayoutOrder = 2
	W.list(slotsRow, 9, Enum.FillDirection.Horizontal)

	local slotsEsq = W.frame(slotsRow, UDim2.new(0.5, -70, 1, 0), "Esq")
	slotsEsq.LayoutOrder = 1
	W.list(slotsEsq, 8)

	local avatarBox = W.cardAccent(slotsRow, UDim2.fromOffset(124, 250), "Avatar")
	avatarBox.LayoutOrder = 2
	local vpf2 = Instance.new("ViewportFrame")
	vpf2.Name = "Viewport"
	vpf2.Size = UDim2.new(1, -16, 1, -40)
	vpf2.Position = UDim2.fromOffset(8, 8)
	vpf2.BackgroundTransparency = 1
	vpf2.Parent = avatarBox
	local avNota = W.mono(avatarBox, "avatar do Roblox", 9, false)
	avNota.TextColor3 = Theme.Muted
	avNota.Position = UDim2.new(0, 0, 1, -26)
	avNota.TextXAlignment = Enum.TextXAlignment.Center

	local slotsDir = W.frame(slotsRow, UDim2.new(0.5, -70, 1, 0), "Dir")
	slotsDir.LayoutOrder = 3
	W.list(slotsDir, 8)

	-- Lista do que está solto na mochila
	local bolsaCard = W.card(corpo, UDim2.new(0.5, -6, 1, 0), "Carregando")
	bolsaCard.LayoutOrder = 2
	W.pad(bolsaCard, 13)
	local bolsaCol = W.frame(bolsaCard, UDim2.new(1, 0, 1, 0), "Col")
	W.list(bolsaCol, 11)
	local bHead = W.frame(bolsaCol, UDim2.new(1, 0, 0, 18), "Head")
	bHead.LayoutOrder = 1
	W.list(bHead, 8, Enum.FillDirection.Horizontal)
	W.icon(bHead, Icons.Espaco, 16).LayoutOrder = 1
	local bLab = W.label(bHead, "CARREGANDO", 10)
	bLab.Size = UDim2.new(1, -260, 0, 12)
	bLab.LayoutOrder = 2
	local bNota = W.mono(bHead, "o que está equipado não aparece aqui", 10, false)
	bNota.TextColor3 = Theme.Muted
	bNota.Size = UDim2.fromOffset(220, 12)
	bNota.TextXAlignment = Enum.TextXAlignment.Right
	bNota.LayoutOrder = 3

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Lista"
	scroll.Size = UDim2.new(1, 0, 1, -52)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.LayoutOrder = 2
	scroll.Parent = bolsaCol
	W.list(scroll, 7)

	local statusLinha = W.mono(bolsaCol, "", 11)
	statusLinha.LayoutOrder = 3
	statusLinha.Size = UDim2.new(1, 0, 0, 16)

	local SLOTS = {
		{ chave = "cabeca", rotulo = "CABEÇA", icone = Icons.Slot_Cabeca, vazio = "vazio", lado = "esq" },
		{ chave = "torso", rotulo = "TORSO", icone = Icons.Slot_Torso, vazio = "vazio", lado = "esq" },
		{ chave = "maoPrincipal", rotulo = "MÃO PRINCIPAL", icone = Icons.Slot_MaoPrincipal, vazio = "vazio", lado = "esq" },
		{ chave = "maoSecundaria", rotulo = "MÃO SECUNDÁRIA", icone = Icons.Slot_MaoSecundaria, vazio = "livre — desarmado 1d6", lado = "esq" },
		{ chave = "costas", rotulo = "COSTAS", icone = Icons.Slot_Costas, vazio = "vazio", lado = "dir" },
		{ chave = "cintura", rotulo = "CINTURA", icone = Icons.Slot_Cintura, vazio = "vazio", lado = "dir" },
		{ chave = "pernas", rotulo = "PERNAS E PÉS", icone = Icons.Slot_Pernas, vazio = "vazio", lado = "dir" },
		{ chave = "acessorio", rotulo = "ACESSÓRIO", icone = Icons.Slot_Acessorio, vazio = "vazio", lado = "dir" },
	}

	local redesenhar: () -> ()

	local function cargaDe(nome: string): number?
		local def = ficha.Itens[nome]
		if not def or not def.usos then return nil end
		local atual = ficha.Cargas[nome]
		return if atual == nil then def.usos else atual
	end

	local function status(texto: string, erro: boolean?)
		statusLinha.Text = texto
		statusLinha.TextColor3 = if erro then Theme.Warn else Theme.Accent
	end

	local function tirarDaBolsa(nome: string)
		for i, it in ipairs(ficha.Bolsa) do
			if it.nome == nome then
				if it.qtd <= 1 then table.remove(ficha.Bolsa, i) else it.qtd -= 1 end
				return
			end
		end
	end

	local function porNaBolsa(nome: string)
		for _, it in ipairs(ficha.Bolsa) do
			if it.nome == nome then it.qtd += 1 return end
		end
		table.insert(ficha.Bolsa, { nome = nome, qtd = 1 })
	end

	local function equipar(nome: string)
		local def = ficha.Itens[nome]
		if not def or not def.slot then return end
		local candidatos = if def.slot == "mao" then { "maoPrincipal", "maoSecundaria" } else { def.slot }
		local alvo = candidatos[1]
		for _, c in ipairs(candidatos) do
			if ficha.Equipado[c] == nil then alvo = c break end
		end
		tirarDaBolsa(nome)
		local anterior = ficha.Equipado[alvo]
		if anterior then
			porNaBolsa(anterior)
			status(string.format("%s equipado — %s voltou para a mochila.", nome, anterior))
		else
			status(nome .. " equipado.")
		end
		ficha.Equipado[alvo] = nome
		redesenhar()
	end

	local function desequipar(chave: string)
		local nome = ficha.Equipado[chave]
		if not nome then return end
		ficha.Equipado[chave] = nil
		porNaBolsa(nome)
		status(nome .. " guardado na mochila.")
		redesenhar()
	end

	local function usar(nome: string)
		local def = ficha.Itens[nome]
		if not def or not def.usos then return end
		local atual = cargaDe(nome) or def.usos
		if atual <= 0 then
			status(nome .. " está sem usos — precisa repor.", true)
			return
		end
		ficha.Cargas[nome] = atual - 1
		status(string.format("%s: 1 uso gasto (%d restantes).", nome, atual - 1))
		redesenhar()
	end

	local function repor(nome: string)
		local def = ficha.Itens[nome]
		if not def or not def.usos then return end
		ficha.Cargas[nome] = def.usos
		status(string.format("%s reposto para %d.", nome, def.usos))
		redesenhar()
	end

	-- Linha de contador USAR / n / m / REPOR
	local function linhaContador(parent: Instance, nome: string, ordem: number)
		local def = ficha.Itens[nome]
		if not def or not def.usos then return end
		local row = W.frame(parent, UDim2.new(1, 0, 0, 22), "Contador")
		row.LayoutOrder = ordem
		W.list(row, 5, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
		W.button(row, "USAR", UDim2.fromOffset(52, 20), function() usar(nome) end).LayoutOrder = 1
		local atual = cargaDe(nome) or 0
		local c = W.mono(row, string.format("%d / %d", atual, def.usos), 10, false)
		c.TextColor3 = if atual == 0 then Theme.Warn else Theme.Accent
		c.Size = UDim2.fromOffset(52, 14)
		c.LayoutOrder = 2
		local b = W.button(row, "REPOR", UDim2.fromOffset(58, 20), function() repor(nome) end)
		b.LayoutOrder = 3
	end

	local function desenharSlot(parent: Instance, info, ordem: number)
		local nome = ficha.Equipado[info.chave]
		local def = if nome then ficha.Itens[nome] else nil
		local temContador = def ~= nil and def.usos ~= nil
		local altura = if nome then (if temContador then 106 else 82) else 56
		local card = if nome then W.cardAccent(parent, UDim2.new(1, 0, 0, altura), info.chave) else W.card(parent, UDim2.new(1, 0, 0, altura), info.chave)
		card.LayoutOrder = ordem
		W.pad(card, 9)
		local row = W.frame(card, UDim2.new(1, 0, 1, 0), "Row")
		W.list(row, 8, Enum.FillDirection.Horizontal)
		local ic = W.icon(row, if nome then Icons.forItem(nome) else info.icone, 19, "Icon_" .. info.chave)
		ic.LayoutOrder = 1
		if not nome then ic.ImageTransparency = 0.6 end
		local col2 = W.frame(row, UDim2.new(1, -28, 1, 0), "Col")
		col2.LayoutOrder = 2
		W.list(col2, 3)

		W.label(col2, info.rotulo, 9).LayoutOrder = 1
		if nome then
			local n = W.value(col2, nome, 12)
			n.LayoutOrder = 2
			n.TextWrapped = true
			n.Size = UDim2.new(1, 0, 0, 15)
			local d = W.mono(col2, (def :: any).detalhe or "", 10, false)
			d.TextColor3 = Theme.Muted
			d.LayoutOrder = 3
			if (def :: any).props ~= "" then
				local p = W.mono(col2, (def :: any).props, 10)
				p.LayoutOrder = 4
				p.TextWrapped = true
				p.Size = UDim2.new(1, 0, 0, 13)
			end
			linhaContador(col2, nome, 5)
			local btn = W.button(col2, "DESEQUIPAR", UDim2.fromOffset(96, 20), function() desequipar(info.chave) end)
			btn.LayoutOrder = 6
		else
			local n = W.label(col2, info.vazio, 12)
			n.LayoutOrder = 2
		end
	end

	local function desenharItem(nome: string, qtd: number, ordem: number)
		local def = ficha.Itens[nome] or {}
		local temContador = def.usos ~= nil
		local altura = 62
		if def.props and def.props ~= "" then altura += 14 end
		if def.slot or temContador then altura += 26 end
		local card = W.card(scroll, UDim2.new(1, -8, 0, altura), nome)
		card.LayoutOrder = ordem
		W.pad(card, 9)
		local row = W.frame(card, UDim2.new(1, 0, 1, 0), "Row")
		W.list(row, 9, Enum.FillDirection.Horizontal)

		local ic = W.icon(row, Icons.forItem(nome), 19)
		ic.LayoutOrder = 1

		local info = W.frame(row, UDim2.new(1, -150, 1, 0), "Info")
		info.LayoutOrder = 2
		W.list(info, 3)
		W.value(info, nome, 13).LayoutOrder = 1
		local d = W.mono(info, string.format("%s · %s", def.detalhe or "—", if def.peso and def.peso > 0 then string.format("%.1f cada", def.peso) else "sem peso"), 10, false)
		d.TextColor3 = Theme.Muted
		d.LayoutOrder = 2
		if def.props and def.props ~= "" then
			local p = W.mono(info, def.props, 10)
			p.LayoutOrder = 3
		end
		local acoes = W.frame(info, UDim2.new(1, 0, 0, 22), "Acoes")
		acoes.LayoutOrder = 4
		W.list(acoes, 6, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
		if def.slot then
			local b = W.button(acoes, "EQUIPAR", UDim2.fromOffset(74, 20), function() equipar(nome) end)
			b.LayoutOrder = 1
			b.BackgroundTransparency = 0.85
		end
		if temContador then
			W.button(acoes, "USAR", UDim2.fromOffset(52, 20), function() usar(nome) end).LayoutOrder = 2
			local atual = cargaDe(nome) or 0
			local c = W.mono(acoes, string.format("%d / %d", atual, def.usos), 10, false)
			c.TextColor3 = if atual == 0 then Theme.Warn else Theme.Accent
			c.Size = UDim2.fromOffset(52, 14)
			c.LayoutOrder = 3
			W.button(acoes, "REPOR", UDim2.fromOffset(58, 20), function() repor(nome) end).LayoutOrder = 4
		end

		local qtdBox = W.frame(row, UDim2.fromOffset(76, 24), "Qtd")
		qtdBox.LayoutOrder = 3
		W.list(qtdBox, 5, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
		W.button(qtdBox, "−", UDim2.fromOffset(22, 22), function()
			tirarDaBolsa(nome)
			redesenhar()
		end).LayoutOrder = 1
		local q = W.mono(qtdBox, tostring(qtd), 13)
		q.Size = UDim2.fromOffset(20, 16)
		q.TextXAlignment = Enum.TextXAlignment.Center
		q.LayoutOrder = 2
		W.button(qtdBox, "+", UDim2.fromOffset(22, 22), function()
			porNaBolsa(nome)
			redesenhar()
		end).LayoutOrder = 3

		local peso = W.mono(row, string.format("%.1f", (def.peso or 0) * qtd), 12, false)
		peso.TextColor3 = Theme.Muted
		peso.Size = UDim2.fromOffset(40, 14)
		peso.TextXAlignment = Enum.TextXAlignment.Right
		peso.LayoutOrder = 4
	end

	function redesenhar()
		for _, filho in ipairs(slotsEsq:GetChildren()) do
			if not filho:IsA("UIListLayout") then filho:Destroy() end
		end
		for _, filho in ipairs(slotsDir:GetChildren()) do
			if not filho:IsA("UIListLayout") then filho:Destroy() end
		end
		for _, filho in ipairs(scroll:GetChildren()) do
			if not filho:IsA("UIListLayout") then filho:Destroy() end
		end

		local oe, od = 0, 0
		for _, info in ipairs(SLOTS) do
			if info.lado == "esq" then
				oe += 1
				desenharSlot(slotsEsq, info, oe)
			else
				od += 1
				desenharSlot(slotsDir, info, od)
			end
		end

		if #ficha.Bolsa == 0 then
			local vazio = W.card(scroll, UDim2.new(1, -8, 0, 40), "Vazio")
			local t = W.mono(vazio, "nada solto na mochila", 11, false)
			t.TextColor3 = Theme.Muted
			t.Size = UDim2.new(1, 0, 1, 0)
			t.TextXAlignment = Enum.TextXAlignment.Center
			t.TextYAlignment = Enum.TextYAlignment.Center
		else
			for i, it in ipairs(ficha.Bolsa) do
				desenharItem(it.nome, it.qtd, i)
			end
		end

		-- Espaço: 2 + 2 × mod FOR + recipientes equipados
		local cap, base, recipientes = Data.capacidade(ficha)
		local peso = Data.pesoCarregado(ficha)
		local excesso = peso - cap
		espVal.Text = string.format("%.1f / %.1f", peso, cap)
		espVal.TextColor3 = if excesso > 0 then Theme.Warn else Theme.Accent
		espFill.Size = UDim2.fromScale(math.clamp(peso / cap, 0, 1), 1)
		espFill.BackgroundColor3 = if excesso > 0 then Theme.Warn else Theme.Accent
		if excesso > 0 then
			espNota.Text = string.format("acima da capacidade em %.1f", excesso)
			espNota.TextColor3 = Theme.Warn
		else
			espNota.Text = string.format("base %d (2 + 2 × mod FOR) + recipientes %.1f", base, recipientes)
			espNota.TextColor3 = Theme.Muted
		end

		atkVal.Text = Data.ataque(ficha)
		dinVal.Text = "$ " .. tostring(ficha.Dinheiro)
	end

	redesenhar()
end

---------------------------------------------------------------- ABRIR/FECHAR

local function alternar()
	sheetHolder.Visible = not sheetHolder.Visible
end

UserInputService.InputBegan:Connect(function(input, processado)
	if processado then return end
	if input.KeyCode == Enum.KeyCode.M then
		alternar()
	elseif input.KeyCode == Enum.KeyCode.Escape and sheetHolder.Visible then
		sheetHolder.Visible = false
	end
end)

-- Botao "FICHA (M)" removido junto com o Hud -- o Lucas esta
-- criando a barra inferior (vida/aura/reacoes/condicoes/atalhos)
-- manualmente numa ScreenGui propria. A tecla M continua abrindo e
-- fechando a ficha normalmente (ver InputBegan acima), independente
-- de existir um botao visual ou nao.
mostrarAba("FICHA")

if not doServidor then
	warn("[HxH5e] FichaUI usando personagem de exemplo — remote GetCharacter não encontrado.")
end
