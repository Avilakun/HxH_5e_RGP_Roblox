--[[
    HxH5e ActionBarClient (COMPLETO — Parte 1 de 3)
    Substitua o arquivo inteiro por esta Parte 1.
    Depois cole a Parte 2 logo abaixo e depois a Parte 3.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local HxH5e = ReplicatedStorage:WaitForChild("HxH5e")
local GetCharacter = HxH5e:WaitForChild("GetCharacter")
local GetHatsus = HxH5e:WaitForChild("GetHatsus")
local ActivateHatsu = HxH5e:WaitForChild("ActivateHatsu")
local ActivatePrinciple = HxH5e:WaitForChild("ActivatePrinciple")
local BasicAttack = HxH5e:WaitForChild("BasicAttack")
local BuffTick = HxH5e:WaitForChild("BuffTick")
local AchievementUnlocked = HxH5e:WaitForChild("AchievementUnlocked")
local AttemptReaction = HxH5e:WaitForChild("AttemptReaction")
local EnemyTelegraph = HxH5e:WaitForChild("EnemyTelegraph")
local EnemyAttackResult = HxH5e:WaitForChild("EnemyAttackResult")

local playerGui = player:WaitForChild("PlayerGui")
local guiAntigo = playerGui:FindFirstChild("HxH5eActionBar")
if guiAntigo then
	guiAntigo:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HxH5eActionBar"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- ================= Helpers =================

local function makeButton(parent, name, text, position, size, textSize)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.Gotham
	button.TextSize = textSize or 15
	button.BorderSizePixel = 0
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
	label.TextSize = textSize or 14
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

-- ================= Switch do HUD =================

local hudToggle = makeButton(screenGui, "HudToggle", "HUD: ON",
	UDim2.new(0, 12, 1, -40), UDim2.new(0, 84, 0, 30), 12)
hudToggle.BackgroundColor3 = Color3.fromRGB(0, 120, 70)

local hudVisible = true
local hudElements = {}

local function setHudVisible(visible)
	hudVisible = visible
	for _, el in ipairs(hudElements) do
		el.Visible = visible
	end
	hudToggle.Text = visible and "HUD: ON" or "HUD: OFF"
	hudToggle.BackgroundColor3 = visible
		and Color3.fromRGB(0, 120, 70)
		or Color3.fromRGB(90, 60, 60)
	local fichaGui = playerGui:FindFirstChild("HxH5eGui")
	if fichaGui then
		local btn = fichaGui:FindFirstChild("AbrirFichaButton")
		if btn then
			btn.Visible = visible
		end
	end
	pcall(function()
		game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, visible)
	end)
end

hudToggle.Activated:Connect(function()
	setHudVisible(not hudVisible)
end)

-- ================= Barras de PV e Aura =================

local barsFrame = makeFrame(screenGui, "BarsFrame",
	UDim2.new(0, 220, 0, 60), UDim2.new(0, 12, 0, 12), Color3.fromRGB(22, 24, 34))
barsFrame.BackgroundTransparency = 0.15

local hpBarBg = makeFrame(barsFrame, "HpBarBg",
	UDim2.new(1, -24, 0, 14), UDim2.new(0, 12, 0, 8), Color3.fromRGB(60, 20, 20))
local hpBar = makeFrame(hpBarBg, "HpBar",
	UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(200, 60, 60))
local hpLabel = makeLabel(barsFrame, "HpLabel", "PV: -",
	UDim2.new(0, 12, 0, 24), UDim2.new(1, -24, 0, 14), 12)

local auraBarBg = makeFrame(barsFrame, "AuraBarBg",
	UDim2.new(1, -24, 0, 14), UDim2.new(0, 12, 0, 38), Color3.fromRGB(20, 40, 80))
local auraBar = makeFrame(auraBarBg, "AuraBar",
	UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(80, 140, 255))
local auraLabel = makeLabel(barsFrame, "AuraLabel", "Aura: -",
	UDim2.new(0, 12, 0, 42), UDim2.new(1, -24, 0, 14), 12)

-- ================= Chips de buff =================

local buffsFrame = makeFrame(screenGui, "BuffsFrame",
	UDim2.new(0, 220, 0, 120), UDim2.new(0, 12, 0, 80), Color3.fromRGB(0, 0, 0))
buffsFrame.BackgroundTransparency = 1
local buffsLayout = Instance.new("UIListLayout")
buffsLayout.Padding = UDim.new(0, 2)
buffsLayout.Parent = buffsFrame

-- ================= LOG de combate =================

local logFrame = makeFrame(screenGui, "LogFrame",
	UDim2.new(0, 300, 0, 200), UDim2.new(1, -312, 0, 12), Color3.fromRGB(10, 10, 10))
logFrame.BackgroundTransparency = 0.55
logFrame.BorderSizePixel = 1
logFrame.BorderColor3 = Color3.fromRGB(60, 60, 70)
logFrame.Visible = false
makeLabel(logFrame, "LogTitle", "LOG DE COMBATE",
	UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 18), 11)

local logList = Instance.new("ScrollingFrame")
logList.Name = "LogList"
logList.Size = UDim2.new(1, -16, 1, -28)
logList.Position = UDim2.new(0, 8, 0, 22)
logList.BackgroundTransparency = 1
logList.ScrollBarThickness = 4
logList.BorderSizePixel = 0
logList.AutomaticCanvasSize = Enum.AutomaticSize.Y
logList.ElasticBehavior = Enum.ElasticBehavior.Never
logList.Parent = logFrame

local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 2)
logLayout.Parent = logList

local LOG_HIDE_DELAY = 5
local logHideTimer = nil

local function logMsg(text)
	if not text or #text == 0 then
		return
	end
	local entry = makeLabel(logList, "LogEntry", tostring(text),
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), 11)
	entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.TextWrapped = false
	entry.LayoutOrder = -math.floor(os.clock() * 1000)
	local children = {}
	for _, child in ipairs(logList:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(children, child)
		end
	end
	if #children > 8 then
		for i = 1, #children - 8 do
			children[i]:Destroy()
		end
	end

	-- So aparece quando ha atividade, some sozinho depois de 5s sem novas
	-- entradas (o historico continua ali dentro, igual ao toast do FichaClient).
	if hudVisible then
		logFrame.Visible = true
	end
	if logHideTimer then
		task.cancel(logHideTimer)
	end
	logHideTimer = task.delay(LOG_HIDE_DELAY, function()
		logFrame.Visible = false
	end)
end

-- ================= Mensagem =================

local msgLabel = makeLabel(screenGui, "MsgLabel", "",
	UDim2.new(0.5, -220, 1, -146), UDim2.new(0, 440, 0, 44), 12)
msgLabel.TextWrapped = true
msgLabel.TextXAlignment = Enum.TextXAlignment.Center

local msgTimer = nil
local function showMsg(text)
	msgLabel.Text = text or ""
	if msgTimer then
		task.cancel(msgTimer)
	end
	msgTimer = task.delay(6, function()
		msgLabel.Text = ""
	end)
end

-- ================= Barra de ações =================

-- Largura recalculada pra caber os 7 botoes sem sobrepor (o Lucas
-- reportou que Esquivar ficava escondido -- o frame antigo tinha so
-- 460px fixos, mas os botoes juntos precisam de ~700px). Cada botao
-- agora mostra a tecla de atalho no proprio texto, pra resolver
-- "nao sei qual tecla ativa" tambem.
local ACTION_BAR_WIDTH = 706
local actionsFrame = makeFrame(screenGui, "ActionsFrame",
	UDim2.new(0, ACTION_BAR_WIDTH, 0, 64), UDim2.new(0.5, -ACTION_BAR_WIDTH / 2, 1, -84), Color3.fromRGB(0, 0, 0))
actionsFrame.BackgroundTransparency = 0.6

local atacarBtn = makeButton(actionsFrame, "Atacar", "ATACAR [F]",
	UDim2.new(0, 10, 0, 10), UDim2.new(0, 96, 0, 44), 12)
local renBtn = makeButton(actionsFrame, "Ren", "REN [R]",
	UDim2.new(0, 114, 0, 10), UDim2.new(0, 74, 0, 44), 12)
local tenBtn = makeButton(actionsFrame, "Ten", "TEN [T]",
	UDim2.new(0, 196, 0, 10), UDim2.new(0, 74, 0, 44), 12)
local zetsuBtn = makeButton(actionsFrame, "Zetsu", "ZETSU [G]",
	UDim2.new(0, 278, 0, 10), UDim2.new(0, 82, 0, 44), 12)
local hatsuBtn = makeButton(actionsFrame, "Hatsu", "HATSU [H]",
	UDim2.new(0, 368, 0, 10), UDim2.new(0, 88, 0, 44), 12)
local blockBtn = makeButton(actionsFrame, "Block", "🛡 BLOQUEAR [Q]",
	UDim2.new(0, 464, 0, 10), UDim2.new(0, 116, 0, 44), 12)
blockBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 75)
local dodgeBtn = makeButton(actionsFrame, "Dodge", "💨 ESQUIVAR [E]",
	UDim2.new(0, 588, 0, 10), UDim2.new(0, 110, 0, 44), 12)
dodgeBtn.BackgroundColor3 = Color3.fromRGB(50, 65, 55)

-- ================= Aviso de telegraph (reacao) =================
local reactionWarning = makeFrame(screenGui, "ReactionWarning",
	UDim2.new(0, 320, 0, 50), UDim2.new(0.5, -160, 0, 60), Color3.fromRGB(40, 15, 15))
reactionWarning.Visible = false
local reactionWarningLabel = makeLabel(reactionWarning, "Label", "⚠ ATAQUE INIMIGO! Reaja agora!",
	UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), 14)
reactionWarningLabel.TextColor3 = Color3.fromRGB(255, 200, 200)

local function doBlock()
	local result = AttemptReaction:InvokeServer("block")
	showMsg(tostring(result.message or result.error))
end
blockBtn.Activated:Connect(doBlock)

local function doDodge()
	local result = AttemptReaction:InvokeServer("dodge")
	showMsg(tostring(result.message or result.error))
end
dodgeBtn.Activated:Connect(doDodge)

EnemyTelegraph.OnClientEvent:Connect(function(duration)
	reactionWarning.Visible = true
	task.delay(duration or 1.8, function()
		reactionWarning.Visible = false
	end)
end)

EnemyAttackResult.OnClientEvent:Connect(function(data)
	reactionWarning.Visible = false
	showMsg(tostring(data.message))
end)

-- ================= Menu de Hatsus =================

local hatsuMenu = makeFrame(screenGui, "HatsuMenu",
	UDim2.new(0, 200, 0, 200), UDim2.new(0.5, -100, 1, -156), Color3.fromRGB(30, 32, 44))
hatsuMenu.Visible = false

-- ================= Registra elementos do HUD no switch =================

table.insert(hudElements, barsFrame)
table.insert(hudElements, buffsFrame)
table.insert(hudElements, logFrame)
table.insert(hudElements, actionsFrame)
table.insert(hudElements, hatsuMenu)


-- ================= Lógica =================

local function refreshBars()
	local character = GetCharacter:InvokeServer()
	if character and character.Vitals then
		local hp = character.Vitals.HP
		local aura = character.Vitals.Aura
		if hp and hp.Max and hp.Max > 0 then
			local pct = math.clamp(hp.Current / hp.Max, 0, 1)
			hpBar.Size = UDim2.new(pct, 0, 1, 0)
			hpLabel.Text = "PV: " .. tostring(math.floor(hp.Current)) .. "/" .. tostring(math.floor(hp.Max))
		end
		if aura and aura.Max and aura.Max > 0 then
			local pct = math.clamp(aura.Current / aura.Max, 0, 1)
			auraBar.Size = UDim2.new(pct, 0, 1, 0)
			auraLabel.Text = "Aura: " .. tostring(math.floor(aura.Current)) .. "/" .. tostring(math.floor(aura.Max))
		end
	else
		hpLabel.Text = "PV: -"
		auraLabel.Text = "Aura: -"
	end
end

task.spawn(function()
	while true do
		task.wait(1)
		refreshBars()
	end
end)

BuffTick.OnClientEvent:Connect(function(lista)
	for _, child in ipairs(buffsFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, buff in ipairs(lista or {}) do
		local nome = tostring(buff and buff.name or "?")
		local restante = tonumber(buff and buff.remaining) or 0
		local chip = makeFrame(buffsFrame, "Buff_" .. nome,
			UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), Color3.fromRGB(38, 42, 58))
		local lbl = makeLabel(chip, "Lbl",
			nome .. "  " .. string.format("%.1fs", restante),
			UDim2.new(0, 6, 0, 0), UDim2.new(1, -12, 1, 0), 11)
		lbl.TextXAlignment = Enum.TextXAlignment.Left
	end
end)

-- ================= Ações =================

-- Extraida pra funcao nomeada pra poder ser chamada tanto pelo
-- clique quanto pela tecla de atalho [F].
local function doAttack()
	local result = BasicAttack:InvokeServer()
	if result then
		if result.success then
			local linhas = {
				"Dano: " .. tostring(result.dano) .. " (" .. tostring(result.hpRestante) .. "/" .. tostring(result.hpMax) .. ")"
			}
			if result.partes then
				table.insert(linhas, "Partes: " .. tostring(result.partes))
			end
			if result.killed then
				if result.xpMsg then
					table.insert(linhas, tostring(result.xpMsg))
				else
					table.insert(linhas, "Boneco destruido! +10 XP")
				end
			end
			if result.revida then
				table.insert(linhas, "Revide: " .. tostring(result.revida) .. " de dano em voce!")
			end
			if result.playerMorto then
				table.insert(linhas, "Voce desmaiou! Recupera em 5s.")
			end
			showMsg(table.concat(linhas, "\n"))
			logMsg("Dano " .. tostring(result.dano) .. (result.partes and (" [" .. tostring(result.partes) .. "]") or ""))
			if result.revida then
				logMsg("Revide " .. tostring(result.revida) .. " -> PV " .. tostring(result.playerHP or "?") .. "/" .. tostring(result.playerMaxHP or "?"))
			end
		else
			showMsg(tostring(result.error or ""))
		end
	end
	refreshBars()
end
atacarBtn.Activated:Connect(doAttack)

local function usePrinciple(nome)
	local result = ActivatePrinciple:InvokeServer(nome)
	if result then
		showMsg(tostring(result.message or result.error or ""))
		if result.success and result.message then
			logMsg(tostring(result.message))
		end
	end
	refreshBars()
end

renBtn.Activated:Connect(function()
	usePrinciple("Ren")
end)

tenBtn.Activated:Connect(function()
	usePrinciple("Ten")
end)

zetsuBtn.Activated:Connect(function()
	usePrinciple("Zetsu")
end)


-- ================= HATSU (menu + ativação) =================

local function toggleHatsuMenu()
	if hatsuMenu.Visible then
		hatsuMenu.Visible = false
		return
	end
	for _, child in ipairs(hatsuMenu:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local hatsus = GetHatsus:InvokeServer() or {}
	local y = 4
	if #hatsus == 0 then
		local empty = makeLabel(hatsuMenu, "Empty", "Sem Hatsus.\nCrie um na ficha.",
			UDim2.new(0, 4, 0, 4), UDim2.new(1, -8, 0, 30), 11)
		empty.TextWrapped = true
	end
	for _, hatsu in ipairs(hatsus) do
		local nomeH = tostring(hatsu.Nome or "?")
		local tipoH = tostring(hatsu.Tipo or "?")
		local btn = makeButton(hatsuMenu, "H_" .. tostring(hatsu.Id or "?"),
			nomeH .. " (" .. tipoH .. ")",
			UDim2.new(0, 4, 0, y), UDim2.new(1, -8, 0, 28), 11)
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Activated:Connect(function()
			hatsuMenu.Visible = false
			hatsuBtn.Text = nomeH
			local result = ActivateHatsu:InvokeServer(hatsu.Id)
			if result then
				local r = result.resultado
				if r and r.rolagem then
					showMsg(tostring(r.nome or "Hatsu") .. "\n" .. tostring(r.rolagem))
					local logLine = tostring(r.nome or "Hatsu") .. " — Dano: " .. tostring(r.dano or 0)
					if r.cura and r.cura > 0 then
						logLine = logLine .. " | Cura: +" .. tostring(r.cura)
					end
					if r.rd and r.rd > 0 then
						logLine = logLine .. " | RD: " .. tostring(r.rd)
					end
					logMsg(logLine)
				elseif r and r.mensagem then
					showMsg(tostring(r.mensagem))
				else
					showMsg(tostring(result.error or ""))
				end
			end
			refreshBars()
		end)
		y = y + 32
	end
	hatsuMenu.Visible = true
end
hatsuBtn.Activated:Connect(toggleHatsuMenu)

refreshBars()

-- ================= Badge de Conquista Desbloqueada =================
-- Aparece no topo-centro da tela por alguns segundos. Fila simples:
-- se varias conquistas chegarem juntas, mostra uma de cada vez.

local achievementBadge = makeFrame(screenGui, "AchievementBadge",
	UDim2.new(0, 360, 0, 74), UDim2.new(0.5, 0, 0, -100), Color3.fromRGB(30, 24, 10))
achievementBadge.AnchorPoint = Vector2.new(0.5, 0)
achievementBadge.BorderSizePixel = 2
achievementBadge.BorderColor3 = Color3.fromRGB(255, 200, 0)
achievementBadge.Visible = false
achievementBadge.ZIndex = 50

local achievementHeader = makeLabel(achievementBadge, "Header", "🏆 CONQUISTA DESBLOQUEADA",
	UDim2.new(0, 12, 0, 6), UDim2.new(1, -24, 0, 18), 11)
achievementHeader.Font = Enum.Font.GothamBold
achievementHeader.TextColor3 = Color3.fromRGB(255, 200, 0)
achievementHeader.ZIndex = 51

local achievementName = makeLabel(achievementBadge, "Name", "",
	UDim2.new(0, 12, 0, 24), UDim2.new(1, -24, 0, 22), 16)
achievementName.Font = Enum.Font.GothamBold
achievementName.ZIndex = 51

local achievementDesc = makeLabel(achievementBadge, "Desc", "",
	UDim2.new(0, 12, 0, 48), UDim2.new(1, -24, 0, 22), 11)
achievementDesc.TextColor3 = Color3.fromRGB(200, 200, 210)
achievementDesc.TextWrapped = true
achievementDesc.ZIndex = 51

local achievementQueue = {}
local achievementShowing = false

local function processAchievementQueue()
	if achievementShowing or #achievementQueue == 0 then
		return
	end
	achievementShowing = true
	local ach = table.remove(achievementQueue, 1)
	achievementName.Text = tostring(ach.nome or "?")
	achievementDesc.Text = tostring(ach.descricao or "")
	achievementBadge.Position = UDim2.new(0.5, 0, 0, -100)
	achievementBadge.Visible = true

	local tweenIn = game:GetService("TweenService"):Create(
		achievementBadge, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 16) })
	tweenIn:Play()

	task.delay(4, function()
		local tweenOut = game:GetService("TweenService"):Create(
			achievementBadge, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -100) })
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			achievementBadge.Visible = false
			achievementShowing = false
			processAchievementQueue()
		end)
	end)
end

AchievementUnlocked.OnClientEvent:Connect(function(achievement)
	if not achievement then return end
	table.insert(achievementQueue, achievement)
	processAchievementQueue()
end)


-- ================= Teclas de atalho =================
-- Pedido do Lucas: sem tecla, era preciso clicar (lento demais pra
-- combate reativo com janela curta de reacao). F/R/T/G/H para as
-- acoes normais, Q/E pras reacoes (Bloquear/Esquivar) -- perto do
-- WASD de proposito, pra dar pra reagir rapido sem tirar a mao do
-- movimento.
local UserInputService = game:GetService("UserInputService")
local KEYBINDS = {
	[Enum.KeyCode.F] = doAttack,
	[Enum.KeyCode.R] = function() usePrinciple("Ren") end,
	[Enum.KeyCode.T] = function() usePrinciple("Ten") end,
	[Enum.KeyCode.G] = function() usePrinciple("Zetsu") end,
	[Enum.KeyCode.H] = toggleHatsuMenu,
	[Enum.KeyCode.Q] = doBlock,
	[Enum.KeyCode.E] = doDodge,
}

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return -- jogador esta digitando em algum TextBox, ignora
	end
	local handler = KEYBINDS[input.KeyCode]
	if handler then
		handler()
	end
end)
