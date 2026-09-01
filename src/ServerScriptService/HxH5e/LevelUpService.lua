--[[
    HxH5e LevelUpService (Shared logic, roda no servidor)
    Portado FIELMENTE do webapp (js/views/sheet.js): LEVEL_REWARDS,
    HIT_DICE, calcRDM, e o fluxo de level-up nivel-a-nivel (fila,
    escolha de dado de vida rolado ou media, escolha atributo-ou-aura
    quando ambos aparecem juntos no mesmo nivel).

    ⚠️ DIVERGENCIA achada entre a tabela em markdown do Lucas e o
    codigo REAL do webapp: nivel 3 diz "2 pontos OU 10% de aura" no
    markdown, mas o codigo do webapp usa auraP=5 (5%, nao 10%). Como
    o Lucas pediu pra seguir o que "ja e funcional" no webapp, usei 5%
    aqui -- mas fica registrado pra ele confirmar se e erro de
    digitacao do markdown ou bug do proprio webapp.

    ⚠️ PECULIARIDADE também copiada do webapp: ao ROLAR o dado de
    vida, soma o modificador de CON (+ bonus de Corpo de Gigante). Mas
    ao usar a MEDIA em vez de rolar, o webapp usa "media do dado + 1 +
    bonus de Gigante" -- SEM somar o modificador de CON de verdade.
    Isso pode ser um bug do webapp (esquecimento de somar CON na
    media), mas segui exatamente assim pra bater com o que "ja e
    funcional" la. Fica registrado pro Lucas decidir se corrige.
]]

local LevelUpService = {}

local AchievementService = require(script.Parent:WaitForChild("AchievementService"))

-- ================= Tabela de recompensas por nivel =================
-- attr + auraP ambos > 0 no MESMO nivel = jogador escolhe um dos dois
-- (nunca os dois juntos). pn = Pontos de Nen (soma direto no pool).
-- pi = Pontos de Inclinacao de Combate/Geral (fica pendente pro
-- jogador escolher inclinacoes depois). prof = Pontos de Proficiencia.
local LEVEL_REWARDS = {
	[1]  = { titulo = "Batismo & Despertar",         attr = 1, auraP = 5,  pn = 6, pi = 0, prof = 0, extras = { "Criação de Hatsu(s) e Domínio de Nen" } },
	[2]  = { titulo = "Inclinações & Proficiências",  attr = 0, auraP = 0,  pn = 2, pi = 2, prof = 0, extras = { "Inclinações de Combate/Gerais", "Proficiência em Armas e Equipamentos" } },
	[3]  = { titulo = "Eficiência de Aura 1",         attr = 2, auraP = 5,  pn = 2, pi = 0, prof = 0, extras = { "Eficiência de Aura 1" } },
	[4]  = { titulo = "Foco de Caça & Renome",        attr = 0, auraP = 0,  pn = 2, pi = 3, prof = 0, extras = { "Foco de Caça", "Renome", "Inclinações de Combate/Gerais" } },
	[5]  = { titulo = "+1 Proficiência",               attr = 0, auraP = 0,  pn = 2, pi = 0, prof = 1, extras = { "+1 Ponto de Proficiência" } },
	[6]  = { titulo = "Evolução de Atributos",         attr = 2, auraP = 10, pn = 3, pi = 0, prof = 0, extras = { "Aumento de Atributo ou Aura" } },
	[7]  = { titulo = "Inclinações de Combate",        attr = 0, auraP = 0,  pn = 3, pi = 2, prof = 0, extras = { "Inclinações de Combate ou Gerais" } },
	[8]  = { titulo = "Eficiência de Aura 2",          attr = 0, auraP = 0,  pn = 3, pi = 0, prof = 0, extras = { "Eficiência de Aura 2" } },
	[9]  = { titulo = "Redistribuição de Atributos",   attr = 0, auraP = 0,  pn = 3, pi = 0, prof = 0, extras = { "Redistribuição de Atributos" } },
	[10] = { titulo = "Nen Post-Mortem",               attr = 0, auraP = 0,  pn = 3, pi = 0, prof = 0, extras = { "Nen Post-Mortem (Pós-Morte)", "Eficiência de Aura 3" } },
	[11] = { titulo = "Inclinações de Combate",        attr = 0, auraP = 0,  pn = 3, pi = 3, prof = 0, extras = { "Inclinação de Combate ou Gerais" } },
	[12] = { titulo = "Evolução Final",                attr = 3, auraP = 15, pn = 3, pi = 0, prof = 0, extras = { "Evolução Final" } },
}
LevelUpService.LEVEL_REWARDS = LEVEL_REWARDS

function LevelUpService.GetLevelReward(level)
	return LEVEL_REWARDS[level]
end

-- ================= Dado de vida por CATEGORIA DE NEN (nao raca) =================
local HIT_DICE = {
	["INTENSIFICAÇÃO"] = { faces = 12, media = 7 },
	["TRANSMUTAÇÃO"]   = { faces = 10, media = 6 },
	["EMISSÃO"]         = { faces = 10, media = 6 },
	["MATERIALIZAÇÃO"] = { faces = 8,  media = 5 },
	["MANIPULAÇÃO"]     = { faces = 8,  media = 5 },
	["ESPECIALIZAÇÃO"] = { faces = 6,  media = 4 },
}

local function attrMod(value)
	return math.floor(((value or 10) - 10) / 2)
end

local function hasCorpoDeGigante(character)
	for _, inc in ipairs((character.Inclinations and character.Inclinations.Positive) or {}) do
		if inc.Nome == "Corpo de Gigante" then
			return true
		end
	end
	return false
end

function LevelUpService.GetHitDiceInfo(character)
	local categoria = character.Nen and character.Nen.Category
	local dado = HIT_DICE[categoria] or { faces = 8, media = 5 }
	local giantBonus = hasCorpoDeGigante(character) and 3 or 0
	local conMod = attrMod(character.Attributes.CON.value)
	return {
		faces = dado.faces,
		conMod = conMod,
		giantBonus = giantBonus,
		-- Media EXATAMENTE como o webapp calcula (ver nota de
		-- divergencia no topo do arquivo -- nao usa conMod de verdade).
		media = math.max(1, dado.media + 1 + giantBonus),
	}
end

function LevelUpService.RollHitDie(character)
	local info = LevelUpService.GetHitDiceInfo(character)
	local roll = math.random(1, info.faces)
	local total = math.max(1, roll + info.conMod + info.giantBonus)
	return { roll = roll, total = total, conMod = info.conMod, giantBonus = info.giantBonus, faces = info.faces }
end

function LevelUpService.GetMediaHitDie(character)
	local info = LevelUpService.GetHitDiceInfo(character)
	return { total = info.media, giantBonus = info.giantBonus }
end

-- ================= RDM: Recuperacao de Sanidade a cada nivel =================
function LevelUpService.CalcRDM(character)
	local intMod = attrMod(character.Attributes.INT.value)
	local lvl = character.Level or 0
	if lvl == 0 then
		return 0
	end
	return (intMod * 2) + lvl
end

-- ================= Fila de niveis (ganho de XP so enfileira, nao aplica) =================
-- Identico ao webapp: multiplicador de genialidade (Ultimate=2x,
-- Genio=1.5x), depois avanca niveis enquanto XP >= XPNext, empilhando
-- em character.PendingLevelUps SEM aplicar nada ainda -- cada nivel
-- so e efetivado quando o jogador confirmar (ConfirmLevelUp), pra dar
-- tempo de escolher dado de vida e atributo/aura nivel a nivel.
local XP_PARA_PROXIMO = {
	[0] = 50, [1] = 150, [2] = 350, [3] = 500, [4] = 800,
	[5] = 1000, [6] = 1500, [7] = 2500, [8] = 3200, [9] = 4000,
	[10] = 5000, [11] = 6500, [12] = nil,
}
LevelUpService.XP_PARA_PROXIMO = XP_PARA_PROXIMO

function LevelUpService.QueueLevelUps(character, amount)
	amount = tonumber(amount) or 0
	if amount <= 0 then
		return { success = false, error = "Valor de XP inválido." }
	end
	local genTier = character.Nen and character.Nen.Genius and character.Nen.Genius.Tier
	local mult = (genTier == "Ultimate") and 2 or ((genTier == "Genio") and 1.5 or 1)
	local ganhoFinal = mult > 1 and math.floor(amount * mult) or amount

	character.XP = (character.XP or 0) + ganhoFinal
	local curLevel = character.Level or 0
	local proximoXp = character.XPNext or XP_PARA_PROXIMO[curLevel] or 50
	local niveis = character.PendingLevelUps or {}

	while character.XP >= proximoXp and curLevel < 12 do
		character.XP = character.XP - proximoXp
		curLevel = curLevel + 1
		table.insert(niveis, curLevel)
		proximoXp = XP_PARA_PROXIMO[curLevel] or 9999
	end

	character.PendingLevelUps = niveis
	character.XPNext = proximoXp

	return {
		success = true,
		ganho = ganhoFinal,
		multiplicador = mult,
		niveisEnfileirados = niveis,
		xpAtual = character.XP,
		xpProximoNivel = proximoXp,
	}
end

-- Retorna os dados do PROXIMO nivel pendente na fila (sem remove-lo),
-- pro cliente montar a tela de level-up (dado de vida, escolha
-- atributo/aura etc). nil se nao ha nada pendente.
function LevelUpService.GetNextPendingLevel(character)
	local fila = character.PendingLevelUps
	if not fila or #fila == 0 then
		return nil
	end
	local proximoNivel = fila[1]
	local rewards = LEVEL_REWARDS[proximoNivel]
	local isAttrChoice = rewards and rewards.attr > 0 and rewards.auraP > 0
	return {
		nivel = proximoNivel,
		restantesNaFila = #fila,
		rewards = rewards,
		isAttrChoice = isAttrChoice,
		hitDiceInfo = LevelUpService.GetHitDiceInfo(character),
	}
end

-- Aplica de fato o PROXIMO nivel da fila. hitGain = quanto de PV
-- ganhar (resultado de RollHitDie ou GetMediaHitDie, ja escolhido
-- pelo jogador). attrChoice = "attr" ou "aura" (obrigatorio SE
-- isAttrChoice for true pro nivel em questao; ignorado senao).
function LevelUpService.ConfirmLevelUp(character, hitGain, attrChoice)
	local fila = character.PendingLevelUps
	if not fila or #fila == 0 then
		return { success = false, error = "Não há nível pendente para confirmar." }
	end
	local nivel = table.remove(fila, 1)
	character.PendingLevelUps = fila
	local rewards = LEVEL_REWARDS[nivel]
	if not rewards then
		return { success = false, error = "Nível " .. nivel .. " sem recompensa definida." }
	end

	if type(hitGain) ~= "number" or hitGain < 1 then
		return { success = false, error = "Ganho de PV inválido." }
	end

	local isAttrChoice = rewards.attr > 0 and rewards.auraP > 0
	if isAttrChoice and attrChoice ~= "attr" and attrChoice ~= "aura" then
		return { success = false, error = "Escolha 'attr' ou 'aura' para este nível." }
	end

	character.Level = nivel

	-- Atributo pendente OU aura direto
	if isAttrChoice then
		if attrChoice == "aura" then
			character.Vitals.Aura.Max = (character.Vitals.Aura.Max or 100) + rewards.auraP
		else
			character.PendingAttrPoints = (character.PendingAttrPoints or 0) + rewards.attr
		end
	elseif rewards.attr and rewards.attr > 0 then
		character.PendingAttrPoints = (character.PendingAttrPoints or 0) + rewards.attr
	end

	-- P.N (Pontos de Nen): NAO soma nada aqui de proposito. O pool de
	-- P.N e SEMPRE recalculado puro a partir de character.Level (ver
	-- NenService.getPHBase / PN_POR_NIVEL) -- e compartilhado entre
	-- Dominio de Nen e Hatsus. Subir de nivel (character.Level = nivel,
	-- linha acima) ja e suficiente pra atualizar o pool sozinho.
	-- rewards.pn so serve de TEXTO informativo na mensagem de retorno
	-- (quanto o pool tende a aumentar nesse nivel especifico -- pode
	-- nao bater 100% pois o proprio webapp tem uma queda conhecida no
	-- nivel 6, documentada em NenService.lua).

	-- P.I (Pontos de Inclinacao) -- fica pendente pro jogador escolher
	if rewards.pi and rewards.pi > 0 then
		character.PendingInclinationPoints = (character.PendingInclinationPoints or 0) + rewards.pi
	end

	-- Proficiencia -- fica pendente (nivel 5, sempre +1)
	if rewards.prof and rewards.prof > 0 then
		character.PendingProficiencyPoints = (character.PendingProficiencyPoints or 0) + rewards.prof
	end

	-- PV: soma no maximo e no atual
	character.Vitals.HP.Max = (character.Vitals.HP.Max or 0) + hitGain
	character.Vitals.HP.Current = (character.Vitals.HP.Current or 0) + hitGain

	-- RDM: recupera sanidade automaticamente
	local rdm = LevelUpService.CalcRDM(character)
	if rdm > 0 then
		character.Vitals.Sanidade.Current = math.min(character.Vitals.Sanidade.Max or 100, (character.Vitals.Sanidade.Current or 100) + rdm)
	end

	character.UpdatedAt = os.time()

	local conquistas = AchievementService.CheckAllLiveAchievements(character)

	return {
		success = true,
		nivel = nivel,
		titulo = rewards.titulo,
		pvGanho = hitGain,
		rdmGanho = rdm,
		restantesNaFila = #fila,
		conquistas = conquistas,
		message = "Nível " .. nivel .. "! +" .. hitGain .. " PV" .. (rdm > 0 and (" | +" .. rdm .. " SAN") or "") .. (rewards.pn > 0 and (" | +" .. rewards.pn .. " P.N") or ""),
	}
end

return LevelUpService
