--[[
    HxH5e NenService (M1.3 — Princípios Avançados)
    Domínio de Nen completo: Fundamentais (Ten/Ren/Zetsu 0-3)
    + Avançados (En/In/Gyo/Shu/Ken/Ko/Ryu) com regra de desbloqueio.
    Pool de P.N por nível (tabela de evolução do Manual de Hatsus).
]]

local NenService = {}

-- ================= Pool de P.N por nível (fonte: Manual de Hatsus) =================
local PN_POR_NIVEL = {
	[0] = 0, [1] = 6, [2] = 8, [3] = 10, [4] = 12, [5] = 14,
	[6] = 17, [7] = 20, [8] = 23, [9] = 26, [10] = 29, [11] = 32, [12] = 35,
}

local function getPHBase(character)
	local level = character and character.Level or 0
	return PN_POR_NIVEL[level] or 35
end

-- ================= Config =================

local PRINCIPLE_COST = {
	Ten = 0, Ren = 10, Zetsu = 0,
	En = 5, Inp = 10, Gyo = 5, Shu = 5, Ken = 30, Ko = 30, Ryu = 15,
}

local ADVANCED_KEYS = { "En", "Inp", "Gyo", "Shu", "Ken", "Ko", "Ryu" }

-- Regra de desbloqueio (app)
local ADVANCED_REQUIREMENTS = {
	En = "Zetsu", Inp = "Zetsu", Gyo = "Zetsu",
	Shu = "Ren", Ken = "Ren",
	Ko = "Ken", Ryu = "Ken",
}

local FUNDAMENTALS = { Ten = 3, Ren = 3, Zetsu = 3 }

local function getDominio(character)
	local nen = character and character.Nen or {}
	if type(nen.Dominio) ~= "table" then
		nen.Dominio = {}
	end
	return nen.Dominio
end

-- ================= Cálculos =================

function NenService.CalcTenRD(character)
	local d = getDominio(character)
	local lvl = d.Ten or 0
	if lvl == 0 then return 0 end
	local base = lvl == 1 and 2 or (lvl == 2 and 4 or 6)
	local extra = lvl == 3 and math.min(7, d.Ten_pn or 0) or 0
	return base + extra
end

function NenService.CalcRenBonus(character)
	local d = getDominio(character)
	local lvl = d.Ren or 0
	if lvl == 0 then
		return { grau = 0, teste = 0, teste1x = 0, freeUso = false, opcao = 1, extra = 0 }
	end
	local opcao = d.Ren_opcao or 1
	local extra = lvl == 3 and math.min(7, d.Ren_pn or 0) or 0
	local bonus = { grau = 1, teste = 0, teste1x = 0, freeUso = (lvl >= 3), opcao = opcao, extra = extra }
	if lvl >= 2 then bonus.teste = 3 end
	if lvl >= 3 then bonus.teste1x = 6 end
	if extra > 0 then
		if opcao == 1 then
			bonus.grau = bonus.grau + extra
		else
			bonus.teste = bonus.teste + extra
			bonus.teste1x = bonus.teste1x + extra
		end
	end
	return bonus
end

function NenService.CalcZetsuBonus(character)
	local d = getDominio(character)
	local lvl = d.Zetsu or 0
	if lvl == 0 then
		return { auraPct = 0, furtividade = 0, reacoes = 0, rodadas = 0, opcao = 1, extra = 0 }
	end
	local opcao = d.Zetsu_opcao or 1
	local extra = lvl == 3 and math.min(7, d.Zetsu_pn or 0) or 0
	local base
	if lvl == 1 then
		base = { auraPct = 5, furtividade = 3, reacoes = 1, rodadas = 3 }
	elseif lvl == 2 then
		base = { auraPct = 10, furtividade = 3, reacoes = 1, rodadas = 2 }
	else
		base = { auraPct = 10, furtividade = 6, reacoes = 2, rodadas = 1 }
	end
	if extra > 0 then
		if opcao == 1 then
			base.auraPct = base.auraPct + math.floor(extra / 2) * 5
		else
			base.furtividade = base.furtividade + extra
		end
	end
	base.opcao = opcao
	base.extra = extra
	return base
end

function NenService.CalcAdvancedBonus(character, key)
	local d = getDominio(character)
	local active = not not d[key]
	local sup = active and not not d[key .. "_sup"]
	local extra = sup and math.min(8, d[key .. "_pn"] or 0) or 0
	local opcao = d[key .. "_opcao"] or 1
	local out = { active = active, sup = sup, extra = extra, opcao = opcao }
	if key == "En" then
		out.diametro = (sup and 6 or 3) + (opcao == 2 and extra * 1.5 or 0)
		out.reacoes = opcao == 1 and math.max(1, 2 - extra) or 2
	elseif key == "Inp" then
		out.rodadas = (sup and 2 or 1) + math.floor(extra / 2)
	elseif key == "Gyo" then
		out.attrBonus = 3 + math.floor(extra / 2)
	elseif key == "Shu" then
		out.rodadas = 1 + extra
	elseif key == "Ken" then
		out.auraCusto = opcao == 1 and math.max(5, 30 - extra * 5) or 30
		out.reacoes = opcao == 2 and math.max(1, 4 - extra) or 4
	elseif key == "Ko" then
		out.caBonus = math.floor(extra / 2)
	elseif key == "Ryu" then
		out.tabelaBonus = math.floor(extra / 2)
	end
	return out
end

-- ================= Pool de P.N =================

function NenService.CalcPNSpentInDominio(character)
	local d = getDominio(character)
	local spent = 0
	spent = spent + (d.Ten or 0) + ((d.Ten == 3) and math.min(7, d.Ten_pn or 0) or 0)
	spent = spent + (d.Ren or 0) + ((d.Ren == 3) and math.min(7, d.Ren_pn or 0) or 0)
	spent = spent + (d.Zetsu or 0) + ((d.Zetsu == 3) and math.min(7, d.Zetsu_pn or 0) or 0)
	for _, key in ipairs(ADVANCED_KEYS) do
		if d[key] then
			spent = spent + 1
			if d[key .. "_sup"] then
				spent = spent + 1 + math.min(8, d[key .. "_pn"] or 0)
			end
		end
	end
	return spent
end

function NenService.CalcPNDisponivel(character)
	local total = getPHBase(character)
	local dominio = NenService.CalcPNSpentInDominio(character)
	return math.max(0, total - dominio)
end

-- ================= Treino de Princípio =================

function NenService.TrainPrinciple(character, principle)
	if type(character) ~= "table" or type(principle) ~= "string" then
		return { success = false, error = "Parâmetros inválidos." }
	end
	local d = getDominio(character)

	if FUNDAMENTALS[principle] then
		local current = d[principle] or 0
		if current >= 3 then
			return { success = false, error = "Maestria já alcançada em " .. principle .. "." }
		end
		if NenService.CalcPNDisponivel(character) < 1 then
			return { success = false, error = "Sem P.N disponível." }
		end
		d[principle] = current + 1
		character.UpdatedAt = os.time()
		return { success = true, message = principle .. " agora é nível " .. tostring(d[principle]) .. "." }
	end

	for _, key in ipairs(ADVANCED_KEYS) do
		if principle == key then
			local reqKey = ADVANCED_REQUIREMENTS[key]
			if reqKey then
				local reqMet
				if FUNDAMENTALS[reqKey] then
					reqMet = (d[reqKey] or 0) >= 2
				else
					reqMet = not not d[reqKey]
				end
				if not reqMet then
					return { success = false, error = "Requer " .. reqKey .. " nível 2 (ou desbloqueado)." }
				end
			end
			if d[key] then
				return { success = false, error = key .. " já está desbloqueado." }
			end
			if NenService.CalcPNDisponivel(character) < 1 then
				return { success = false, error = "Sem P.N disponível." }
			end
			d[key] = true
			character.UpdatedAt = os.time()
			return { success = true, message = key .. " desbloqueado!" }
		end
	end

	return { success = false, error = "Princípio desconhecido: " .. tostring(principle) }
end

-- ================= Ativação de Princípio =================

local activeBuffs = {}

function NenService.GetNenStatus(character)
	local advanced = {}
	for _, key in ipairs(ADVANCED_KEYS) do
		advanced[key] = NenService.CalcAdvancedBonus(character, key)
	end
	return {
		Category = character.Nen and character.Nen.Category or character.Class,
		Affinity = character.Nen and character.Nen.Affinity,
		Genius = character.Nen and character.Nen.Genius,
		Dominio = getDominio(character),
		PNDisponivel = NenService.CalcPNDisponivel(character),
		Bonus = {
			Ten = NenService.CalcTenRD(character),
			Ren = NenService.CalcRenBonus(character),
			Zetsu = NenService.CalcZetsuBonus(character),
			Advanced = advanced,
		},
	}
end

function NenService.ActivatePrinciple(player, character, principle)
	if type(principle) ~= "string" then
		return { success = false, error = "Princípio inválido." }
	end
	local cost = PRINCIPLE_COST[principle]
	if not cost then
		return { success = false, error = "Princípio desconhecido." }
	end
	local d = getDominio(character)

	if FUNDAMENTALS[principle] then
		if (d[principle] or 0) < 1 then
			return { success = false, error = "Você ainda não treinou " .. principle .. "." }
		end
	else
		if not d[principle] then
			return { success = false, error = "Você ainda não desbloqueou " .. principle .. "." }
		end
	end

	local aura = character.Vitals and character.Vitals.Aura
	if type(aura) ~= "table" then
		return { success = false, error = "Personagem sem Vitals." }
	end
	local auraMax = aura.Max or 100
	local custoPct = cost
	if principle == "Ken" and (d.Ken_opcao or 1) == 1 then
		custoPct = math.max(5, 30 - (d.Ken_pn or 0) * 5)
	end
	local custoReal = math.floor(auraMax * custoPct / 100)
	if (aura.Current or 0) < custoReal then
		return { success = false, error = "Aura insuficiente (custa " .. custoPct .. "% = " .. custoReal .. ")." }
	end
	aura.Current = aura.Current - custoReal

	if principle == "Zetsu" then
		local z = NenService.CalcZetsuBonus(character)
		local rec = math.floor(auraMax * z.auraPct / 100)
		aura.Current = math.min(aura.Max, aura.Current + rec)
		return {
			success = true,
			message = "Zetsu: +" .. rec .. " de aura recuperada (+" .. z.auraPct .. "%).",
			aura = aura.Current,
		}
	end

	local buffs = activeBuffs[player]
	if not buffs then
		buffs = {}
		activeBuffs[player] = buffs
	end
	buffs[principle] = os.clock() + 6

	local message = principle .. " ativado por 6s (-" .. custoPct .. "% de aura)."
	if principle == "Ten" then
		message = "TEN ativado: +" .. NenService.CalcTenRD(character) .. " RD por 6s."
	elseif principle == "Ren" then
		local r = NenService.CalcRenBonus(character)
		message = "REN ativado: próximo ataque +" .. r.grau .. " Grau(s) de dano."
	elseif principle == "En" then
		local a = NenService.CalcAdvancedBonus(character, "En")
		message = "EN ativado: detecta em " .. a.diametro .. "m por 6s."
	elseif principle == "Inp" then
		message = "IN ativado: oculta objeto de aura por 6s."
	elseif principle == "Gyo" then
		local a = NenService.CalcAdvancedBonus(character, "Gyo")
		message = "GYO ativado: +" .. a.attrBonus .. " FOR/DES/CON por 6s."
	elseif principle == "Shu" then
		message = "SHU ativado: objeto envolto +1d4 dano/CA por 6s."
	elseif principle == "Ken" then
		message = "KEN ativado: defesa máxima por 6s."
	elseif principle == "Ko" then
		message = "KO ativado: próximo golpe dano x3 (CA -80%)."
	elseif principle == "Ryu" then
		message = "RYU ativado: fluidez de aura por 6s."
	end

	return { success = true, message = message, aura = aura.Current }
end

function NenService.ClearSession(player)
	activeBuffs[player] = nil
end

return NenService