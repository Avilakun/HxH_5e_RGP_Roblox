--[[
    HxH5e CombatService (M2.0) — combate reativo com boneco de treino
    que se MOVE, persegue o jogador e ataca com telegraph (aviso
    visual antes do golpe, pra dar tempo real de reagir).

    Reacoes implementadas (extraidas do livro principal, Cap. 4
    Combate -- ver secao "Reacoes"):
    - ESQUIVA: 1d20 + DES vs ataque total inimigo. Sucesso evita tudo.
      Falha (inclusive empate) = dano inteiro + a propria DES somada
      ao dano (alto risco/alta recompensa, conforme o livro).
    - BLOQUEIO DESARMADO: 1d20 + CON + FOR vs ataque total inimigo.
      Sucesso evita tudo. Falha = dano inteiro + rola 1d6 que reduz a
      CA ate o fim do proximo turno.
    - SEM REACAO (nao apertou nada a tempo): toma o dano cheio, sem
      penalidade extra (diferente de uma esquiva/bloqueio FALHOS).

    Recurso "Reacoes" (Vitals.Reacoes = 7+SAB, ja existia): cada uso
    de Bloqueio ou Esquiva gasta 1 ponto (character.ReacoesGastas).
    Sem saldo, a reacao nao pode ser tentada. Recupera com Zetsu ou
    descanso (⚠️ "descanso" ainda nao existe como sistema -- so o
    reset via Zetsu esta conectado por enquanto).

    ⚠️ NUMEROS PROVISORIOS pro playtest (nao especificados, documentado
    pra ajustar depois): bonus de ataque do boneco (+3), janela de
    telegraph (1.8s), alcance de deteccao (40 studs), alcance de
    ataque (7 studs), WalkSpeed do boneco (12).
]]

local CombatService = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local HxH5e = ReplicatedStorage:WaitForChild("HxH5e")

local BuffManager = require(script.Parent:WaitForChild("BuffManager"))
local NenService = require(script.Parent:WaitForChild("NenService"))
local AchievementService = require(script.Parent:WaitForChild("AchievementService"))
local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))
local DiceUtils = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("DiceUtils"))

local CharacterService = nil
local dummyFolder = nil
local dummies = {} -- [modelo] = { hp, maxHp, respawning, humanoid, root, attacking, targetPlayer, reactionWindow }

local DUMMY_MAX_HP = 20
-- Aura do boneco: adicionada so pra permitir testar o Sugar Aura dos
-- Vampiros (o boneco antes so tinha HP). Placeholder de teste ate
-- existir PvP ou NPCs com Aura de verdade -- valor arbitrario.
local DUMMY_MAX_AURA = 50
local DUMMY_CON_MOD = 1 -- usado no TR de resistencia ao dreno
local DUMMY_CA = 12 -- CA do boneco de treino, provisorio (10 + mod CON generico)
local DUMMY_POS = Vector3.new(0, 3, 30)
local DUMMY_ATTACK_BONUS = 3
local TELEGRAPH_SECONDS = 1.8
local DETECTION_RANGE = 40
local ATTACK_RANGE = 7
local DUMMY_WALKSPEED = 12

local EnemyTelegraph = nil
local EnemyAttackResult = nil

local function rollDice(count, sides)
	local total = 0
	for _ = 1, count do
		total = total + math.random(1, sides)
	end
	return total
end

local function attrMod(character, key)
	local attrs = character.Attributes or {}
	local val = attrs[key] and attrs[key].value or 10
	return math.floor((val - 10) / 2)
end

-- ================= Recurso de Reacoes (gasto por uso) =================
local function hasReactionAvailable(character)
	local max = (character.Vitals and character.Vitals.Reacoes) or 0
	local gastas = character.ReacoesGastas or 0
	return gastas < max
end

local function spendReaction(character)
	character.ReacoesGastas = (character.ReacoesGastas or 0) + 1
end

-- ================= Resolucao das reacoes (funcoes puras, testaveis) =================
-- attackTotal = resultado ja rolado do ataque inimigo (d20+bonus).
function CombatService.ResolveDodge(character, attackTotal)
	local desMod = attrMod(character, "DES")
	local desValue = (character.Attributes and character.Attributes.DES and character.Attributes.DES.value) or 10
	-- Esquiva e um Teste de Resistencia -- Exaustao Nivel 1+ da
	-- desvantagem nele.
	local modsEx = CharacterService.GetConditionModifiers(character)
	local roll = DiceUtils.RollD20(modsEx.desvantagemHabilidade and "DESVANTAGEM" or "NORMAL").total
	local total = roll + desMod
	if total > attackTotal then
		return { success = true, avoided = true, roll = roll, total = total, dano = 0 }
	end
	-- Falha (inclusive empate): dano inteiro + o valor de DES somado.
	return { success = true, avoided = false, roll = roll, total = total, danoExtra = desValue }
end

function CombatService.ResolveBlock(character, attackTotal)
	local conMod = attrMod(character, "CON")
	local forMod = attrMod(character, "FOR")
	-- Bloqueio e um Teste de Resistencia tambem -- mesma regra.
	local modsEx = CharacterService.GetConditionModifiers(character)
	local roll = DiceUtils.RollD20(modsEx.desvantagemHabilidade and "DESVANTAGEM" or "NORMAL").total
	local total = roll + conMod + forMod
	if total > attackTotal then
		return { success = true, avoided = true, roll = roll, total = total }
	end
	-- Falha (inclusive empate): dano inteiro + 1d6 de reducao de CA
	-- ate o fim do proximo turno.
	local caPenalidade = rollDice(1, 6)
	return { success = true, avoided = false, roll = roll, total = total, caPenalidade = caPenalidade }
end

-- ================= Boneco de treino (Humanoid de verdade, se move) =================
local function updateLabel(dummy)
	local data = dummies[dummy]
	local cabeca = dummy:FindFirstChild("Head")
	local gui = cabeca and cabeca:FindFirstChild("HealthGui")
	if not gui then return end
	local bar = gui:FindFirstChild("Bg") and gui.Bg:FindFirstChild("Bar")
	local label = gui:FindFirstChild("Label")
	local pct = data and (data.hp / data.maxHp) or 0
	if bar then
		bar.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 0, 10)
		bar.BackgroundColor3 = pct > 0.5 and Color3.fromRGB(0, 200, 80) or (pct > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 60, 60))
	end
	if label then
		local hp = data and math.floor(math.max(0, data.hp)) or 0
		label.Text = "Boneco de Treino\nHP " .. hp .. "/" .. (data and data.maxHp or 0)
	end
end

-- Aviso visual (telegraph) acima da cabeca do boneco: barra regressiva
-- + texto, pra dar tempo real do jogador reagir (pedido do Lucas: sem
-- isso nao da pra saber QUANDO reagir).
local function showTelegraph(dummy, duration)
	local cabeca = dummy:FindFirstChild("Head")
	if not cabeca then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "TelegraphGui"
	gui.Size = UDim2.new(0, 160, 0, 30)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 1, 0)
	bar.BackgroundColor3 = Color3.fromRGB(255, 60, 40)
	bar.BorderSizePixel = 0
	bar.Parent = bg
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "⚠ ATACANDO!"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.Font = Enum.Font.GothamBold
	label.Parent = bg
	gui.Parent = cabeca

	local start = os.clock()
	local conn
	conn = game:GetService("RunService").Heartbeat:Connect(function()
		local elapsed = os.clock() - start
		local pct = math.clamp(1 - (elapsed / duration), 0, 1)
		bar.Size = UDim2.new(pct, 0, 1, 0)
		if elapsed >= duration then
			conn:Disconnect()
			gui:Destroy()
		end
	end)
end

local function placeDummy(dummy, pos)
	local root = dummy:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(pos)
	end
end

-- Usa o metodo NATIVO do Roblox pra gerar um rig R15 completo e
-- funcional (mesmo jeito que o proprio Roblox monta o character de
-- qualquer jogador) -- monta peca por peca com WeldConstraint e
-- CanCollide=true tombava/capotava ao andar (confirmado visualmente
-- testando em Play, o boneco virou um bloco deitado no chao). Rig
-- nativo ja vem com fisica de Humanoid correta, testada pelo proprio
-- Roblox.
local function buildDummy()
	local hd = Players:GetHumanoidDescriptionFromUserId(1) -- avatar "Roblox" padrao, sempre existe
	local model = Players:CreateHumanoidModelFromDescription(hd, Enum.HumanoidRigType.R15)
	model.Name = "BonecoTreino"
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.BrickColor = BrickColor.new("Really black")
		end
	end

	local cabeca = model:FindFirstChild("Head")
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.WalkSpeed = DUMMY_WALKSPEED

	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthGui"
	gui.Size = UDim2.new(0, 140, 0, 44)
	gui.StudsOffset = Vector3.new(0, 2.2, 0)
	gui.AlwaysOnTop = true
	local bg = Instance.new("Frame")
	bg.Name = "Bg"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	bg.BackgroundTransparency = 0.2
	bg.BorderSizePixel = 0
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, 0, 0, 10)
	bar.Position = UDim2.new(0, 0, 0, 4)
	bar.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
	bar.BorderSizePixel = 0
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 0, 22)
	label.Position = UDim2.new(0, 0, 0, 16)
	label.BackgroundTransparency = 1
	label.Text = "Boneco de Treino"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	bg.Parent = gui
	bar.Parent = bg
	label.Parent = gui
	gui.Parent = cabeca

	model.PrimaryPart = root
	dummies[model] = { hp = DUMMY_MAX_HP, maxHp = DUMMY_MAX_HP, aura = DUMMY_MAX_AURA, maxAura = DUMMY_MAX_AURA, respawning = false, humanoid = humanoid, root = root, attacking = false }
	placeDummy(model, DUMMY_POS)
	updateLabel(model)
	return model
end

local function respawnDummy(dummy)
	local data = dummies[dummy]
	data.hp = data.maxHp
	data.aura = data.maxAura
	data.respawning = false
	data.attacking = false
	for _, part in ipairs(dummy:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end
	placeDummy(dummy, DUMMY_POS)
	updateLabel(dummy)
end

-- Resolve o ataque do boneco contra um jogador especifico, apos o
-- telegraph ja ter passado. Confere se o jogador tentou uma reacao
-- (guardado em data.pendingReaction pelo remote AttemptBlock/AttemptDodge).
local function resolveDummyAttack(dummy, targetPlayer)
	local data = dummies[dummy]
	if not CharacterService then return end
	local character = CharacterService.GetActiveCharacter(targetPlayer)
	if not character then return end

	-- Exaustao Nivel 2+ do ALVO da o inimigo vantagem pra acertar
	-- (regra do Nivel 2: "vantagem contra voce").
	local modsAlvo = CharacterService.GetConditionModifiers(character)
	local modoInimigo = modsAlvo.vantagemInimigoContra and "VANTAGEM" or "NORMAL"
	local rollInimigo = DiceUtils.RollD20(modoInimigo)
	local attackRoll = rollInimigo.total
	local attackTotal = attackRoll + DUMMY_ATTACK_BONUS
	local dano = rollDice(1, 4)

	local reaction = data.pendingReaction
	data.pendingReaction = nil

	local resultMsg
	local finalDano = dano
	if reaction == "dodge" then
		local r = CombatService.ResolveDodge(character, attackTotal)
		if r.avoided then
			finalDano = 0
			resultMsg = "Você ESQUIVOU! (rolou " .. r.total .. " vs ataque " .. attackTotal .. ")"
		else
			finalDano = dano + r.danoExtra
			resultMsg = "Esquiva falhou (rolou " .. r.total .. " vs ataque " .. attackTotal .. ") — dano dobrado: " .. finalDano
		end
	elseif reaction == "block" then
		local r = CombatService.ResolveBlock(character, attackTotal)
		if r.avoided then
			finalDano = 0
			resultMsg = "Você BLOQUEOU! (rolou " .. r.total .. " vs ataque " .. attackTotal .. ")"
		else
			finalDano = dano
			resultMsg = "Bloqueio falhou (rolou " .. r.total .. " vs ataque " .. attackTotal .. ") — CA reduzida em " .. r.caPenalidade .. " até o fim do próximo turno."
		end
	else
		resultMsg = "Você não reagiu a tempo — tomou o golpe cheio."
	end

	if finalDano > 0 and character.Vitals and character.Vitals.HP then
		local vit = character.Vitals.HP
		vit.Current = math.max(0, (vit.Current or vit.Max) - finalDano)
		local conquista = AchievementService.CheckPVBaixo(character)
		if conquista then
			HxH5e.AchievementUnlocked:FireClient(targetPlayer, conquista)
		end
		-- Gancho do requisito "sobreviver a ferimento quase-fatal
		-- (5%-10% PV) como Lorde Vampiro" (Lorde -> Conde). So conta
		-- se sobreviveu (Current > 0) dentro dessa faixa especifica.
		if character.Race == "Vampiros" and character.VampiroCasta == "Lorde Vampiro" and vit.Max > 0 then
			local pct = vit.Current / vit.Max
			if vit.Current > 0 and pct >= 0.05 and pct <= 0.10 then
				character.VampiroSobreviveuFerimentoFatal = true
			end
		end
		CharacterService.SavePlayer(targetPlayer)
	end

	if EnemyAttackResult then
		EnemyAttackResult:FireClient(targetPlayer, { message = resultMsg, dano = finalDano, hp = character.Vitals and character.Vitals.HP })
	end
end

-- IA do boneco: persegue o jogador mais proximo, ataca com telegraph
-- quando chega perto. Roda em loop continuo por boneco.
local function startDummyAI(dummy)
	task.spawn(function()
		while dummy.Parent do
			local data = dummies[dummy]
			if data and not data.respawning and not data.attacking then
				local root = data.root
				local nearestPlayer, bestDist = nil, math.huge
				for _, plr in ipairs(Players:GetPlayers()) do
					local plrChar = plr.Character
					if plrChar and plrChar.PrimaryPart then
						local dist = (plrChar.PrimaryPart.Position - root.Position).Magnitude
						if dist < bestDist then
							nearestPlayer = plr
							bestDist = dist
						end
					end
				end

				if nearestPlayer and bestDist <= DETECTION_RANGE then
					if bestDist > ATTACK_RANGE then
						data.humanoid:MoveTo(nearestPlayer.Character.PrimaryPart.Position)
					else
						data.humanoid:MoveTo(root.Position) -- para no lugar
						data.attacking = true
						showTelegraph(dummy, TELEGRAPH_SECONDS)
						if EnemyTelegraph then
							EnemyTelegraph:FireClient(nearestPlayer, TELEGRAPH_SECONDS)
						end
						task.delay(TELEGRAPH_SECONDS, function()
							if dummies[dummy] and not dummies[dummy].respawning then
								resolveDummyAttack(dummy, nearestPlayer)
								if dummies[dummy] then
									dummies[dummy].attacking = false
								end
							end
						end)
					end
				end
			end
			task.wait(0.5)
		end
	end)
end

function CombatService.Setup(charService)
	CharacterService = charService
	EnemyTelegraph = HxH5e:FindFirstChild("EnemyTelegraph")
	EnemyAttackResult = HxH5e:FindFirstChild("EnemyAttackResult")
	dummyFolder = Workspace:FindFirstChild("HxH5eDummies")
	if not dummyFolder then
		dummyFolder = Instance.new("Folder")
		dummyFolder.Name = "HxH5eDummies"
		dummyFolder.Parent = Workspace
	end
	local dummy = buildDummy()
	dummy.Parent = dummyFolder
	startDummyAI(dummy)
end

-- Chamado pelos remotes AttemptBlock/AttemptDodge enquanto o telegraph
-- do boneco esta ativo pro jogador. So aceita se houver saldo de
-- Reacoes disponivel.
function CombatService.AttemptReaction(player, reactionType)
	if not CharacterService then
		return { success = false, error = "Sistema de combate não iniciado." }
	end
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	if not hasReactionAvailable(character) then
		return { success = false, error = "Sem Reações disponíveis (recupera com Zetsu)." }
	end

	local foundDummy, foundData = nil, nil
	for dummy, data in pairs(dummies) do
		if data.attacking then
			foundDummy = dummy
			foundData = data
			break
		end
	end
	if not foundData then
		return { success = false, error = "Nenhum ataque em andamento pra reagir agora." }
	end

	spendReaction(character)
	foundData.pendingReaction = reactionType
	CharacterService.SavePlayer(player)
	return { success = true, message = "Reação registrada: " .. reactionType }
end

-- ================= SUGAR AURA (Vampiros) =================
-- Escala por casta (documento real do Lucas):
--   Vampiro: 5% de dreno por sucesso (sem opcao de cura ainda)
--   Lorde Vampiro: 5% de dreno OU curar PV = dano causado (escolha)
--   Conde Vampiro: 10% de dreno OU curar 1d6+CON
--   Imperador Vampiro: 15% de dreno OU curar 2d6+CON
-- DC do TR de resistencia do alvo: 8 + floor(nivel do vampiro / 2) +
-- mod de CON do vampiro (mesmo padrao ja usado no resto do sistema
-- pra formulas de TR baseadas em nivel).
local SUGAR_AURA_POR_CASTA = {
	["Vampiro"] = { pct = 5, podeCurar = false },
	["Lorde Vampiro"] = { pct = 5, podeCurar = true, curaFormula = nil }, -- cura = dano causado
	["Conde Vampiro"] = { pct = 10, podeCurar = true, curaFormula = { 1, 6 } }, -- 1d6+CON
	["Imperador Vampiro"] = { pct = 15, podeCurar = true, curaFormula = { 2, 6 } }, -- 2d6+CON
}

-- targetId: identificador estavel do alvo (pro rastreio de "seres
-- diferentes drenados"). targetAura/targetConMod: estado do alvo (o
-- boneco de treino usa valores fixos de teste por ora).
function CombatService.SugarAuraAttack(character, targetId, targetAuraState, targetConMod, modo)
	if character.Race ~= "Vampiros" then
		return { success = false, error = "Só personagens da raça Vampiros têm Sugar Aura." }
	end
	local casta = character.VampiroCasta or "Vampiro"
	local config = SUGAR_AURA_POR_CASTA[casta]
	if not config then
		return { success = false, error = "Casta de vampiro inválida." }
	end
	if modo == "curar" and not config.podeCurar then
		return { success = false, error = "Sua casta (" .. casta .. ") ainda não pode escolher curar -- só drenar." }
	end

	-- Mordida: 1d6 de dano perfurante
	local danoMordida = rollDice(1, 6)

	if modo == "curar" then
		local cura
		if config.curaFormula then
			local conMod = attrMod(character, "CON")
			cura = rollDice(config.curaFormula[1], config.curaFormula[2]) + conMod
		else
			cura = danoMordida -- Lorde: cura = dano causado
		end
		if character.Vitals and character.Vitals.HP then
			local vit = character.Vitals.HP
			vit.Current = math.min(vit.Max, (vit.Current or 0) + cura)
		end
		return { success = true, modo = "curar", danoMordida = danoMordida, cura = cura, casta = casta }
	end

	-- Modo drenar: TR de CON do alvo vs DC do vampiro
	local nivel = character.Level or 1
	local dc = 8 + math.floor(nivel / 2) + attrMod(character, "CON")
	local rolagem = math.random(1, 20)
	local totalAlvo = rolagem + (targetConMod or 0)

	local resultado = {
		success = true,
		modo = "drenar",
		danoMordida = danoMordida,
		dc = dc,
		rolagemAlvo = rolagem,
		totalAlvo = totalAlvo,
		casta = casta,
		pct = config.pct,
	}

	if totalAlvo >= dc then
		resultado.drenou = false
		resultado.message = "O alvo resistiu ao dreno (TR " .. totalAlvo .. " vs DC " .. dc .. ")."
		return resultado
	end

	-- Alvo falhou: drena a % da AURA MAXIMA do alvo
	local auraDrenada = math.floor((targetAuraState.maxAura or 0) * (config.pct / 100))
	targetAuraState.aura = math.max(0, (targetAuraState.aura or 0) - auraDrenada)

	if character.Vitals and character.Vitals.Aura then
		local vitAura = character.Vitals.Aura
		vitAura.Current = math.min(vitAura.Max, (vitAura.Current or 0) + auraDrenada)
	end

	-- Contadores cumulativos pra progressao de casta
	character.VampiroAuraTotalDrenada = (character.VampiroAuraTotalDrenada or 0) + config.pct
	character.VampiroSeresDrenados = character.VampiroSeresDrenados or {}
	if not table.find(character.VampiroSeresDrenados, targetId) then
		table.insert(character.VampiroSeresDrenados, targetId)
	end

	resultado.drenou = true
	resultado.auraDrenada = auraDrenada
	resultado.message = "Drenou " .. auraDrenada .. " de aura (" .. config.pct .. "%) -- total acumulado na vida: " .. character.VampiroAuraTotalDrenada .. "%."
	return resultado
end

-- Ataca o boneco de treino especificamente com Sugar Aura (uso real
-- do jogador via remote). Reaproveita a busca de alvo do BasicAttack.
function CombatService.SugarAuraOnDummy(player, modo)
	if not CharacterService then
		return { success = false, error = "Sistema de combate não iniciado." }
	end
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end

	local plrChar = player.Character
	local origin = plrChar and plrChar:GetPivot().Position or Vector3.zero
	local nearest, bestDist = nil, math.huge
	for dummy in pairs(dummies) do
		local data = dummies[dummy]
		if data and not data.respawning then
			local root = data.root
			local dist = (root.Position - origin).Magnitude
			if dist < bestDist then
				nearest = dummy
				bestDist = dist
			end
		end
	end
	if not nearest then
		return { success = false, error = "Nenhum boneco de treino disponível." }
	end
	if bestDist > 25 then
		return { success = false, error = "Muito longe do boneco (" .. math.floor(bestDist) .. "m). Aproxime-se." }
	end

	local data = dummies[nearest]
	local result = CombatService.SugarAuraAttack(character, "boneco_treino", data, DUMMY_CON_MOD, modo)

	if result.success and result.modo == "drenar" then
		data.hp = data.hp - result.danoMordida
		if data.hp <= 0 then
			data.hp = 0
			data.respawning = true
			task.delay(5, function() respawnDummy(nearest) end)
		end
		updateLabel(nearest)
	end

	return result
end

function CombatService.BasicAttack(player)
	if not CharacterService then
		return { success = false, error = "Sistema de combate não iniciado." }
	end
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo. Ative ou crie um na ficha." }
	end

	local plrChar = player.Character
	local origin = plrChar and plrChar:GetPivot().Position or Vector3.zero

	local nearest, bestDist = nil, math.huge
	for dummy in pairs(dummies) do
		local data = dummies[dummy]
		if data and not data.respawning then
			local root = data.root
			local dummyPos = root and root.Position or dummy:GetPivot().Position
			local dist = (dummyPos - origin).Magnitude
			if dist < bestDist then
				nearest = dummy
				bestDist = dist
			end
		end
	end

	if not nearest then
		return { success = false, error = "Nenhum boneco de treino disponível." }
	end
	if bestDist > 25 then
		return { success = false, error = "Muito longe do boneco (" .. math.floor(bestDist) .. "m). Aproxime-se." }
	end

	local attrs = character.Attributes or {}
	local forVal = attrs.FOR and attrs.FOR.value or 10
	local forMod = math.max(0, math.floor((forVal - 10) / 2))

	-- Jogada de ataque de verdade: 1d20 + mod FOR vs CA do alvo (pedido
	-- do Lucas -- antes o ataque sempre acertava, so causava dano
	-- direto). CA do boneco e um valor provisorio de teste (DUMMY_CA).
	-- FOR e o atributo certo aqui porque e um ataque desarmado (sem
	-- alcance nem acuidade) -- ataques a distancia ou com acuidade
	-- devem usar DES no lugar (regra confirmada com o Lucas; ainda
	-- nao ha sistema de armas equipadas pra decidir isso automatico).
	local modsExaustao = CharacterService.GetConditionModifiers(character)
	local modoAtaque = modsExaustao.desvantagemAtaque and "DESVANTAGEM" or "NORMAL"
	local rollAtaque = DiceUtils.RollD20(modoAtaque)
	local rolagemAtaque = rollAtaque.total
	local totalAtaque = rolagemAtaque + forMod
	local caAlvo = DUMMY_CA
	if totalAtaque < caAlvo then
		return {
			success = true,
			acertou = false,
			rolagemAtaque = rolagemAtaque,
			totalAtaque = totalAtaque,
			caAlvo = caAlvo,
			dano = 0,
			hpRestante = dummies[nearest].hp,
			hpMax = dummies[nearest].maxHp,
		}
	end

	local danoBase = rollDice(1, 6)
	local dano = danoBase + forMod
	local partes = { "1d6=" .. danoBase, "FOR+" .. forMod }

	local renBonus = 0
	if BuffManager.Has(player, "Ren") then
		local ren = NenService.CalcRenBonus and NenService.CalcRenBonus(character) or { grau = 0 }
		renBonus = ren.grau or 0
		dano = dano + renBonus
		table.insert(partes, "REN+" .. renBonus)
	end

	local data = dummies[nearest]
	data.hp = data.hp - dano
	local killed = data.hp <= 0
	if killed then
		data.hp = 0
	end
	updateLabel(nearest)

	local result = {
		success = true,
		acertou = true,
		rolagemAtaque = rolagemAtaque,
		totalAtaque = totalAtaque,
		caAlvo = caAlvo,
		dano = dano,
		partes = table.concat(partes, " + "),
		renBonus = renBonus,
		hpRestante = math.max(0, data.hp),
		hpMax = data.maxHp,
		killed = killed,
	}

	if killed then
		-- Conquista "Primeira Cacada" (derrotar um inimigo que se
		-- move): o boneco de treino agora persegue de verdade
		-- (CombatService M2.0), entao ja cumpre a descricao da
		-- conquista. Gancho pronto desde o motor de Conquistas,
		-- so faltava esse momento pra disparar.
		local rAch = AchievementService.Unlock(character, "primeira_cacada")
		if rAch.isNew then
			result.conquista = rAch.achievement
		end
		data.respawning = true
		data.attacking = false
		for _, part in ipairs(nearest:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.9
				part.CanCollide = false
			end
		end
		task.delay(5, function()
			respawnDummy(nearest)
		end)
	end

	return result
end

return CombatService
