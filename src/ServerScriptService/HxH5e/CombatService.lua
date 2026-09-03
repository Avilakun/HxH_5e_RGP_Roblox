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
local SanityTagService = require(script.Parent:WaitForChild("SanityTagService"))
local SanitySurgeService = require(script.Parent:WaitForChild("SanitySurgeService"))
local AnimationDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("AnimationDB"))

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

-- Esquiva Acrobatica: 1d20+Acrobacia vs ataque (mesma regra da Esquiva
-- comum -- falha soma o mod de DES ao dano). Diferente da Esquiva
-- comum, exige estar de pe e ter um quadrado adjacente livre pra
-- escapar -- sem grid real no jogo ainda, essa exigencia fica como
-- responsabilidade de quem chama (nao validada aqui).
function CombatService.ResolveEsquivaAcrobatica(character, attackTotal)
	local desMod = attrMod(character, "DES")
	local desValue = (character.Attributes and character.Attributes.DES and character.Attributes.DES.value) or 10
	local acrobaciaBonus = SkillSystem and SkillSystem.GetSkillBonus(character, "Acrobacia") or desMod
	local modsEx = CharacterService.GetConditionModifiers(character)
	local roll = DiceUtils.RollD20(modsEx.desvantagemHabilidade and "DESVANTAGEM" or "NORMAL").total
	local total = roll + acrobaciaBonus
	if total > attackTotal then
		return { success = true, avoided = true, roll = roll, total = total, dano = 0 }
	end
	return { success = true, avoided = false, roll = roll, total = total, danoExtra = desValue }
end

-- Bloqueio Armado: 1d20+CON+FOR+bonus da arma vs ataque. Falha
-- (inclusive empate) toma o dano inteiro e rola 1d10: 1-8 desarma
-- (a arma cai a 1,5m), 9-10 quebra a arma (-2 graus de eficiencia,
-- perde proficiencia no ataque ate ser reparada). bonusArma e passado
-- por quem chama -- CombatService ainda nao sabe qual arma o
-- personagem tem equipada (sem sistema de slots ainda, ver FichaUI).
function CombatService.ResolveBloqueioArmado(character, attackTotal, bonusArma)
	local conMod = attrMod(character, "CON")
	local forMod = attrMod(character, "FOR")
	local modsEx = CharacterService.GetConditionModifiers(character)
	local roll = DiceUtils.RollD20(modsEx.desvantagemHabilidade and "DESVANTAGEM" or "NORMAL").total
	local total = roll + conMod + forMod + (bonusArma or 0)
	if total > attackTotal then
		return { success = true, avoided = true, roll = roll, total = total }
	end
	local resultado = math.random(1, 10)
	local quebrou = resultado >= 9
	return {
		success = true,
		avoided = false,
		roll = roll,
		total = total,
		desarmou = not quebrou,
		quebrouArma = quebrou,
	}
end

-- Contra-Ataque: 1d20+Modificador do Ataque (mesmo formula usada em
-- BasicAttack, FOR pra ataque desarmado) vs ataque total inimigo.
-- Ganhando OU perdendo, gasta a proxima Acao Principal do personagem
-- (regra do livro: "Fique atento! Esse recurso gasta sua proxima
-- acao principal" -- nao e condicional ao sucesso). Quem CHAMA essa
-- funcao e responsavel por aplicar o flag de bloqueio da proxima
-- acao (character.ProximaAcaoPrincipalBloqueada) e, se quiser, causar
-- dano de volta no atacante quando avoided=true.
--
-- ⚠️ Excecao do livro nao implementada ainda: "Em caso de estar
-- utilizando EN voce ganha esse contra-ataque assim que o inimigo
-- entra em seu alcance SEM perder sua proxima acao principal." EN
-- ainda nao e rastreado como ativo durante o combate de verdade
-- (so como buff temporario de 6s via BuffManager) -- fica pra quando
-- isso existir.
function CombatService.ResolveContraAtaque(character, attackTotal)
	local forMod = attrMod(character, "FOR")
	local roll = DiceUtils.RollD20("NORMAL").total
	local total = roll + forMod
	if total > attackTotal then
		return { success = true, avoided = true, roll = roll, total = total }
	end
	return { success = true, avoided = false, roll = roll, total = total }
end

-- Assumir Lugar: quem reage precisa estar adjacente a quem tomaria o
-- golpe (checado por quem chama, via distancia). Formula do livro:
-- CA + 1d6 vs acerto total do inimigo. Em QUALQUER dos 3 resultados
-- (menor/igual/maior) perde a proxima Acao Principal -- e um custo
-- fixo do recurso, nao condicional.
function CombatService.ResolveAssumirLugar(character, attackTotal)
	local ca = CharacterService.GetEffectiveCA(character)
	local roll = rollDice(1, 6)
	local total = ca + roll
	if total < attackTotal then
		return { success = true, resultado = "menor", total = total } -- sofre o dano no lugar do aliado
	elseif total == attackTotal then
		return { success = true, resultado = "igual", total = total } -- divide o dano com o aliado
	else
		return { success = true, resultado = "maior", total = total } -- nao sofre dano
	end
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
	-- Trocado de R15 pra R6: o jogo inteiro migrou pra R6 (as
	-- animacoes de combate foram convertidas/gravadas em R6) -- o
	-- boneco precisa bater com o mesmo tipo de esqueleto do jogador,
	-- senao as animacoes carregam sem erro mas nao aparecem visualmente
	-- (mesmo bug que ja resolvemos no personagem do jogador).
	local model = Players:CreateHumanoidModelFromDescription(hd, Enum.HumanoidRigType.R6)
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

	-- Animacao de ataque do boneco -- toca no servidor (Animator
	-- replica Play/Stop automaticamente pra todos os clientes que
	-- veem o personagem, sem precisar de RemoteEvent). Reaproveita a
	-- MESMA animacao "AtaqueCaC" que o jogador usa -- pedido do
	-- Lucas: "o inimigo nao esta atacando com a animacao... deveria
	-- me atacar para testarmos o tempo de reacao do QTE".
	local dummyAnimator = Instance.new("Animator")
	dummyAnimator.Parent = humanoid
	local dummyAttackTrack = nil
	local atkDef = AnimationDB.FindByChave("AtaqueCaC")
	if atkDef and atkDef.id and atkDef.id ~= "" then
		local anim = Instance.new("Animation")
		anim.AnimationId = atkDef.id
		local ok, track = pcall(function()
			return dummyAnimator:LoadAnimation(anim)
		end)
		if ok then
			dummyAttackTrack = track
		end
	end

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
	dummies[model] = { hp = DUMMY_MAX_HP, maxHp = DUMMY_MAX_HP, aura = DUMMY_MAX_AURA, maxAura = DUMMY_MAX_AURA, respawning = false, humanoid = humanoid, root = root, attacking = false, attackTrack = dummyAttackTrack }
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

-- Aplica dano a um boneco especifico e trata morte/respawn/conquista.
-- Extraida do BasicAttack pra ser reusada tambem pelo Contra-Ataque
-- (que causa dano de volta no atacante quando a reacao da certo).
-- player/character sao opcionais -- so usados pra conquista/SanityTag
-- (fazem sentido quando quem causou o dano foi um JOGADOR, seja via
-- ataque normal ou contra-ataque).
local function damageDummy(dummy, dano, player, character)
	local data = dummies[dummy]
	if not data then return { hpRestante = 0, hpMax = 0, killed = false } end
	data.hp = data.hp - dano
	local killed = data.hp <= 0
	if killed then
		data.hp = 0
	end
	updateLabel(dummy)

	local resultado = { hpRestante = math.max(0, data.hp), hpMax = data.maxHp, killed = killed }

	if killed and not data.respawning then
		if character and player then
			local rAch = AchievementService.Unlock(character, "primeira_cacada")
			if rAch.isNew then
				resultado.conquista = rAch.achievement
			end
			SanityTagService.OnCombatVictory(player, character)
		end
		data.respawning = true
		data.attacking = false
		for _, part in ipairs(dummy:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.9
				part.CanCollide = false
			end
		end
		task.delay(5, function()
			respawnDummy(dummy)
		end)
	end

	return resultado
end

-- ================= Ataque generico vs personagem (NUCLEO SIMETRICO) =================
-- Pedido do Lucas: "as mecanicas de acerto e dano devem ser EXATAMENTE
-- iguais para inimigos e personagens. O que vai diferenciar sao os
-- recursos que eles vao ter nas fichas". Esta funcao e ESSE nucleo --
-- qualquer atacante (boneco de treino, monstro futuro, ou um jogador
-- atacando outro em PvP) usa a MESMA rolagem de acerto/dano/reacao
-- contra um personagem-alvo. O que muda por atacante e so o
-- "atacanteStats" que ele fornece (attackBonus, dano, tipo de dano) --
-- e o que muda por ALVO e so os recursos que ELE tem disponiveis
-- (Reacoes, RD do TEN, Exaustao, etc.), todos ja lidos daqui.
-- Aplica dano final (com RD ja calculada) a UM personagem e dispara
-- todos os hooks de sempre (conquista PV baixo, SanityTag, morte,
-- gancho Vampiro, save). Extraida pra ser reusada tanto no fluxo
-- normal quanto no de Assumir Lugar (que pode precisar aplicar em
-- ATE DOIS personagens no caso de divisao de dano).
-- Personagem "protegido por tecnica" (doc do Lucas sobre durabilidade
-- de armadura): TEN, KEN ou RYU ativos no momento do golpe evitam o
-- desgaste. Usa o mesmo BuffManager que ja controla os buffs
-- temporarios de 6s de Ren/Ten/etc (ver NenService.ActivatePrinciple).
local function protegidoPorTecnica(player)
	if not player then return false end
	return BuffManager.Has(player, "Ten") or BuffManager.Has(player, "Ken") or BuffManager.Has(player, "Ryu")
end

local function aplicarDanoEHooks(character, player, dano, tipoDano, propriedadeGolpe)
	if dano <= 0 or not (character.Vitals and character.Vitals.HP) then
		return { danoFinal = 0, danoBloqueado = 0, hpAtual = 0, hpMax = 0, morreu = false }
	end

	-- Resistencia Balistica da armadura: reduz o dano pela metade
	-- ANTES da RD (regra do livro: "Resistencia... reduz em 50% o
	-- tipo especifico de dano descrito").
	local armadura = CharacterService.GetArmaduraAtiva(character)
	if armadura and armadura.resistenciaTipos and tipoDano then
		for _, tipo in ipairs(armadura.resistenciaTipos) do
			if tipo == tipoDano then
				dano = math.floor(dano / 2)
				break
			end
		end
	end

	local rd = 0
	if tipoDano == "Corte" or tipoDano == "Impacto" or tipoDano == "Explosão" then
		rd = NenService.CalcTenRD(character)
		if armadura and armadura.rd and armadura.rdTipos then
			for _, tipo in ipairs(armadura.rdTipos) do
				if tipo == tipoDano then
					rd = rd + armadura.rd
					break
				end
			end
		end
	elseif tipoDano == "Psíquico" or tipoDano == "Mental" then
		-- RDM (Reducao de Dano Mental) = INT + nivel (ja calculado em
		-- character.Vitals.RDM por CharacterService, comentario de
		-- sessao anterior: "RDM ainda nao conectado a nenhum calculo
		-- de dano real -- nao existe tipo Mental/Psiquico no
		-- CombatService"). Fecha essa pendencia -- ainda nao existe
		-- NENHUMA fonte de dano Psiquico/Mental de verdade no jogo
		-- (nenhum Hatsu/ataque gera esse tipo ainda), entao a reducao
		-- fica pronta mas sem uso real ate existir uma fonte.
		rd = character.Vitals.RDM or 0
	end

	-- Desgasta a armadura equipada (se houver e o golpe realmente
	-- acertou) -- ver CharacterService.DesgastarArmadura pra regra
	-- completa (nao desgasta se TEN/KEN/RYU estiver ativo).
	CharacterService.DesgastarArmadura(character, protegidoPorTecnica(player), propriedadeGolpe)
	-- Escudo desgasta com regra DIFERENTE (so Balistico/explosivo,
	-- independente de TEN/KEN/RYU) -- ver CharacterService.DesgastarEscudo.
	CharacterService.DesgastarEscudo(character, tipoDano, propriedadeGolpe)

	local resultado = CharacterService.ApplyDamage(character, dano, rd)

	local conquista = AchievementService.CheckPVBaixo(character)
	if conquista and player then
		HxH5e.AchievementUnlocked:FireClient(player, conquista)
	end
	if resultado.hpAtual > 0 and resultado.hpMax > 0 and (resultado.hpAtual / resultado.hpMax) <= 0.10 and player then
		SanityTagService.OnSurvivedLowHP(player, character)
	end
	if resultado.morreu and player then
		SanityTagService.OnDeath(player, character)
	end
	if character.Race == "Vampiros" and character.VampiroCasta == "Lorde Vampiro" and resultado.hpMax > 0 then
		local pct = resultado.hpAtual / resultado.hpMax
		if resultado.hpAtual > 0 and pct >= 0.05 and pct <= 0.10 then
			character.VampiroSobreviveuFerimentoFatal = true
		end
	end
	if player then
		CharacterService.SavePlayer(player)
	end
	return resultado
end

-- atacanteStats = { attackBonus, danoDados={n,d}, danoBonus, tipoDano, nome, applyDamageBack }
-- applyDamageBack(dano): opcional, chamado quando um Contra-Ataque da
-- certo -- quem fornece o atacante decide como aplicar o dano de
-- volta nele (ex.: reduzir HP do boneco).
-- reactionOpts = { bonusArma, interceptor = { character, player } }
function CombatService.ResolveAttackVsCharacter(atacanteStats, targetCharacter, targetPlayer, reactionType, reactionOpts)
	reactionOpts = reactionOpts or {}
	local character = targetCharacter

	-- Exaustao Nivel 2+ do ALVO da vantagem pro atacante (regra do
	-- Nivel 2: "vantagem contra voce"). Mesma regra vale seja o
	-- atacante um boneco, monstro, ou outro jogador.
	local modsAlvo = CharacterService.GetConditionModifiers(character)
	local modoAtacante = modsAlvo.vantagemInimigoContra and "VANTAGEM" or "NORMAL"
	local rollAtacante = DiceUtils.RollD20(modoAtacante)
	local attackRoll = rollAtacante.total
	local attackTotal = attackRoll + (atacanteStats.attackBonus or 0)

	local danoDados = atacanteStats.danoDados or { n = 1, d = 4 }
	local tipoDano = atacanteStats.tipoDano or "Impacto"

	-- ================= ASSUMIR LUGAR (intercepta ANTES da checagem
	-- normal de acerto -- usa a CA do INTERCEPTADOR, nao do alvo
	-- original, conforme a formula do livro: CA+1d6 vs ataque total).
	if reactionType == "assumir_lugar" and reactionOpts.interceptor then
		local interceptor = reactionOpts.interceptor
		local r = CombatService.ResolveAssumirLugar(interceptor.character, attackTotal)
		interceptor.character.ProximaAcaoPrincipalBloqueada = true

		local danoBase = rollDice(danoDados.n, danoDados.d) + (atacanteStats.danoBonus or 0)
		local msg

		if r.resultado == "menor" then
			aplicarDanoEHooks(interceptor.character, interceptor.player, danoBase, tipoDano, atacanteStats.propriedade)
			msg = (interceptor.character.Name or "Alguém") .. " assumiu o lugar e tomou o golpe cheio (rolou " .. r.total .. " vs ataque " .. attackTotal .. ")."
		elseif r.resultado == "igual" then
			local metade = math.floor(danoBase / 2)
			aplicarDanoEHooks(interceptor.character, interceptor.player, metade, tipoDano, atacanteStats.propriedade)
			aplicarDanoEHooks(character, targetPlayer, danoBase - metade, tipoDano, atacanteStats.propriedade)
			msg = (interceptor.character.Name or "Alguém") .. " dividiu o dano ao assumir o lugar (rolou " .. r.total .. " -- empatou com o ataque)."
		else
			msg = (interceptor.character.Name or "Alguém") .. " assumiu o lugar e NÃO sofreu dano (rolou " .. r.total .. " vs ataque " .. attackTotal .. ")."
		end

		return {
			acertou = true,
			message = msg,
			interceptado = true,
			hp = character.Vitals and character.Vitals.HP,
			hpInterceptor = interceptor.character.Vitals and interceptor.character.Vitals.HP,
		}
	end

	local caAlvo = CharacterService.GetEffectiveCA(character)
	if attackTotal < caAlvo then
		return {
			acertou = false,
			message = (atacanteStats.nome or "O ataque") .. " errou (" .. attackTotal .. " vs CA " .. caAlvo .. ").",
			hp = character.Vitals and character.Vitals.HP,
		}
	end
	-- Empate: acerto com metade do dano (exceto propriedade
	-- perfurante -- nao modelada ainda, ver ItemsDB pendencia).
	local meioDano = (attackTotal == caAlvo)

	local danoBase = rollDice(danoDados.n, danoDados.d) + (atacanteStats.danoBonus or 0)
	local dano = meioDano and math.floor(danoBase / 2) or danoBase

	local resultMsg
	local finalDano = dano
	if reactionType == "dodge" then
		local r = CombatService.ResolveDodge(character, attackTotal)
		if r.avoided then
			finalDano = 0
			resultMsg = "Você ESQUIVOU! (rolou " .. r.total .. " vs ataque " .. attackTotal .. ")"
		else
			finalDano = dano + r.danoExtra
			resultMsg = "Esquiva falhou (rolou " .. r.total .. " vs ataque " .. attackTotal .. ") — dano dobrado: " .. finalDano
		end
	elseif reactionType == "esquiva_acrobatica" then
		local r = CombatService.ResolveEsquivaAcrobatica(character, attackTotal)
		if r.avoided then
			finalDano = 0
			resultMsg = "Você ESQUIVOU (acrobático)! (rolou " .. r.total .. " vs ataque " .. attackTotal .. ")"
		else
			finalDano = dano + r.danoExtra
			resultMsg = "Esquiva acrobática falhou (rolou " .. r.total .. " vs ataque " .. attackTotal .. ") — dano dobrado: " .. finalDano
		end
	elseif reactionType == "block" then
		local r = CombatService.ResolveBlock(character, attackTotal)
		if r.avoided then
			finalDano = 0
			resultMsg = "Você BLOQUEOU! (rolou " .. r.total .. " vs ataque " .. attackTotal .. ")"
		else
			finalDano = dano
			resultMsg = "Bloqueio falhou (rolou " .. r.total .. " vs ataque " .. attackTotal .. ") — CA reduzida em " .. r.caPenalidade .. " até o fim do próximo turno."
		end
	elseif reactionType == "bloqueio_armado" then
		local r = CombatService.ResolveBloqueioArmado(character, attackTotal, reactionOpts.bonusArma)
		if r.avoided then
			finalDano = 0
			resultMsg = "Você BLOQUEOU (armado)! (rolou " .. r.total .. " vs ataque " .. attackTotal .. ")"
		else
			finalDano = dano
			if r.quebrouArma then
				resultMsg = "Bloqueio armado falhou (rolou " .. r.total .. ") — sua arma QUEBROU (-2 graus de eficiência, sem proficiência até reparar)."
			else
				resultMsg = "Bloqueio armado falhou (rolou " .. r.total .. ") — você foi DESARMADO."
			end
		end
	elseif reactionType == "contra_ataque" then
		-- Ganhando ou perdendo, gasta a proxima Acao Principal (regra
		-- do livro -- nao e condicional ao sucesso).
		character.ProximaAcaoPrincipalBloqueada = true
		local r = CombatService.ResolveContraAtaque(character, attackTotal)
		if r.avoided then
			finalDano = 0
			resultMsg = "CONTRA-ATACOU com sucesso! (rolou " .. r.total .. " vs ataque " .. attackTotal .. ") Sua próxima Ação Principal já foi usada nisso."
			if atacanteStats.applyDamageBack then
				local forMod = attrMod(character, "FOR")
				local danoContra = rollDice(1, 6) + forMod
				atacanteStats.applyDamageBack(danoContra)
				resultMsg = resultMsg .. " Você causou " .. danoContra .. " de dano de volta!"
			end
		else
			finalDano = dano
			resultMsg = "Contra-ataque falhou (rolou " .. r.total .. " vs ataque " .. attackTotal .. ") — tomou o golpe cheio, e sua próxima Ação Principal já foi usada nisso."
		end
	else
		resultMsg = "Você não reagiu a tempo — tomou o golpe cheio."
	end

	local resultado = { danoFinal = 0, danoBloqueado = 0, hpAtual = 0, hpMax = 0, morreu = false }
	if finalDano > 0 and character.Vitals and character.Vitals.HP then
		resultado = aplicarDanoEHooks(character, targetPlayer, finalDano, tipoDano, atacanteStats.propriedade)
		if resultado.danoBloqueado > 0 then
			resultMsg = resultMsg .. " RD do TEN bloqueou " .. resultado.danoBloqueado .. " de dano."
		end
	end

	return {
		acertou = true,
		message = resultMsg,
		dano = finalDano,
		danoAplicado = resultado.danoFinal,
		hp = character.Vitals and character.Vitals.HP,
	}
end

local function resolveDummyAttack(dummy, targetPlayer)
	local data = dummies[dummy]
	if not CharacterService then return end
	local character = CharacterService.GetActiveCharacter(targetPlayer)
	if not character then return end

	local reaction = data.pendingReaction
	local interceptor = data.pendingAssumirLugar
	data.pendingReaction = nil
	data.pendingAssumirLugar = nil
	if interceptor then
		reaction = "assumir_lugar"
	end

	local atacanteStats = {
		attackBonus = DUMMY_ATTACK_BONUS,
		danoDados = { n = 1, d = 4 },
		danoBonus = 0,
		tipoDano = "Impacto",
		nome = "Boneco de Treino",
		applyDamageBack = function(danoContra)
			damageDummy(dummy, danoContra, targetPlayer, character)
		end,
	}
	local reactionOpts = interceptor and { interceptor = interceptor } or nil
	local resultado = CombatService.ResolveAttackVsCharacter(atacanteStats, character, targetPlayer, reaction, reactionOpts)

	if EnemyAttackResult then
		EnemyAttackResult:FireClient(targetPlayer, { message = resultado.message, dano = resultado.dano, hp = resultado.hp })
		if interceptor and interceptor.player then
			EnemyAttackResult:FireClient(interceptor.player, { message = resultado.message, dano = resultado.dano, hp = resultado.hpInterceptor })
		end
	end
end

-- IA do boneco: persegue o jogador mais proximo, ataca com telegraph
-- quando chega perto. Roda em loop continuo por boneco.
-- Zona segura de descanso (CasaDescanso.SafeZoneMarker no
-- Workspace): o boneco NUNCA persegue/detecta jogadores la dentro --
-- e assim que "fora de combate pra descansar" e garantido pela
-- propria geografia, sem precisar de um flag separado de "em combate".
local function isInSafeZone(position)
	local casa = Workspace:FindFirstChild("CasaDescanso")
	local marker = casa and casa:FindFirstChild("SafeZoneMarker")
	if not marker then return false end
	local rel = marker.CFrame:PointToObjectSpace(position)
	local half = marker.Size / 2
	return math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z
end
CombatService.IsInSafeZone = isInSafeZone

-- Usado pelo SanitySurgeService pro efeito "ataca_aliado" (Surto de
-- Sanidade): forca um ataque leve contra o jogador mais proximo, se
-- houver um por perto. Sem PvP de verdade no jogo ainda, entao isso
-- so aplica dano simbolico (1d4) sem interagir com CA/HP real do
-- alvo -- so serve pra registrar que o efeito aconteceu (a notificacao
-- ao jogador ja avisa da situacao).
function CombatService.ForceAttackNearestPlayer(player, character)
	local plrChar = player.Character
	if not plrChar or not plrChar.PrimaryPart then return end
	local bestDist, alvo = 3, nil
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character and other.Character.PrimaryPart then
			local dist = (other.Character.PrimaryPart.Position - plrChar.PrimaryPart.Position).Magnitude
			if dist <= bestDist then
				alvo = other
				bestDist = dist
			end
		end
	end
	if alvo then
		return { atacou = true, alvo = alvo.Name, dano = rollDice(1, 4) }
	end
	return { atacou = false }
end

-- Usado pelo SanityTagService pro Desgosto "Perigo constante": true se
-- algum boneco esta com o telegraph de ataque ativo contra esse jogador.
function CombatService.IsBeingChased(player)
	local plrChar = player.Character
	if not plrChar or not plrChar.PrimaryPart then return false end
	for dummy, data in pairs(dummies) do
		if data.attacking then
			local dist = (data.root.Position - plrChar.PrimaryPart.Position).Magnitude
			if dist <= ATTACK_RANGE + 3 then
				return true
			end
		end
	end
	return false
end

local function startDummyAI(dummy)
	task.spawn(function()
		while dummy.Parent do
			local data = dummies[dummy]
			if data and not data.respawning and not data.attacking then
				local root = data.root
				local nearestPlayer, bestDist = nil, math.huge
				for _, plr in ipairs(Players:GetPlayers()) do
					local plrChar = plr.Character
					if plrChar and plrChar.PrimaryPart and not isInSafeZone(plrChar.PrimaryPart.Position) then
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
						data.currentTarget = nearestPlayer
						showTelegraph(dummy, TELEGRAPH_SECONDS)
						if data.attackTrack then
							data.attackTrack:Play()
						end
						if EnemyTelegraph then
							EnemyTelegraph:FireClient(nearestPlayer, TELEGRAPH_SECONDS)
						end
						task.delay(TELEGRAPH_SECONDS, function()
							if dummies[dummy] and not dummies[dummy].respawning then
								resolveDummyAttack(dummy, nearestPlayer)
								if dummies[dummy] then
									dummies[dummy].attacking = false
									dummies[dummy].currentTarget = nil
									dummies[dummy].pendingAssumirLugar = nil
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

-- Reacoes "auto" (o proprio alvo do ataque reage por si). SO o
-- jogador que esta REALMENTE sob ataque (data.currentTarget) pode
-- registrar uma -- ⚠️ bug real corrigido aqui: antes, QUALQUER
-- jogador que chamasse esse remote conseguia "roubar" a reacao de um
-- ataque em andamento contra OUTRO jogador (o codigo so checava se
-- existia ALGUM boneco atacando, sem comparar o alvo).
local SELF_REACTIONS = { dodge = true, esquiva_acrobatica = true, block = true, bloqueio_armado = true, contra_ataque = true }

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

	if SELF_REACTIONS[reactionType] then
		if foundData.currentTarget ~= player then
			return { success = false, error = "Esse ataque não é contra você -- só quem está sendo atacado pode reagir assim." }
		end
		spendReaction(character)
		foundData.pendingReaction = reactionType
		CharacterService.SavePlayer(player)
		return { success = true, message = "Reação registrada: " .. reactionType }
	end

	if reactionType == "assumir_lugar" then
		local aliado = foundData.currentTarget
		if not aliado then
			return { success = false, error = "Nenhum ataque em andamento pra reagir agora." }
		end
		if aliado == player then
			return { success = false, error = "Você não pode assumir seu próprio lugar -- essa reação é pra proteger um ALIADO." }
		end
		local aliadoChar = aliado.Character
		local meuChar = player.Character
		if not aliadoChar or not aliadoChar.PrimaryPart or not meuChar or not meuChar.PrimaryPart then
			return { success = false, error = "Personagem não encontrado no mundo." }
		end
		local dist = (aliadoChar.PrimaryPart.Position - meuChar.PrimaryPart.Position).Magnitude
		if dist > 3 then
			return { success = false, error = "Precisa estar adjacente a " .. aliado.Name .. " pra assumir o lugar dele (está a " .. math.floor(dist) .. "m)." }
		end
		spendReaction(character)
		foundData.pendingAssumirLugar = { character = character, player = player }
		CharacterService.SavePlayer(player)
		return { success = true, message = "Você vai assumir o lugar de " .. aliado.Name .. "!" }
	end

	return { success = false, error = "Tipo de reação desconhecido: " .. tostring(reactionType) }
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
	-- Contra-Ataque e Assumir Lugar gastam a proxima Acao Principal
	-- (regra do livro, nao condicional ao sucesso da reacao) -- essa
	-- flag e o "cooldown" simples que representa isso, ja que o jogo
	-- ainda nao tem turnos rigidos pra aplicar um cooldown por tempo.
	if character.ProximaAcaoPrincipalBloqueada then
		character.ProximaAcaoPrincipalBloqueada = false
		CharacterService.SavePlayer(player)
		return { success = false, error = "Sua Ação Principal já foi usada (Contra-Ataque ou Assumir Lugar no ataque anterior)." }
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
	-- Tremores (Surto Longa 71-86, so FOR/DES) e Talisma longe demais
	-- (Surto Longa 21-40) tambem dao desvantagem no ataque.
	local temDesvantagemExtra = SanitySurgeService.TemTremores(character) or SanitySurgeService.LongeDoTalisma(player, character)
	local modoAtaque = (modsExaustao.desvantagemAtaque or temDesvantagemExtra) and "DESVANTAGEM" or "NORMAL"
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

	SanitySurgeService.RegistrarAcaoPrincipal(character)
	local danoBase = rollDice(1, 6)
	local dano = danoBase + forMod
	local partes = { "1d6=" .. danoBase, "FOR+" .. forMod }

	local renBonus = 0
	local atacaComAura = BuffManager.Has(player, "Ren")
	if atacaComAura then
		local ren = NenService.CalcRenBonus and NenService.CalcRenBonus(character) or { grau = 0 }
		renBonus = ren.grau or 0
		dano = dano + renBonus
		table.insert(partes, "REN+" .. renBonus)
	end

	-- Critico: ataque COM AURA (Ren ativo) contra um alvo SEM NEN. O
	-- boneco de treino representa exatamente isso -- um "constructo"
	-- sem aura propria, igual as Bestas Naturais e humanos nao
	-- despertados descritos no livro ("normalmente SAO VULNERAVEIS a
	-- ataques de Aura"). Dobra o dano final (mesmo padrao das fichas
	-- de monstro reais, que usam multiplicadores tipo "Mortal x2/x3/x4"
	-- pra pontos vulneraveis -- aqui usamos x2 como base generica).
	-- ⚠️ So cobre jogador-ataca-boneco por enquanto -- nao ha PvP
	-- jogador-contra-jogador implementado ainda pra estender a mesma
	-- regra contra Zetsu/personagens sem Nen desperto.
	local foiCritico = false
	if atacaComAura then
		dano = dano * 2
		foiCritico = true
		table.insert(partes, "CRÍTICO x2 (aura vs sem Nen)")
	end

	local dmgResultado = damageDummy(nearest, dano, player, character)

	local result = {
		success = true,
		acertou = true,
		rolagemAtaque = rolagemAtaque,
		totalAtaque = totalAtaque,
		caAlvo = caAlvo,
		dano = dano,
		partes = table.concat(partes, " + "),
		renBonus = renBonus,
		foiCritico = foiCritico,
		hpRestante = dmgResultado.hpRestante,
		hpMax = dmgResultado.hpMax,
		killed = dmgResultado.killed,
		conquista = dmgResultado.conquista,
	}

	return result
end

return CombatService
