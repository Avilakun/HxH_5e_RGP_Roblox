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

-- ================= Toast =================

local toastFrame = makeFrame(screenGui, "ToastFrame",
	UDim2.new(0, 280, 0, 90), UDim2.new(1, -300, 0, 12), Color3.fromRGB(10, 10, 10))
toastFrame.AnchorPoint = Vector2.new(1, 0)
toastFrame.BackgroundTransparency = 0.15
toastFrame.BorderSizePixel = 2
toastFrame.BorderColor3 = Color3.fromRGB(0, 255, 157)
toastFrame.ZIndex = 100
toastFrame.Visible = false

local toastLabel = makeLabel(toastFrame, "ToastText", "",
	UDim2.new(0, 10, 0, 8), UDim2.new(1, -20, 1, -16), 14)
toastLabel.TextWrapped = true
toastLabel.TextXAlignment = Enum.TextXAlignment.Left
toastLabel.TextYAlignment = Enum.TextYAlignment.Top
toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
toastLabel.ZIndex = 101

local toastClose = makeButton(toastFrame, "ToastClose", "X",
	UDim2.new(1, -28, 0, 4), UDim2.new(0, 24, 0, 24))
toastClose.TextSize = 12
toastClose.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
toastClose.ZIndex = 102

local toastTimer = nil
local function showToast(message, duration)
	toastLabel.Text = message or ""
	toastFrame.Visible = true
	if toastTimer then
		task.cancel(toastTimer)
	end
	toastTimer = task.delay(duration or 4, function()
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

-- ================= Janela da ficha (rolável) =================

local fichaFrame = makeFrame(screenGui, "FichaWindow",
	UDim2.fromOffset(400, 520), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
fichaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fichaFrame.Visible = false
addCloseButton(fichaFrame)

local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Name = "ContentScroll"
contentScroll.Size = UDim2.new(1, -20, 1, -150)
contentScroll.Position = UDim2.new(0, 10, 0, 44)
contentScroll.BackgroundTransparency = 1
contentScroll.ScrollBarThickness = 6
contentScroll.BorderSizePixel = 0
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentScroll.ElasticBehavior = Enum.ElasticBehavior.Never
contentScroll.Parent = fichaFrame

local content = makeFrame(contentScroll, "Content",
	UDim2.new(1, 0, 0, 660), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0))
content.BackgroundTransparency = 1

local titleLabel = makeLabel(content, "TitleLabel", "Nenhum personagem",
	UDim2.new(0, 0, 0, 8), UDim2.new(1, -20, 0, 30), 20)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextWrapped = true

local categoryLabel = makeLabel(content, "CategoryLabel", "Categoria: —",
	UDim2.new(0, 0, 0, 40), UDim2.new(1, 0, 0, 20), 14)
categoryLabel.TextColor3 = Color3.fromRGB(0, 255, 157)

local geniusLabel = makeLabel(content, "GeniusLabel", "Genialidade: —",
	UDim2.new(0, 0, 0, 60), UDim2.new(1, 0, 0, 18), 12)
geniusLabel.TextColor3 = Color3.fromRGB(190, 170, 255)

local xpLabel = makeLabel(content, "XpLabel", "XP: -",
	UDim2.new(0, 0, 0, 78), UDim2.new(1, 0, 0, 18), 12)
xpLabel.TextColor3 = Color3.fromRGB(255, 220, 120)

local attributeNames = { "FOR", "DES", "CON", "INT", "SAB", "PRE" }
local attributeLabels = {}
for i, attributeName in ipairs(attributeNames) do
	local label = makeLabel(content, "Attr_" .. attributeName,
		attributeName .. ": -",
		UDim2.new(0, 20, 0, 100 + (i - 1) * 24),
		UDim2.new(0, 150, 0, 22), 16)
	attributeLabels[attributeName] = label
end

local hpLabel = makeLabel(content, "HpLabel", "HP: -",
	UDim2.new(0, 190, 0, 100), UDim2.new(0, 150, 0, 22), 16)
local auraLabel = makeLabel(content, "AuraLabel", "Aura: -",
	UDim2.new(0, 190, 0, 124), UDim2.new(0, 150, 0, 22), 16)
local sanidadeLabel = makeLabel(content, "SanidadeLabel", "Sanidade: -",
	UDim2.new(0, 190, 0, 148), UDim2.new(0, 150, 0, 22), 16)

local dominioTitle = makeLabel(content, "DominioTitle", "DOMÍNIO DE NEN",
	UDim2.new(0, 20, 0, 250), UDim2.new(0, 200, 0, 18), 13)
dominioTitle.Font = Enum.Font.GothamBold
dominioTitle.TextColor3 = Color3.fromRGB(0, 255, 157)

local pnLabel = makeLabel(content, "PnLabel", "P.N: -",
	UDim2.new(0, 190, 0, 250), UDim2.new(0, 150, 0, 18), 12)
pnLabel.TextColor3 = Color3.fromRGB(255, 220, 120)

local FUND_NAMES = { "Ten", "Ren", "Zetsu" }
local dominioRows = {}
for i, name in ipairs(FUND_NAMES) do
	local rowY = 274 + (i - 1) * 30
	local levelLabel = makeLabel(content, "Dom_" .. name .. "_Lvl",
		name .. ": -",
		UDim2.new(0, 20, 0, rowY), UDim2.new(0, 80, 0, 24), 14)
	local trainButton = makeButton(content, "Dom_" .. name .. "_Train", "+1",
		UDim2.new(0, 110, 0, rowY), UDim2.new(0, 40, 0, 24))
	trainButton.TextSize = 12
	local activateButton = makeButton(content, "Dom_" .. name .. "_Act", "ATIVAR",
		UDim2.new(0, 155, 0, rowY), UDim2.new(0, 70, 0, 24))
	activateButton.TextSize = 11
	dominioRows[name] = { levelLabel = levelLabel, trainButton = trainButton, activateButton = activateButton }
end

local advTitle = makeLabel(content, "AdvTitle", "PRINCÍPIOS AVANÇADOS",
	UDim2.new(0, 20, 0, 372), UDim2.new(0, 200, 0, 16), 12)
advTitle.Font = Enum.Font.GothamBold
advTitle.TextColor3 = Color3.fromRGB(0, 200, 255)

local ADV_NAMES = { "En", "Inp", "Gyo", "Shu", "Ken", "Ko", "Ryu" }
local advRows = {}
for i, name in ipairs(ADV_NAMES) do
	local rowY = 394 + (i - 1) * 26
	local statusLabel = makeLabel(content, "Adv_" .. name .. "_Lvl",
		name .. ": —",
		UDim2.new(0, 20, 0, rowY), UDim2.new(0, 100, 0, 22), 13)
	local unlockButton = makeButton(content, "Adv_" .. name .. "_Unlock", "DESBLOQ",
		UDim2.new(0, 130, 0, rowY), UDim2.new(0, 90, 0, 22))
	unlockButton.TextSize = 10
	local activateButton = makeButton(content, "Adv_" .. name .. "_Act", "ATIVAR",
		UDim2.new(0, 225, 0, rowY), UDim2.new(0, 70, 0, 22))
	activateButton.TextSize = 10
	advRows[name] = { statusLabel = statusLabel, unlockButton = unlockButton, activateButton = activateButton }
end

local nenMessageLabel = makeLabel(content, "NenMessage", "",
	UDim2.new(0, 20, 0, 584), UDim2.new(0, 360, 0, 40), 11)
nenMessageLabel.TextWrapped = true
nenMessageLabel.TextXAlignment = Enum.TextXAlignment.Left
nenMessageLabel.TextYAlignment = Enum.TextYAlignment.Top
nenMessageLabel.TextColor3 = Color3.fromRGB(200, 200, 210)

-- ================= Botões fixos da ficha =================

local xpButton = makeButton(fichaFrame, "XpButton", "+50 XP",
	UDim2.new(0, 20, 1, -92), UDim2.new(0, 110, 0, 36))
xpButton.TextSize = 12

local hatsuButton = makeButton(fichaFrame, "HatsuButton", "HATSUS",
	UDim2.new(0, 140, 1, -92), UDim2.new(0, 90, 0, 36))
hatsuButton.TextSize = 13

local trocarButton = makeButton(fichaFrame, "TrocarButton", "TROCAR",
	UDim2.new(0, 240, 1, -92), UDim2.new(0, 140, 0, 36))
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


-- ================= Janela de Hatsu =================

local hatsuFrame = makeFrame(screenGui, "HatsuWindow",
	UDim2.fromOffset(440, 520), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(22, 24, 34))
hatsuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
hatsuFrame.Visible = false
addCloseButton(hatsuFrame)

makeLabel(hatsuFrame, "HatsuTitle", "HATSUS",
	UDim2.new(0, 16, 0, 10), UDim2.new(1, -40, 0, 26), 18)

local hatsuScroll = Instance.new("ScrollingFrame")
hatsuScroll.Name = "HatsuScroll"
hatsuScroll.Size = UDim2.new(1, -32, 1, -170)
hatsuScroll.Position = UDim2.new(0, 16, 0, 44)
hatsuScroll.BackgroundTransparency = 1
hatsuScroll.ScrollBarThickness = 6
hatsuScroll.BorderSizePixel = 0
hatsuScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
hatsuScroll.ElasticBehavior = Enum.ElasticBehavior.Never
hatsuScroll.Parent = hatsuFrame

local hatsuLayout = Instance.new("UIListLayout")
hatsuLayout.Padding = UDim.new(0, 6)
hatsuLayout.Parent = hatsuScroll

local hatsuEmptyLabel = makeLabel(hatsuScroll, "HatsuEmpty",
	"Nenhum Hatsu ainda.\nClique em CRIAR (WIZARD).",
	UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 60), 15)
hatsuEmptyLabel.TextWrapped = true

local hatsuNameBox = Instance.new("TextBox")
hatsuNameBox.Name = "HatsuNameBox"
hatsuNameBox.Size = UDim2.new(0, 200, 0, 34)
hatsuNameBox.Position = UDim2.new(0, 16, 1, -130)
hatsuNameBox.PlaceholderText = "Nome do Hatsu"
hatsuNameBox.Text = ""
hatsuNameBox.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
hatsuNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
hatsuNameBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
hatsuNameBox.Font = Enum.Font.Gotham
hatsuNameBox.TextSize = 14
hatsuNameBox.BorderSizePixel = 0
hatsuNameBox.Parent = hatsuFrame

local hatsuTypeBox = Instance.new("TextBox")
hatsuTypeBox.Name = "HatsuTypeBox"
hatsuTypeBox.Size = UDim2.new(0, 200, 0, 34)
hatsuTypeBox.Position = UDim2.new(0, 16, 1, -88)
hatsuTypeBox.PlaceholderText = "Tipo: Reforço"
hatsuTypeBox.Text = ""
hatsuTypeBox.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
hatsuTypeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
hatsuTypeBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
hatsuTypeBox.Font = Enum.Font.Gotham
hatsuTypeBox.TextSize = 14
hatsuTypeBox.BorderSizePixel = 0
hatsuTypeBox.Parent = hatsuFrame

local hatsuCreateButton = makeButton(hatsuFrame, "HatsuCreateButton", "CRIAR (WIZARD)",
	UDim2.new(0, 230, 1, -130), UDim2.new(0, 90, 0, 76))
hatsuCreateButton.TextSize = 11

local hatsuCloseButton = makeButton(hatsuFrame, "HatsuCloseButton", "FECHAR",
	UDim2.new(0, 330, 1, -46), UDim2.new(0, 90, 0, 34))
hatsuCloseButton.TextSize = 12

local hatsuMessageLabel = makeLabel(hatsuFrame, "HatsuMessage", "",
	UDim2.new(0, 16, 1, -46), UDim2.new(0, 300, 0, 40), 11)
hatsuMessageLabel.TextWrapped = true
hatsuMessageLabel.TextColor3 = Color3.fromRGB(200, 200, 210)

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

	titleLabel.Text = character.Name .. "  •  Nível " .. tostring(character.Level)

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
				openWindow(fichaFrame)
			end
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
	local result = CreateCharacter:InvokeServer(name)
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
		resultInfoLabel.Text = "Sua categoria de Nen define seus Hatsus.\nSua genialidade (2d20) afeta seu avanço.\nNo Domínio de Nen você treina os princípios."

		closeWindow(createFrame)
		closeWindow(listFrame)
		openWindow(resultFrame)
	else
		createErrorLabel.Text = (result and result.error) or "Erro ao criar personagem."
	end
end

-- ================= Eventos =================

openButton.Activated:Connect(function()
	if fichaFrame.Visible then
		closeWindow(fichaFrame)
		return
	end
	refreshFicha()
	openWindow(fichaFrame)
end)

criarButton.Activated:Connect(function()
	openCreateWindow()
end)

trocarButton.Activated:Connect(function()
	refreshList()
	openWindow(listFrame)
end)

hatsuButton.Activated:Connect(function()
	refreshHatsus()
	openWindow(hatsuFrame)
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

hatsuCloseButton.Activated:Connect(function()
	closeWindow(hatsuFrame)
end)

confirmButton.Activated:Connect(onCreateConfirm)

cancelButton.Activated:Connect(function()
	closeWindow(createFrame)
end)

resultContinueButton.Activated:Connect(function()
	closeWindow(resultFrame)
	refreshFicha()
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
addDragBar(resultFrame)
addDragBar(hatsuFrame)


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
	{ label = "Leves", key = "Leve" },
	{ label = "Moderadas", key = "Media" },
	{ label = "Pesadas", key = "Pesada" },
	{ label = "Variáveis", key = "Variavel" },
	{ label = "Extremas", key = "Extrema" },
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
	wizardState.pnDisponivel = (character and character.PN) or 0
	wizardState.level = (character and character.Level) or 1
	wizardState.step = 1
	wizardState.nome = ""
	wizardState.efeitos = {}
	wizardState.restricoes = {}
	wizardState.efeitoAba = "Gerais"
	wizardState.pesoAba = "Todas"
	wizardState.editId = nil
	wizardState.natureza = "Ataque"
	wizardState.ocultarBloqueados = true
	wizardState.catalog = GetHatsuCatalog:InvokeServer("Reforço")

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

