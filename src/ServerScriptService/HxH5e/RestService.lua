--[[
    HxH5e RestService (server) — sistema de Descanso (Curto/Longo),
    baseado no documento exato do Lucas ("Niveis de Exaustao" +
    "Recuperacao"). Usa o TimeService (1min real = 1h de jogo) pra
    medir a duracao real do descanso.

    ================= REGRAS =================
    Descanso Curto: 4h de jogo (= 4min reais). Descanso Longo: 8h de
    jogo (= 8min reais).

    Exige estar numa ZONA SEGURA (CombatService.IsInSafeZone) --
    pedido do Lucas: "precisa estar fora de combate pra descansar".
    A zona segura (CasaDescanso no Workspace) e onde o boneco de
    treino nunca persegue/ataca, entao "fora de combate" e garantido
    pela propria geografia, sem precisar de um flag separado.

    Reducao de Exaustao (⚠️ MINHA INTERPRETACAO, combinando o
    documento original do Lucas com o que ja estava no ConditionsDB
    de antes -- confirmar se bate):
    - Grau 1 ou 2: descanso curto reduz 1 grau; descanso longo reduz
      2 graus (ou remove, o que vier primeiro).
    - Grau 3: descanso longo SOZINHO so consegue baixar ate o grau 1
      -- pra remover de vez, precisa TAMBEM ter cumprido a condicao
      extra (Zetsu CONTINUO por 2 dias OU nao usar Nen por 1 semana).
      Aplicado a mesma escala de tempo do Lucas (1min=1h): 2 dias =
      48h de jogo, 1 semana = 168h de jogo.

    Recuperacao de PV: rola Medicina OU Sobrevivencia (⚠️ o documento
    nao diz qual escolher -- por padrao pega a MAIOR das duas, mas
    aceita escolha explicita do jogador). Falha (1-12): SEM PV, mas
    ainda remove Exaustao (regra acima) e enche a Aura 100%. Sucesso:
    dados de vida + % do PV maximo, conforme a tabela exata do Lucas.
]]

local RestService = {}

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TimeService = require(script.Parent:WaitForChild("TimeService"))
local LevelUpService = require(script.Parent:WaitForChild("LevelUpService"))
local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))
local SanityTagService = require(script.Parent:WaitForChild("SanityTagService"))

local CharacterService = nil
local CombatService = nil

local SHORT_REST_HOURS = 4
local LONG_REST_HOURS = 8
local ZETSU_CONTINUO_HORAS = 48 -- "2 dias" (1min real = 1h de jogo)
local SEM_NEN_HORAS = 168 -- "1 semana"

function RestService.Setup(charService, combatService)
	CharacterService = charService
	CombatService = combatService
end

-- Estado de descanso em andamento por personagem (so na sessao -- se
-- desconectar no meio, perde o progresso, aceitavel por ora).
local descansosAtivos = {} -- [characterId] = { tipo, inicioHoras, cancelado }

function RestService.EstaDescansando(characterId)
	return descansosAtivos[characterId] ~= nil
end

local function grauExaustaoAtual(character)
	for _, entry in ipairs(character.Conditions or {}) do
		if entry.id == "exausto" then
			return tonumber(entry.grau) or 0
		end
	end
	return 0
end

-- Resolve o descanso: reduz Exaustao, enche Aura, rola recuperacao de
-- PV. Retorna um relatorio detalhado (mostrado ao jogador).
local function resolverDescanso(player, character, tipo, periciaEscolhida)
	local grauAtual = grauExaustaoAtual(character)
	local novoGrau = grauAtual

	if grauAtual == 3 then
		local agora = TimeService.GetTotalGameHours()
		local zetsuOk = character.ZetsuContinuoDesde and (agora - character.ZetsuContinuoDesde) >= ZETSU_CONTINUO_HORAS
		local semNenOk = character.UltimoUsoNen and (agora - character.UltimoUsoNen) >= SEM_NEN_HORAS
		if tipo == "longo" and (zetsuOk or semNenOk) then
			novoGrau = 0
		elseif tipo == "longo" then
			novoGrau = 1
		else
			novoGrau = 2
		end
	elseif grauAtual > 0 then
		local reducao = tipo == "curto" and 1 or 2
		novoGrau = math.max(0, grauAtual - reducao)
	end

	if novoGrau ~= grauAtual then
		if novoGrau <= 0 then
			CharacterService.RemoveCondition(character, "exausto")
		else
			CharacterService.ApplyCondition(character, "exausto", tostring(novoGrau))
		end
	end

	-- Aura: recuperacao completa, sucesso ou falha.
	if character.Vitals and character.Vitals.Aura then
		character.Vitals.Aura.Current = character.Vitals.Aura.Max
	end

	-- Escolhe a pericia: a pedida pelo jogador, ou por padrao a maior
	-- das duas (Medicina/Sobrevivencia) -- regra nao especifica.
	local pericia = periciaEscolhida
	if pericia ~= "Medicina" and pericia ~= "Sobrevivência" then
		local bMed = SkillSystem.GetSkillBonus(character, "Medicina")
		local bSob = SkillSystem.GetSkillBonus(character, "Sobrevivência")
		pericia = bMed >= bSob and "Medicina" or "Sobrevivência"
	end
	local rollResult = SkillSystem.RollSkill(character, pericia, "NORMAL")
	local totalTeste = rollResult.total
	local sucesso = totalTeste >= 13

	local pvRecuperado = 0
	if sucesso then
		local dadosVida, percentualPV
		if tipo == "curto" then
			if totalTeste <= 15 then dadosVida, percentualPV = 1, 0.25
			elseif totalTeste <= 20 then dadosVida, percentualPV = 2, 0.40
			else dadosVida, percentualPV = 3, 0.50 end
		else
			if totalTeste <= 15 then dadosVida, percentualPV = 4, 0.50
			elseif totalTeste <= 20 then dadosVida, percentualPV = 5, 0.75
			else dadosVida, percentualPV = 0, 1.0 end -- 21+ longo = 100% direto
		end

		for _ = 1, dadosVida do
			local r = LevelUpService.RollHitDie(character)
			pvRecuperado = pvRecuperado + r.total
		end
		local maxEfetivo = CharacterService.GetEffectiveMaxHP(character)
		pvRecuperado = pvRecuperado + math.floor(maxEfetivo * percentualPV)

		if character.Vitals and character.Vitals.HP then
			local hp = character.Vitals.HP
			hp.Current = math.min(hp.Max, (hp.Current or 0) + pvRecuperado)
		end
	end

	SanityTagService.OnRestComplete(player, character)
	CharacterService.SavePlayer(player)

	return {
		tipo = tipo,
		pericia = pericia,
		totalTeste = totalTeste,
		sucesso = sucesso,
		pvRecuperado = pvRecuperado,
		exaustaoAntes = grauAtual,
		exaustaoDepois = novoGrau,
	}
end

-- Inicia um descanso. Exige estar dentro da zona segura. Resolve
-- automaticamente apos o tempo passar (task.delay).
function RestService.IniciarDescanso(player, character, tipo, periciaEscolhida)
	if tipo ~= "curto" and tipo ~= "longo" then
		return { success = false, error = "Tipo de descanso inválido (use 'curto' ou 'longo')." }
	end
	if descansosAtivos[character.Id] then
		return { success = false, error = "Você já está descansando." }
	end
	local plrChar = player.Character
	if not plrChar or not plrChar.PrimaryPart or not CombatService.IsInSafeZone(plrChar.PrimaryPart.Position) then
		return { success = false, error = "Precisa estar dentro de uma zona segura (Casa de Descanso) para descansar." }
	end

	local horasNecessarias = tipo == "curto" and SHORT_REST_HOURS or LONG_REST_HOURS
	local inicioHoras = TimeService.GetTotalGameHours()
	descansosAtivos[character.Id] = { tipo = tipo, inicioHoras = inicioHoras, cancelado = false }

	local segundosReais = horasNecessarias * 60 -- 1h de jogo = 60s reais
	task.delay(segundosReais, function()
		local estado = descansosAtivos[character.Id]
		if not estado or estado.cancelado or estado.inicioHoras ~= inicioHoras then
			return
		end
		descansosAtivos[character.Id] = nil
		local relatorio = resolverDescanso(player, character, tipo, periciaEscolhida)
		if RestService.OnRestComplete then
			RestService.OnRestComplete(player, relatorio)
		end
	end)

	return {
		success = true,
		message = "Descanso " .. tipo .. " iniciado (" .. horasNecessarias .. "h de jogo, " .. segundosReais .. "s reais).",
		segundosReais = segundosReais,
	}
end

function RestService.CancelarDescanso(character)
	local estado = descansosAtivos[character.Id]
	if not estado then
		return { success = false, error = "Você não está descansando." }
	end
	estado.cancelado = true
	descansosAtivos[character.Id] = nil
	return { success = true, message = "Descanso cancelado." }
end

return RestService
