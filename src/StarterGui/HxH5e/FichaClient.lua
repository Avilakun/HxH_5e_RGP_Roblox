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
	UDim2.fromOffset(430, 560), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
fichaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fichaFrame.Visible = false
addCloseButton(fichaFrame)

-- ---------- Barra de guias ----------
-- (elementos que nao precisam sobreviver ficam dentro do "do...end" pra
-- liberar o registrador de variavel local assim que o bloco termina --
-- Luau tem um teto de 200 locais simultaneas por escopo)

local TAB_LIST = {
	{ id = "FICHA", label = "FICHA", enabled = true },
	{ id = "BIO", label = "BIO", enabled = false },
	{ id = "NEN", label = "NEN", enabled = true },
	{ id = "TRACOS", label = "TRAÇOS", enabled = true },
	{ id = "INV", label = "INV", enabled = false },
	{ id = "DADOS", label = "DADOS", enabled = false },
	{ id = "COND", label = "COND", enabled = false },
}

local tabButtons = {}
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
do
	local statusContent = makeFrame(statusScroll, "Content",
		UDim2.new(1, 0, 0, 200), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0))
	statusContent.BackgroundTransparency = 1

	titleLabel = makeLabel(statusContent, "TitleLabel", "Nenhum personagem",
		UDim2.new(0, 0, 0, 4), UDim2.new(1, -20, 0, 30), 20)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextWrapped = true

	categoryLabel = makeLabel(statusContent, "CategoryLabel", "Categoria: —",
		UDim2.new(0, 0, 0, 36), UDim2.new(1, 0, 0, 20), 14)
	categoryLabel.TextColor3 = Color3.fromRGB(0, 255, 157)

	geniusLabel = makeLabel(statusContent, "GeniusLabel", "Genialidade: —",
		UDim2.new(0, 0, 0, 56), UDim2.new(1, 0, 0, 18), 12)
	geniusLabel.TextColor3 = Color3.fromRGB(190, 170, 255)

	xpLabel = makeLabel(statusContent, "XpLabel", "XP: -",
		UDim2.new(0, 0, 0, 74), UDim2.new(1, 0, 0, 18), 12)
	xpLabel.TextColor3 = Color3.fromRGB(255, 220, 120)

	for i, attributeName in ipairs(attributeNames) do
		local col = (i - 1) % 2
		local row = math.floor((i - 1) / 2)
		local label = makeLabel(statusContent, "Attr_" .. attributeName,
			attributeName .. ": -",
			UDim2.new(0, 20 + col * 190, 0, 100 + row * 26),
			UDim2.new(0, 170, 0, 22), 16)
		attributeLabels[attributeName] = label
	end

	hpLabel = makeLabel(statusContent, "HpLabel", "HP: -",
		UDim2.new(0, 20, 0, 184), UDim2.new(0, 190, 0, 22), 16)
	auraLabel = makeLabel(statusContent, "AuraLabel", "Aura: -",
		UDim2.new(0, 210, 0, 184), UDim2.new(0, 170, 0, 22), 16)
	sanidadeLabel = makeLabel(statusContent, "SanidadeLabel", "Sanidade: -",
		UDim2.new(0, 20, 0, 208), UDim2.new(0, 190, 0, 22), 16)
end

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

-- ================= Janela de atributos (compra de pontos) =================

local attrFrame = makeFrame(screenGui, "AttrWindow",
	UDim2.fromOffset(380, 420), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
attrFrame.AnchorPoint = Vector2.new(0.5, 0.5)
attrFrame.Visible = false
addCloseButton(attrFrame)

makeLabel(attrFrame, "AttrTitle", "ATRIBUTOS (Compra de Pontos)",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 24), 16)

local attrPointsLabel = makeLabel(attrFrame, "AttrPoints", "Pontos: 0 / 20",
	UDim2.new(0, 16, 0, 38), UDim2.new(1, -32, 0, 20), 13)
attrPointsLabel.TextColor3 = Color3.fromRGB(255, 220, 120)

local attrRows = {}
for i, key in ipairs(attributeNames) do
	local y = 68 + (i - 1) * 44
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
		geniusLabel.Text = "Genialidade: —"
		xpLabel.Text = "XP: -"
		for _, attributeName in ipairs(attributeNames) do
			attributeLabels[attributeName].Text = attributeName .. ": -"
		end
		hpLabel.Text = "HP: -"
		auraLabel.Text = "Aura: -"
		sanidadeLabel.Text = "Sanidade: -"
		refreshNen()
		return
	end

	local racaSufixo = character.Race and ("  •  " .. tostring(character.Race)) or ""
	titleLabel.Text = character.Name .. "  •  Nível " .. tostring(character.Level) .. racaSufixo

	local nen = character.Nen or {}
	local category = nen.Category or character.Class or nil
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
		geniusLabel.Text = "Genialidade: " .. tostring(nen.Genius.Tier)
			.. " (" .. tostring(nen.Genius.Roll) .. ")"
	else
		geniusLabel.Text = "Genialidade: —"
	end

	local xp = character.XP or 0
	local xpNext = character.XPNext or 50
	xpLabel.Text = "XP: " .. tostring(xp) .. " / " .. tostring(xpNext)

	for _, attributeName in ipairs(attributeNames) do
		local attr = character.Attributes and character.Attributes[attributeName]
		local value = (attr and attr.value) or "-"
		attributeLabels[attributeName].Text = attributeName .. ": " .. tostring(value)
	end

	if character.Vitals then
		hpLabel.Text = "HP: " .. vitalText(character.Vitals.HP)
		auraLabel.Text = "Aura: " .. vitalText(character.Vitals.Aura)
		sanidadeLabel.Text = "Sanidade: " .. vitalText(character.Vitals.Sanidade)
	end

	refreshNen()
end

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

	local racaTxt = tostring(character.Race or "—")
	if character.RaceBonusPending and #character.RaceBonusPending > 0 then
		racaTxt = racaTxt .. "\n(bônus a definir: " .. table.concat(character.RaceBonusPending, ", ") .. ")"
	end
	addSection("RAÇA", racaTxt)

	local bgTxt = character.Background and (tostring(character.Background) .. "\nCaracterística: " .. tostring(character.BackgroundFeature)) or "—"
	addSection("ANTECEDENTE", bgTxt)

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

	for id, btn in pairs(tabButtons) do
		local isActive = (id == tabId)
		btn.BackgroundColor3 = isActive and Color3.fromRGB(0, 120, 70) or Color3.fromRGB(38, 42, 58)
	end

	statusScroll.Visible = (tabId == "FICHA")
	nenScroll.Visible = (tabId == "NEN")
	tracosScroll.Visible = (tabId == "TRACOS")

	if tabId == "NEN" then
		refreshNen()
		refreshHatsus()
	elseif tabId == "TRACOS" then
		refreshTracos()
	end
end

for _, tabInfo in ipairs(TAB_LIST) do
	tabButtons[tabInfo.id].Activated:Connect(function()
		setFichaTab(tabInfo.id)
	end)
end

local pendingCreateName = nil
local pendingRace = nil
local pendingAttrs = nil
local pointBuyInfo = nil -- { costs = {...}, maxCost = 20, defaultValue = 10 }
local backgroundsCache = nil
local selectedBgName = nil

local function finishCreateCharacter(raceName, attrsBuild, backgroundName, backgroundFeature, positiveInclinations, negativeInclinations, chosenSkills, chosenOtherSkills)
	local result = CreateCharacter:InvokeServer(pendingCreateName, raceName, attrsBuild, backgroundName, backgroundFeature, positiveInclinations, negativeInclinations, chosenSkills, chosenOtherSkills)
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
	local total = 0
	for _, key in ipairs(attributeNames) do
		local value = pendingAttrs[key]
		local cost = attrCost(value)
		total = total + cost
		attrRows[key].label.Text = key .. ": " .. value .. "  (custo " .. cost .. ")"
	end
	local maxCost = pointBuyInfo and pointBuyInfo.maxCost or 20
	attrPointsLabel.Text = "Pontos: " .. total .. " / " .. maxCost
	attrPointsLabel.TextColor3 = (total > maxCost) and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 220, 120)
end

local function openAttrStep()
	if not pointBuyInfo then
		pointBuyInfo = GetPointBuyInfo:InvokeServer()
	end
	pendingAttrs = {}
	for _, key in ipairs(attributeNames) do
		pendingAttrs[key] = (pointBuyInfo and pointBuyInfo.defaultValue) or 10
	end
	refreshAttrUI()
	openWindow(attrFrame)
end

for _, key in ipairs(attributeNames) do
	attrRows[key].minus.Activated:Connect(function()
		pendingAttrs[key] = math.max(1, pendingAttrs[key] - 1)
		refreshAttrUI()
	end)
	attrRows[key].plus.Activated:Connect(function()
		pendingAttrs[key] = math.min(30, pendingAttrs[key] + 1)
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
		local escolherBtn = makeButton(row, "BEscolher", expandido and "SELECIONADO" or "VER",
			UDim2.new(1, -96, 0, 14), UDim2.new(0, 86, 0, 36))
		escolherBtn.TextSize = 11
		escolherBtn.BackgroundColor3 = expandido and Color3.fromRGB(0, 120, 70) or Color3.fromRGB(48, 62, 110)
		escolherBtn.Activated:Connect(function()
			selectedBgName = expandido and nil or bg.nome
			refreshBackgrounds()
		end)
		if expandido then
			for fi, c in ipairs(bg.caracteristicas) do
				local featBtn = makeButton(row, "BFeat_" .. fi, "🌟 " .. tostring(c.nome),
					UDim2.new(0, 10, 0, 64 + (fi - 1) * 28), UDim2.new(1, -20, 0, 24))
				featBtn.TextSize = 10
				featBtn.TextXAlignment = Enum.TextXAlignment.Left
				featBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 30)
				featBtn.Activated:Connect(function()
					pendingBackground = bg.nome
					pendingBackgroundFeature = c.nome
					closeWindow(bgFrame)
					openInclinationsStep()
				end)
			end
		end
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
	local total = 0
	for _, key in ipairs(attributeNames) do
		total = total + attrCost(pendingAttrs[key])
	end
	local maxCost = pointBuyInfo and pointBuyInfo.maxCost or 20
	if total > maxCost then
		showToast("Você gastou " .. total .. " pontos, o máximo é " .. maxCost .. ".")
		return
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
			pendingRace = race.nome
			closeWindow(raceFrame)
			openAttrStep()
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
addDragBar(attrFrame)
addDragBar(bgFrame)
addDragBar(incFrame)
addDragBar(skillFrame)
addDragBar(resultFrame)


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
	UDim2.new(1, -32, 0, 28), UDim2.new(0, 16, 0, 82), Color3.fromRGB(0, 0, 0))
efeitoAbasFrame.BackgroundTransparency = 1
efeitoAbasFrame.Visible = false

local wizardScroll = Instance.new("ScrollingFrame")
wizardScroll.Name = "WizardScroll"
wizardScroll.Size = UDim2.new(1, -32, 1, -170)
wizardScroll.Position = UDim2.new(0, 16, 0, 114)
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
			if wizardState.pesoAba == "Todas" then
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

		for _, child in ipairs(efeitoAbasFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local grupos = { "Gerais", "Reforço" }
		for gi, grupo in ipairs(grupos) do
			local aba = makeButton(efeitoAbasFrame, "Aba_" .. grupo, grupo,
				UDim2.new(0, (gi - 1) * 100, 0, 0), UDim2.new(0, 94, 0, 26))
			aba.TextSize = 12
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
			UDim2.new(0, 210, 0, 0), UDim2.new(0, 150, 0, 26))
		ocultarBtn.TextSize = 10
		ocultarBtn.BackgroundColor3 = wizardState.ocultarBloqueados
			and Color3.fromRGB(0, 120, 70) or Color3.fromRGB(60, 60, 80)
		ocultarBtn.Activated:Connect(function()
			wizardState.ocultarBloqueados = not wizardState.ocultarBloqueados
			wizardRender()
		end)

		local ordenados = sortEffects(cat.effects)
		local ultimoNivel = nil
		for _, e in ipairs(ordenados) do
			if e.grupo == wizardState.efeitoAba then
				local bloqueado = (e.nivel or 1) > wizardState.level
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
						bloqueado and ("🔒 Requer Nível " .. tostring(e.nivel or 1)) or tostring(e.desc or ""),
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
		-- PASSO 4: REVISÃO
		wizardStepLabel.Text = "Passo 4/4 — Revisão"
		wizardInfoLabel.Text = "Confira antes de criar."
		pesoAbasFrame.Visible = false
		efeitoAbasFrame.Visible = false

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
	wizardState.ocultarBloqueados = true
	-- Passa o proprio Id (se editando) pra excluir do calculo de P.N gasto,
	-- exatamente como o webapp faz com editingIdx.
	wizardState.catalog = GetHatsuCatalog:InvokeServer(wizardState.editId)
	wizardState.pnDisponivel = wizardState.catalog and wizardState.catalog.pnDisponivel or 0

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
		}
		local result
		if wizardState.editId then
			result = EditHatsu:InvokeServer(wizardState.editId, build)
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
