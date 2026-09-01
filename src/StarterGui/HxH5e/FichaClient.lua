--[[
    HxH5e FichaClient (COMPLETO — Parte 1 de 3)
    Substitua o arquivo inteiro por esta Parte 1.
    Depois cole a Parte 2 logo abaixo e depois a Parte 3.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local HxH5e = ReplicatedStorage:WaitForChild("HxH5e")

local GetCharacter = HxH5e:WaitForChild("GetCharacter")
local GetCharacters = HxH5e:WaitForChild("GetCharacters")
local SetActiveCharacter = HxH5e:WaitForChild("SetActiveCharacter")
local CreateCharacter = HxH5e:WaitForChild("CreateCharacter")
local GetNenStatus = HxH5e:WaitForChild("GetNenStatus")
local TrainPrinciple = HxH5e:WaitForChild("TrainPrinciple")
local ActivatePrinciple = HxH5e:WaitForChild("ActivatePrinciple")
local CreateHatsu = HxH5e:WaitForChild("CreateHatsu")
local GetHatsus = HxH5e:WaitForChild("GetHatsus")
local ActivateHatsu = HxH5e:WaitForChild("ActivateHatsu")
local DeleteHatsu = HxH5e:WaitForChild("DeleteHatsu")
local GainXP = HxH5e:WaitForChild("GainXP")
local AddGrau = HxH5e:WaitForChild("AddGrau")
local AddRestricao = HxH5e:WaitForChild("AddRestricao")
local GetRaces = HxH5e:WaitForChild("GetRaces")
local GetRaceBonusInfo = HxH5e:WaitForChild("GetRaceBonusInfo")
local DeleteCharacter = HxH5e:WaitForChild("DeleteCharacter")
local GetBackgrounds = HxH5e:WaitForChild("GetBackgrounds")
local GetPointBuyInfo = HxH5e:WaitForChild("GetPointBuyInfo")
local GetInclinations = HxH5e:WaitForChild("GetInclinations")
local GetSkillsInfo = HxH5e:WaitForChild("GetSkillsInfo")

local RESTRICAO_IDS = { "Compromisso", "Condicao", "Limitacao", "Requisito" }

-- Declarações antecipadas (as funções são definidas na Parte 3)
local wizardOpen
local openHatsuDetail

-- ================= Helpers =================

local function makeButton(parent, name, text, position, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.Gotham
	button.TextSize = 15
	button.BorderSizePixel = 0
	button.ZIndex = 10
	button.Parent = parent
	return button
end

local function makeLabel(parent, name, text, position, size, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.Gotham
	label.TextSize = textSize or 16
	label.Active = false
	label.Selectable = false
	label.Parent = parent
	return label
end

local function makeFrame(parent, name, size, position, color)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

local function vitalText(vital)
	if type(vital) == "table" then
		return tostring(vital.Current) .. "/" .. tostring(vital.Max)
	end
	return tostring(vital)
end

-- ================= Tela principal =================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HxH5eGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10 -- fica acima do HUD (ActionBarClient), evita roubo de clique em botoes sobrepostos
screenGui.Parent = player:WaitForChild("PlayerGui")

local openButton = makeButton(screenGui, "AbrirFichaButton", "ABRIR FICHA",
	UDim2.new(1, -170, 1, -60), UDim2.new(0, 150, 0, 42))
openButton.AnchorPoint = Vector2.new(1, 1)

-- ================= Toast (notificacoes empilhadas) =================
-- Caixa fica invisivel ate a primeira mensagem. Cada nova mensagem entra
-- no topo da lista (mais transparente, texto acumula). Some sozinha depois
-- de 5s sem novas mensagens, mas o historico continua ali dentro; se uma
-- nova acao gerar texto, ela reaparece com tudo que já tinha antes.

local toastFrame = makeFrame(screenGui, "ToastFrame",
	UDim2.new(0, 280, 0, 160), UDim2.new(1, -300, 0, 12), Color3.fromRGB(10, 10, 10))
toastFrame.AnchorPoint = Vector2.new(1, 0)
toastFrame.BackgroundTransparency = 0.55
toastFrame.BorderSizePixel = 1
toastFrame.BorderColor3 = Color3.fromRGB(0, 255, 157)
toastFrame.ZIndex = 100
toastFrame.Visible = false

local toastClose = makeButton(toastFrame, "ToastClose", "X",
	UDim2.new(1, -28, 0, 4), UDim2.new(0, 24, 0, 24))
toastClose.TextSize = 12
toastClose.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
toastClose.BackgroundTransparency = 0.3
toastClose.ZIndex = 102

local toastScroll = Instance.new("ScrollingFrame")
toastScroll.Name = "ToastScroll"
toastScroll.Size = UDim2.new(1, -20, 1, -36)
toastScroll.Position = UDim2.new(0, 10, 0, 32)
toastScroll.BackgroundTransparency = 1
toastScroll.ScrollBarThickness = 4
toastScroll.BorderSizePixel = 0
toastScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
toastScroll.ElasticBehavior = Enum.ElasticBehavior.Never
toastScroll.ZIndex = 101
toastScroll.Parent = toastFrame

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 4)
toastLayout.Parent = toastScroll

local TOAST_MAX_ENTRIES = 15
local TOAST_HIDE_DELAY = 5
local toastHideTimer = nil

local function showToast(message)
	if not message or #message == 0 then
		return
	end

	local entry = makeLabel(toastScroll, "ToastEntry", message,
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 0), 12)
	entry.TextWrapped = true
	entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.TextYAlignment = Enum.TextYAlignment.Top
	entry.AutomaticSize = Enum.AutomaticSize.Y
	entry.BackgroundTransparency = 1
	entry.ZIndex = 101
	entry.LayoutOrder = -math.floor(os.clock() * 1000) -- mais recente primeiro

	local entries = {}
	for _, child in ipairs(toastScroll:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(entries, child)
		end
	end
	table.sort(entries, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	if #entries > TOAST_MAX_ENTRIES then
		for i = TOAST_MAX_ENTRIES + 1, #entries do
			entries[i]:Destroy()
		end
	end

	toastFrame.Visible = true
	toastScroll.CanvasPosition = Vector2.zero

	if toastHideTimer then
		task.cancel(toastHideTimer)
	end
	toastHideTimer = task.delay(TOAST_HIDE_DELAY, function()
		toastFrame.Visible = false
	end)
end

toastClose.Activated:Connect(function()
	toastFrame.Visible = false
end)

-- ================= Pilha de janelas + ESC + bringToFront =================

local windowStack = {}

local function removeFromStack(frame)
	for i, f in ipairs(windowStack) do
		if f == frame then
			table.remove(windowStack, i)
			break
		end
	end
end

local function bringToFront(frame)
	local parent = frame.Parent
	if parent then
		frame.Parent = nil
		frame.Parent = parent
	end
end

local function resetWindowScrolls(frame)
	for _, child in ipairs(frame:GetDescendants()) do
		if child:IsA("ScrollingFrame") then
			child.CanvasPosition = Vector2.zero
		end
	end
end

local function openWindow(frame)
	removeFromStack(frame)
	table.insert(windowStack, frame)
	bringToFront(frame)
	resetWindowScrolls(frame)
	frame.Visible = true
end

local function closeWindow(frame)
	removeFromStack(frame)
	frame.Visible = false
end

local function closeTopWindow()
	local frame = table.remove(windowStack)
	if frame then
		frame.Visible = false
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape then
		closeTopWindow()
	end
end)

local function addCloseButton(frame)
	local closeBtn = makeButton(frame, "CloseBtn", "X",
		UDim2.new(1, -30, 0, 6), UDim2.new(0, 24, 0, 24))
	closeBtn.TextSize = 14
	closeBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
	closeBtn.Activated:Connect(function()
		closeWindow(frame)
	end)
end

-- ================= Janela da ficha (com guias, igual ao webapp) =================
-- 7 guias reais do webapp: FICHA / BIO / NEN / TRAÇOS / INV / DADOS / COND.
-- Por ora, so FICHA / NEN / TRAÇOS tem dados de verdade no servidor; as
-- outras 4 aparecem na barra mas ficam desabilitadas ("em breve").

local fichaFrame = makeFrame(screenGui, "FichaWindow",
	UDim2.fromOffset(940, 640), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
fichaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fichaFrame.Visible = false
addCloseButton(fichaFrame)

-- ---------- Barra de guias ----------
-- (elementos que nao precisam sobreviver ficam dentro do "do...end" pra
-- liberar o registrador de variavel local assim que o bloco termina --
-- Luau tem um teto de 200 locais simultaneas por escopo)

local TAB_LIST = {
	{ id = "FICHA", label = "FICHA", enabled = true },
	{ id = "BIO", label = "BIO", enabled = true },
	{ id = "NEN", label = "NEN", enabled = true },
	{ id = "TRACOS", label = "TRAÇOS", enabled = true },
	{ id = "INV", label = "INV", enabled = true },
	{ id = "DADOS", label = "DADOS", enabled = false },
	{ id = "COND", label = "COND", enabled = false },
}

local tabButtons = {}
tabButtons.NenColors = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("NenColors"))
do
	local tabBarFrame = makeFrame(fichaFrame, "TabBar",
		UDim2.new(1, -20, 0, 26), UDim2.new(0, 10, 0, 40), Color3.fromRGB(0, 0, 0))
	tabBarFrame.BackgroundTransparency = 1
	for i, tabInfo in ipairs(TAB_LIST) do
		local btn = makeButton(tabBarFrame, "Tab_" .. tabInfo.id, tabInfo.label,
			UDim2.new(0, (i - 1) * 57, 0, 0), UDim2.new(0, 55, 0, 26))
		btn.TextSize = 9
		if not tabInfo.enabled then
			btn.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
			btn.TextColor3 = Color3.fromRGB(90, 90, 100)
		end
		tabButtons[tabInfo.id] = btn
	end
end

-- ---------- Conteudo: FICHA (status) ----------

local statusScroll = Instance.new("ScrollingFrame")
statusScroll.Name = "StatusScroll"
statusScroll.Size = UDim2.new(1, -20, 1, -180)
statusScroll.Position = UDim2.new(0, 10, 0, 72)
statusScroll.BackgroundTransparency = 1
statusScroll.ScrollBarThickness = 6
statusScroll.BorderSizePixel = 0
statusScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
statusScroll.ElasticBehavior = Enum.ElasticBehavior.Never
statusScroll.Parent = fichaFrame

local titleLabel, categoryLabel, geniusLabel, xpLabel
local attributeNames = { "FOR", "DES", "CON", "INT", "SAB", "PRE" }
local attributeLabels = {}
local hpLabel, auraLabel, sanidadeLabel

-- ================= ABA FICHA v2: header (retrato/nome/nivel/XP/info)
-- + grid de 6 atributos coloridos por categoria de Nen + barra de
-- vitals -- layout novo baseado na referencia visual do Lucas.
-- Reaproveita tabButtons pro resto (teto de 200 locais do Luau).
tabButtons.attrCards = {}
tabButtons.vitalsBars = {}
tabButtons.ALIGNMENT_CYCLE = { "Neutro", "Heróico", "Caótico", "Maligno" }
tabButtons.VITALS_INFO = {
	{ key = "HP", label = "VIDA", color = Color3.fromRGB(0, 255, 90) },
	{ key = "Aura", label = "AURA", color = Color3.fromRGB(0, 180, 255) },
	{ key = "Sanidade", label = "SANIDADE", color = Color3.fromRGB(255, 200, 0) },
}

do
	local content = makeFrame(statusScroll, "Content", UDim2.new(1, 0, 0, 470), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0))
	content.BackgroundTransparency = 1

	local header = makeFrame(content, "Header", UDim2.new(1, 0, 0, 130), UDim2.new(0, 0, 0, 0), Color3.fromRGB(18, 20, 28))
	tabButtons.fichaHeaderStroke = Instance.new("UIStroke")
	tabButtons.fichaHeaderStroke.Thickness = 2
	tabButtons.fichaHeaderStroke.Color = Color3.fromRGB(0, 255, 157)
	tabButtons.fichaHeaderStroke.Parent = header
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

	tabButtons.fichaPortrait = Instance.new("ImageLabel")
	tabButtons.fichaPortrait.Name = "Portrait"
	tabButtons.fichaPortrait.Size = UDim2.new(0, 100, 0, 100)
	tabButtons.fichaPortrait.Position = UDim2.new(0, 10, 0, 10)
	tabButtons.fichaPortrait.BackgroundColor3 = Color3.fromRGB(35, 38, 46)
	tabButtons.fichaPortrait.Image = ""
	tabButtons.fichaPortrait.Parent = header
	Instance.new("UICorner", tabButtons.fichaPortrait).CornerRadius = UDim.new(1, 0)
	tabButtons.fichaPortraitStroke = Instance.new("UIStroke")
	tabButtons.fichaPortraitStroke.Thickness = 2
	tabButtons.fichaPortraitStroke.Color = Color3.fromRGB(0, 255, 157)
	tabButtons.fichaPortraitStroke.Parent = tabButtons.fichaPortrait

	titleLabel = makeLabel(header, "TitleLabel", "Nenhum personagem",
		UDim2.new(0, 122, 0, 8), UDim2.new(0, 220, 0, 26), 18)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left

	tabButtons.nivelMinusBtn = makeButton(header, "NivelMinus", "-",
		UDim2.new(0, 122, 0, 40), UDim2.new(0, 24, 0, 24))
	tabButtons.nivelLabel = makeLabel(header, "NivelLabel", "NÍVEL -/-",
		UDim2.new(0, 150, 0, 40), UDim2.new(0, 100, 0, 24), 12)
	tabButtons.nivelPlusBtn = makeButton(header, "NivelPlus", "+",
		UDim2.new(0, 254, 0, 40), UDim2.new(0, 24, 0, 24))

	xpLabel = makeLabel(header, "XpLabel", "XP: -",
		UDim2.new(0, 122, 0, 70), UDim2.new(0, 156, 0, 16), 11)
	xpLabel.TextXAlignment = Enum.TextXAlignment.Left
	tabButtons.xpBarFill = makeFrame(
		makeFrame(header, "XpBarBg", UDim2.new(0, 156, 0, 6), UDim2.new(0, 122, 0, 92), Color3.fromRGB(45, 45, 45)),
		"Fill", UDim2.new(0, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 200, 0))

	tabButtons.alignmentBtn = makeButton(header, "AlignmentBtn", "TENDÊNCIA\nNeutro",
		UDim2.new(0, 298, 0, 8), UDim2.new(0, 110, 0, 50))
	tabButtons.alignmentBtn.TextSize = 11

	tabButtons.proficienciaLabel = makeLabel(header, "ProficienciaLabel", "PROFICIÊNCIA\n?",
		UDim2.new(0, 298, 0, 62), UDim2.new(0, 110, 0, 32), 11)

	categoryLabel = makeLabel(header, "CategoryLabel", "Categoria: —",
		UDim2.new(0, 122, 0, 104), UDim2.new(0, 300, 0, 18), 10)
	categoryLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
	categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
	geniusLabel = makeLabel(header, "GeniusLabel", "",
		UDim2.new(0, 420, 0, 8), UDim2.new(0, 160, 0, 18), 10)
	geniusLabel.TextColor3 = Color3.fromRGB(190, 170, 255)

	tabButtons.deslLabel = makeLabel(header, "DeslLabel", "DESL.\n-",
		UDim2.new(0, 420, 0, 32), UDim2.new(0, 90, 0, 32), 11)
	tabButtons.jogadorLabel = makeLabel(header, "JogadorLabel", "JOGADOR\n-",
		UDim2.new(0, 420, 0, 72), UDim2.new(0, 120, 0, 32), 11)

	local attrGrid = makeFrame(content, "AttrGrid", UDim2.new(1, 0, 0, 150), UDim2.new(0, 0, 0, 142), Color3.fromRGB(0, 0, 0))
	attrGrid.BackgroundTransparency = 1
	for i, attrName in ipairs(attributeNames) do
		local card = makeFrame(attrGrid, "Card_" .. attrName, UDim2.new(0, 138, 0, 140), UDim2.new(0, (i - 1) * 146, 0, 0), Color3.fromRGB(20, 20, 26))
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(0, 255, 157)
		stroke.Parent = card
		local nameLbl = makeLabel(card, "Name", attrName, UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 16), 12)
		nameLbl.Font = Enum.Font.GothamBold
		local valueLbl = makeLabel(card, "Value", "-", UDim2.new(0, 0, 0, 30), UDim2.new(1, 0, 0, 40), 26)
		valueLbl.Font = Enum.Font.GothamBold
		local modLbl = makeLabel(card, "Mod", "(+0)", UDim2.new(0, 0, 0, 72), UDim2.new(1, 0, 0, 18), 12)
		local trBadge = makeLabel(card, "TR", "+0", UDim2.new(0, 0, 0, 110), UDim2.new(1, 0, 0, 20), 12)
		trBadge.TextColor3 = Color3.fromRGB(150, 150, 160)
		tabButtons.attrCards[attrName] = { card = card, stroke = stroke, nameLbl = nameLbl, valueLbl = valueLbl, modLbl = modLbl, trBadge = trBadge }
	end

	local vitalsRow = makeFrame(content, "VitalsRow", UDim2.new(1, 0, 0, 66), UDim2.new(0, 0, 0, 300), Color3.fromRGB(0, 0, 0))
	vitalsRow.BackgroundTransparency = 1
	for i, v in ipairs(tabButtons.VITALS_INFO) do
		local box = makeFrame(vitalsRow, "Vital_" .. v.key, UDim2.new(0, 168, 0, 60), UDim2.new(0, (i - 1) * 176, 0, 0), Color3.fromRGB(20, 20, 26))
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
		local lbl = makeLabel(box, "Label", v.label, UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 16), 11)
		lbl.TextColor3 = v.color
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		local valLbl = makeLabel(box, "Value", "- / -", UDim2.new(0, 8, 0, 20), UDim2.new(1, -16, 0, 16), 12)
		valLbl.TextXAlignment = Enum.TextXAlignment.Left
		local barFill = makeFrame(
			makeFrame(box, "BarBg", UDim2.new(1, -16, 0, 6), UDim2.new(0, 8, 0, 44), Color3.fromRGB(45, 45, 45)),
			"Fill", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), v.color)
		tabButtons.vitalsBars[v.key] = { valLbl = valLbl, fill = barFill }
	end

	local reacoesBox = makeFrame(vitalsRow, "Vital_Reacoes", UDim2.new(0, 168, 0, 60), UDim2.new(0, 3 * 176, 0, 0), Color3.fromRGB(20, 20, 26))
	Instance.new("UICorner", reacoesBox).CornerRadius = UDim.new(0, 8)
	makeLabel(reacoesBox, "Label", "REAÇÕES", UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 16), 11).TextColor3 = Color3.fromRGB(190, 100, 255)
	tabButtons.reacoesValueLbl = makeLabel(reacoesBox, "Value", "-", UDim2.new(0, 8, 0, 22), UDim2.new(1, -16, 0, 26), 20)
	tabButtons.reacoesValueLbl.TextXAlignment = Enum.TextXAlignment.Left

	local armaduraBox = makeFrame(vitalsRow, "Vital_Armadura", UDim2.new(0, 168, 0, 60), UDim2.new(0, 4 * 176, 0, 0), Color3.fromRGB(20, 20, 26))
	Instance.new("UICorner", armaduraBox).CornerRadius = UDim.new(0, 8)
	makeLabel(armaduraBox, "Label", "ARMADURA", UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 16), 11).TextColor3 = Color3.fromRGB(200, 200, 200)
	tabButtons.armaduraValueLbl = makeLabel(armaduraBox, "Value", "-", UDim2.new(0, 8, 0, 22), UDim2.new(1, -16, 0, 26), 20)
	tabButtons.armaduraValueLbl.TextXAlignment = Enum.TextXAlignment.Left
end

hpLabel = { Text = "" }
auraLabel = { Text = "" }
sanidadeLabel = { Text = "" }

tabButtons.alignmentBtn.Activated:Connect(function()
	local current = tostring((GetCharacter:InvokeServer() or {}).Alignment or "Neutro")
	local nextIndex = 1
	for i, v in ipairs(tabButtons.ALIGNMENT_CYCLE) do
		if v == current then
			nextIndex = (i % #tabButtons.ALIGNMENT_CYCLE) + 1
			break
		end
	end
	local result = HxH5e.SetAlignment:InvokeServer(tabButtons.ALIGNMENT_CYCLE[nextIndex])
	if result and result.success then
		tabButtons.refreshFichaRef()
	end
end)

tabButtons.nivelPlusBtn.Activated:Connect(function()
	tabButtons.openLevelUp()
end)

tabButtons.nivelMinusBtn.Activated:Connect(function()
	showToast("Reduzir nível manualmente ainda não está implementado.", 3)
end)

-- ---------- Conteudo: NEN (dominio + hatsus, igual ao webapp) ----------

local nenScroll = Instance.new("ScrollingFrame")
nenScroll.Name = "NenScroll"
nenScroll.Size = UDim2.new(1, -20, 1, -180)
nenScroll.Position = UDim2.new(0, 10, 0, 72)
nenScroll.BackgroundTransparency = 1
nenScroll.ScrollBarThickness = 6
nenScroll.BorderSizePixel = 0
nenScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
nenScroll.ElasticBehavior = Enum.ElasticBehavior.Never
nenScroll.Visible = false
nenScroll.Parent = fichaFrame
do
	local nenLayout = Instance.new("UIListLayout")
	nenLayout.Padding = UDim.new(0, 4)
	nenLayout.SortOrder = Enum.SortOrder.LayoutOrder
	nenLayout.Parent = nenScroll
end

local pnLabel
do
	local dominioHeaderRow = makeFrame(nenScroll, "DominioHeader",
		UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0))
	dominioHeaderRow.BackgroundTransparency = 1
	dominioHeaderRow.LayoutOrder = 10

	local dominioTitle = makeLabel(dominioHeaderRow, "DominioTitle", "DOMÍNIO DE NEN",
		UDim2.new(0, 0, 0, 0), UDim2.new(0, 220, 1, 0), 13)
	dominioTitle.Font = Enum.Font.GothamBold
	dominioTitle.TextColor3 = Color3.fromRGB(0, 255, 157)
	dominioTitle.TextXAlignment = Enum.TextXAlignment.Left

	pnLabel = makeLabel(dominioHeaderRow, "PnLabel", "P.N: -",
		UDim2.new(0, 220, 0, 0), UDim2.new(0, 150, 1, 0), 12)
	pnLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
end

local FUND_NAMES = { "Ten", "Ren", "Zetsu" }
local dominioRows = {}
for i, name in ipairs(FUND_NAMES) do
	local rowFrame = makeFrame(nenScroll, "DomRow_" .. name,
		UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0))
	rowFrame.BackgroundTransparency = 1
	rowFrame.LayoutOrder = 20 + i
	local levelLabel = makeLabel(rowFrame, "Lvl", name .. ": -",
		UDim2.new(0, 0, 0, 0), UDim2.new(0, 80, 1, 0), 14)
	local trainButton = makeButton(rowFrame, "Train", "+1",
		UDim2.new(0, 90, 0, 0), UDim2.new(0, 40, 1, 0))
	trainButton.TextSize = 12
	local activateButton = makeButton(rowFrame, "Act", "ATIVAR",
		UDim2.new(0, 135, 0, 0), UDim2.new(0, 70, 1, 0))
	activateButton.TextSize = 11
	dominioRows[name] = { levelLabel = levelLabel, trainButton = trainButton, activateButton = activateButton }
end

do
	local advTitle = makeLabel(nenScroll, "AdvTitle", "PRINCÍPIOS AVANÇADOS",
		UDim2.new(0, 0, 0, 0), UDim2.new(0, 220, 0, 16), 12)
	advTitle.Font = Enum.Font.GothamBold
	advTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
	advTitle.TextXAlignment = Enum.TextXAlignment.Left
	advTitle.LayoutOrder = 30
end

local ADV_NAMES = { "En", "Inp", "Gyo", "Shu", "Ken", "Ko", "Ryu" }
local advRows = {}
for i, name in ipairs(ADV_NAMES) do
	local rowFrame = makeFrame(nenScroll, "AdvRow_" .. name,
		UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0))
	rowFrame.BackgroundTransparency = 1
	rowFrame.LayoutOrder = 40 + i
	local statusLabel = makeLabel(rowFrame, "Lvl", name .. ": —",
		UDim2.new(0, 0, 0, 0), UDim2.new(0, 100, 1, 0), 13)
	local unlockButton = makeButton(rowFrame, "Unlock", "DESBLOQ",
		UDim2.new(0, 110, 0, 0), UDim2.new(0, 90, 1, 0))
	unlockButton.TextSize = 10
	local activateButton = makeButton(rowFrame, "Act", "ATIVAR",
		UDim2.new(0, 205, 0, 0), UDim2.new(0, 70, 1, 0))
	activateButton.TextSize = 10
	advRows[name] = { statusLabel = statusLabel, unlockButton = unlockButton, activateButton = activateButton }
end

local nenMessageLabel = makeLabel(nenScroll, "NenMessage", "",
	UDim2.new(0, 0, 0, 0), UDim2.new(1, -10, 0, 40), 11)
nenMessageLabel.TextWrapped = true
nenMessageLabel.TextXAlignment = Enum.TextXAlignment.Left
nenMessageLabel.TextYAlignment = Enum.TextYAlignment.Top
nenMessageLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
nenMessageLabel.LayoutOrder = 50

do
	local hatsuSectionTitle = makeLabel(nenScroll, "HatsuSectionTitle", "HATSUS",
		UDim2.new(0, 0, 0, 0), UDim2.new(0, 220, 0, 20), 14)
	hatsuSectionTitle.Font = Enum.Font.GothamBold
	hatsuSectionTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
	hatsuSectionTitle.TextXAlignment = Enum.TextXAlignment.Left
	hatsuSectionTitle.LayoutOrder = 60
end

local hatsuCreateButton
do
	local hatsuActionRow = makeFrame(nenScroll, "HatsuActionRow",
		UDim2.new(1, 0, 0, 34), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0))
	hatsuActionRow.BackgroundTransparency = 1
	hatsuActionRow.LayoutOrder = 70

	hatsuCreateButton = makeButton(hatsuActionRow, "HatsuCreateButton", "CRIAR HATSU (WIZARD)",
		UDim2.new(0, 0, 0, 0), UDim2.new(0, 180, 1, 0))
	hatsuCreateButton.TextSize = 11
end

local hatsuMessageLabel = makeLabel(nenScroll, "HatsuMessage", "",
	UDim2.new(0, 0, 0, 0), UDim2.new(1, -10, 0, 32), 11)
hatsuMessageLabel.TextWrapped = true
hatsuMessageLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
hatsuMessageLabel.LayoutOrder = 80

local hatsuScroll = Instance.new("Frame")
hatsuScroll.Name = "HatsuScroll"
hatsuScroll.Size = UDim2.new(1, 0, 0, 60)
hatsuScroll.BackgroundTransparency = 1
hatsuScroll.AutomaticSize = Enum.AutomaticSize.Y
hatsuScroll.LayoutOrder = 90
hatsuScroll.Parent = nenScroll
do
	local hatsuLayout = Instance.new("UIListLayout")
	hatsuLayout.Padding = UDim.new(0, 6)
	hatsuLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hatsuLayout.Parent = hatsuScroll
end

local hatsuEmptyLabel = makeLabel(hatsuScroll, "HatsuEmpty",
	"Nenhum Hatsu ainda.\nClique em CRIAR HATSU (WIZARD).",
	UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 40), 12)
hatsuEmptyLabel.TextWrapped = true

-- ---------- Conteudo: TRAÇOS (raca, antecedente, inclinacoes, pericias) ----------

local tracosScroll = Instance.new("ScrollingFrame")
tracosScroll.Name = "TracosScroll"
tracosScroll.Size = UDim2.new(1, -20, 1, -180)
tracosScroll.Position = UDim2.new(0, 10, 0, 72)
tracosScroll.BackgroundTransparency = 1
tracosScroll.ScrollBarThickness = 6
tracosScroll.BorderSizePixel = 0
tracosScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
tracosScroll.ElasticBehavior = Enum.ElasticBehavior.Never
tracosScroll.Visible = false
tracosScroll.Parent = fichaFrame
do
	local tracosLayout = Instance.new("UIListLayout")
	tracosLayout.Padding = UDim.new(0, 8)
	tracosLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tracosLayout.Parent = tracosScroll
end

-- ---------- Conteudo: BIO (personalidade, historia, organizacoes, inimigos, aliados) ----------

local bioScroll = Instance.new("ScrollingFrame")
bioScroll.Name = "BioScroll"
bioScroll.Size = UDim2.new(1, -20, 1, -180)
bioScroll.Position = UDim2.new(0, 10, 0, 72)
bioScroll.BackgroundTransparency = 1
bioScroll.ScrollBarThickness = 6
bioScroll.BorderSizePixel = 0
bioScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
bioScroll.ElasticBehavior = Enum.ElasticBehavior.Never
bioScroll.Visible = false
bioScroll.Parent = fichaFrame
do
	local bioLayout = Instance.new("UIListLayout")
	bioLayout.Padding = UDim.new(0, 6)
	bioLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bioLayout.Parent = bioScroll
end

-- ---------- Conteudo: INV (inventario + loja) ----------
-- Reaproveita "tabButtons" de novo pra guardar o Frame (invScroll ja
-- seria mais um local de topo, e o arquivo esta no teto de 200).
tabButtons.invScroll = Instance.new("ScrollingFrame")
tabButtons.invScroll.Name = "InvScroll"
tabButtons.invScroll.Size = UDim2.new(1, -20, 1, -180)
tabButtons.invScroll.Position = UDim2.new(0, 10, 0, 72)
tabButtons.invScroll.BackgroundTransparency = 1
tabButtons.invScroll.ScrollBarThickness = 6
tabButtons.invScroll.BorderSizePixel = 0
tabButtons.invScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabButtons.invScroll.ElasticBehavior = Enum.ElasticBehavior.Never
tabButtons.invScroll.Visible = false
tabButtons.invScroll.Parent = fichaFrame
do
	local invLayout = Instance.new("UIListLayout")
	invLayout.Padding = UDim.new(0, 6)
	invLayout.SortOrder = Enum.SortOrder.LayoutOrder
	invLayout.Parent = tabButtons.invScroll
end

-- ================= Botões fixos da ficha =================

local xpButton = makeButton(fichaFrame, "XpButton", "+50 XP",
	UDim2.new(0, 20, 1, -92), UDim2.new(0, 110, 0, 36))
xpButton.TextSize = 12

local trocarButton = makeButton(fichaFrame, "TrocarButton", "TROCAR",
	UDim2.new(0, 140, 1, -92), UDim2.new(0, 140, 0, 36))
trocarButton.TextSize = 12

local criarButton = makeButton(fichaFrame, "CriarButton", "CRIAR PERSONAGEM",
	UDim2.new(0, 20, 1, -46), UDim2.new(0, 250, 0, 36))
criarButton.TextSize = 13

local fecharFichaButton = makeButton(fichaFrame, "FecharFichaButton", "FECHAR",
	UDim2.new(0, 280, 1, -46), UDim2.new(0, 100, 0, 36))
fecharFichaButton.TextSize = 13

-- ================= Lista de personagens =================

local listFrame = makeFrame(screenGui, "CharacterList",
	UDim2.fromOffset(420, 440), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
listFrame.AnchorPoint = Vector2.new(0.5, 0.5)
listFrame.Visible = false
addCloseButton(listFrame)

makeLabel(listFrame, "ListTitle", "SEUS PERSONAGENS",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 26), 18)

local listScroll = Instance.new("ScrollingFrame")
listScroll.Name = "ListScroll"
listScroll.Size = UDim2.new(1, -32, 1, -110)
listScroll.Position = UDim2.new(0, 16, 0, 44)
listScroll.BackgroundTransparency = 1
listScroll.ScrollBarThickness = 6
listScroll.BorderSizePixel = 0
listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
listScroll.ElasticBehavior = Enum.ElasticBehavior.Never
listScroll.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = listScroll

local emptyLabel = makeLabel(listScroll, "EmptyLabel",
	"Nenhum personagem ainda.\nClique em CRIAR PERSONAGEM.",
	UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 60), 15)
emptyLabel.TextWrapped = true

local criarListaButton = makeButton(listFrame, "CriarListaButton", "CRIAR PERSONAGEM",
	UDim2.new(0, 16, 1, -50), UDim2.new(0, 200, 0, 36))
local fecharListaButton = makeButton(listFrame, "FecharListaButton", "FECHAR",
	UDim2.new(0, 236, 1, -50), UDim2.new(0, 168, 0, 36))

-- ================= Janela de criação =================

local createFrame = makeFrame(screenGui, "CreateWindow",
	UDim2.fromOffset(360, 220), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
createFrame.AnchorPoint = Vector2.new(0.5, 0.5)
createFrame.Visible = false
addCloseButton(createFrame)

makeLabel(createFrame, "CreateTitle", "CRIAR PERSONAGEM",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 26), 18)

local nameBox = Instance.new("TextBox")
nameBox.Name = "NameBox"
nameBox.Size = UDim2.new(1, -32, 0, 36)
nameBox.Position = UDim2.new(0, 16, 0, 48)
nameBox.PlaceholderText = "Nome do personagem"
nameBox.Text = ""
nameBox.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 16
nameBox.BorderSizePixel = 0
nameBox.Parent = createFrame

local createErrorLabel = makeLabel(createFrame, "CreateError", "",
	UDim2.new(0, 16, 0, 92), UDim2.new(1, -32, 0, 40), 13)
createErrorLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
createErrorLabel.TextWrapped = true

local confirmButton = makeButton(createFrame, "ConfirmButton", "CONFIRMAR",
	UDim2.new(0, 16, 1, -46), UDim2.new(0, 160, 0, 36))
local cancelButton = makeButton(createFrame, "CancelButton", "CANCELAR",
	UDim2.new(0, 184, 1, -46), UDim2.new(0, 160, 0, 36))

-- ================= Janela de escolha de raça =================

local raceFrame = makeFrame(screenGui, "RaceWindow",
	UDim2.fromOffset(420, 460), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
raceFrame.AnchorPoint = Vector2.new(0.5, 0.5)
raceFrame.Visible = false
addCloseButton(raceFrame)

makeLabel(raceFrame, "RaceTitle", "ESCOLHA SUA RAÇA",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 26), 18)

local raceScroll = Instance.new("ScrollingFrame")
raceScroll.Name = "RaceScroll"
raceScroll.Size = UDim2.new(1, -32, 1, -60)
raceScroll.Position = UDim2.new(0, 16, 0, 44)
raceScroll.BackgroundTransparency = 1
raceScroll.ScrollBarThickness = 6
raceScroll.BorderSizePixel = 0
raceScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
raceScroll.ElasticBehavior = Enum.ElasticBehavior.Never
raceScroll.Parent = raceFrame

local raceLayout = Instance.new("UIListLayout")
raceLayout.Padding = UDim.new(0, 6)
raceLayout.Parent = raceScroll

-- ================= Janela de DETALHE da raça (descricao completa,
-- bonus, caracteristicas passivas e escolha de caracteristica) =================
-- Reaproveita tabButtons pro Frame/estado/funcoes (arquivo no teto de
-- 200 locais do Luau).
tabButtons.raceDetailFrame = makeFrame(screenGui, "RaceDetailWindow",
	UDim2.fromOffset(440, 520), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
tabButtons.raceDetailFrame.AnchorPoint = Vector2.new(0.5, 0.5)
tabButtons.raceDetailFrame.Visible = false
addCloseButton(tabButtons.raceDetailFrame)

tabButtons.raceDetailTitle = makeLabel(tabButtons.raceDetailFrame, "RDTitle", "RAÇA",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 24), 18)
tabButtons.raceDetailTitle.Font = Enum.Font.GothamBold
tabButtons.raceDetailTitle.TextColor3 = Color3.fromRGB(0, 255, 157)

tabButtons.raceDetailDesc = makeLabel(tabButtons.raceDetailFrame, "RDDesc", "",
	UDim2.new(0, 16, 0, 36), UDim2.new(1, -32, 0, 34), 12)
tabButtons.raceDetailDesc.TextWrapped = true
tabButtons.raceDetailDesc.TextXAlignment = Enum.TextXAlignment.Left
tabButtons.raceDetailDesc.TextYAlignment = Enum.TextYAlignment.Top
tabButtons.raceDetailDesc.TextColor3 = Color3.fromRGB(170, 170, 180)

tabButtons.raceDetailBonus = makeLabel(tabButtons.raceDetailFrame, "RDBonus", "",
	UDim2.new(0, 16, 0, 72), UDim2.new(1, -32, 0, 20), 13)
tabButtons.raceDetailBonus.Font = Enum.Font.GothamBold
tabButtons.raceDetailBonus.TextColor3 = Color3.fromRGB(255, 220, 120)
tabButtons.raceDetailBonus.TextXAlignment = Enum.TextXAlignment.Left

tabButtons.raceDetailScroll = Instance.new("ScrollingFrame")
tabButtons.raceDetailScroll.Name = "RDScroll"
tabButtons.raceDetailScroll.Size = UDim2.new(1, -32, 1, -160)
tabButtons.raceDetailScroll.Position = UDim2.new(0, 16, 0, 96)
tabButtons.raceDetailScroll.BackgroundTransparency = 1
tabButtons.raceDetailScroll.ScrollBarThickness = 6
tabButtons.raceDetailScroll.BorderSizePixel = 0
tabButtons.raceDetailScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabButtons.raceDetailScroll.ElasticBehavior = Enum.ElasticBehavior.Never
tabButtons.raceDetailScroll.Parent = tabButtons.raceDetailFrame
do
	local rdLayout = Instance.new("UIListLayout")
	rdLayout.Padding = UDim.new(0, 6)
	rdLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rdLayout.Parent = tabButtons.raceDetailScroll
end

tabButtons.raceDetailConfirm = makeButton(tabButtons.raceDetailFrame, "RDConfirm", "CONFIRMAR RAÇA",
	UDim2.new(0, 16, 1, -46), UDim2.new(1, -32, 0, 36))
tabButtons.raceDetailConfirm.BackgroundColor3 = Color3.fromRGB(0, 120, 70)

tabButtons.raceDetailData = nil
tabButtons.raceDetailEscolha = nil

-- Formata aumento_atributo (tabela {CON=2,...} OU string "Escolha +2"/
-- "Varia"/"Nenhum") num texto legivel de uma linha.
tabButtons.formatarBonusAtributo = function(bonus)
	if type(bonus) == "string" then
		if bonus == "Nenhum" then
			return "Bônus de Atributo: Nenhum"
		end
		return "Bônus de Atributo: " .. bonus .. " (escolha na próxima tela)"
	elseif type(bonus) == "table" then
		local partes = {}
		for attr, delta in pairs(bonus) do
			local sinal = delta >= 0 and "+" or ""
			table.insert(partes, attr .. " " .. sinal .. tostring(delta))
		end
		return "Bônus de Atributo: " .. table.concat(partes, ", ")
	end
	return "Bônus de Atributo: —"
end

tabButtons.refreshRaceDetail = function(race)
	tabButtons.raceDetailData = race
	tabButtons.raceDetailEscolha = nil
	tabButtons.raceDetailTitle.Text = tostring(race.nome) .. " — " .. tostring(race.categoria or "")
	tabButtons.raceDetailDesc.Text = tostring(race.descricao or "")
	tabButtons.raceDetailBonus.Text = tabButtons.formatarBonusAtributo(race.aumento_atributo)

	for _, child in ipairs(tabButtons.raceDetailScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local ordem = 0
	if race.caracteristicas and #race.caracteristicas > 0 then
		ordem = ordem + 1
		local titulo = makeLabel(tabButtons.raceDetailScroll, "CaracTitulo", "CARACTERÍSTICAS (recebe todas)",
			UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), 12)
		titulo.Font = Enum.Font.GothamBold
		titulo.TextColor3 = Color3.fromRGB(0, 255, 157)
		titulo.TextXAlignment = Enum.TextXAlignment.Left
		titulo.LayoutOrder = ordem
		for _, c in ipairs(race.caracteristicas) do
			ordem = ordem + 1
			local box = makeFrame(tabButtons.raceDetailScroll, "Carac_" .. ordem, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(30, 32, 44))
			box.AutomaticSize = Enum.AutomaticSize.Y
			box.LayoutOrder = ordem
			local nomeLbl = makeLabel(box, "Nome", tostring(c.nome), UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 16), 12)
			nomeLbl.Font = Enum.Font.GothamBold
			nomeLbl.TextXAlignment = Enum.TextXAlignment.Left
			local efeitoLbl = makeLabel(box, "Efeito", tostring(c.efeito), UDim2.new(0, 8, 0, 20), UDim2.new(1, -16, 0, 0), 11)
			efeitoLbl.AutomaticSize = Enum.AutomaticSize.Y
			efeitoLbl.TextWrapped = true
			efeitoLbl.TextXAlignment = Enum.TextXAlignment.Left
			efeitoLbl.TextYAlignment = Enum.TextYAlignment.Top
			efeitoLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
			box.Size = UDim2.new(1, 0, 0, 44)
		end
	end

	if race.opcoes_caracteristica and #race.opcoes_caracteristica > 0 then
		ordem = ordem + 1
		local titulo2 = makeLabel(tabButtons.raceDetailScroll, "EscolhaTitulo", "ESCOLHA UMA CARACTERÍSTICA",
			UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 18), 12)
		titulo2.Font = Enum.Font.GothamBold
		titulo2.TextColor3 = Color3.fromRGB(0, 255, 157)
		titulo2.TextXAlignment = Enum.TextXAlignment.Left
		titulo2.LayoutOrder = ordem
		for _, op in ipairs(race.opcoes_caracteristica) do
			ordem = ordem + 1
			local optBtn = Instance.new("TextButton")
			optBtn.Name = "Opt_" .. ordem
			optBtn.Text = ""
			optBtn.AutoButtonColor = false
			optBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 44)
			optBtn.BorderSizePixel = 0
			optBtn.Size = UDim2.new(1, 0, 0, 54)
			optBtn.AutomaticSize = Enum.AutomaticSize.Y
			optBtn.LayoutOrder = ordem
			optBtn.Parent = tabButtons.raceDetailScroll
			local nomeLbl = makeLabel(optBtn, "Nome", "○ " .. tostring(op.nome), UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 16), 12)
			nomeLbl.Font = Enum.Font.GothamBold
			nomeLbl.TextXAlignment = Enum.TextXAlignment.Left
			local efeitoLbl = makeLabel(optBtn, "Efeito", tostring(op.efeito), UDim2.new(0, 8, 0, 20), UDim2.new(1, -16, 0, 0), 11)
			efeitoLbl.AutomaticSize = Enum.AutomaticSize.Y
			efeitoLbl.TextWrapped = true
			efeitoLbl.TextXAlignment = Enum.TextXAlignment.Left
			efeitoLbl.TextYAlignment = Enum.TextYAlignment.Top
			efeitoLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
			optBtn.Activated:Connect(function()
				tabButtons.raceDetailEscolha = op.nome
				for _, sibling in ipairs(tabButtons.raceDetailScroll:GetChildren()) do
					if sibling:IsA("TextButton") then
						sibling.BackgroundColor3 = Color3.fromRGB(30, 32, 44)
						local nl = sibling:FindFirstChild("Nome")
						if nl then nl.Text = "○ " .. nl.Text:gsub("^[○●] ", "") end
					end
				end
				optBtn.BackgroundColor3 = Color3.fromRGB(0, 90, 60)
				nomeLbl.Text = "● " .. op.nome
			end)
		end
	end

	openWindow(tabButtons.raceDetailFrame)
end

tabButtons.raceDetailConfirm.Activated:Connect(function()
	local race = tabButtons.raceDetailData
	if not race then return end
	if race.opcoes_caracteristica and #race.opcoes_caracteristica > 0 and not tabButtons.raceDetailEscolha then
		showToast("Escolha uma característica antes de confirmar.", 3)
		return
	end
	pendingRace = race.nome
	tabButtons.pendingRaceCaracteristica = tabButtons.raceDetailEscolha
	closeWindow(tabButtons.raceDetailFrame)
	local req = GetRaceBonusInfo:InvokeServer(race.nome)
	if req then
		openRaceBonusStep(req)
	else
		pendingRaceBonusAllocations = nil
		openAttrStep()
	end
end)

-- ================= Janela de DETALHE do antecedente (descricao
-- completa, proficiencias, equipamento, escolha de caracteristica) =================
tabButtons.bgDetailFrame = makeFrame(screenGui, "BgDetailWindow",
	UDim2.fromOffset(440, 520), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
tabButtons.bgDetailFrame.AnchorPoint = Vector2.new(0.5, 0.5)
tabButtons.bgDetailFrame.Visible = false
addCloseButton(tabButtons.bgDetailFrame)

tabButtons.bgDetailTitle = makeLabel(tabButtons.bgDetailFrame, "BDTitle", "ANTECEDENTE",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 24), 18)
tabButtons.bgDetailTitle.Font = Enum.Font.GothamBold
tabButtons.bgDetailTitle.TextColor3 = Color3.fromRGB(0, 255, 157)

tabButtons.bgDetailDesc = makeLabel(tabButtons.bgDetailFrame, "BDDesc", "",
	UDim2.new(0, 16, 0, 36), UDim2.new(1, -32, 0, 50), 12)
tabButtons.bgDetailDesc.TextWrapped = true
tabButtons.bgDetailDesc.TextXAlignment = Enum.TextXAlignment.Left
tabButtons.bgDetailDesc.TextYAlignment = Enum.TextYAlignment.Top
tabButtons.bgDetailDesc.TextColor3 = Color3.fromRGB(170, 170, 180)

tabButtons.bgDetailScroll = Instance.new("ScrollingFrame")
tabButtons.bgDetailScroll.Name = "BDScroll"
tabButtons.bgDetailScroll.Size = UDim2.new(1, -32, 1, -140)
tabButtons.bgDetailScroll.Position = UDim2.new(0, 16, 0, 92)
tabButtons.bgDetailScroll.BackgroundTransparency = 1
tabButtons.bgDetailScroll.ScrollBarThickness = 6
tabButtons.bgDetailScroll.BorderSizePixel = 0
tabButtons.bgDetailScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabButtons.bgDetailScroll.ElasticBehavior = Enum.ElasticBehavior.Never
tabButtons.bgDetailScroll.Parent = tabButtons.bgDetailFrame
do
	local bdLayout = Instance.new("UIListLayout")
	bdLayout.Padding = UDim.new(0, 6)
	bdLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bdLayout.Parent = tabButtons.bgDetailScroll
end

tabButtons.bgDetailConfirm = makeButton(tabButtons.bgDetailFrame, "BDConfirm", "CONFIRMAR ANTECEDENTE",
	UDim2.new(0, 16, 1, -46), UDim2.new(1, -32, 0, 36))
tabButtons.bgDetailConfirm.BackgroundColor3 = Color3.fromRGB(0, 120, 70)

tabButtons.bgDetailData = nil
tabButtons.bgDetailEscolha = nil

tabButtons.refreshBgDetail = function(bg)
	tabButtons.bgDetailData = bg
	tabButtons.bgDetailEscolha = nil
	tabButtons.bgDetailTitle.Text = tostring(bg.nome)
	tabButtons.bgDetailDesc.Text = tostring(bg.descricao or "")

	for _, child in ipairs(tabButtons.bgDetailScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local ordem = 0

	if bg.proficiencias and #bg.proficiencias > 0 then
		ordem = ordem + 1
		local profLbl = makeLabel(tabButtons.bgDetailScroll, "ProfLbl", "PROFICIÊNCIAS: " .. tostring(bg.proficiencias),
			UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 0), 11)
		profLbl.AutomaticSize = Enum.AutomaticSize.Y
		profLbl.TextWrapped = true
		profLbl.TextXAlignment = Enum.TextXAlignment.Left
		profLbl.TextColor3 = Color3.fromRGB(120, 200, 255)
		profLbl.LayoutOrder = ordem
	end

	if bg.equipamento and #bg.equipamento > 0 then
		ordem = ordem + 1
		local eqTitulo = makeLabel(tabButtons.bgDetailScroll, "EqTitulo", "EQUIPAMENTO INICIAL",
			UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 18), 12)
		eqTitulo.Font = Enum.Font.GothamBold
		eqTitulo.TextColor3 = Color3.fromRGB(255, 220, 120)
		eqTitulo.TextXAlignment = Enum.TextXAlignment.Left
		eqTitulo.LayoutOrder = ordem
		for _, item in ipairs(bg.equipamento) do
			ordem = ordem + 1
			local itemLbl = makeLabel(tabButtons.bgDetailScroll, "Eq_" .. ordem, "• " .. tostring(item),
				UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 0), 11)
			itemLbl.AutomaticSize = Enum.AutomaticSize.Y
			itemLbl.TextWrapped = true
			itemLbl.TextXAlignment = Enum.TextXAlignment.Left
			itemLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
			itemLbl.LayoutOrder = ordem
		end
	end

	if bg.caracteristicas and #bg.caracteristicas > 0 then
		ordem = ordem + 1
		local titulo2 = makeLabel(tabButtons.bgDetailScroll, "EscolhaTitulo", "ESCOLHA UMA CARACTERÍSTICA",
			UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 18), 12)
		titulo2.Font = Enum.Font.GothamBold
		titulo2.TextColor3 = Color3.fromRGB(0, 255, 157)
		titulo2.TextXAlignment = Enum.TextXAlignment.Left
		titulo2.LayoutOrder = ordem
		for _, c in ipairs(bg.caracteristicas) do
			ordem = ordem + 1
			local optBtn = Instance.new("TextButton")
			optBtn.Name = "Opt_" .. ordem
			optBtn.Text = ""
			optBtn.AutoButtonColor = false
			optBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 44)
			optBtn.BorderSizePixel = 0
			optBtn.Size = UDim2.new(1, 0, 0, 54)
			optBtn.AutomaticSize = Enum.AutomaticSize.Y
			optBtn.LayoutOrder = ordem
			optBtn.Parent = tabButtons.bgDetailScroll
			local nomeLbl = makeLabel(optBtn, "Nome", "○ " .. tostring(c.nome), UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 16), 12)
			nomeLbl.Font = Enum.Font.GothamBold
			nomeLbl.TextXAlignment = Enum.TextXAlignment.Left
			local efeitoLbl = makeLabel(optBtn, "Efeito", tostring(c.efeito), UDim2.new(0, 8, 0, 20), UDim2.new(1, -16, 0, 0), 11)
			efeitoLbl.AutomaticSize = Enum.AutomaticSize.Y
			efeitoLbl.TextWrapped = true
			efeitoLbl.TextXAlignment = Enum.TextXAlignment.Left
			efeitoLbl.TextYAlignment = Enum.TextYAlignment.Top
			efeitoLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
			optBtn.Activated:Connect(function()
				tabButtons.bgDetailEscolha = c.nome
				for _, sibling in ipairs(tabButtons.bgDetailScroll:GetChildren()) do
					if sibling:IsA("TextButton") then
						sibling.BackgroundColor3 = Color3.fromRGB(30, 32, 44)
						local nl = sibling:FindFirstChild("Nome")
						if nl then nl.Text = "○ " .. nl.Text:gsub("^[○●] ", "") end
					end
				end
				optBtn.BackgroundColor3 = Color3.fromRGB(0, 90, 60)
				nomeLbl.Text = "● " .. c.nome
			end)
		end
	end

	openWindow(tabButtons.bgDetailFrame)
end

tabButtons.bgDetailConfirm.Activated:Connect(function()
	local bg = tabButtons.bgDetailData
	if not bg then return end
	if bg.caracteristicas and #bg.caracteristicas > 0 and not tabButtons.bgDetailEscolha then
		showToast("Escolha uma característica antes de confirmar.", 3)
		return
	end
	pendingBackground = bg.nome
	pendingBackgroundFeature = tabButtons.bgDetailEscolha
	closeWindow(tabButtons.bgDetailFrame)
	openInclinationsStep()
end)

-- ================= Janela de bônus racial (raças com "Escolha +2" etc.) =================

local raceBonusFrame = makeFrame(screenGui, "RaceBonusWindow",
	UDim2.fromOffset(360, 320), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
raceBonusFrame.AnchorPoint = Vector2.new(0.5, 0.5)
raceBonusFrame.Visible = false
addCloseButton(raceBonusFrame)

makeLabel(raceBonusFrame, "RaceBonusTitle", "BÔNUS RACIAL",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 24), 16)

local raceBonusInfoLabel = makeLabel(raceBonusFrame, "RaceBonusInfo", "",
	UDim2.new(0, 16, 0, 38), UDim2.new(1, -32, 0, 36), 12)
raceBonusInfoLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
raceBonusInfoLabel.TextWrapped = true

local raceBonusRows = {}
for i, key in ipairs(attributeNames) do
	local y = 80 + (i - 1) * 34
	local lbl = makeLabel(raceBonusFrame, "RaceBonusLbl_" .. key, key .. ": +0",
		UDim2.new(0, 16, 0, y), UDim2.new(0, 180, 0, 28), 14)
	local minusBtn = makeButton(raceBonusFrame, "RaceBonusMinus_" .. key, "-",
		UDim2.new(0, 200, 0, y), UDim2.new(0, 30, 0, 28))
	local plusBtn = makeButton(raceBonusFrame, "RaceBonusPlus_" .. key, "+",
		UDim2.new(0, 234, 0, y), UDim2.new(0, 30, 0, 28))
	local chooseBtn = makeButton(raceBonusFrame, "RaceBonusChoose_" .. key, "ESCOLHER " .. key,
		UDim2.new(0, 16, 0, y), UDim2.new(0, 248, 0, 28))
	chooseBtn.Visible = false
	raceBonusRows[key] = { label = lbl, minus = minusBtn, plus = plusBtn, choose = chooseBtn }
end

local raceBonusConfirmButton = makeButton(raceBonusFrame, "RaceBonusConfirm", "CONFIRMAR",
	UDim2.new(0, 16, 1, -46), UDim2.new(1, -32, 0, 36))
raceBonusConfirmButton.TextColor3 = Color3.fromRGB(0, 255, 157)

-- ================= Janela de atributos (compra de pontos) =================

local attrFrame = makeFrame(screenGui, "AttrWindow",
	UDim2.fromOffset(380, 460), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
attrFrame.AnchorPoint = Vector2.new(0.5, 0.5)
attrFrame.Visible = false
addCloseButton(attrFrame)

makeLabel(attrFrame, "AttrTitle", "ATRIBUTOS",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 24), 16)

local attrPointsLabel = makeLabel(attrFrame, "AttrPoints", "Pontos: 0 / 20",
	UDim2.new(0, 16, 0, 38), UDim2.new(1, -32, 0, 20), 12)
attrPointsLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
attrPointsLabel.TextWrapped = true

-- Abas de metodo (Compra/Rolagem/Array) -- reaproveita tabButtons pro
-- estado E pros Frames/Buttons (arquivo no teto de 200 locais do Luau,
-- ver aba BIO/INV).
tabButtons.attrMethod = "compra"
tabButtons.attrPool = {}
tabButtons.attrAssigned = {}

tabButtons.attrMethodTabsFrame = makeFrame(attrFrame, "AttrMethodTabs",
	UDim2.new(1, -32, 0, 26), UDim2.new(0, 16, 0, 62), Color3.fromRGB(0, 0, 0))
tabButtons.attrMethodTabsFrame.BackgroundTransparency = 1

tabButtons.attrActionButton = makeButton(attrFrame, "AttrAction", "ROLAR ATRIBUTOS",
	UDim2.new(0, 16, 0, 94), UDim2.new(1, -32, 0, 28))
tabButtons.attrActionButton.BackgroundColor3 = Color3.fromRGB(120, 40, 160)
tabButtons.attrActionButton.Visible = false

local attrRows = {}
for i, key in ipairs(attributeNames) do
	local y = 130 + (i - 1) * 44
	local lbl = makeLabel(attrFrame, "AttrLbl_" .. key, key .. ": 10  (custo 0)",
		UDim2.new(0, 16, 0, y), UDim2.new(0, 220, 0, 36), 14)
	local minusBtn = makeButton(attrFrame, "AttrMinus_" .. key, "-",
		UDim2.new(0, 250, 0, y), UDim2.new(0, 36, 0, 36))
	local plusBtn = makeButton(attrFrame, "AttrPlus_" .. key, "+",
		UDim2.new(0, 292, 0, y), UDim2.new(0, 36, 0, 36))
	attrRows[key] = { label = lbl, minus = minusBtn, plus = plusBtn }
end

local attrConfirmButton = makeButton(attrFrame, "AttrConfirm", "CONFIRMAR",
	UDim2.new(0, 16, 1, -46), UDim2.new(0, 160, 0, 36))
attrConfirmButton.TextColor3 = Color3.fromRGB(0, 255, 157)
local attrBackButton = makeButton(attrFrame, "AttrBack", "VOLTAR",
	UDim2.new(0, 184, 1, -46), UDim2.new(0, 160, 0, 36))

-- ================= Janela de antecedente =================

local bgFrame = makeFrame(screenGui, "BackgroundWindow",
	UDim2.fromOffset(440, 480), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
bgFrame.AnchorPoint = Vector2.new(0.5, 0.5)
bgFrame.Visible = false
addCloseButton(bgFrame)

makeLabel(bgFrame, "BgTitle", "ESCOLHA SEU ANTECEDENTE",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 26), 18)

local bgScroll = Instance.new("ScrollingFrame")
bgScroll.Name = "BgScroll"
bgScroll.Size = UDim2.new(1, -32, 1, -60)
bgScroll.Position = UDim2.new(0, 16, 0, 44)
bgScroll.BackgroundTransparency = 1
bgScroll.ScrollBarThickness = 6
bgScroll.BorderSizePixel = 0
bgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
bgScroll.ElasticBehavior = Enum.ElasticBehavior.Never
bgScroll.Parent = bgFrame

local bgLayout = Instance.new("UIListLayout")
bgLayout.Padding = UDim.new(0, 6)
bgLayout.Parent = bgScroll

-- ================= Janela de inclinações =================

local incFrame = makeFrame(screenGui, "IncWindow",
	UDim2.fromOffset(460, 500), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
incFrame.AnchorPoint = Vector2.new(0.5, 0.5)
incFrame.Visible = false
addCloseButton(incFrame)

makeLabel(incFrame, "IncTitle", "INCLINAÇÕES",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 24), 18)

local incSummaryLabel = makeLabel(incFrame, "IncSummary", "",
	UDim2.new(0, 16, 0, 36), UDim2.new(1, -32, 0, 32), 11)
incSummaryLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
incSummaryLabel.TextWrapped = true

local incTabsFrame = makeFrame(incFrame, "IncTabs",
	UDim2.new(1, -32, 0, 28), UDim2.new(0, 16, 0, 70), Color3.fromRGB(0, 0, 0))
incTabsFrame.BackgroundTransparency = 1

local incPosTab = makeButton(incTabsFrame, "IncPosTab", "POSITIVAS",
	UDim2.new(0, 0, 0, 0), UDim2.new(0, 150, 0, 26))
incPosTab.TextSize = 11
local incNegTab = makeButton(incTabsFrame, "IncNegTab", "NEGATIVAS",
	UDim2.new(0, 154, 0, 0), UDim2.new(0, 150, 0, 26))
incNegTab.TextSize = 11

local incScroll = Instance.new("ScrollingFrame")
incScroll.Name = "IncScroll"
incScroll.Size = UDim2.new(1, -32, 1, -168)
incScroll.Position = UDim2.new(0, 16, 0, 104)
incScroll.BackgroundTransparency = 1
incScroll.ScrollBarThickness = 6
incScroll.BorderSizePixel = 0
incScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
incScroll.ElasticBehavior = Enum.ElasticBehavior.Never
incScroll.Parent = incFrame

local incLayout = Instance.new("UIListLayout")
incLayout.Padding = UDim.new(0, 4)
incLayout.Parent = incScroll

local incConfirmButton = makeButton(incFrame, "IncConfirm", "CONFIRMAR E CRIAR",
	UDim2.new(0, 16, 1, -46), UDim2.new(0, 220, 0, 36))
incConfirmButton.TextColor3 = Color3.fromRGB(0, 255, 157)
local incBackButton = makeButton(incFrame, "IncBack", "VOLTAR",
	UDim2.new(0, 244, 1, -46), UDim2.new(0, 100, 0, 36))

-- ================= Janela de perícias/treinamentos =================

local skillFrame = makeFrame(screenGui, "SkillWindow",
	UDim2.fromOffset(440, 500), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
skillFrame.AnchorPoint = Vector2.new(0.5, 0.5)
skillFrame.Visible = false
addCloseButton(skillFrame)

makeLabel(skillFrame, "SkillTitle", "PERÍCIAS E TREINAMENTOS",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 24), 16)

local skillSummaryLabel = makeLabel(skillFrame, "SkillSummary", "",
	UDim2.new(0, 16, 0, 36), UDim2.new(1, -32, 0, 32), 11)
skillSummaryLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
skillSummaryLabel.TextWrapped = true

local skillTabsFrame = makeFrame(skillFrame, "SkillTabs",
	UDim2.new(1, -32, 0, 28), UDim2.new(0, 16, 0, 70), Color3.fromRGB(0, 0, 0))
skillTabsFrame.BackgroundTransparency = 1

local skillMainTab = makeButton(skillTabsFrame, "SkillMainTab", "PERÍCIAS",
	UDim2.new(0, 0, 0, 0), UDim2.new(0, 150, 0, 26))
skillMainTab.TextSize = 11
local skillOtherTab = makeButton(skillTabsFrame, "SkillOtherTab", "OUTROS TREINOS",
	UDim2.new(0, 154, 0, 0), UDim2.new(0, 150, 0, 26))
skillOtherTab.TextSize = 11

local skillScroll = Instance.new("ScrollingFrame")
skillScroll.Name = "SkillScroll"
skillScroll.Size = UDim2.new(1, -32, 1, -168)
skillScroll.Position = UDim2.new(0, 16, 0, 104)
skillScroll.BackgroundTransparency = 1
skillScroll.ScrollBarThickness = 6
skillScroll.BorderSizePixel = 0
skillScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
skillScroll.ElasticBehavior = Enum.ElasticBehavior.Never
skillScroll.Parent = skillFrame

local skillLayout = Instance.new("UIListLayout")
skillLayout.Padding = UDim.new(0, 3)
skillLayout.Parent = skillScroll

local skillConfirmButton = makeButton(skillFrame, "SkillConfirm", "CONFIRMAR E CRIAR",
	UDim2.new(0, 16, 1, -46), UDim2.new(0, 220, 0, 36))
skillConfirmButton.TextColor3 = Color3.fromRGB(0, 255, 157)
local skillBackButton = makeButton(skillFrame, "SkillBack", "VOLTAR",
	UDim2.new(0, 244, 1, -46), UDim2.new(0, 100, 0, 36))

-- ================= Janela de revelação =================

local resultFrame = makeFrame(screenGui, "AffinityResult",
	UDim2.fromOffset(360, 300), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
resultFrame.AnchorPoint = Vector2.new(0.5, 0.5)
resultFrame.Visible = false
addCloseButton(resultFrame)

makeLabel(resultFrame, "ResultTitle", "DESPERTAR DE NEN",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 26), 18)

local resultRollLabel = makeLabel(resultFrame, "ResultRoll", "",
	UDim2.new(0, 16, 0, 44), UDim2.new(1, -32, 0, 30), 24)
resultRollLabel.Font = Enum.Font.GothamBold

local resultGeniusLabel = makeLabel(resultFrame, "ResultGenius", "",
	UDim2.new(0, 16, 0, 78), UDim2.new(1, -32, 0, 24), 14)
resultGeniusLabel.TextColor3 = Color3.fromRGB(190, 170, 255)

local resultTierLabel = makeLabel(resultFrame, "ResultTier", "",
	UDim2.new(0, 16, 0, 106), UDim2.new(1, -32, 0, 22), 16)

local resultCategoryLabel = makeLabel(resultFrame, "ResultCategory", "",
	UDim2.new(0, 16, 0, 132), UDim2.new(1, -32, 0, 40), 18)
resultCategoryLabel.TextWrapped = true

local resultInfoLabel = makeLabel(resultFrame, "ResultInfo", "",
	UDim2.new(0, 16, 0, 174), UDim2.new(1, -32, 0, 60), 13)
resultInfoLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
resultInfoLabel.TextWrapped = true

local resultContinueButton = makeButton(resultFrame, "ResultContinue", "CONTINUAR",
	UDim2.new(0, 16, 1, -46), UDim2.new(1, -32, 0, 36))


-- ================= Janela de detalhes do Hatsu =================

local hatsuDetailFrame = makeFrame(screenGui, "HatsuDetail",
	UDim2.fromOffset(460, 560), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
hatsuDetailFrame.AnchorPoint = Vector2.new(0.5, 0.5)
hatsuDetailFrame.Visible = false
addCloseButton(hatsuDetailFrame)

local detailTitle = makeLabel(hatsuDetailFrame, "DetailTitle", "HATSU",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 26), 18)

local detailScroll = Instance.new("ScrollingFrame")
detailScroll.Name = "DetailScroll"
detailScroll.Size = UDim2.new(1, -32, 1, -50)
detailScroll.Position = UDim2.new(0, 16, 0, 44)
detailScroll.BackgroundTransparency = 1
detailScroll.ScrollBarThickness = 6
detailScroll.BorderSizePixel = 0
detailScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
detailScroll.ElasticBehavior = Enum.ElasticBehavior.Never
detailScroll.Parent = hatsuDetailFrame

local detailLayout = Instance.new("UIListLayout")
detailLayout.Padding = UDim.new(0, 8)
detailLayout.Parent = detailScroll

openHatsuDetail = function(hatsu)
	for _, child in ipairs(detailScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	detailTitle.Text = tostring(hatsu.Nome or "HATSU")
	local info = makeLabel(detailScroll, "Info",
		"Categoria: " .. tostring(hatsu.Tipo or "?")
			.. "\nNatureza: " .. tostring(hatsu.Natureza or "Ataque")
			.. "\nCusto de Aura: " .. tostring(hatsu.CustoAura or 50) .. "%"
			.. "\nCD TR: " .. tostring(hatsu.TR or 8)
			.. "\nDano: " .. tostring(hatsu.Graus and hatsu.Graus.Dano or 0) .. " graus",
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 90), 13)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.TextWrapped = true

	local eTitle = makeLabel(detailScroll, "ETitle", "EFEITOS",
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), 14)
	eTitle.Font = Enum.Font.GothamBold
	eTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
	eTitle.TextXAlignment = Enum.TextXAlignment.Left
	for _, e in ipairs(hatsu.Efeitos or {}) do
		local lbl = makeLabel(detailScroll, "E_" .. e.id,
			"• " .. tostring(e.nome or "?") .. " (" .. tostring(e.custo or 0) .. " P.N)",
			UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), 11)
		lbl.TextXAlignment = Enum.TextXAlignment.Left
	end

	local rTitle = makeLabel(detailScroll, "RTitle", "RESTRIÇÕES",
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), 14)
	rTitle.Font = Enum.Font.GothamBold
	rTitle.TextColor3 = Color3.fromRGB(255, 120, 120)
	rTitle.TextXAlignment = Enum.TextXAlignment.Left
	for _, r in ipairs(hatsu.Restricoes or {}) do
		local lbl = makeLabel(detailScroll, "R_" .. r.id,
			"• " .. tostring(r.nome or "?") .. " [" .. tostring(r.peso or "?") .. "]"
				.. (r.pura and " (PURA +" .. tostring(r.ganho or 0) .. ")" or ""),
			UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), 11)
		lbl.TextXAlignment = Enum.TextXAlignment.Left
	end
	openWindow(hatsuDetailFrame)
end

-- ================= Lógica =================

local function refreshNen()
	local status = GetNenStatus:InvokeServer()
	if not status then
		pnLabel.Text = "P.N: -"
		for _, name in ipairs(FUND_NAMES) do
			dominioRows[name].levelLabel.Text = name .. ": -"
		end
		for _, name in ipairs(ADV_NAMES) do
			advRows[name].statusLabel.Text = name .. ": —"
		end
		return
	end
	pnLabel.Text = "P.N: " .. tostring(status.PNDisponivel)
	local d = status.Dominio or {}
	for _, name in ipairs(FUND_NAMES) do
		dominioRows[name].levelLabel.Text = name .. ": " .. tostring(d[name] or 0)
	end
	for _, name in ipairs(ADV_NAMES) do
		local unlocked = d[name]
		local sup = d[name .. "_sup"]
		local label = name .. ": "
		if unlocked then
			label = label .. (sup and "Sup" or "Ok")
		else
			label = label .. "Bloq"
		end
		advRows[name].statusLabel.Text = label
	end
end

local function refreshFicha()
	local character = GetCharacter:InvokeServer()
	if not character then
		titleLabel.Text = "Nenhum personagem"
		categoryLabel.Text = "Categoria: —"
		geniusLabel.Text = ""
		xpLabel.Text = "XP: -"
		tabButtons.nivelLabel.Text = "NÍVEL -/-"
		for _, attrName in ipairs(attributeNames) do
			local c = tabButtons.attrCards[attrName]
			c.valueLbl.Text = "-"
			c.modLbl.Text = ""
			c.trBadge.Text = ""
		end
		for _, v in ipairs(tabButtons.VITALS_INFO) do
			tabButtons.vitalsBars[v.key].valLbl.Text = "- / -"
		end
		tabButtons.reacoesValueLbl.Text = "-"
		tabButtons.armaduraValueLbl.Text = "-"
		refreshNen()
		return
	end

	titleLabel.Text = character.Name
	tabButtons.nivelLabel.Text = "NÍVEL " .. tostring(character.Level) .. "/12"

	local nen = character.Nen or {}
	local category = nen.Category or character.Class or nil
	local themeColor = tabButtons.NenColors.Get(category)
	tabButtons.fichaHeaderStroke.Color = themeColor
	tabButtons.fichaPortraitStroke.Color = themeColor
	tabButtons.xpBarFill.BackgroundColor3 = themeColor

	if category then
		local tier = nen.Affinity and nen.Affinity.Tier
		local roll = nen.Affinity and nen.Affinity.Roll
		local extra = ""
		if tier then extra = " — Afinidade " .. tostring(tier) end
		if roll then extra = extra .. " (" .. tostring(roll) .. ")" end
		categoryLabel.Text = "Categoria: " .. tostring(category) .. extra
	else
		categoryLabel.Text = "Categoria: —"
	end

	if nen.Genius and nen.Genius.Tier then
		geniusLabel.Text = "Genialidade: " .. tostring(nen.Genius.Tier) .. " (" .. tostring(nen.Genius.Roll) .. ")"
	else
		geniusLabel.Text = ""
	end

	local xp = character.XP or 0
	local xpNext = character.XPNext or 50
	xpLabel.Text = "XP  " .. tostring(xp) .. " / " .. tostring(xpNext)
	local xpPct = xpNext > 0 and math.clamp(xp / xpNext, 0, 1) or 0
	tabButtons.xpBarFill.Size = UDim2.new(xpPct, 0, 1, 0)

	tabButtons.alignmentBtn.Text = "TENDÊNCIA\n" .. tostring(character.Alignment or "Neutro")
	tabButtons.proficienciaLabel.Text = "PROFICIÊNCIA\n?" -- pendente: aguardando definicao exata com o Lucas
	tabButtons.deslLabel.Text = "DESL.\n" .. tostring(character.Vitals and character.Vitals.Deslocamento or "-") .. "m"
	tabButtons.jogadorLabel.Text = "JOGADOR\n" .. tostring(game.Players.LocalPlayer.DisplayName)

	for _, attrName in ipairs(attributeNames) do
		local c = tabButtons.attrCards[attrName]
		c.stroke.Color = themeColor
		c.nameLbl.TextColor3 = themeColor
		local attr = character.Attributes and character.Attributes[attrName]
		local value = attr and attr.value or 10
		local mod = math.floor((value - 10) / 2)
		c.valueLbl.Text = tostring(value)
		c.modLbl.Text = (mod >= 0 and "(+" or "(") .. tostring(mod) .. ")"

		local trSkill = "TR de " .. attrName
		local trBonus = mod
		local isExpert = false
		local isTrained = false
		for _, s in ipairs(character.Expertise or {}) do
			if s == trSkill then isExpert = true break end
		end
		if not isExpert then
			for _, s in ipairs(character.Skills or {}) do
				if s == trSkill then isTrained = true break end
			end
		end
		if isExpert then
			trBonus = trBonus + 3
			c.trBadge.TextColor3 = Color3.fromRGB(255, 220, 0)
		elseif isTrained then
			trBonus = trBonus + 2
			c.trBadge.TextColor3 = themeColor
		else
			c.trBadge.TextColor3 = Color3.fromRGB(110, 110, 118)
		end
		c.trBadge.Text = (trBonus >= 0 and "+" or "") .. tostring(trBonus)
	end

	if character.Vitals then
		for _, v in ipairs(tabButtons.VITALS_INFO) do
			local vit = character.Vitals[v.key]
			local bar = tabButtons.vitalsBars[v.key]
			if vit then
				bar.valLbl.Text = tostring(vit.Current) .. " / " .. tostring(vit.Max)
				local pct = vit.Max > 0 and math.clamp(vit.Current / vit.Max, 0, 1) or 0
				bar.fill.Size = UDim2.new(pct, 0, 1, 0)
			end
		end
		tabButtons.reacoesValueLbl.Text = tostring(character.Vitals.Reacoes or "-")
		tabButtons.armaduraValueLbl.Text = tostring(character.Vitals.CA or "-")
	end

	refreshNen()
end
tabButtons.refreshFichaRef = refreshFicha

local function refreshList()
	for _, child in ipairs(listScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local characters = GetCharacters:InvokeServer() or {}
	emptyLabel.Visible = (#characters == 0)

	for index, character in ipairs(characters) do
		local row = makeFrame(listScroll, "Row_" .. index,
			UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), Color3.fromRGB(38, 42, 58))

		local rowName = makeLabel(row, "RowName", character.Name,
			UDim2.new(0, 12, 0, 0), UDim2.new(0, 170, 1, 0), 16)
		rowName.TextXAlignment = Enum.TextXAlignment.Left

		local rowLevel = makeLabel(row, "RowLevel", "Nível " .. tostring(character.Level),
			UDim2.new(0, 190, 0, 0), UDim2.new(0, 70, 1, 0), 14)
		rowLevel.TextXAlignment = Enum.TextXAlignment.Left
		rowLevel.TextColor3 = Color3.fromRGB(170, 170, 180)

		local selectButton = makeButton(row, "SelectButton",
			character.IsActive and "ATIVO" or "SELECIONAR",
			UDim2.new(1, -110, 0, 6), UDim2.new(0, 104, 1, -12))
		selectButton.TextSize = 13
		selectButton.BackgroundColor3 = character.IsActive
			and Color3.fromRGB(60, 90, 60)
			or Color3.fromRGB(48, 62, 110)

		selectButton.Activated:Connect(function()
			if character.IsActive then
				return
			end
			local ok = SetActiveCharacter:InvokeServer(character.Id)
			if ok then
				closeWindow(listFrame)
				refreshFicha()
				setFichaTab("FICHA")
				openWindow(fichaFrame)
			end
		end)

		local excluirCharButton = makeButton(row, "ExcluirChar", "EXCLUIR",
			UDim2.new(1, -110, 0, 6), UDim2.new(0, 104, 1, -12))
		excluirCharButton.TextSize = 11
		excluirCharButton.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
		excluirCharButton.Position = UDim2.new(1, -110, 0, 6)
		-- Empilha o botao EXCLUIR embaixo do SELECIONAR/ATIVO (linha ganha altura)
		row.Size = UDim2.new(1, 0, 0, 68)
		selectButton.Size = UDim2.new(0, 104, 0, 26)
		selectButton.Position = UDim2.new(1, -110, 0, 4)
		excluirCharButton.Size = UDim2.new(0, 104, 0, 26)
		excluirCharButton.Position = UDim2.new(1, -110, 0, 36)
		excluirCharButton.Activated:Connect(function()
			local result = DeleteCharacter:InvokeServer(character.Id)
			if result then
				showToast(tostring(result.message or result.error))
			end
			refreshList()
			refreshFicha()
		end)
	end
end

local function refreshHatsus()
	for _, child in ipairs(hatsuScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local hatsus = GetHatsus:InvokeServer() or {}
	hatsuEmptyLabel.Visible = (#hatsus == 0)
	for index, hatsu in ipairs(hatsus) do
		local row = makeFrame(hatsuScroll, "HRow_" .. index,
			UDim2.new(1, 0, 0, 96), UDim2.new(0, 0, 0, 0), Color3.fromRGB(38, 42, 58))
		row.LayoutOrder = index

		local restricoes = hatsu.Restricoes or {}
		local contagem = #restricoes

		local rowName = makeLabel(row, "HName",
			tostring(hatsu.Nome or "?") .. " (" .. tostring(hatsu.Tipo or "?") .. ")",
			UDim2.new(0, 12, 0, 4), UDim2.new(0, 150, 0, 20), 14)
		rowName.TextXAlignment = Enum.TextXAlignment.Left

		local rowGraus = makeLabel(row, "HGraus",
			"Dano: " .. tostring(hatsu.Graus and hatsu.Graus.Dano or 0)
				.. " • Custo: " .. tostring(hatsu.CustoAura or 50) .. "% aura"
				.. " • Restr: " .. tostring(contagem),
			UDim2.new(0, 12, 0, 26), UDim2.new(0, 150, 0, 44), 10)
		rowGraus.TextXAlignment = Enum.TextXAlignment.Left
		rowGraus.TextWrapped = true
		rowGraus.TextColor3 = Color3.fromRGB(170, 170, 180)

		-- Coluna esquerda (X = 1, -180): DETALHES em cima, EXCLUIR embaixo
		local detalhesButton = makeButton(row, "HDetalhes", "DETALHES",
			UDim2.new(1, -180, 0, 4), UDim2.new(0, 80, 0, 26))
		detalhesButton.TextSize = 10
		detalhesButton.BackgroundColor3 = Color3.fromRGB(48, 62, 110)
		detalhesButton.Activated:Connect(function()
			openHatsuDetail(hatsu)
		end)

		local excluirButton = makeButton(row, "HExcluir", "EXCLUIR",
			UDim2.new(1, -180, 0, 34), UDim2.new(0, 80, 0, 26))
		excluirButton.TextSize = 9
		excluirButton.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
		excluirButton.Activated:Connect(function()
			local result = DeleteHatsu:InvokeServer(hatsu.Id)
			if result then
				showToast(tostring(result.message or result.error), 4)
			end
			refreshHatsus()
			refreshFicha()
		end)

		-- Coluna direita (X = 1, -90): USAR em cima, EDITAR no meio, +DANO embaixo
		local useButton = makeButton(row, "HUse", "USAR",
			UDim2.new(1, -90, 0, 4), UDim2.new(0, 80, 0, 28))
		useButton.TextSize = 12
		useButton.Activated:Connect(function()
			local result = ActivateHatsu:InvokeServer(hatsu.Id)
			if result then
				local r = result.resultado
				if r and r.rolagem then
					showToast(tostring(r.nome or "Hatsu") .. "\n" .. tostring(r.rolagem), 6)
				elseif r and r.mensagem then
					showToast(tostring(r.mensagem), 4)
				else
					showToast(tostring(result.error or ""), 4)
				end
			end
			refreshFicha()
		end)

		local editarButton = makeButton(row, "HEditar", "EDITAR",
			UDim2.new(1, -90, 0, 34), UDim2.new(0, 80, 0, 26))
		editarButton.TextSize = 10
		editarButton.BackgroundColor3 = Color3.fromRGB(48, 62, 110)
		editarButton.Activated:Connect(function()
			wizardOpen(hatsu)
		end)

		local grauButton = makeButton(row, "HGrau", "+DANO",
			UDim2.new(1, -90, 0, 66), UDim2.new(0, 80, 0, 26))
		grauButton.TextSize = 10
		grauButton.Activated:Connect(function()
			local result = AddGrau:InvokeServer(hatsu.Id, "Dano")
			if result then
				showToast(tostring(result.message or result.error), 3)
			end
			refreshHatsus()
		end)
	end
end

-- ---------- Troca de guia ----------

-- ---------- BIO: reaproveita a tabela "tabButtons" pra guardar a funcao
-- refreshBio e o estado do sanfona, SEM criar novo local de topo (o
-- arquivo ja esta no teto de 200 locais do Luau nesse escopo principal).
tabButtons.bioExpanded = { Personalidade = true, Historia = false, Organizacoes = false, Inimigos = false, Aliados = false }

tabButtons.refreshBio = function()
	for _, child in ipairs(bioScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local character = GetCharacter:InvokeServer()
	if not character then
		local lbl = makeLabel(bioScroll, "Empty", "Nenhum personagem ativo.",
			UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 30), 13)
		return
	end
	local characterId = character.Id
	local bio = character.Bio or {}

	local function saveField(field, value)
		HxH5e.SetBioField:InvokeServer(characterId, field, value)
	end

	local function addTextBox(parent, name, placeholder, initialText, sizeY, posY, field)
		local box = Instance.new("TextBox")
		box.Name = name
		box.Size = UDim2.new(1, -16, 0, sizeY)
		box.Position = UDim2.new(0, 8, 0, posY)
		box.PlaceholderText = placeholder
		box.Text = initialText or ""
		box.MultiLine = true
		box.TextWrapped = true
		box.ClearTextOnFocus = false
		box.BackgroundColor3 = Color3.fromRGB(30, 32, 44)
		box.TextColor3 = Color3.fromRGB(120, 200, 255)
		box.PlaceholderColor3 = Color3.fromRGB(120, 120, 135)
		box.Font = Enum.Font.Gotham
		box.TextSize = 13
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextYAlignment = Enum.TextYAlignment.Top
		box.BorderSizePixel = 0
		box.Parent = parent
		box.FocusLost:Connect(function()
			saveField(field, box.Text)
		end)
		return box
	end

	local SECOES = {
		{ id = "Personalidade", titulo = "PERSONALIDADE" },
		{ id = "Historia", titulo = "HISTÓRIA" },
		{ id = "Organizacoes", titulo = "ORGANIZAÇÕES" },
		{ id = "Inimigos", titulo = "INIMIGOS" },
		{ id = "Aliados", titulo = "ALIADOS" },
	}

	for si, secao in ipairs(SECOES) do
		local expandido = tabButtons.bioExpanded[secao.id]
		local alturaConteudo = 0
		if expandido then
			if secao.id == "Personalidade" then
				alturaConteudo = 8 + 70 + 8 + 70 + 8 + 90 + 8
			else
				alturaConteudo = 8 + 120 + 8
			end
		end
		local sectionFrame = makeFrame(bioScroll, "BioSec_" .. secao.id,
			UDim2.new(1, 0, 0, 34 + alturaConteudo), UDim2.new(0, 0, 0, 0), Color3.fromRGB(30, 32, 44))
		sectionFrame.LayoutOrder = si

		local headerBtn = makeButton(sectionFrame, "Header", (expandido and "▼ " or "▶ ") .. secao.titulo,
			UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 34))
		headerBtn.TextXAlignment = Enum.TextXAlignment.Left
		headerBtn.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
		headerBtn.TextSize = 13
		headerBtn.Activated:Connect(function()
			tabButtons.bioExpanded[secao.id] = not tabButtons.bioExpanded[secao.id]
			tabButtons.refreshBio()
		end)

		if expandido then
			if secao.id == "Personalidade" then
				addTextBox(sectionFrame, "Tracos", "Descreva como seu personagem se comporta...", bio.Personality, 70, 40, "Personality")
				addTextBox(sectionFrame, "Sonho", "Qual a maior desejo do seu personagem?", bio.Goals, 70, 118, "Goals")
				local odeioLbl = makeLabel(sectionFrame, "OdeioLbl", "O QUE ODEIO", UDim2.new(0, 8, 0, 196), UDim2.new(0.5, -12, 0, 14), 10)
				odeioLbl.TextColor3 = Color3.fromRGB(150, 150, 165)
				local gostoLbl = makeLabel(sectionFrame, "GostoLbl", "O QUE GOSTO", UDim2.new(0.5, 4, 0, 196), UDim2.new(0.5, -12, 0, 14), 10)
				gostoLbl.TextColor3 = Color3.fromRGB(150, 150, 165)
				local odeioBox = Instance.new("TextBox")
				odeioBox.Name = "Odeio"
				odeioBox.Size = UDim2.new(0.5, -12, 0, 66)
				odeioBox.Position = UDim2.new(0, 8, 0, 212)
				odeioBox.PlaceholderText = "O que te tira do sério..."
				odeioBox.Text = bio.Hates or ""
				odeioBox.MultiLine = true
				odeioBox.TextWrapped = true
				odeioBox.ClearTextOnFocus = false
				odeioBox.BackgroundColor3 = Color3.fromRGB(30, 32, 44)
				odeioBox.TextColor3 = Color3.fromRGB(120, 200, 255)
				odeioBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 135)
				odeioBox.Font = Enum.Font.Gotham
				odeioBox.TextSize = 13
				odeioBox.TextXAlignment = Enum.TextXAlignment.Left
				odeioBox.TextYAlignment = Enum.TextYAlignment.Top
				odeioBox.BorderSizePixel = 0
				odeioBox.Parent = sectionFrame
				odeioBox.FocusLost:Connect(function() saveField("Hates", odeioBox.Text) end)
				local gostoBox = Instance.new("TextBox")
				gostoBox.Name = "Gosto"
				gostoBox.Size = UDim2.new(0.5, -12, 0, 66)
				gostoBox.Position = UDim2.new(0.5, 4, 0, 212)
				gostoBox.PlaceholderText = "O que te agrada..."
				gostoBox.Text = bio.Likes or ""
				gostoBox.MultiLine = true
				gostoBox.TextWrapped = true
				gostoBox.ClearTextOnFocus = false
				gostoBox.BackgroundColor3 = Color3.fromRGB(30, 32, 44)
				gostoBox.TextColor3 = Color3.fromRGB(120, 200, 255)
				gostoBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 135)
				gostoBox.Font = Enum.Font.Gotham
				gostoBox.TextSize = 13
				gostoBox.TextXAlignment = Enum.TextXAlignment.Left
				gostoBox.TextYAlignment = Enum.TextYAlignment.Top
				gostoBox.BorderSizePixel = 0
				gostoBox.Parent = sectionFrame
				gostoBox.FocusLost:Connect(function() saveField("Likes", gostoBox.Text) end)
			elseif secao.id == "Historia" then
				addTextBox(sectionFrame, "Campo", "Escreva a história do seu personagem...", bio.Historia, 120, 40, "Historia")
			elseif secao.id == "Organizacoes" then
				addTextBox(sectionFrame, "Campo", "Organizações aliadas e seu grau de poder/autoridade nelas...", bio.Organizacoes, 120, 40, "Organizacoes")
			elseif secao.id == "Inimigos" then
				addTextBox(sectionFrame, "Campo", "Inimigos do seu personagem...", bio.Inimigos, 120, 40, "Inimigos")
			elseif secao.id == "Aliados" then
				addTextBox(sectionFrame, "Campo", "Aliados do seu personagem...", bio.Aliados, 120, 40, "Aliados")
			end
		end
	end
end

-- ---------- INV: inventario + loja. Reaproveita "tabButtons" de novo
-- (estado + funcao), pelo mesmo motivo do BIO -- arquivo no teto de 200
-- locais do Luau.
tabButtons.invCategoria = "armas"
tabButtons.invBusca = ""

tabButtons.refreshInv = function()
	local scroll = tabButtons.invScroll
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextBox") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local character = GetCharacter:InvokeServer()
	if not character then
		local lbl = makeLabel(scroll, "Empty", "Nenhum personagem ativo.",
			UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 30), 13)
		return
	end

	local moneyLbl = makeLabel(scroll, "Money", "DINHEIRO: $" .. tostring(character.Money or 0),
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 22), 15)
	moneyLbl.Font = Enum.Font.GothamBold
	moneyLbl.TextColor3 = Color3.fromRGB(255, 220, 120)
	moneyLbl.LayoutOrder = 1

	local invTitle = makeLabel(scroll, "InvTitle", "SEU INVENTÁRIO",
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), 13)
	invTitle.Font = Enum.Font.GothamBold
	invTitle.TextColor3 = Color3.fromRGB(0, 255, 157)
	invTitle.LayoutOrder = 2

	local inventario = character.Inventory or {}
	if #inventario == 0 then
		local vazio = makeLabel(scroll, "InvVazio", "Nenhum item ainda.",
			UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), 11)
		vazio.TextColor3 = Color3.fromRGB(150, 150, 165)
		vazio.LayoutOrder = 3
	end
	for ii, item in ipairs(inventario) do
		local row = makeFrame(scroll, "InvItem_" .. ii, UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0), Color3.fromRGB(38, 42, 58))
		row.LayoutOrder = 3 + ii
		local lbl = makeLabel(row, "Lbl", item.Name .. "  x" .. item.Qty,
			UDim2.new(0, 8, 0, 0), UDim2.new(1, -100, 1, 0), 12)
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		local sellBtn = makeButton(row, "Sell", "VENDER 1",
			UDim2.new(1, -92, 0, 3), UDim2.new(0, 84, 0, 26))
		sellBtn.TextSize = 10
		sellBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
		sellBtn.Activated:Connect(function()
			local result = HxH5e.SellItem:InvokeServer(item.Name, 1)
			showToast(tostring(result and (result.message or result.error)), 3)
			tabButtons.refreshInv()
		end)
	end

	local lojaTitle = makeLabel(scroll, "LojaTitle", "LOJA",
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), 13)
	lojaTitle.Font = Enum.Font.GothamBold
	lojaTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
	lojaTitle.LayoutOrder = 1000

	local buscaBox = Instance.new("TextBox")
	buscaBox.Name = "InvBusca"
	buscaBox.Size = UDim2.new(1, 0, 0, 30)
	buscaBox.PlaceholderText = "🔍 Buscar item por nome (todas as categorias)..."
	buscaBox.Text = tabButtons.invBusca
	buscaBox.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
	buscaBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	buscaBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
	buscaBox.Font = Enum.Font.Gotham
	buscaBox.TextSize = 13
	buscaBox.BorderSizePixel = 0
	buscaBox.LayoutOrder = 1001
	buscaBox.Parent = scroll
	buscaBox.FocusLost:Connect(function()
		tabButtons.invBusca = buscaBox.Text
		tabButtons.refreshInv()
	end)

	local CATEGORIAS = {
		{ id = "armas", label = "Armas" },
		{ id = "armaduras", label = "Armaduras" },
		{ id = "municoes", label = "Munições" },
		{ id = "itens_medicos", label = "Médicos" },
		{ id = "kits", label = "Kits" },
		{ id = "equipamentos_gerais", label = "Gerais" },
	}
	local abasFrame = makeFrame(scroll, "CategoriaAbas", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0))
	abasFrame.BackgroundTransparency = 1
	abasFrame.LayoutOrder = 1002
	for ci, catInfo in ipairs(CATEGORIAS) do
		local btn = makeButton(abasFrame, "Cat_" .. catInfo.id, catInfo.label,
			UDim2.new(0, (ci - 1) * 84, 0, 0), UDim2.new(0, 80, 0, 26))
		btn.TextSize = 9
		btn.BackgroundColor3 = (tabButtons.invCategoria == catInfo.id)
			and Color3.fromRGB(0, 255, 157) or Color3.fromRGB(38, 42, 58)
		btn.TextColor3 = (tabButtons.invCategoria == catInfo.id)
			and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(255, 255, 255)
		btn.Activated:Connect(function()
			tabButtons.invCategoria = catInfo.id
			tabButtons.refreshInv()
		end)
	end

	local ItemsDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("ItemsDB"))
	local buscaAtiva = #tabButtons.invBusca > 0
	local listaItens = buscaAtiva and ItemsDB.Todos or (ItemsDB[tabButtons.invCategoria] or {})

	local ordem = 1003
	for _, item in ipairs(listaItens) do
		local bate = (not buscaAtiva) or item.nome:lower():find(tabButtons.invBusca:lower(), 1, true) ~= nil
		if bate then
			ordem = ordem + 1
			local row = makeFrame(scroll, "Shop_" .. ordem, UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0), Color3.fromRGB(30, 32, 44))
			row.LayoutOrder = ordem
			local infoTxt = item.nome .. "  ($" .. item.custo .. ")"
			if item.dano then infoTxt = infoTxt .. " — " .. item.dano end
			if item.ca then infoTxt = infoTxt .. " — CA " .. tostring(item.ca) end
			local lbl = makeLabel(row, "Lbl", infoTxt,
				UDim2.new(0, 8, 0, 0), UDim2.new(1, -100, 1, 0), 11)
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextWrapped = true
			local buyBtn = makeButton(row, "Buy", "COMPRAR",
				UDim2.new(1, -92, 0, 3), UDim2.new(0, 84, 0, 26))
			buyBtn.TextSize = 10
			buyBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 70)
			buyBtn.Activated:Connect(function()
				local result = HxH5e.BuyItem:InvokeServer(item.nome, 1)
				showToast(tostring(result and (result.message or result.error)), 3)
				tabButtons.refreshInv()
			end)
		end
	end
end

local function refreshTracos()
	for _, child in ipairs(tracosScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local character = GetCharacter:InvokeServer()
	if not character then
		local lbl = makeLabel(tracosScroll, "Empty", "Nenhum personagem ativo.",
			UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 30), 13)
		return
	end

	local sectionOrder = 0
	local function addSection(titleText, bodyText, color)
		sectionOrder = sectionOrder + 1
		local header = makeLabel(tracosScroll, "H_" .. titleText, titleText,
			UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), 13)
		header.LayoutOrder = sectionOrder * 10
		header.Font = Enum.Font.GothamBold
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.TextColor3 = color or Color3.fromRGB(0, 255, 157)
		local body = makeLabel(tracosScroll, "B_" .. titleText, bodyText,
			UDim2.new(0, 0, 0, 0), UDim2.new(1, -10, 0, 40), 12)
		body.LayoutOrder = sectionOrder * 10 + 1
		body.TextWrapped = true
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.TextColor3 = Color3.fromRGB(210, 210, 220)
	end

	-- RAÇA: nome + caracteristicas PASSIVAS (recebe todas) + a
	-- ESCOLHIDA (se a raca tiver opcoes_caracteristica), com efeito
	-- completo -- nao so o nome. Busca os dados completos da raca de
	-- novo (GetRaces ja envia caracteristicas/opcoes_caracteristica).
	local racaLinhas = { tostring(character.Race or "—") }
	if character.RaceBonusPending and #character.RaceBonusPending > 0 then
		table.insert(racaLinhas, "(bônus a definir: " .. table.concat(character.RaceBonusPending, ", ") .. ")")
	end
	if character.Race then
		local todasRacas = GetRaces:InvokeServer() or {}
		local racaCompleta = nil
		for _, r in ipairs(todasRacas) do
			if r.nome == character.Race then racaCompleta = r break end
		end
		if racaCompleta then
			for _, c in ipairs(racaCompleta.caracteristicas or {}) do
				table.insert(racaLinhas, "• " .. c.nome .. ": " .. c.efeito)
			end
			if character.RaceCaracteristicaEscolhida and racaCompleta.opcoes_caracteristica then
				for _, op in ipairs(racaCompleta.opcoes_caracteristica) do
					if op.nome == character.RaceCaracteristicaEscolhida then
						table.insert(racaLinhas, "★ " .. op.nome .. " (escolhida): " .. op.efeito)
						break
					end
				end
			end
		end
	end
	addSection("RAÇA", table.concat(racaLinhas, "\n"))

	-- ANTECEDENTE: nome + a caracteristica escolhida com efeito completo.
	local bgLinhas = { character.Background and tostring(character.Background) or "—" }
	if character.Background and character.BackgroundFeature then
		local todosBgs = GetBackgrounds:InvokeServer() or {}
		for _, b in ipairs(todosBgs) do
			if b.nome == character.Background then
				for _, c in ipairs(b.caracteristicas or {}) do
					if c.nome == character.BackgroundFeature then
						table.insert(bgLinhas, "★ " .. c.nome .. ": " .. c.efeito)
						break
					end
				end
				break
			end
		end
	end
	addSection("ANTECEDENTE", table.concat(bgLinhas, "\n"))

	local skillsTxt = (character.Skills and #character.Skills > 0) and table.concat(character.Skills, ", ") or "—"
	addSection("PERÍCIAS", skillsTxt, Color3.fromRGB(0, 200, 255))

	local otherTxt = (character.OtherSkills and #character.OtherSkills > 0) and table.concat(character.OtherSkills, ", ") or "—"
	addSection("OUTROS TREINAMENTOS", otherTxt, Color3.fromRGB(0, 200, 255))

	local incPos = {}
	for _, p in ipairs((character.Inclinations and character.Inclinations.Positive) or {}) do
		table.insert(incPos, p.Nome)
	end
	local incNeg = {}
	for _, n in ipairs((character.Inclinations and character.Inclinations.Negative) or {}) do
		table.insert(incNeg, n.Nome)
	end
	addSection("INCLINAÇÕES POSITIVAS", #incPos > 0 and table.concat(incPos, ", ") or "—", Color3.fromRGB(0, 255, 157))
	addSection("INCLINAÇÕES NEGATIVAS", #incNeg > 0 and table.concat(incNeg, ", ") or "—", Color3.fromRGB(255, 100, 100))

	-- CONQUISTAS: registro persistente (pedido do Lucas: "tambem fica
	-- marcado/registrado na ficha", alem do badge passageiro no HUD).
	local conquistasTxt = "—"
	if character.Achievements and #character.Achievements > 0 then
		local catalogo = HxH5e.GetAchievementsCatalog:InvokeServer() or {}
		local porId = {}
		for _, a in ipairs(catalogo) do porId[a.id] = a end
		local linhas = {}
		for _, id in ipairs(character.Achievements) do
			local def = porId[id]
			if def then
				table.insert(linhas, "🏆 " .. def.nome)
			end
		end
		conquistasTxt = table.concat(linhas, "\n")
	end
	addSection("CONQUISTAS (" .. (character.Achievements and #character.Achievements or 0) .. ")", conquistasTxt, Color3.fromRGB(255, 200, 0))
end

local function setFichaTab(tabId)
	local tabInfo
	for _, t in ipairs(TAB_LIST) do
		if t.id == tabId then
			tabInfo = t
			break
		end
	end
	if not tabInfo then
		return
	end
	if not tabInfo.enabled then
		showToast(tabInfo.label .. ": em breve, ainda não implementado.")
		return
	end

	for _, tabInfo2 in ipairs(TAB_LIST) do
		local id = tabInfo2.id
		local btn = tabButtons[id]
		local isActive = (id == tabId)
		btn.BackgroundColor3 = isActive and Color3.fromRGB(0, 120, 70) or Color3.fromRGB(38, 42, 58)
	end

	statusScroll.Visible = (tabId == "FICHA")
	nenScroll.Visible = (tabId == "NEN")
	tracosScroll.Visible = (tabId == "TRACOS")
	bioScroll.Visible = (tabId == "BIO")
	tabButtons.invScroll.Visible = (tabId == "INV")

	if tabId == "NEN" then
		refreshNen()
		refreshHatsus()
	elseif tabId == "TRACOS" then
		refreshTracos()
	elseif tabId == "BIO" then
		tabButtons.refreshBio()
	elseif tabId == "INV" then
		tabButtons.refreshInv()
	end
end

for _, tabInfo in ipairs(TAB_LIST) do
	tabButtons[tabInfo.id].Activated:Connect(function()
		setFichaTab(tabInfo.id)
	end)
end

local pendingCreateName = nil
local pendingRace = nil
local pendingRaceBonusAllocations = nil
local pendingAttrs = {}
local pointBuyInfo = nil -- { costs = {...}, maxCost = 20, defaultValue = 10 }
local backgroundsCache = nil
local selectedBgName = nil

local function finishCreateCharacter(raceName, attrsBuild, backgroundName, backgroundFeature, positiveInclinations, negativeInclinations, chosenSkills, chosenOtherSkills)
	local result = CreateCharacter:InvokeServer(pendingCreateName, raceName, attrsBuild, backgroundName, backgroundFeature, positiveInclinations, negativeInclinations, chosenSkills, chosenOtherSkills, pendingRaceBonusAllocations, tabButtons.attrMethod, nil, tabButtons.pendingRaceCaracteristica)
	if result and result.success then
		local character = result.character
		local nen = character.Nen or {}
		local affinity = nen.Affinity or {}
		local genius = nen.Genius or {}

		resultRollLabel.Text = "🎲 Afinidade: " .. tostring(affinity.Roll or "-")
		resultGeniusLabel.Text = "🎲 Genialidade: " .. tostring(genius.Roll or "-")
			.. " (" .. tostring(genius.Tier or "-") .. ")"
		resultTierLabel.Text = "Afinidade " .. tostring(affinity.Tier or "-")
		resultCategoryLabel.Text = "Categoria: " .. tostring(nen.Category or character.Class or "?")
		local racaTexto = character.Race and ("Raça: " .. tostring(character.Race)) or "Raça: —"
		if character.RaceBonusPending and #character.RaceBonusPending > 0 then
			racaTexto = racaTexto .. " (bônus a definir: " .. table.concat(character.RaceBonusPending, ", ") .. ")"
		end
		local bgTexto = character.Background and ("Antecedente: " .. tostring(character.Background) .. " (" .. tostring(character.BackgroundFeature) .. ")") or "Antecedente: —"
		local incTexto = "Inclinações: —"
		if character.Inclinations then
			local posNomes, negNomes = {}, {}
			for _, p in ipairs(character.Inclinations.Positive or {}) do table.insert(posNomes, p.Nome) end
			for _, n in ipairs(character.Inclinations.Negative or {}) do table.insert(negNomes, n.Nome) end
			if #posNomes > 0 or #negNomes > 0 then
				incTexto = "Inclinações: +" .. table.concat(posNomes, ", ") .. " | -" .. table.concat(negNomes, ", ")
			end
		end
		resultInfoLabel.Text = racaTexto .. "\n" .. bgTexto .. "\n" .. incTexto .. "\nSua categoria de Nen define seus Hatsus.\nSua genialidade (2d20) afeta seu avanço."

		closeWindow(skillFrame)
		closeWindow(incFrame)
		closeWindow(bgFrame)
		closeWindow(attrFrame)
		closeWindow(raceFrame)
		closeWindow(createFrame)
		closeWindow(listFrame)
		openWindow(resultFrame)
	else
		showToast(tostring(result and result.error) or "Erro ao criar personagem.")
	end
end

-- ================= Passo: Atributos (compra de pontos) =================

local function attrCost(value)
	if not pointBuyInfo then
		return 0
	end
	return pointBuyInfo.costs[value] or 0
end

local function refreshAttrUI()
	if tabButtons.attrMethod == "compra" then
		local total = 0
		for _, key in ipairs(attributeNames) do
			local value = pendingAttrs[key]
			local cost = attrCost(value)
			total = total + cost
			attrRows[key].label.Text = key .. ": " .. value .. "  (custo " .. cost .. ")"
			attrRows[key].minus.Visible = true
			attrRows[key].plus.Visible = true
		end
		local maxCost = pointBuyInfo and pointBuyInfo.maxCost or 20
		attrPointsLabel.Text = "Pontos: " .. total .. " / " .. maxCost
		attrPointsLabel.TextColor3 = (total > maxCost) and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 220, 120)
	else
		-- Rolagem/Array: mostra o valor atribuido (ou vazio) por atributo,
		-- e a lista dos valores do banco que ainda nao foram usados.
		for _, key in ipairs(attributeNames) do
			local val = tabButtons.attrAssigned[key]
			attrRows[key].label.Text = key .. ": " .. (val and tostring(val) or "—")
			attrRows[key].minus.Visible = (val ~= nil)
			attrRows[key].plus.Visible = (val == nil) and (#tabButtons.attrPool > 0)
			pendingAttrs[key] = val or 10 -- fallback seguro; validado de verdade so no confirmar
		end
		if #tabButtons.attrPool > 0 then
			attrPointsLabel.Text = "Disponível: " .. table.concat(tabButtons.attrPool, ", ")
			attrPointsLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
		else
			attrPointsLabel.Text = "Todos os valores distribuídos."
			attrPointsLabel.TextColor3 = Color3.fromRGB(0, 255, 157)
		end
	end
end

-- ================= Passo: Bônus racial (raças com escolha manual) =================

local raceBonusState = { req = nil, allocations = {} }

local function refreshRaceBonusUI()
	local req = raceBonusState.req
	if not req then
		return
	end
	if req.type == "wildcard" then
		local total = 0
		for _, key in ipairs(attributeNames) do
			local amt = raceBonusState.allocations[key] or 0
			total = total + amt
			raceBonusRows[key].label.Text = key .. ": +" .. amt
		end
		raceBonusInfoLabel.Text = "Distribua " .. req.amount .. " ponto(s) entre quaisquer atributos. Alocado: " .. total .. "/" .. req.amount
		raceBonusConfirmButton.BackgroundColor3 = (total == req.amount) and Color3.fromRGB(0, 120, 70) or Color3.fromRGB(38, 42, 58)
	elseif req.type == "choice" then
		raceBonusInfoLabel.Text = "Escolha um atributo pra receber +" .. req.amount .. ":"
	end
end

function openRaceBonusStep(req)
	raceBonusState.req = req
	raceBonusState.allocations = {}
	for _, key in ipairs(attributeNames) do
		local row = raceBonusRows[key]
		local isAllowed = (req.type == "wildcard") or (req.type == "choice" and table.find(req.keys, key))
		row.label.Visible = (req.type == "wildcard")
		row.minus.Visible = (req.type == "wildcard")
		row.plus.Visible = (req.type == "wildcard")
		row.choose.Visible = (req.type == "choice" and isAllowed)
	end
	refreshRaceBonusUI()
	openWindow(raceBonusFrame)
end

for _, key in ipairs(attributeNames) do
	raceBonusRows[key].minus.Activated:Connect(function()
		if raceBonusState.req and raceBonusState.req.type == "wildcard" then
			raceBonusState.allocations[key] = math.max(0, (raceBonusState.allocations[key] or 0) - 1)
			refreshRaceBonusUI()
		end
	end)
	raceBonusRows[key].plus.Activated:Connect(function()
		if raceBonusState.req and raceBonusState.req.type == "wildcard" then
			local total = 0
			for _, k in ipairs(attributeNames) do total = total + (raceBonusState.allocations[k] or 0) end
			if total < raceBonusState.req.amount then
				raceBonusState.allocations[key] = (raceBonusState.allocations[key] or 0) + 1
				refreshRaceBonusUI()
			end
		end
	end)
	raceBonusRows[key].choose.Activated:Connect(function()
		if raceBonusState.req and raceBonusState.req.type == "choice" then
			pendingRaceBonusAllocations = { [key] = raceBonusState.req.amount }
			closeWindow(raceBonusFrame)
			openAttrStep()
		end
	end)
end

raceBonusConfirmButton.Activated:Connect(function()
	local req = raceBonusState.req
	if not req or req.type ~= "wildcard" then
		return
	end
	local total = 0
	local allocCopy = {}
	for _, key in ipairs(attributeNames) do
		local amt = raceBonusState.allocations[key] or 0
		total = total + amt
		if amt > 0 then
			allocCopy[key] = amt
		end
	end
	if total ~= req.amount then
		showToast("Aloque exatamente " .. req.amount .. " ponto(s) antes de confirmar.")
		return
	end
	pendingRaceBonusAllocations = allocCopy
	closeWindow(raceBonusFrame)
	openAttrStep()
end)

tabButtons.ATTR_METHOD_LABELS = {
	{ id = "compra", label = "Compra" },
	{ id = "rolagem", label = "Rolagem" },
	{ id = "array", label = "Array" },
}

tabButtons.setAttrMethod = function(method)
	tabButtons.attrMethod = method
	tabButtons.attrPool = {}
	tabButtons.attrAssigned = {}
	tabButtons.attrMethodLocked = false -- reseta a trava (novo personagem/nova tentativa)
	for _, key in ipairs(attributeNames) do
		pendingAttrs[key] = (pointBuyInfo and pointBuyInfo.defaultValue) or 10
	end
	if method == "compra" then
		tabButtons.attrActionButton.Visible = false
	elseif method == "rolagem" then
		tabButtons.attrActionButton.Visible = true
		tabButtons.attrActionButton.Text = "🎲 ROLAR ATRIBUTOS (4d6, descarta o menor)"
		tabButtons.attrActionButton.BackgroundColor3 = Color3.fromRGB(120, 40, 160)
	else
		tabButtons.attrActionButton.Visible = true
		tabButtons.attrActionButton.Text = "USAR ARRAY PADRÃO (15,14,13,12,10,8)"
	end
	for _, btnInfo in ipairs(tabButtons.ATTR_METHOD_LABELS) do
		local btn = tabButtons.attrMethodTabsFrame:FindFirstChild("Tab_" .. btnInfo.id)
		if btn then
			btn.BackgroundColor3 = (tabButtons.attrMethod == btnInfo.id)
				and Color3.fromRGB(0, 255, 157) or Color3.fromRGB(38, 42, 58)
			btn.TextColor3 = (tabButtons.attrMethod == btnInfo.id)
				and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(255, 255, 255)
		end
	end
	refreshAttrUI()
end

for i, btnInfo in ipairs(tabButtons.ATTR_METHOD_LABELS) do
	local btn = makeButton(tabButtons.attrMethodTabsFrame, "Tab_" .. btnInfo.id, btnInfo.label,
		UDim2.new(0, (i - 1) * 116, 0, 0), UDim2.new(0, 112, 0, 26))
	btn.TextSize = 11
	btn.Activated:Connect(function()
		if tabButtons.attrMethodLocked and btnInfo.id ~= tabButtons.attrMethod then
			showToast("Você já rolou os atributos. Não é possível trocar de método agora.", 4)
			return
		end
		tabButtons.setAttrMethod(btnInfo.id)
	end)
end

tabButtons.attrActionButton.Activated:Connect(function()
	if tabButtons.attrMethod == "rolagem" and tabButtons.attrMethodLocked then
		showToast("Você já rolou os atributos. Não é possível rolar de novo nem trocar de método.", 4)
		return
	end
	local pool
	if tabButtons.attrMethod == "rolagem" then
		pool = HxH5e.RollAttributePool:InvokeServer()
		if type(pool) == "table" and pool.locked then
			showToast(tostring(pool.error), 4)
			return
		end
		-- Trava definitiva: uma vez rolado, nao da mais pra rolar de novo
		-- nem trocar de metodo (evita "cacar" um resultado bom).
		tabButtons.attrMethodLocked = true
		tabButtons.attrActionButton.Text = "✅ JÁ ROLADO (travado)"
		tabButtons.attrActionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		for _, btnInfo in ipairs(tabButtons.ATTR_METHOD_LABELS) do
			local btn = tabButtons.attrMethodTabsFrame:FindFirstChild("Tab_" .. btnInfo.id)
			if btn and btnInfo.id ~= "rolagem" then
				btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
				btn.TextColor3 = Color3.fromRGB(90, 90, 95)
			end
		end
	else
		pool = HxH5e.GetStandardArray:InvokeServer()
	end
	tabButtons.attrPool = pool
	tabButtons.attrAssigned = {}
	refreshAttrUI()
end)

function openAttrStep()
	if not pointBuyInfo then
		pointBuyInfo = GetPointBuyInfo:InvokeServer()
	end
	tabButtons.setAttrMethod("compra")
	openWindow(attrFrame)
end

for _, key in ipairs(attributeNames) do
	attrRows[key].minus.Activated:Connect(function()
		if tabButtons.attrMethod == "compra" then
			pendingAttrs[key] = math.max(1, pendingAttrs[key] - 1)
		else
			local val = tabButtons.attrAssigned[key]
			if val then
				table.insert(tabButtons.attrPool, val)
				table.sort(tabButtons.attrPool, function(a, b) return a > b end)
				tabButtons.attrAssigned[key] = nil
			end
		end
		refreshAttrUI()
	end)
	attrRows[key].plus.Activated:Connect(function()
		if tabButtons.attrMethod == "compra" then
			pendingAttrs[key] = math.min(30, pendingAttrs[key] + 1)
		else
			if not tabButtons.attrAssigned[key] and #tabButtons.attrPool > 0 then
				local val = table.remove(tabButtons.attrPool, 1)
				tabButtons.attrAssigned[key] = val
			end
		end
		refreshAttrUI()
	end)
end

-- ================= Passo: Antecedente =================

local function refreshBackgrounds()
	for _, child in ipairs(bgScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for index, bg in ipairs(backgroundsCache or {}) do
		local expandido = (selectedBgName == bg.nome)
		local alturaBase = 64
		local alturaFeatures = expandido and (28 * #bg.caracteristicas + 6) or 0
		local row = makeFrame(bgScroll, "BgRow_" .. index,
			UDim2.new(1, 0, 0, alturaBase + alturaFeatures), UDim2.new(0, 0, 0, 0),
			expandido and Color3.fromRGB(48, 62, 50) or Color3.fromRGB(38, 42, 58))
		local rowName = makeLabel(row, "BName", tostring(bg.nome or "?"),
			UDim2.new(0, 10, 0, 4), UDim2.new(1, -110, 0, 18), 13)
		rowName.TextXAlignment = Enum.TextXAlignment.Left
		local rowDesc = makeLabel(row, "BDesc", tostring(bg.descricao or ""),
			UDim2.new(0, 10, 0, 24), UDim2.new(1, -110, 0, 36), 10)
		rowDesc.TextXAlignment = Enum.TextXAlignment.Left
		rowDesc.TextWrapped = true
		rowDesc.TextYAlignment = Enum.TextYAlignment.Top
		rowDesc.TextColor3 = Color3.fromRGB(170, 170, 180)
		local escolherBtn = makeButton(row, "BEscolher", "VER",
			UDim2.new(1, -96, 0, 14), UDim2.new(0, 86, 0, 36))
		escolherBtn.TextSize = 11
		escolherBtn.BackgroundColor3 = Color3.fromRGB(48, 62, 110)
		escolherBtn.Activated:Connect(function()
			closeWindow(bgFrame)
			tabButtons.refreshBgDetail(bg)
		end)
	end
end

local function openBackgroundStep()
	if not backgroundsCache then
		backgroundsCache = GetBackgrounds:InvokeServer()
	end
	selectedBgName = nil
	refreshBackgrounds()
	openWindow(bgFrame)
end

-- ================= Passo: Inclinações =================

local pendingBackground = nil
local pendingBackgroundFeature = nil
local inclinationsCache = nil -- { positivas, negativas, basicMaxCusto, negativeMaxTotal }
local incTab = "POSITIVAS"
local selectedPositive = {} -- set: [fullName] = true
local selectedNegative = {} -- set: [fullName] = true
local incExpanded = nil -- nome do item com hasOptions atualmente expandido

local function incFullName(inc, opt)
	if opt then
		return inc.nome .. ": " .. opt.label
	end
	return inc.nome
end

local function calcIncTotals()
	local posCost = 0
	for name in pairs(selectedPositive) do
		for _, inc in ipairs(inclinationsCache.positivas) do
			if inc.hasOptions then
				for _, opt in ipairs(inc.options) do
					if incFullName(inc, opt) == name then
						posCost = posCost + opt.custo
					end
				end
			elseif inc.nome == name then
				posCost = posCost + inc.custo
			end
		end
	end
	local negVal = 0
	for name in pairs(selectedNegative) do
		for _, inc in ipairs(inclinationsCache.negativas) do
			if inc.hasOptions then
				for _, opt in ipairs(inc.options) do
					if incFullName(inc, opt) == name then
						negVal = negVal + opt.valor
					end
				end
			elseif inc.nome == name then
				negVal = negVal + inc.valor
			end
		end
	end
	local freeCost = 0
	for name in pairs(selectedPositive) do
		for _, inc in ipairs(inclinationsCache.positivas) do
			local custo = nil
			if inc.hasOptions then
				for _, opt in ipairs(inc.options) do
					if incFullName(inc, opt) == name then custo = opt.custo end
				end
			elseif inc.nome == name then
				custo = inc.custo
			end
			if custo and custo <= inclinationsCache.basicMaxCusto and custo > freeCost then
				freeCost = custo
			end
		end
	end
	local paidCost = math.max(0, posCost - freeCost)
	return posCost, freeCost, paidCost, negVal
end

local function refreshIncSummary()
	local posCost, freeCost, paidCost, negVal = calcIncTotals()
	local ok = paidCost <= negVal
	incSummaryLabel.Text = string.format(
		"Positivo: %d pts | Grátis: %d | Pago: %d | Negativo: %d/%d | Saldo: %s",
		posCost, freeCost, paidCost, negVal, inclinationsCache.negativeMaxTotal,
		ok and "OK" or ("faltam " .. (paidCost - negVal))
	)
	incSummaryLabel.TextColor3 = ok and Color3.fromRGB(0, 255, 157) or Color3.fromRGB(255, 100, 100)
end

local function refreshInclinations()
	for _, child in ipairs(incScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local list = (incTab == "POSITIVAS") and inclinationsCache.positivas or inclinationsCache.negativas
	local selectedSet = (incTab == "POSITIVAS") and selectedPositive or selectedNegative
	local sinal = (incTab == "POSITIVAS") and "" or "+"

	for index, inc in ipairs(list) do
		local expandido = (incExpanded == inc.nome) and inc.hasOptions
		local marcado = (not inc.hasOptions) and selectedSet[inc.nome]
		local alturaBase = 54
		local alturaOpts = expandido and (26 * #inc.options + 6) or 0
		local row = makeFrame(incScroll, "IncRow_" .. index,
			UDim2.new(1, 0, 0, alturaBase + alturaOpts), UDim2.new(0, 0, 0, 0),
			marcado and Color3.fromRGB(48, 62, 50) or Color3.fromRGB(38, 42, 58))
		local custoTxt = inc.hasOptions and "(opções)" or (sinal .. tostring(inc.custo or inc.valor) .. " pts")
		local rowName = makeLabel(row, "IName", tostring(inc.nome) .. "  " .. custoTxt,
			UDim2.new(0, 8, 0, 3), UDim2.new(1, -100, 0, 16), 12)
		rowName.TextXAlignment = Enum.TextXAlignment.Left
		local rowDesc = makeLabel(row, "IDesc", tostring(inc.desc or ""),
			UDim2.new(0, 8, 0, 19), UDim2.new(1, -16, 0, 32), 9)
		rowDesc.TextXAlignment = Enum.TextXAlignment.Left
		rowDesc.TextWrapped = true
		rowDesc.TextYAlignment = Enum.TextYAlignment.Top
		rowDesc.TextColor3 = Color3.fromRGB(170, 170, 180)

		local actionBtn = makeButton(row, "IAction",
			inc.hasOptions and (expandido and "FECHAR" or "VER") or (marcado and "REMOVER" or "ESCOLHER"),
			UDim2.new(1, -92, 0, 12), UDim2.new(0, 84, 0, 28))
		actionBtn.TextSize = 10
		actionBtn.BackgroundColor3 = marcado and Color3.fromRGB(120, 30, 30) or Color3.fromRGB(48, 62, 110)
		actionBtn.Activated:Connect(function()
			if inc.hasOptions then
				incExpanded = expandido and nil or inc.nome
				refreshInclinations()
			else
				if marcado then
					selectedSet[inc.nome] = nil
				else
					selectedSet[inc.nome] = true
				end
				refreshInclinations()
				refreshIncSummary()
			end
		end)

		if expandido then
			for oi, opt in ipairs(inc.options) do
				local fullName = incFullName(inc, opt)
				local optSel = selectedSet[fullName]
				local optBtn = makeButton(row, "IOpt_" .. oi,
					(optSel and "✓ " or "") .. opt.label .. "  (" .. sinal .. tostring(opt.custo or opt.valor) .. ")",
					UDim2.new(0, 8, 0, 54 + (oi - 1) * 26), UDim2.new(1, -16, 0, 22))
				optBtn.TextSize = 9
				optBtn.TextXAlignment = Enum.TextXAlignment.Left
				optBtn.BackgroundColor3 = optSel and Color3.fromRGB(0, 120, 70) or Color3.fromRGB(60, 60, 80)
				optBtn.Activated:Connect(function()
					if optSel then
						selectedSet[fullName] = nil
					else
						selectedSet[fullName] = true
					end
					refreshInclinations()
					refreshIncSummary()
				end)
			end
		end
	end
end

function openInclinationsStep()
	if not inclinationsCache then
		inclinationsCache = GetInclinations:InvokeServer()
	end
	selectedPositive = {}
	selectedNegative = {}
	incExpanded = nil
	incTab = "POSITIVAS"
	refreshInclinations()
	refreshIncSummary()
	openWindow(incFrame)
end

incPosTab.Activated:Connect(function()
	incTab = "POSITIVAS"
	incExpanded = nil
	refreshInclinations()
end)

incNegTab.Activated:Connect(function()
	incTab = "NEGATIVAS"
	incExpanded = nil
	refreshInclinations()
end)

incBackButton.Activated:Connect(function()
	closeWindow(incFrame)
	openBackgroundStep()
end)

incConfirmButton.Activated:Connect(function()
	local posCost, freeCost, paidCost, negVal = calcIncTotals()
	if paidCost > negVal then
		showToast("Suas positivas custam " .. paidCost .. " P.N (após desconto), mas as negativas só cobrem " .. negVal .. ".")
		return
	end
	local posList, negList = {}, {}
	for name in pairs(selectedPositive) do table.insert(posList, name) end
	for name in pairs(selectedNegative) do table.insert(negList, name) end
	pendingPositiveInc = posList
	pendingNegativeInc = negList
	closeWindow(incFrame)
	openSkillsStep()
end)

-- ================= Passo: Perícias e Treinamentos =================

local pendingPositiveInc = nil
local pendingNegativeInc = nil
local skillsCache = nil -- { skills, otherSkills, autoSkills, maxMain, maxOther, kitsLocked }
local skillTab = "MAIN"
local selectedMainSkills = {} -- set
local selectedOtherSkills = {} -- set

local function refreshSkillSummary()
	local mainCount = 0
	for _ in pairs(selectedMainSkills) do mainCount = mainCount + 1 end
	local otherCount = 0
	for _ in pairs(selectedOtherSkills) do otherCount = otherCount + 1 end
	local autoTxt = (#skillsCache.autoSkills > 0) and ("Do antecedente (automático): " .. table.concat(skillsCache.autoSkills, ", ")) or "Sem perícias automáticas do antecedente."
	skillSummaryLabel.Text = autoTxt .. string.format("\nPerícias manuais: %d/%d | Outros treinos: %d/%d",
		mainCount, skillsCache.maxMain, otherCount, skillsCache.maxOther)
end

local function refreshSkills()
	for _, child in ipairs(skillScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local autoSet = {}
	for _, s in ipairs(skillsCache.autoSkills) do autoSet[s] = true end

	if skillTab == "MAIN" then
		for index, skill in ipairs(skillsCache.skills) do
			local isAuto = autoSet[skill]
			local isSel = selectedMainSkills[skill]
			local row = makeFrame(skillScroll, "SkillRow_" .. index,
				UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0),
				isAuto and Color3.fromRGB(40, 55, 70) or (isSel and Color3.fromRGB(48, 62, 50) or Color3.fromRGB(38, 42, 58)))
			local lbl = makeLabel(row, "L", skill .. (isAuto and "  [ANTECEDENTE]" or ""),
				UDim2.new(0, 8, 0, 0), UDim2.new(1, -100, 1, 0), 11)
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			if isAuto then
				lbl.TextColor3 = Color3.fromRGB(120, 200, 255)
			else
				local btn = makeButton(row, "B", isSel and "REMOVER" or "ESCOLHER",
					UDim2.new(1, -90, 0, 2), UDim2.new(0, 82, 0, 26))
				btn.TextSize = 10
				btn.BackgroundColor3 = isSel and Color3.fromRGB(120, 30, 30) or Color3.fromRGB(48, 62, 110)
				btn.Activated:Connect(function()
					if isSel then
						selectedMainSkills[skill] = nil
					else
						selectedMainSkills[skill] = true
					end
					refreshSkills()
					refreshSkillSummary()
				end)
			end
		end
	else
		for index, skill in ipairs(skillsCache.otherSkills) do
			local isLocked = (skill == "Kits") and skillsCache.kitsLocked
			local isSel = selectedOtherSkills[skill]
			local row = makeFrame(skillScroll, "OtherRow_" .. index,
				UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0),
				isLocked and Color3.fromRGB(40, 55, 70) or (isSel and Color3.fromRGB(48, 62, 50) or Color3.fromRGB(38, 42, 58)))
			local lbl = makeLabel(row, "L", skill .. (isLocked and "  [ANTECEDENTE]" or ""),
				UDim2.new(0, 8, 0, 0), UDim2.new(1, -100, 1, 0), 11)
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			if isLocked then
				lbl.TextColor3 = Color3.fromRGB(120, 200, 255)
			else
				local btn = makeButton(row, "B", isSel and "REMOVER" or "ESCOLHER",
					UDim2.new(1, -90, 0, 2), UDim2.new(0, 82, 0, 26))
				btn.TextSize = 10
				btn.BackgroundColor3 = isSel and Color3.fromRGB(120, 30, 30) or Color3.fromRGB(48, 62, 110)
				btn.Activated:Connect(function()
					if isSel then
						selectedOtherSkills[skill] = nil
					else
						selectedOtherSkills[skill] = true
					end
					refreshSkills()
					refreshSkillSummary()
				end)
			end
		end
	end
end

function openSkillsStep()
	skillsCache = GetSkillsInfo:InvokeServer(pendingBackground)
	selectedMainSkills = {}
	selectedOtherSkills = {}
	skillTab = "MAIN"
	refreshSkills()
	refreshSkillSummary()
	openWindow(skillFrame)
end

skillMainTab.Activated:Connect(function()
	skillTab = "MAIN"
	refreshSkills()
end)

skillOtherTab.Activated:Connect(function()
	skillTab = "OTHER"
	refreshSkills()
end)

skillBackButton.Activated:Connect(function()
	closeWindow(skillFrame)
	openWindow(incFrame)
end)

skillConfirmButton.Activated:Connect(function()
	local mainCount = 0
	for _ in pairs(selectedMainSkills) do mainCount = mainCount + 1 end
	local otherCount = 0
	for _ in pairs(selectedOtherSkills) do otherCount = otherCount + 1 end
	if mainCount > skillsCache.maxMain then
		showToast("Você escolheu " .. mainCount .. " perícias manuais, o máximo é " .. skillsCache.maxMain .. ".")
		return
	end
	if otherCount > skillsCache.maxOther then
		showToast("Você escolheu " .. otherCount .. " outros treinos, o máximo é " .. skillsCache.maxOther .. ".")
		return
	end
	local mainList, otherList = {}, {}
	for s in pairs(selectedMainSkills) do table.insert(mainList, s) end
	for s in pairs(selectedOtherSkills) do table.insert(otherList, s) end
	finishCreateCharacter(pendingRace, pendingAttrs, pendingBackground, pendingBackgroundFeature, pendingPositiveInc, pendingNegativeInc, mainList, otherList)
end)

attrConfirmButton.Activated:Connect(function()
	if tabButtons.attrMethod == "compra" then
		local total = 0
		for _, key in ipairs(attributeNames) do
			total = total + attrCost(pendingAttrs[key])
		end
		local maxCost = pointBuyInfo and pointBuyInfo.maxCost or 20
		if total > maxCost then
			showToast("Você gastou " .. total .. " pontos, o máximo é " .. maxCost .. ".")
			return
		end
	else
		for _, key in ipairs(attributeNames) do
			if not tabButtons.attrAssigned[key] then
				showToast("Distribua todos os 6 valores antes de continuar.", 3)
				return
			end
			pendingAttrs[key] = tabButtons.attrAssigned[key]
		end
	end
	closeWindow(attrFrame)
	openBackgroundStep()
end)

attrBackButton.Activated:Connect(function()
	closeWindow(attrFrame)
	openWindow(raceFrame)
end)

local function refreshRaces()
	for _, child in ipairs(raceScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local races = GetRaces:InvokeServer() or {}
	for index, race in ipairs(races) do
		local row = makeFrame(raceScroll, "RaceRow_" .. index,
			UDim2.new(1, 0, 0, 64), UDim2.new(0, 0, 0, 0), Color3.fromRGB(38, 42, 58))
		local rowName = makeLabel(row, "RName",
			tostring(race.nome or "?") .. "  [" .. tostring(race.categoria or "") .. "]",
			UDim2.new(0, 10, 0, 4), UDim2.new(1, -110, 0, 18), 13)
		rowName.TextXAlignment = Enum.TextXAlignment.Left
		local rowDesc = makeLabel(row, "RDesc", tostring(race.descricao or ""),
			UDim2.new(0, 10, 0, 24), UDim2.new(1, -110, 0, 36), 10)
		rowDesc.TextXAlignment = Enum.TextXAlignment.Left
		rowDesc.TextWrapped = true
		rowDesc.TextYAlignment = Enum.TextYAlignment.Top
		rowDesc.TextColor3 = Color3.fromRGB(170, 170, 180)
		local escolherBtn = makeButton(row, "REscolher", "ESCOLHER",
			UDim2.new(1, -96, 0, 14), UDim2.new(0, 86, 0, 36))
		escolherBtn.TextSize = 11
		escolherBtn.Activated:Connect(function()
			closeWindow(raceFrame)
			tabButtons.refreshRaceDetail(race)
		end)
	end
end

local function openCreateWindow()
	nameBox.Text = ""
	createErrorLabel.Text = ""
	openWindow(createFrame)
end

local function onCreateConfirm()
	local name = nameBox.Text
	if #name == 0 then
		createErrorLabel.Text = "Digite um nome."
		return
	end
	pendingCreateName = name
	closeWindow(createFrame)
	refreshRaces()
	openWindow(raceFrame)
end

-- ================= Eventos =================

openButton.Activated:Connect(function()
	if fichaFrame.Visible then
		closeWindow(fichaFrame)
		return
	end
	refreshFicha()
	setFichaTab("FICHA")
	openWindow(fichaFrame)
end)

criarButton.Activated:Connect(function()
	openCreateWindow()
end)

trocarButton.Activated:Connect(function()
	refreshList()
	openWindow(listFrame)
end)

xpButton.Activated:Connect(function()
	local result = GainXP:InvokeServer(50)
	if result then
		showToast(tostring(result.message or result.error), 3)
	end
	refreshFicha()
	if result and result.success and result.pendingLevelUps and #result.pendingLevelUps > 0 then
		tabButtons.openLevelUp()
	end
end)

fecharFichaButton.Activated:Connect(function()
	closeWindow(fichaFrame)
end)

criarListaButton.Activated:Connect(function()
	openCreateWindow()
end)

fecharListaButton.Activated:Connect(function()
	closeWindow(listFrame)
end)

confirmButton.Activated:Connect(onCreateConfirm)

cancelButton.Activated:Connect(function()
	closeWindow(createFrame)
end)

resultContinueButton.Activated:Connect(function()
	closeWindow(resultFrame)
	refreshFicha()
	setFichaTab("FICHA")
	openWindow(fichaFrame)
end)

for _, name in ipairs(FUND_NAMES) do
	dominioRows[name].trainButton.Activated:Connect(function()
		local result = TrainPrinciple:InvokeServer(name)
		if result then
			showToast(tostring(result.message or result.error), 3)
		end
		refreshNen()
	end)

	dominioRows[name].activateButton.Activated:Connect(function()
		local result = ActivatePrinciple:InvokeServer(name)
		if result then
			showToast(tostring(result.message or result.error), 3)
		end
		refreshFicha()
	end)
end

for _, name in ipairs(ADV_NAMES) do
	advRows[name].unlockButton.Activated:Connect(function()
		local result = TrainPrinciple:InvokeServer(name)
		if result then
			showToast(tostring(result.message or result.error), 3)
		end
		refreshNen()
	end)

	advRows[name].activateButton.Activated:Connect(function()
		local result = ActivatePrinciple:InvokeServer(name)
		if result then
			showToast(tostring(result.message or result.error), 3)
		end
		refreshFicha()
	end)
end

-- ================= JANELA DE LEVEL-UP =================
-- Reaproveita tabButtons pro Frame/estado/funcoes (arquivo no teto de
-- 200 locais do Luau, ver aba BIO/INV/Atributos).
tabButtons.levelUpFrame = makeFrame(screenGui, "LevelUpWindow",
	UDim2.fromOffset(400, 440), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
tabButtons.levelUpFrame.AnchorPoint = Vector2.new(0.5, 0.5)
tabButtons.levelUpFrame.Visible = false
addCloseButton(tabButtons.levelUpFrame)

tabButtons.levelUpTitle = makeLabel(tabButtons.levelUpFrame, "LvlTitle", "NÍVEL X",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 26), 18)
tabButtons.levelUpTitle.Font = Enum.Font.GothamBold
tabButtons.levelUpTitle.TextColor3 = Color3.fromRGB(255, 200, 0)

tabButtons.levelUpRewards = makeLabel(tabButtons.levelUpFrame, "LvlRewards", "",
	UDim2.new(0, 16, 0, 42), UDim2.new(1, -32, 0, 60), 12)
tabButtons.levelUpRewards.TextWrapped = true
tabButtons.levelUpRewards.TextXAlignment = Enum.TextXAlignment.Left
tabButtons.levelUpRewards.TextYAlignment = Enum.TextYAlignment.Top
tabButtons.levelUpRewards.TextColor3 = Color3.fromRGB(200, 200, 210)

tabButtons.levelUpDiceLabel = makeLabel(tabButtons.levelUpFrame, "LvlDiceLabel", "Dado de Vida: —",
	UDim2.new(0, 16, 0, 106), UDim2.new(1, -32, 0, 20), 13)
tabButtons.levelUpDiceLabel.TextColor3 = Color3.fromRGB(0, 200, 255)

tabButtons.levelUpRollButton = makeButton(tabButtons.levelUpFrame, "LvlRoll", "🎲 ROLAR DADO",
	UDim2.new(0, 16, 0, 130), UDim2.new(0, 178, 0, 36))
tabButtons.levelUpMediaButton = makeButton(tabButtons.levelUpFrame, "LvlMedia", "USAR MÉDIA",
	UDim2.new(0, 202, 0, 130), UDim2.new(0, 182, 0, 36))

tabButtons.levelUpResultLabel = makeLabel(tabButtons.levelUpFrame, "LvlResult", "",
	UDim2.new(0, 16, 0, 172), UDim2.new(1, -32, 0, 24), 13)
tabButtons.levelUpResultLabel.TextColor3 = Color3.fromRGB(0, 255, 157)

tabButtons.levelUpChoiceLabel = makeLabel(tabButtons.levelUpFrame, "LvlChoiceLabel", "Escolha: Atributo ou Aura",
	UDim2.new(0, 16, 0, 204), UDim2.new(1, -32, 0, 20), 13)
tabButtons.levelUpChoiceLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
tabButtons.levelUpChoiceLabel.Visible = false

tabButtons.levelUpAttrButton = makeButton(tabButtons.levelUpFrame, "LvlChoiceAttr", "ATRIBUTO",
	UDim2.new(0, 16, 0, 228), UDim2.new(0, 178, 0, 36))
tabButtons.levelUpAuraButton = makeButton(tabButtons.levelUpFrame, "LvlChoiceAura", "AURA",
	UDim2.new(0, 202, 0, 228), UDim2.new(0, 182, 0, 36))
tabButtons.levelUpAttrButton.Visible = false
tabButtons.levelUpAuraButton.Visible = false

tabButtons.levelUpConfirmButton = makeButton(tabButtons.levelUpFrame, "LvlConfirm", "CONFIRMAR NÍVEL",
	UDim2.new(0, 16, 1, -50), UDim2.new(1, -32, 0, 38))
tabButtons.levelUpConfirmButton.BackgroundColor3 = Color3.fromRGB(0, 120, 70)

tabButtons.levelUpState = { hitGain = nil, attrChoice = nil, isAttrChoice = false }

tabButtons.refreshLevelUp = function()
	local pending = HxH5e.GetNextPendingLevel:InvokeServer()
	if not pending then
		closeWindow(tabButtons.levelUpFrame)
		return
	end
	tabButtons.levelUpState = { hitGain = nil, attrChoice = nil, isAttrChoice = pending.isAttrChoice }

	local r = pending.rewards
	tabButtons.levelUpTitle.Text = "🎉 NÍVEL " .. pending.nivel .. " — " .. tostring(r.titulo)
	local linhas = {}
	if r.pi and r.pi > 0 then table.insert(linhas, "+" .. r.pi .. " Ponto(s) de Inclinação") end
	if r.prof and r.prof > 0 then table.insert(linhas, "+" .. r.prof .. " Ponto(s) de Proficiência") end
	if r.pn and r.pn > 0 then table.insert(linhas, "P.N do pool sobe automaticamente") end
	if pending.restantesNaFila > 1 then
		table.insert(linhas, "(" .. (pending.restantesNaFila - 1) .. " nível(is) na fila depois deste)")
	end
	tabButtons.levelUpRewards.Text = table.concat(linhas, "\n")

	tabButtons.levelUpDiceLabel.Text = "Dado de Vida: 1d" .. pending.hitDiceInfo.faces
		.. " + CON (" .. pending.hitDiceInfo.conMod .. ")"
		.. (pending.hitDiceInfo.giantBonus > 0 and (" + Gigante (" .. pending.hitDiceInfo.giantBonus .. ")") or "")
	tabButtons.levelUpResultLabel.Text = ""

	tabButtons.levelUpChoiceLabel.Visible = pending.isAttrChoice
	tabButtons.levelUpAttrButton.Visible = pending.isAttrChoice
	tabButtons.levelUpAuraButton.Visible = pending.isAttrChoice
	tabButtons.levelUpAttrButton.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
	tabButtons.levelUpAuraButton.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
	if pending.isAttrChoice then
		tabButtons.levelUpAttrButton.Text = "ATRIBUTO (+" .. r.attr .. ")"
		tabButtons.levelUpAuraButton.Text = "AURA (+" .. r.auraP .. "%)"
	end

	tabButtons.levelUpConfirmButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	openWindow(tabButtons.levelUpFrame)
end

tabButtons.openLevelUp = function()
	tabButtons.refreshLevelUp()
end

tabButtons.levelUpRollButton.Activated:Connect(function()
	local result = HxH5e.RollHitDie:InvokeServer()
	if result and result.total then
		tabButtons.levelUpState.hitGain = result.total
		tabButtons.levelUpResultLabel.Text = "🎲 Rolou " .. result.roll .. " + " .. result.conMod
			.. (result.giantBonus > 0 and (" + " .. result.giantBonus) or "") .. " = +" .. result.total .. " PV"
		tabButtons.levelUpConfirmButton.BackgroundColor3 = Color3.fromRGB(0, 120, 70)
	end
end)

tabButtons.levelUpMediaButton.Activated:Connect(function()
	local result = HxH5e.GetMediaHitDie:InvokeServer()
	if result and result.total then
		tabButtons.levelUpState.hitGain = result.total
		tabButtons.levelUpResultLabel.Text = "📊 Média: +" .. result.total .. " PV"
		tabButtons.levelUpConfirmButton.BackgroundColor3 = Color3.fromRGB(0, 120, 70)
	end
end)

tabButtons.levelUpAttrButton.Activated:Connect(function()
	tabButtons.levelUpState.attrChoice = "attr"
	tabButtons.levelUpAttrButton.BackgroundColor3 = Color3.fromRGB(0, 120, 70)
	tabButtons.levelUpAuraButton.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
end)

tabButtons.levelUpAuraButton.Activated:Connect(function()
	tabButtons.levelUpState.attrChoice = "aura"
	tabButtons.levelUpAuraButton.BackgroundColor3 = Color3.fromRGB(0, 120, 70)
	tabButtons.levelUpAttrButton.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
end)

tabButtons.levelUpConfirmButton.Activated:Connect(function()
	local st = tabButtons.levelUpState
	if not st.hitGain then
		showToast("Role o dado de vida ou use a média antes de confirmar.", 3)
		return
	end
	if st.isAttrChoice and not st.attrChoice then
		showToast("Escolha Atributo ou Aura antes de confirmar.", 3)
		return
	end
	local result = HxH5e.ConfirmLevelUp:InvokeServer(st.hitGain, st.attrChoice)
	if result then
		showToast(tostring(result.message or result.error), 5)
	end
	refreshFicha()
	if result and result.success and result.restantesNaFila and result.restantesNaFila > 0 then
		tabButtons.refreshLevelUp()
	else
		closeWindow(tabButtons.levelUpFrame)
	end
end)

-- ================= JANELAS ARRASTÁVEIS =================

local function makeDraggable(frame, handle)
	local dragging = false
	local dragStart = Vector2.zero
	local frameStart = frame.Position

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			frameStart = frame.Position
		end
	end)

	handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	handle.InputChanged:Connect(function(input)
		if dragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				frame.Position = UDim2.new(
					frameStart.X.Scale,
					frameStart.X.Offset + delta.X,
					frameStart.Y.Scale,
					frameStart.Y.Offset + delta.Y
				)
			end
		end
	end)
end

local function addDragBar(window)
	local bar = Instance.new("Frame")
	bar.Name = "DragBar"
	bar.Size = UDim2.new(1, 0, 0, 36)
	bar.Position = UDim2.new(0, 0, 0, 0)
	bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.Active = true
	bar.Parent = window
	makeDraggable(window, bar)
end

addDragBar(fichaFrame)
addDragBar(listFrame)
addDragBar(createFrame)
addDragBar(raceFrame)
addDragBar(raceBonusFrame)
addDragBar(attrFrame)
addDragBar(bgFrame)
addDragBar(incFrame)
addDragBar(skillFrame)
addDragBar(resultFrame)
addDragBar(tabButtons.levelUpFrame)


-- ================================================================
-- WIZARD DE CRIAÇÃO/EDIÇÃO DE HATSU
-- ================================================================

local GetHatsuCatalog = HxH5e:WaitForChild("GetHatsuCatalog", 5)
local CreateHatsuV2 = HxH5e:WaitForChild("CreateHatsuV2", 5)
local EditHatsu = HxH5e:WaitForChild("EditHatsu", 5)

local wizardFrame = makeFrame(screenGui, "HatsuWizard",
	UDim2.fromOffset(520, 520), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
wizardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
wizardFrame.Visible = false
addCloseButton(wizardFrame)
addDragBar(wizardFrame)

local wizardTitleLabel = makeLabel(wizardFrame, "WizardTitle", "CRIAR HATSU — REFORÇO",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 26), 18)

local wizardStepLabel = makeLabel(wizardFrame, "WizardStep", "Passo 1/4 — Restrições",
	UDim2.new(0, 16, 0, 40), UDim2.new(1, -32, 0, 20), 13)
wizardStepLabel.TextColor3 = Color3.fromRGB(0, 255, 157)

local wizardInfoLabel = makeLabel(wizardFrame, "WizardInfo", "",
	UDim2.new(0, 16, 0, 62), UDim2.new(1, -32, 0, 18), 12)
wizardInfoLabel.TextColor3 = Color3.fromRGB(255, 220, 120)

local pesoAbasFrame = makeFrame(wizardFrame, "PesoAbas",
	UDim2.new(1, -32, 0, 28), UDim2.new(0, 16, 0, 82), Color3.fromRGB(0, 0, 0))
pesoAbasFrame.BackgroundTransparency = 1

local efeitoAbasFrame = makeFrame(wizardFrame, "EfeitoAbas",
	UDim2.new(1, -32, 0, 58), UDim2.new(0, 16, 0, 82), Color3.fromRGB(0, 0, 0))
efeitoAbasFrame.BackgroundTransparency = 1
efeitoAbasFrame.Visible = false

local wizardScroll = Instance.new("ScrollingFrame")
wizardScroll.Name = "WizardScroll"
wizardScroll.Size = UDim2.new(1, -32, 1, -200)
wizardScroll.Position = UDim2.new(0, 16, 0, 144)
wizardScroll.BackgroundTransparency = 1
wizardScroll.ScrollBarThickness = 6
wizardScroll.BorderSizePixel = 0
wizardScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
wizardScroll.ElasticBehavior = Enum.ElasticBehavior.Never
wizardScroll.Parent = wizardFrame

local wizardLayout = Instance.new("UIListLayout")
wizardLayout.Padding = UDim.new(0, 4)
wizardLayout.Parent = wizardScroll

local wizardBack = makeButton(wizardFrame, "WizardBack", "VOLTAR",
	UDim2.new(0, 16, 1, -50), UDim2.new(0, 100, 0, 36))
wizardBack.ZIndex = 20

local wizardNext = makeButton(wizardFrame, "WizardNext", "AVANÇAR",
	UDim2.new(0, 280, 1, -50), UDim2.new(0, 220, 0, 36))
wizardNext.ZIndex = 20
wizardNext.TextColor3 = Color3.fromRGB(0, 255, 157)

local PESO_ABAS = {
	{ label = "Todas", key = "Todas" },
	{ label = "Leves", key = "leve" },
	{ label = "Moderadas", key = "moderada" },
	{ label = "Pesadas", key = "pesada" },
	{ label = "Variáveis", key = "variavel" },
	{ label = "Extremas", key = "extrema" },
	{ label = "Reforço", key = "Reforço" },
}

local wizardState = {
	step = 1,
	nome = "",
	efeitos = {},
	restricoes = {},
	catalog = nil,
	pnDisponivel = 0,
	level = 1,
	efeitoAba = "Gerais",
	pesoAba = "Todas",
	editId = nil,
	natureza = "Ataque",
	ocultarBloqueados = true,
}

local function wizardClear()
	for _, child in ipairs(wizardScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextBox") then
			child:Destroy()
		end
	end
end

local function sortEffects(lista)
	local copia = {}
	for _, e in ipairs(lista) do
		table.insert(copia, e)
	end
	table.sort(copia, function(a, b)
		local na = a.nivel or 1
		local nb = b.nivel or 1
		if na ~= nb then
			return na < nb
		end
		return tostring(a.nome or "") < tostring(b.nome or "")
	end)
	return copia
end

local function wizardCustoEfeitos()
	local cat = wizardState.catalog
	local total = 0
	for _, e in ipairs(cat and cat.effects or {}) do
		if wizardState.efeitos[e.id] then
			total = total + e.custo
		end
	end
	return total
end

local function wizardGanhoRestricoes()
	local total = 0
	for _, r in pairs(wizardState.restricoes) do
		if r.pura then
			total = total + (r.ganho or 0)
		end
	end
	return total
end

local function wizardRender()
	wizardClear()
	local cat = wizardState.catalog
	if not cat then
		return
	end

	local custoEfeitos = wizardCustoEfeitos()
	local ganhoRest = wizardGanhoRestricoes()
	local custoLiquido = math.max(0, custoEfeitos - ganhoRest)
	local saldo = wizardState.pnDisponivel - custoLiquido

	if wizardState.step == 1 then
		-- PASSO 1: RESTRIÇÕES
		wizardStepLabel.Text = "Passo 1/4 — Restrições (Nível " .. wizardState.level .. ")"
		wizardInfoLabel.Text = "Escolha restrições PURAS para ganhar P.N antes de comprar efeitos. Puras: +" .. ganhoRest .. " P.N"
		pesoAbasFrame.Visible = true
		efeitoAbasFrame.Visible = false

		do
			local buscaBox = Instance.new("TextBox")
			buscaBox.Name = "BuscaRestricao"
			buscaBox.Size = UDim2.new(1, 0, 0, 30)
			buscaBox.PlaceholderText = "🔍 Buscar restrição por nome (todas as categorias)..."
			buscaBox.Text = wizardState.buscaRestricao
			buscaBox.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
			buscaBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			buscaBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
			buscaBox.Font = Enum.Font.Gotham
			buscaBox.TextSize = 13
			buscaBox.BorderSizePixel = 0
			buscaBox.Parent = wizardScroll
			buscaBox.FocusLost:Connect(function()
				wizardState.buscaRestricao = buscaBox.Text
				wizardRender()
			end)
		end

		for _, child in ipairs(pesoAbasFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for pi, abaInfo in ipairs(PESO_ABAS) do
			local aba = makeButton(pesoAbasFrame, "Aba_" .. abaInfo.key, abaInfo.label,
				UDim2.new(0, (pi - 1) * 74, 0, 0), UDim2.new(0, 70, 0, 26))
			aba.TextSize = 9
			aba.BackgroundColor3 = (wizardState.pesoAba == abaInfo.key)
				and Color3.fromRGB(0, 255, 157) or Color3.fromRGB(38, 42, 58)
			aba.TextColor3 = (wizardState.pesoAba == abaInfo.key)
				and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(255, 255, 255)
			aba.Activated:Connect(function()
				wizardState.pesoAba = abaInfo.key
				wizardRender()
			end)
		end

		for _, r in ipairs(cat.restrictions) do
			local mostra = false
			local buscaAtiva = #wizardState.buscaRestricao > 0
			if buscaAtiva then
				mostra = r.nome:lower():find(wizardState.buscaRestricao:lower(), 1, true) ~= nil
			elseif wizardState.pesoAba == "Todas" then
				mostra = true
			elseif wizardState.pesoAba == "Reforço" then
				mostra = (r.categoria == "Reforço")
			else
				mostra = (r.peso == wizardState.pesoAba)
			end
			if mostra then
				local sel = wizardState.restricoes[r.id]
				local row = makeFrame(wizardScroll, "Res_" .. r.id,
					UDim2.new(1, 0, 0, 108), UDim2.new(0, 0, 0, 0), Color3.fromRGB(38, 42, 58))
				local lbl = makeLabel(row, "Lbl",
					tostring(r.nome or "?") .. "  [" .. tostring(r.peso or "?") .. (r.categoria and (" • " .. r.categoria) or "") .. "]",
					UDim2.new(0, 8, 0, 3), UDim2.new(0, 360, 0, 18), 11)
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				local desc = makeLabel(row, "Desc", tostring(r.descricao or ""),
					UDim2.new(0, 8, 0, 21), UDim2.new(1, -16, 0, 40), 9)
				desc.TextXAlignment = Enum.TextXAlignment.Left
				desc.TextWrapped = true
				desc.TextYAlignment = Enum.TextYAlignment.Top
				desc.TextColor3 = Color3.fromRGB(170, 170, 180)

				local ben = makeButton(row, "Ben", "BENEFÍCIO",
					UDim2.new(0, 8, 0, 62), UDim2.new(0, 120, 0, 22))
				ben.TextSize = 10
				ben.BackgroundColor3 = (sel and not sel.pura)
					and Color3.fromRGB(0, 120, 70) or Color3.fromRGB(60, 60, 80)
				ben.Activated:Connect(function()
					if sel and not sel.pura then
						wizardState.restricoes[r.id] = nil
					else
						local beneficios = r.beneficios or {}
						if #beneficios > 1 then
							wizardState.restricoes[r.id] = { id = r.id, pura = false, ganho = 0, trBonus = r.trBonus or 0, escolhendo = true }
						else
							wizardState.restricoes[r.id] = { id = r.id, pura = false, ganho = 0, trBonus = r.trBonus or 0, beneficioIndex = 1 }
							local detalhes = "🔹 " .. r.nome .. " [" .. r.peso .. "]\n\nBenefício:\n  1) " .. (beneficios[1] or "?")
							if r.trBonus then
								detalhes = detalhes .. "\n\nBônus de TR: +" .. r.trBonus
							end
							showToast(detalhes, 6)
						end
					end
					wizardRender()
				end)

				if sel and sel.escolhendo then
					local beneficios = r.beneficios or {}
					for bi, b in ipairs(beneficios) do
						local altBtn = makeButton(row, "Alt_" .. bi, "Opção " .. bi .. ": " .. b,
							UDim2.new(0, 8, 0, 62 + (bi - 1) * 24), UDim2.new(1, -16, 0, 22))
						altBtn.TextSize = 9
						altBtn.TextXAlignment = Enum.TextXAlignment.Left
						altBtn.BackgroundColor3 = Color3.fromRGB(48, 62, 110)
						altBtn.Activated:Connect(function()
							wizardState.restricoes[r.id] = { id = r.id, pura = false, ganho = 0, trBonus = r.trBonus or 0, beneficioIndex = bi }
							local detalhes = "🔹 " .. r.nome .. " [" .. r.peso .. "]\n\nBenefício:\n  " .. bi .. ") " .. b
							if r.trBonus then
								detalhes = detalhes .. "\n\nBônus de TR: +" .. r.trBonus
							end
							showToast(detalhes, 6)
							wizardRender()
						end)
					end
				end

				local pura = makeButton(row, "Pura",
					"PURA +" .. tostring(r.pura or 0) .. " P.N",
					UDim2.new(0, 136, 0, 62), UDim2.new(0, 140, 0, 22))
				pura.TextSize = 10
				pura.BackgroundColor3 = (sel and sel.pura)
					and Color3.fromRGB(180, 140, 0) or Color3.fromRGB(70, 60, 30)
				pura.Activated:Connect(function()
					if sel and sel.pura then
						wizardState.restricoes[r.id] = nil
					else
						wizardState.restricoes[r.id] = { id = r.id, pura = true, ganho = r.pura or 0, trBonus = r.trBonus or 0 }
					end
					wizardRender()
				end)

				local estado = makeLabel(row, "Estado",
					(sel and (sel.pura and "Pura selecionada" or (sel.beneficioIndex and "Benefício " .. sel.beneficioIndex .. " selecionado" or "Escolhendo benefício..."))) or "",
					UDim2.new(0, 8, 0, 88), UDim2.new(1, -16, 0, 16), 9)
				estado.TextXAlignment = Enum.TextXAlignment.Left
				estado.TextColor3 = Color3.fromRGB(0, 255, 157)
			end
		end
	elseif wizardState.step == 2 then
		-- PASSO 2: EFEITOS
		wizardStepLabel.Text = "Passo 2/4 — Efeitos (Nível " .. wizardState.level .. ")"
		wizardInfoLabel.Text = "P.N: " .. wizardState.pnDisponivel
			.. " | Puras: +" .. ganhoRest
			.. " | Custo efeitos: " .. custoEfeitos
			.. " | Saldo: " .. saldo
		pesoAbasFrame.Visible = false
		efeitoAbasFrame.Visible = true

		do
			local buscaBox = Instance.new("TextBox")
			buscaBox.Name = "BuscaEfeito"
			buscaBox.Size = UDim2.new(1, 0, 0, 30)
			buscaBox.PlaceholderText = "🔍 Buscar efeito por nome (todas as categorias acessíveis)..."
			buscaBox.Text = wizardState.buscaEfeito
			buscaBox.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
			buscaBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			buscaBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
			buscaBox.Font = Enum.Font.Gotham
			buscaBox.TextSize = 13
			buscaBox.BorderSizePixel = 0
			buscaBox.Parent = wizardScroll
			buscaBox.FocusLost:Connect(function()
				wizardState.buscaEfeito = buscaBox.Text
				wizardRender()
			end)
		end

		for _, child in ipairs(efeitoAbasFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local grupos = {}
		do
			local vistos = {}
			for _, e in ipairs(cat.effects) do
				if not vistos[e.grupo] then
					vistos[e.grupo] = true
					table.insert(grupos, e.grupo)
				end
			end
			table.sort(grupos, function(a, b)
				if a == "Gerais" then return true end
				if b == "Gerais" then return false end
				if a == cat.categoria then return true end
				if b == cat.categoria then return false end
				return a < b
			end)
		end
		for gi, grupo in ipairs(grupos) do
			local aba = makeButton(efeitoAbasFrame, "Aba_" .. grupo, grupo,
				UDim2.new(0, (gi - 1) * 78, 0, 0), UDim2.new(0, 74, 0, 24))
			aba.TextSize = 10
			aba.BackgroundColor3 = (wizardState.efeitoAba == grupo)
				and Color3.fromRGB(0, 255, 157) or Color3.fromRGB(38, 42, 58)
			aba.TextColor3 = (wizardState.efeitoAba == grupo)
				and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(255, 255, 255)
			aba.Activated:Connect(function()
				wizardState.efeitoAba = grupo
				wizardRender()
			end)
		end

		local ocultarBtn = makeButton(efeitoAbasFrame, "OcultarBloqueados",
			wizardState.ocultarBloqueados and "✓ Ocultar bloqueados" or "✗ Mostrar bloqueados",
			UDim2.new(0, 0, 0, 30), UDim2.new(0, 180, 0, 26))
		ocultarBtn.TextSize = 10
		ocultarBtn.BackgroundColor3 = wizardState.ocultarBloqueados
			and Color3.fromRGB(0, 120, 70) or Color3.fromRGB(60, 60, 80)
		ocultarBtn.Activated:Connect(function()
			wizardState.ocultarBloqueados = not wizardState.ocultarBloqueados
			wizardRender()
		end)

		local ordenados = sortEffects(cat.effects)
		local ultimoNivel = nil
		local buscaEfeitoAtiva = #wizardState.buscaEfeito > 0
		for _, e in ipairs(ordenados) do
			if buscaEfeitoAtiva or e.grupo == wizardState.efeitoAba then
				local bateBusca = (not buscaEfeitoAtiva) or e.nome:lower():find(wizardState.buscaEfeito:lower(), 1, true) ~= nil
				if bateBusca then
				local bloqueado = (e.nivel or 1) > (e.nivelMaxAcessivel or wizardState.level)
				if not (wizardState.ocultarBloqueados and bloqueado) then
					if e.nivel ~= ultimoNivel then
						ultimoNivel = e.nivel
						local header = makeLabel(wizardScroll, "NivelHeader",
							"— NÍVEL " .. tostring(e.nivel) .. " —",
							UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), 12)
						header.TextColor3 = Color3.fromRGB(0, 200, 255)
						header.Font = Enum.Font.GothamBold
					end

					local selecionado = wizardState.efeitos[e.id]
					local row = makeFrame(wizardScroll, "Eff_" .. e.id,
						UDim2.new(1, 0, 0, 46), UDim2.new(0, 0, 0, 0), Color3.fromRGB(38, 42, 58))
					local lbl = makeLabel(row, "Lbl",
						tostring(e.nome or "?") .. "  (" .. tostring(e.custo) .. " P.N)",
						UDim2.new(0, 8, 0, 3), UDim2.new(0, 300, 0, 18), 12)
					lbl.TextXAlignment = Enum.TextXAlignment.Left
					local desc = makeLabel(row, "Desc",
						bloqueado and ("🔒 Requer acesso nível " .. tostring(e.nivel or 1) .. " em " .. tostring(e.grupo) .. " (seu acesso vai até " .. tostring(e.nivelMaxAcessivel or 0) .. ")") or tostring(e.desc or ""),
						UDim2.new(0, 8, 0, 21), UDim2.new(0, 360, 0, 22), 9)
					desc.TextXAlignment = Enum.TextXAlignment.Left
					desc.TextWrapped = true
					desc.TextColor3 = bloqueado
						and Color3.fromRGB(120, 120, 130) or Color3.fromRGB(170, 170, 180)
					local btn = makeButton(row, "Btn",
						bloqueado and "🔒" or (selecionado and "✓" or "+"),
						UDim2.new(1, -36, 0, 6), UDim2.new(0, 28, 1, -12))
					btn.TextSize = 16
					if bloqueado then
						btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
						btn.TextColor3 = Color3.fromRGB(140, 140, 140)
					else
						btn.BackgroundColor3 = selecionado
							and Color3.fromRGB(0, 120, 70) or Color3.fromRGB(60, 60, 80)
					end
					btn.Activated:Connect(function()
						if bloqueado then
							showToast("🔒 Efeito bloqueado: requer Nível " .. tostring(e.nivel or 1) .. ".", 3)
							return
						end
						if wizardState.efeitos[e.id] then
							wizardState.efeitos[e.id] = nil
						else
							wizardState.efeitos[e.id] = true
						end
						wizardRender()
					end)
				end
			end
			end
		end
	elseif wizardState.step == 3 then
		-- PASSO 3: NATUREZA E NOME
		wizardStepLabel.Text = "Passo 3/4 — Natureza e Nome"
		wizardInfoLabel.Text = "Defina o tipo do Hatsu e dê um nome."
		pesoAbasFrame.Visible = false
		efeitoAbasFrame.Visible = false

		local naturaLabel = makeLabel(wizardScroll, "NaturaLabel", "Natureza do Hatsu:",
			UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 18), 12)
		naturaLabel.TextXAlignment = Enum.TextXAlignment.Left
		naturaLabel.TextColor3 = Color3.fromRGB(0, 200, 255)

		local naturezas = { "Ataque", "Área", "Buff/Utilidade" }
		for ni, nat in ipairs(naturezas) do
			local natBtn = makeButton(wizardScroll, "Nat_" .. nat, nat,
				UDim2.new(0, 8 + (ni - 1) * 130, 0, 26), UDim2.new(0, 122, 0, 26))
			natBtn.TextSize = 11
			natBtn.BackgroundColor3 = (wizardState.natureza == nat)
				and Color3.fromRGB(0, 120, 70) or Color3.fromRGB(60, 60, 80)
			natBtn.Activated:Connect(function()
				wizardState.natureza = nat
				wizardRender()
			end)
		end

		local box = Instance.new("TextBox")
		box.Name = "WizardName"
		box.Size = UDim2.new(1, -32, 0, 40)
		box.Position = UDim2.new(0, 16, 0, 60)
		box.PlaceholderText = "Nome do Hatsu"
		box.Text = wizardState.nome
		box.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
		box.Font = Enum.Font.Gotham
		box.TextSize = 16
		box.BorderSizePixel = 0
		box.Parent = wizardScroll
		box.FocusLost:Connect(function(enter)
			wizardState.nome = box.Text
		end)
	elseif wizardState.step == 4 then
		-- PASSO 4: REVISÃO (+ Graus de Potência iniciais, so no 1o Hatsu)
		wizardStepLabel.Text = "Passo 4/4 — Revisão"
		wizardInfoLabel.Text = "Confira antes de criar."
		pesoAbasFrame.Visible = false
		efeitoAbasFrame.Visible = false

		if wizardState.ehPrimeiroHatsu and #wizardState.grauOpcoes > 0 then
			local totalUsado = 0
			for _, pontos in pairs(wizardState.grauAlocacao) do
				totalUsado = totalUsado + pontos
			end

			local grauTitle = makeLabel(wizardScroll, "GrauTitle",
				"GRAUS DE POTÊNCIA INICIAIS — " .. totalUsado .. "/" .. wizardState.grauTotal .. " (só no 1º Hatsu)",
				UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), 12)
			grauTitle.Font = Enum.Font.GothamBold
			grauTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
			grauTitle.TextXAlignment = Enum.TextXAlignment.Left

			for gi, caracteristica in ipairs(wizardState.grauOpcoes) do
				local pontos = wizardState.grauAlocacao[caracteristica] or 0
				local row = makeFrame(wizardScroll, "Grau_" .. caracteristica, UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 0), Color3.fromRGB(38, 42, 58))
				local lbl = makeLabel(row, "Lbl", caracteristica .. ": " .. pontos, UDim2.new(0, 8, 0, 0), UDim2.new(0, 220, 1, 0), 12)
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				local minusBtn = makeButton(row, "Minus", "-", UDim2.new(1, -70, 0, 2), UDim2.new(0, 30, 0, 24))
				local plusBtn = makeButton(row, "Plus", "+", UDim2.new(1, -34, 0, 2), UDim2.new(0, 30, 0, 24))
				minusBtn.Activated:Connect(function()
					local atual = wizardState.grauAlocacao[caracteristica] or 0
					if atual > 0 then
						wizardState.grauAlocacao[caracteristica] = atual - 1
						wizardRender()
					end
				end)
				plusBtn.Activated:Connect(function()
					local soma = 0
					for _, p in pairs(wizardState.grauAlocacao) do soma = soma + p end
					if soma < wizardState.grauTotal then
						wizardState.grauAlocacao[caracteristica] = (wizardState.grauAlocacao[caracteristica] or 0) + 1
						wizardRender()
					end
				end)
			end

			local grauAviso = makeLabel(wizardScroll, "GrauAviso",
				"Só Redução de Custo, Dano/Cura e CD do TR já têm efeito de jogo. As outras ficam registradas pra quando o sistema completo existir.",
				UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 28), 9)
			grauAviso.TextColor3 = Color3.fromRGB(170, 170, 180)
			grauAviso.TextWrapped = true
		end

		local resumo = "RESTRIÇÕES:\n"
		for _, r in pairs(wizardState.restricoes) do
			local rc
			for _, rc2 in ipairs(cat.restrictions) do
				if rc2.id == r.id then
					rc = rc2
					break
				end
			end
			if rc then
				local benefEscolhido = ""
				if r.pura then
					benefEscolhido = " (PURA +" .. r.ganho .. " P.N)"
				elseif r.beneficioIndex then
					local b = (rc.beneficios or {})[r.beneficioIndex]
					benefEscolhido = " (Benefício: " .. (b or "?") .. ")"
				else
					benefEscolhido = " (Benefício)"
				end
				resumo = resumo .. "  • " .. rc.nome .. benefEscolhido .. "\n"
			end
		end
		resumo = resumo .. "EFEITOS:\n"
		for _, e in ipairs(cat.effects) do
			if wizardState.efeitos[e.id] then
				resumo = resumo .. "  • " .. e.nome .. " (" .. e.custo .. " P.N)\n"
			end
		end
		resumo = resumo .. "\nNatureza: " .. wizardState.natureza
		resumo = resumo .. "\nEfeitos: " .. custoEfeitos .. " P.N"
		resumo = resumo .. "\nRestrições puras: -" .. ganhoRest .. " P.N"
		resumo = resumo .. "\nCusto líquido: " .. custoLiquido .. " P.N"
		resumo = resumo .. "\nP.N restante: " .. saldo
		resumo = resumo .. "\nNome: " .. wizardState.nome

		local rev = makeLabel(wizardScroll, "Review", resumo,
			UDim2.new(0, 8, 0, 8), UDim2.new(1, -16, 0, 320), 12)
		rev.TextXAlignment = Enum.TextXAlignment.Left
		rev.TextYAlignment = Enum.TextYAlignment.Top
		rev.TextWrapped = true
	end

	wizardScroll.CanvasPosition = Vector2.zero
end

wizardOpen = function(hatsuParaEditar)
	if not GetHatsuCatalog or not CreateHatsuV2 then
		showToast("Wizard indisponível: atualize o ServerBootstrap (remotes GetHatsuCatalog/CreateHatsuV2).", 5)
		return
	end
	local character = GetCharacter:InvokeServer()
	wizardState.level = (character and character.Level) or 1
	wizardState.step = 1
	wizardState.nome = ""
	wizardState.efeitos = {}
	wizardState.restricoes = {}
	wizardState.efeitoAba = "Gerais"
	wizardState.pesoAba = "Todas"
	wizardState.editId = hatsuParaEditar and hatsuParaEditar.Id or nil
	wizardState.natureza = "Ataque"
	wizardState.ocultarBloqueados = true -- padrao original restaurado (o switch "Ocultar bloqueados" continua disponivel pro jogador revelar tudo)
	-- Passa o proprio Id (se editando) pra excluir do calculo de P.N gasto,
	-- exatamente como o webapp faz com editingIdx.
	wizardState.catalog = GetHatsuCatalog:InvokeServer(wizardState.editId)
	wizardState.pnDisponivel = wizardState.catalog and wizardState.catalog.pnDisponivel or 0
	wizardState.ehPrimeiroHatsu = (not hatsuParaEditar) and wizardState.catalog and wizardState.catalog.ehPrimeiroHatsu or false
	wizardState.grauOpcoes = (wizardState.catalog and wizardState.catalog.grauOptions) or {}
	wizardState.grauTotal = (wizardState.catalog and wizardState.catalog.grauTotal) or 5
	wizardState.grauAlocacao = {}
	wizardState.buscaEfeito = ""
	wizardState.buscaRestricao = ""

	if hatsuParaEditar then
		wizardState.editId = hatsuParaEditar.Id
		wizardState.nome = hatsuParaEditar.Nome or ""
		wizardState.natureza = hatsuParaEditar.Natureza or "Ataque"
		for _, e in ipairs(hatsuParaEditar.Efeitos or {}) do
			wizardState.efeitos[e.id] = true
		end
		for _, r in ipairs(hatsuParaEditar.Restricoes or {}) do
			wizardState.restricoes[r.id] = { id = r.id, pura = r.pura or false, ganho = r.ganho or 0, trBonus = r.trBonus or 0, beneficioIndex = r.beneficioIndex }
		end
		wizardTitleLabel.Text = "EDITAR HATSU — REFORÇO"
	else
		wizardTitleLabel.Text = "CRIAR HATSU — REFORÇO"
	end

	wizardRender()
	openWindow(wizardFrame)
end

wizardNext.Activated:Connect(function()
	if wizardState.step == 1 then
		wizardState.step = 2
	elseif wizardState.step == 2 then
		if not next(wizardState.efeitos) then
			showToast("Selecione pelo menos um efeito.", 3)
			return
		end
		wizardState.step = 3
	elseif wizardState.step == 3 then
		if #wizardState.nome == 0 then
			showToast("Digite um nome.", 3)
			return
		end
		wizardState.step = 4
	elseif wizardState.step == 4 then
		local efeitos = {}
		for id in pairs(wizardState.efeitos) do
			table.insert(efeitos, id)
		end
		local restricoes = {}
		for _, r in pairs(wizardState.restricoes) do
			table.insert(restricoes, { id = r.id, pura = r.pura, beneficioIndex = r.beneficioIndex })
		end
		local build = {
			nome = wizardState.nome,
			tipo = "Reforço",
			natureza = wizardState.natureza,
			efeitos = efeitos,
			restricoes = restricoes,
			grauAlocacao = (wizardState.ehPrimeiroHatsu and not wizardState.editId) and wizardState.grauAlocacao or nil,
		}
		local result
		if wizardState.editId then
			result = EditHatsu:InvokeServer(wizardState.editId,
	build)
		else
			result = CreateHatsuV2:InvokeServer(build)
		end
		if result then
			showToast(tostring(result.message or result.error), 6)
			if result.success then
				closeWindow(wizardFrame)
				refreshHatsus()
				refreshFicha()
			end
		end
		return
	end
	wizardRender()
end)

wizardBack.Activated:Connect(function()
	if wizardState.step > 1 then
		wizardState.step = wizardState.step - 1
		wizardRender()
	else
		closeWindow(wizardFrame)
	end
end)

hatsuCreateButton.Activated:Connect(function()
	wizardOpen(nil)
end)
