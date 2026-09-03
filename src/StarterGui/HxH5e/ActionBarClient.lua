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
local HotkeyButtonFX = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("HotkeyButtonFX"))
local AnimationDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("AnimationDB"))
local Theme = require(script.Parent:WaitForChild("FichaUITheme"))
local FichaUIData = require(script.Parent:WaitForChild("FichaUIData"))

-- ================= Animacoes do personagem (Ataque/Bloquear) =================
-- Primeiro pedaco de conexao real de animacao -- o Lucas foi
-- publicando os IDs aos poucos e preenchendo o AnimationDB. So toca
-- se o id nao estiver vazio (assim nao quebra enquanto faltam
-- animacoes ainda nao publicadas). Recarrega as tracks toda vez que
-- o personagem (re)nasce -- Animator/Humanoid sao recriados no
-- respawn, igual o cuidado que ja tomei no MouseLockCamera.
local animTracks = {} -- [chave do AnimationDB] = AnimationTrack carregada
local function carregarAnimacoes(character)
	animTracks = {}
	local ok1, humanoid = pcall(function()
		return character:WaitForChild("Humanoid", 5)
	end)
	if not ok1 or not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	for _, chave in ipairs({ "AtaqueCaC", "Bloquear" }) do
		local def = AnimationDB.FindByChave(chave)
		if def and def.id and def.id ~= "" then
			local anim = Instance.new("Animation")
			anim.AnimationId = def.id
			local ok, track = pcall(function()
				return animator:LoadAnimation(anim)
			end)
			if ok then
				animTracks[chave] = track
			else
				warn("[HxH5e] Falha ao carregar animacao '" .. chave .. "': " .. tostring(track))
			end
		end
	end
end

local function tocarAnimacao(chave)
	local track = animTracks[chave]
	if not track then return end
	-- Item 1 (Lucas): "quando clico repetidas vezes a animacao volta
	-- cedo demais pro inicio" -- Play() sempre reinicia do zero, mesmo
	-- se ja estiver tocando. Ignora cliques repetidos enquanto a
	-- animacao anterior ainda esta rodando, em vez de reiniciar.
	if track.IsPlaying then return end
	track:Play()
end

-- Item 2 (Lucas): bloqueio deveria ser so enquanto o botao esta
-- segurado, mas isso ainda nao existe -- por enquanto, toca e para
-- sozinha depois de um tempo curto (nao fica "grudada"). Duracao
-- escolhida pra bater com a janela de reacao ja usada no jogo
-- (TELEGRAPH_SECONDS = 1.8s no servidor).
local BLOQUEIO_DURACAO_AUTO = 1.5
local function tocarBloqueioComDuracaoLimitada()
	local track = animTracks["Bloquear"]
	if not track then return end
	track:Play()
	task.delay(BLOQUEIO_DURACAO_AUTO, function()
		if track.IsPlaying then
			track:Stop()
		end
	end)
end

player.CharacterAdded:Connect(carregarAnimacoes)
-- Roblox pode demorar pra criar o personagem apos o jogador entrar --
-- o resto do script (varios requires, GUIs, etc) roda ANTES disso
-- terminar, entao "if player.Character then" sozinho podia rodar
-- cedo demais e nunca carregar nada (bug real que encontrei
-- testando). task.spawn + WaitForChild espera sem travar o resto do
-- script.
task.spawn(function()
	local character = player.Character or player.CharacterAdded:Wait()
	carregarAnimacoes(character)
end)

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

-- ⚠️ Escondido de proposito: duplicava exatamente as barras de PV/Aura
-- que ja aparecem no HUD novo (FichaUIClient.lua). Pedido do Design
-- (brief FichaUI): "HUD aparecendo por tras da ficha, duplicado -- so
-- existe UM HUD". O resto deste script (acoes, buffs, hatsu menu)
-- continua ativo -- so as barras passivas de vitais somem.
barsFrame.Visible = false

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
	tocarBloqueioComDuracaoLimitada()
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
table.insert(hudElements, hatsuMenu)
-- ActionsFrame (barra de texto ATACAR[F]/BLOQUEAR[Q]/etc) removida
-- de proposito -- pedido do Lucas, substituida pelos botoes de icone
-- que ele esta montando na ScreenGui separada. Nao entra em
-- hudElements de proposito, pra nunca mais reaparecer nem com o
-- toggle geral do HUD.
actionsFrame.Visible = false


-- ================= Lógica =================

-- ================= Vitais novos do Lucas (PV/Sanidade/Reacoes/Armadura) =================
-- Icones proprios (PNG com linhas brancas), vivem na mesma ScreenGui
-- separada dos botoes de acao. A moldura (ImageColor3) e o
-- preenchimento (Frame por cima, na area da "trilha" vazia do
-- desenho) seguem a cor da categoria de Nen -- pedido do Lucas, pra
-- testar a sincronia com o tema.
--
-- ⚠️ Armadura: ainda sem regra definida (nao existe um recurso
-- "armadura atual/maxima" no sistema hoje) -- moldura ja tinge com o
-- tema, mas o preenchimento fica parado em 0% ate o Lucas confirmar
-- o que deve aparecer ali (CA? RDM? um recurso novo?).
local VitalFills = {}

task.spawn(function()
	local iconGui = player.PlayerGui:WaitForChild("ScreenGui", 10)
	if not iconGui then
		warn("[HxH5e] ScreenGui dos icones de vitais nao encontrada.")
		return
	end

	local okFicha, ficha = pcall(FichaUIData.carregar)
	if okFicha and ficha then
		Theme.setCategory(ficha.Categoria)
	end

	-- Posicao/tamanho da "trilha" dentro do desenho, estimados
	-- visualmente (icone ocupa a esquerda, trilha fica a direita,
	-- centralizada verticalmente) -- ajustavel no Explorer depois se
	-- nao bater 100% com o PNG.
	local function montarFill(nomeBotao)
		local btn = iconGui:FindFirstChild(nomeBotao)
		if not btn then
			warn("[HxH5e] Botao de vital nao encontrado: " .. nomeBotao)
			return nil
		end
		Theme.register(btn, "ImageColor3")

		local trilho = Instance.new("Frame")
		trilho.Name = "Trilho"
		-- Recalibrado com zoom em Play (antes tinha um "buraco" preto
		-- visivel entre a borda arredondada esquerda do desenho e o
		-- inicio real do preenchimento -- valores antigos 0.6/0.32
		-- eram so estimativa visual, nunca conferidos de perto).
		trilho.Size = UDim2.new(0.72, 0, 0.16, 0)
		trilho.Position = UDim2.new(0.245, 0, 0.42, 0)
		trilho.BackgroundTransparency = 1
		trilho.ClipsDescendants = true
		trilho.Parent = btn

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.BorderSizePixel = 0
		fill.Parent = trilho
		Theme.register(fill, "BackgroundColor3")

		return fill
	end

	VitalFills.PV = montarFill("PV_Bar")
	VitalFills.Aura = montarFill("Aura")
	VitalFills.Sanidade = montarFill("Sanidade_Bar")
	VitalFills.Reacoes = montarFill("Reacoes_Bar")
	montarFill("Armadura_Bar") -- so tinge a moldura por enquanto, sem preenchimento definido
end)

local function updateVitalFill(fill, atual, max)
	if not fill then return end
	local pct = (max and max > 0) and math.clamp(atual / max, 0, 1) or 0
	fill.Size = UDim2.new(pct, 0, 1, 0)
end

local function refreshBars()
	local character = GetCharacter:InvokeServer()
	if character and character.Vitals then
		local hp = character.Vitals.HP
		local aura = character.Vitals.Aura
		local sanidade = character.Vitals.Sanidade
		if hp and hp.Max and hp.Max > 0 then
			local pct = math.clamp(hp.Current / hp.Max, 0, 1)
			hpBar.Size = UDim2.new(pct, 0, 1, 0)
			hpLabel.Text = "PV: " .. tostring(math.floor(hp.Current)) .. "/" .. tostring(math.floor(hp.Max))
			updateVitalFill(VitalFills.PV, hp.Current, hp.Max)
		end
		if aura and aura.Max and aura.Max > 0 then
			local pct = math.clamp(aura.Current / aura.Max, 0, 1)
			auraBar.Size = UDim2.new(pct, 0, 1, 0)
			auraLabel.Text = "Aura: " .. tostring(math.floor(aura.Current)) .. "/" .. tostring(math.floor(aura.Max))
			updateVitalFill(VitalFills.Aura, aura.Current, aura.Max)
		end
		if sanidade and sanidade.Max and sanidade.Max > 0 then
			updateVitalFill(VitalFills.Sanidade, sanidade.Current, sanidade.Max)
		end
		local reacoesMax = character.Vitals.Reacoes or 0
		local reacoesAtual = reacoesMax - (character.ReacoesGastas or 0)
		updateVitalFill(VitalFills.Reacoes, reacoesAtual, reacoesMax)
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
	tocarAnimacao("AtaqueCaC")
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
-- Icones de Atacar/Bloquear/Esquivar sao preenchidos mais abaixo
-- (task.spawn que espera a ScreenGui do Lucas aparecer) -- declarados
-- aqui em cima pra as teclas de atalho tambem conseguirem piscar o
-- icone certo, nao so o clique do mouse.
local atacarIconRef, bloquearIconRef, esquivarIconRef, tenIconRef = nil, nil, nil, nil

local KEYBINDS = {
	[Enum.KeyCode.F] = function()
		if atacarIconRef then HotkeyButtonFX.Blink(atacarIconRef) end
		doAttack()
	end,
	[Enum.KeyCode.R] = function() usePrinciple("Ren") end,
	[Enum.KeyCode.T] = function()
		if tenIconRef then HotkeyButtonFX.Blink(tenIconRef) end
		usePrinciple("Ten")
	end,
	[Enum.KeyCode.G] = function() usePrinciple("Zetsu") end,
	[Enum.KeyCode.H] = toggleHatsuMenu,
	[Enum.KeyCode.Q] = function()
		if bloquearIconRef then HotkeyButtonFX.Blink(bloquearIconRef) end
		doBlock()
	end,
	[Enum.KeyCode.E] = function()
		if esquivarIconRef then HotkeyButtonFX.Blink(esquivarIconRef) end
		doDodge()
	end,
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

-- ================= Botoes de icone (ScreenGui separada, montada pelo Lucas) =================
-- Os 3 botoes (Ataque-C-a-C / Bloquear / Esquivar) vivem numa
-- ScreenGui a parte, editada visualmente no Explorer (posicao, icone,
-- tamanho). Aqui so conectamos cada um na MESMA funcao que ja
-- respondia ao botao de texto antigo e a tecla -- clicar no icone faz
-- exatamente a mesma coisa que apertar F/Q/E. Cada clique tambem
-- "pisca" o botao (HotkeyButtonFX.Blink) -- mesmo efeito que os
-- futuros botoes de TEN/REN/KEN/GYO etc vao usar (exceto EN e ZETSU
-- por enquanto, pedido do Lucas).
task.spawn(function()
	local iconGui = player.PlayerGui:WaitForChild("ScreenGui", 10)
	if not iconGui then
		warn("[HxH5e] ScreenGui dos botoes de icone nao encontrada -- hotkeys de icone nao conectadas.")
		return
	end
	local atacarIcon = iconGui:WaitForChild("Ataque-C-a-C", 5)
	local bloquearIcon = iconGui:WaitForChild("Bloquear", 5)
	local esquivarIcon = iconGui:WaitForChild("Esquivar", 5)
	-- Preenche as referencias compartilhadas com as teclas de atalho
	-- (ver KEYBINDS acima) -- assim Q/F/E tambem piscam o icone certo,
	-- nao so o clique do mouse.
	atacarIconRef = atacarIcon
	bloquearIconRef = bloquearIcon
	esquivarIconRef = esquivarIcon
	if atacarIcon then
		atacarIcon.Activated:Connect(function()
			HotkeyButtonFX.Blink(atacarIcon)
			doAttack()
		end)
	end
	if bloquearIcon then
		bloquearIcon.Activated:Connect(function()
			HotkeyButtonFX.Blink(bloquearIcon)
			doBlock()
		end)
	end
	if esquivarIcon then
		esquivarIcon.Activated:Connect(function()
			HotkeyButtonFX.Blink(esquivarIcon)
			doDodge()
		end)
	end

	-- ================= Botoes dos principios de Nen (Ten + avancados) =================
	-- Pedido do Lucas: os botoes so ficam "ativos" (cor normal, clique
	-- funciona de verdade) quando o personagem ja treinou/desbloqueou
	-- aquele principio na aba NEN -- bloqueados ficam esmaecidos e o
	-- clique so mostra a mensagem de erro que o servidor ja devolve
	-- ("Você ainda não treinou Ren." / "Você ainda não desbloqueou Ken.").
	-- EN e ZETSU ficam de fora por enquanto (combinado com o Lucas).
	local PRINCIPIOS = { "Ten", "Ren", "Gyo", "Shu", "Ken", "Ko", "Ryu", "Inp" }
	local principioIcones = {}
	for _, nome in ipairs(PRINCIPIOS) do
		local icon = iconGui:FindFirstChild(nome)
		principioIcones[nome] = icon
		if nome == "Ten" then
			tenIconRef = icon
		end
		-- Os 8 icones NAO ficam soltos na tela -- somem por padrao e so
		-- aparecem organizados em circulo quando o menu radial abre
		-- (ver mais abaixo). O clique neles, quando visiveis dentro do
		-- radial, atribui aquele principio ao slot que estiver sendo
		-- configurado no momento.
		if icon then
			icon.Visible = false
		end
	end

	-- ================= Menu radial de hotkeys (4 slots configuraveis) =================
	-- Clique ESQUERDO num slot preenchido: ativa o principio (igual
	-- clicar direto no icone). Clique num slot VAZIO, ou clique
	-- DIREITO em qualquer slot: abre o radial pra escolher/trocar o
	-- que fica ali. So principios ja desbloqueados sao clicaveis
	-- dentro do radial (os travados ficam esmaecidos e sem acao).
	local NUM_SLOTS = 4
	-- Espacamento aumentado (pedido do Lucas: "menu radial deixou um
	-- icone de fora" -- testando essa alternativa primeiro, antes de
	-- mexer em manter 1 icone sempre selecionado). Raio maior +
	-- centro mais proximo do meio vertical da tela, com mais folga
	-- de segurança pras bordas em telas menores.
	local RAIO_RADIAL = 165
	local CENTRO_X, CENTRO_Y = 0.5, 0.46

	local slotButtons = {}
	local slotLabels = {}
	local slotAtribuido = {} -- [slotIndex] = nome do principio ou false

	for i = 1, NUM_SLOTS do
		local slot = iconGui:FindFirstChild("Slot" .. i)
		slotButtons[i] = slot
		if slot then
			slotLabels[i] = slot:FindFirstChild("Sigla")
		end
	end

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "RadialBackdrop"
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.45
	backdrop.Visible = false
	backdrop.ZIndex = 100
	backdrop.Parent = iconGui

	local slotSendoEditado = nil
	local radialAbertoViaShift = false -- modo "ativar na hora" (sem slot)

	local function fecharRadial()
		backdrop.Visible = false
		for _, nome in ipairs(PRINCIPIOS) do
			local icon = principioIcones[nome]
			if icon then icon.Visible = false end
		end
		slotSendoEditado = nil
		radialAbertoViaShift = false
	end

	local function abrirRadial(slotIndex)
		slotSendoEditado = slotIndex
		backdrop.Visible = true
		local total = #PRINCIPIOS
		for i, nome in ipairs(PRINCIPIOS) do
			local icon = principioIcones[nome]
			if icon then
				local angulo = (i - 1) / total * math.pi * 2 - math.pi / 2
				local x = math.cos(angulo) * RAIO_RADIAL
				local y = math.sin(angulo) * RAIO_RADIAL
				icon.Position = UDim2.new(CENTRO_X, x - 33, CENTRO_Y, y - 33)
				icon.ZIndex = 101
				icon.Visible = true
			end
		end
	end

	backdrop.Activated:Connect(fecharRadial)

	-- Pedido do Lucas: quando um principio e atribuido a um slot, o
	-- SIMBOLO (icone) precisa continuar aparecendo -- antes so o texto
	-- (sigla) ficava visivel e o icone sumia. Agora copia a Image do
	-- icone de origem pro proprio slot, e esconde o texto; slot vazio
	-- volta a mostrar "+" sem imagem nenhuma.
	local function atualizarSlotVisual(slotIndex)
		local slot = slotButtons[slotIndex]
		local lbl = slotLabels[slotIndex]
		local nome = slotAtribuido[slotIndex]
		if nome then
			local icon = principioIcones[nome]
			if slot and icon then
				slot.Image = icon.Image
				slot.ImageColor3 = icon.ImageColor3
			end
			if lbl then lbl.Visible = false end
		else
			if slot then slot.Image = "" end
			if lbl then
				lbl.Visible = true
				lbl.Text = "+"
			end
		end
	end

	for i = 1, NUM_SLOTS do
		local slot = slotButtons[i]
		if slot then
			slot.Activated:Connect(function()
				local nome = slotAtribuido[i]
				if nome then
					HotkeyButtonFX.Blink(slot)
					usePrinciple(nome)
				else
					abrirRadial(i)
				end
			end)
			slot.MouseButton2Click:Connect(function()
				abrirRadial(i)
			end)
		end
	end

	-- Nome de exibicao pra cada principio -- "Inp" e so a chave interna,
	-- o nome de verdade do principio (In) e mais curto.
	local NOME_EXIBICAO = {
		Ten = "Ten", Ren = "Ren", Gyo = "Gyo", Shu = "Shu",
		Ken = "Ken", Ko = "Ko", Ryu = "Ryu", Inp = "In",
	}

	-- Titulo com o nome do principio, abaixo de cada icone do radial --
	-- pedido do Lucas pra ajudar quem ainda nao decorou qual icone e
	-- qual principio. Segunda passada de estilo (a primeira so tinha
	-- o texto cru): sombra de verdade (label duplicado, deslocado e
	-- semitransparente, atras do texto principal) + sublinhado via
	-- RichText (<u>). Criado como FILHO do icone, assim acompanha a
	-- posicao dele automaticamente sem precisar recalcular nada no
	-- abrirRadial.
	for _, nome in ipairs(PRINCIPIOS) do
		local icon = principioIcones[nome]
		if icon then
			local texto = NOME_EXIBICAO[nome] or nome

			-- Sombra: copia deslocada (2px direita/baixo), preta,
			-- semitransparente, por TRAS do texto principal (ZIndex
			-- menor). Mais suave/legivel que so o TextStroke sozinho
			-- em fundos muito escuros ou muito claros.
			local sombra = Instance.new("TextLabel")
			sombra.Name = "TituloSombra"
			sombra.Size = UDim2.new(3, 0, 0, 16)
			sombra.Position = UDim2.new(-1, 2, 1, 6)
			sombra.BackgroundTransparency = 1
			sombra.Font = Enum.Font.GothamBold
			sombra.TextSize = 13
			sombra.TextColor3 = Color3.new(0, 0, 0)
			sombra.TextTransparency = 0.35
			sombra.RichText = true
			sombra.Text = "<u>" .. texto .. "</u>"
			sombra.ZIndex = 100
			sombra.Parent = icon

			local titulo = Instance.new("TextLabel")
			titulo.Name = "Titulo"
			titulo.Size = UDim2.new(3, 0, 0, 16)
			titulo.Position = UDim2.new(-1, 0, 1, 4)
			titulo.BackgroundTransparency = 1
			titulo.Font = Enum.Font.GothamBold
			titulo.TextSize = 13
			titulo.TextColor3 = Color3.new(1, 1, 1)
			titulo.TextStrokeTransparency = 0.4
			titulo.TextStrokeColor3 = Color3.new(0, 0, 0)
			titulo.RichText = true
			titulo.Text = "<u>" .. texto .. "</u>"
			titulo.ZIndex = 101
			titulo.Parent = icon
		end
	end

	for _, nome in ipairs(PRINCIPIOS) do
		local icon = principioIcones[nome]
		if icon then
			icon.Activated:Connect(function()
				if slotSendoEditado then
					-- Radial aberto pra configurar um SLOT.
					-- Pedido do Lucas, testando: clicar num principio
					-- que JA ESTA atribuido a algum slot (qualquer um,
					-- incluindo o que esta sendo editado agora) REMOVE
					-- ele de la, em vez de atribuir ao slot atual --
					-- essa virou a forma de "tirar" um principio da
					-- hotbar (alem do botao direito, que so abre o
					-- radial pra trocar). So atribui normalmente ao
					-- slotSendoEditado se o principio clicado ainda
					-- NAO estiver em slot nenhum.
					local slotIndex = slotSendoEditado
					local jaAtribuidoEm = nil
					for outroIndex, outroNome in pairs(slotAtribuido) do
						if outroNome == nome then
							jaAtribuidoEm = outroIndex
							break
						end
					end
					if jaAtribuidoEm then
						local resultRemove = HxH5e.SetHotkeySlot:InvokeServer(jaAtribuidoEm, false)
						if resultRemove and resultRemove.success then
							slotAtribuido[jaAtribuidoEm] = nil
							atualizarSlotVisual(jaAtribuidoEm)
						end
					else
						local result = HxH5e.SetHotkeySlot:InvokeServer(slotIndex, nome)
						if result and result.success then
							slotAtribuido[slotIndex] = nome
							atualizarSlotVisual(slotIndex)
						end
					end
					fecharRadial()
				elseif radialAbertoViaShift then
					-- Radial aberto via SHIFT: ativa o principio na
					-- hora, sem mexer em nenhum slot salvo.
					HotkeyButtonFX.Blink(icon)
					usePrinciple(nome)
					fecharRadial()
				end
			end)
		end
	end

	-- ================= Atalho SHIFT: abre/fecha o radial pra ativar na hora =================
	-- Pedido do Lucas: segurando (na pratica, apertando -- alternando a
	-- cada toque) Shift, o radial aparece com os principios
	-- desbloqueados; apertar de novo fecha. Diferente de clicar num
	-- slot -- aqui nao atribui nada, so ativa o principio escolhido
	-- direto. ⚠️ Shift tambem e a tecla nativa do Shift Lock do
	-- Roblox (camera travada no mouse) -- o Lucas testou e nao notou
	-- efeito nenhum do Shift Lock no jogo atual, entao ficou combinado
	-- usar Shift mesmo pro radial sem se preocupar com conflito.
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			if radialAbertoViaShift or slotSendoEditado then
				fecharRadial()
			else
				radialAbertoViaShift = true
				abrirRadial(nil)
			end
		end
	end)

	-- Carrega os slots ja salvos do personagem
	do
		local ok, ficha = pcall(FichaUIData.carregar)
		if ok and ficha and ficha.HotkeySlots then
			for i = 1, NUM_SLOTS do
				local valor = ficha.HotkeySlots[i]
				slotAtribuido[i] = (valor and valor ~= false) and valor or nil
				atualizarSlotVisual(i)
			end
		end
	end

	-- Consulta a ficha (mesmo dado que a aba NEN usa) periodicamente e
	-- esmaece o icone de qualquer principio ainda nao disponivel.
	-- FUNDAMENTAIS (Ten/Ren): "disponivel" = ja treinado pelo menos
	-- nivel 1. AVANCADOS (Gyo/Shu/Ken/Ko/Ryu/Inp): "disponivel" =
	-- desbloqueado (bool).
	task.spawn(function()
		while true do
			local ok, ficha = pcall(FichaUIData.carregar)
			if ok and ficha and ficha.Nen then
				local desbloqueado = {}
				for _, f in ipairs(ficha.Nen.Fundamentais or {}) do
					desbloqueado[f.sigla] = (f.nivel or 0) >= 1
				end
				for _, a in ipairs(ficha.Nen.Avancados or {}) do
					desbloqueado[a.sigla] = a.desbloqueado == true
				end
				for nome, icon in pairs(principioIcones) do
					if icon then
						local siglaBusca = if nome == "Inp" then "IN" else string.upper(nome)
						local ok2 = desbloqueado[siglaBusca]
						icon.ImageTransparency = ok2 and 0 or 0.7
					end
				end
			end
			task.wait(2)
		end
	end)
end)
