--[[
    HxH5e NenService (M1.3 — Princípios Avançados)
    Domínio de Nen completo: Fundamentais (Ten/Ren/Zetsu 0-3)
    + Avançados (En/In/Gyo/Shu/Ken/Ko/Ryu) com regra de desbloqueio.

    Pool de P.N: CONFIRMADO no código-fonte do webapp (calcularPHBase em
    transmutacao-db.js) que Domínio de Nen e Hatsus COMPARTILHAM a MESMA
    reserva de P.N por nível — não são dois "baldes" separados. Gastar em
    Ten/Ren/Zetsu reduz o que sobra pra Hatsu, e vice-versa. A tabela abaixo
    é cópia exata do webapp (inclusive a queda no nível 6, que existe assim
    no código original).
]]

local NenService = {}

local AchievementService = require(script.Parent:WaitForChild("AchievementService"))

-- ================= Pool de P.N por nível (identico a calcularPHBase do webapp) =================
-- Nivel 0 tratado como 1 (webapp usa "parseInt(level) || 1", e 0 e falsy em JS).
local PN_POR_NIVEL = {
	[1] = 6, [2] = 8, [3] = 10, [4] = 12, [5] = 14,
	[6] = 7, [7] = 10, [8] = 13, [9] = 16, [10] = 19, [11] = 22, [12] = 25,
}

-- CORRIGIDO em relação ao webapp: no nível 0 o personagem ainda NÃO
-- despertou o Nen ("Batismo e Despertar" só acontece no nível 1, confirmado
-- na tabela de progressão do Manual: coluna "Ponto de Domínio de NEN" no
-- nível 0 é "-"). O webapp tem um bug de JS aqui (parseInt(level)||1 trata
-- nível 0 como se fosse nível 1, por 0 ser "falsy"), dando P.N indevido a
-- quem ainda não despertou. Corrigido: nível 0 = 0 P.N, sem exceção.
local function getPHBase(character)
	local level = (character and character.Level) or 0
	if level < 1 then
		return 0
	end
	if level > 12 then
		level = 12
	end
	return PN_POR_NIVEL[level] or 25
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
	return NenService.CalcPNDisponivelParaHatsu(character, nil)
end

-- Soma o PNUsados de todos os Hatsus do personagem, exceto o de excludeHatsuId
-- (usado na edicao, pra reaproveitar o P.N que o proprio Hatsu ja ocupava —
-- identico a calcPNSpentInOtherHatsus(char, editingIdx) do webapp).
function NenService.CalcPNSpentInHatsus(character, excludeHatsuId)
	local spent = 0
	for _, h in ipairs(character.Hatsus or {}) do
		if h.Id ~= excludeHatsuId then
			spent = spent + (h.PNUsados or 0)
		end
	end
	return spent
end

-- P.N disponivel para criar/editar um Hatsu: reserva total do nivel, menos o
-- que ja foi gasto em Dominio, menos o que os OUTROS Hatsus ja usam.
-- Identico a calcPNDisponivelParaHatsu(char, editingIdx) do webapp.
function NenService.CalcPNDisponivelParaHatsu(character, excludeHatsuId)
	local total = getPHBase(character)
	local dominio = NenService.CalcPNSpentInDominio(character)
	local outrosHatsus = NenService.CalcPNSpentInHatsus(character, excludeHatsuId)
	return math.max(0, total - dominio - outrosHatsus)
end

-- ================= Treino de Princípio =================

function NenService.TrainPrinciple(character, principle)
	if type(character) ~= "table" or type(principle) ~= "string" then
		return { success = false, error = "Parâmetros inválidos." }
	end
	if (character.Level or 0) < 1 then
		return { success = false, error = "Nen ainda não foi despertado. Isso só acontece a partir do nível 1 (Batismo e Despertar)." }
	end
	local d = getDominio(character)

	if FUNDAMENTALS[principle] then
		local current = d[principle] or 0
		if current < 3 then
			if NenService.CalcPNDisponivel(character) < 1 then
				return { success = false, error = "Sem P.N disponível." }
			end
			d[principle] = current + 1
			character.UpdatedAt = os.time()
			local conquistas = AchievementService.CheckAllLiveAchievements(character)
			return { success = true, message = principle .. " agora é nível " .. tostring(d[principle]) .. ".", conquistas = conquistas }
		end
		-- Aprimoramento pos-Maestria (livro "Atualizacoes Principios e
		-- Tecnicas"): apos a Maestria (grau 3), cada P.N investido a
		-- mais escala o efeito continuamente, ate o maximo de 10 P.N
		-- aplicaveis no total (ou seja, +7 alem dos 3 da Maestria). Os
		-- calculos ja existiam (NenService.CalcTenRD/CalcRenBonus/
		-- CalcZetsuBonus), so faltava permitir continuar investindo.
		local pnKey = principle .. "_pn"
		local pnAtual = d[pnKey] or 0
		if pnAtual >= 7 then
			return { success = false, error = principle .. " já está no máximo de Aprimoramento (10 P.N no total, 3 da Maestria + 7 investidos)." }
		end
		if NenService.CalcPNDisponivel(character) < 1 then
			return { success = false, error = "Sem P.N disponível." }
		end
		d[pnKey] = pnAtual + 1
		character.UpdatedAt = os.time()
		local conquistas = AchievementService.CheckAllLiveAchievements(character)
		return { success = true, message = principle .. " aprimorado: +" .. tostring(d[pnKey]) .. " P.N além da Maestria.", conquistas = conquistas }
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
			local conquistas = AchievementService.CheckAllLiveAchievements(character)
			return { success = true, message = key .. " desbloqueado!", conquistas = conquistas }
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

	-- Contadores de ativacao pras conquistas "Ten/Ren/Zetsu Nx vezes"
	-- (ver AchievementsDB.lua) -- so ATIVACAO conta aqui, treinar/subir
	-- de grau e outra coisa (ja coberto em TrainPrinciple).
	local conquistaAtivacao = nil
	if principle == "Ten" then
		local r = AchievementService.IncrementCounter(character, "TenAtivacoes", "ten_20x")
		if r.isNew then conquistaAtivacao = r.achievement end
	elseif principle == "Ren" then
		local r = AchievementService.IncrementCounter(character, "RenAtivacoes", "ren_20x")
		if r.isNew then conquistaAtivacao = r.achievement end
	elseif principle == "Zetsu" then
		local r = AchievementService.IncrementCounter(character, "ZetsuAtivacoes", "zetsu_10x")
		if r.isNew then conquistaAtivacao = r.achievement end
	end

	if principle == "Zetsu" then
		local z = NenService.CalcZetsuBonus(character)
		local rec = math.floor(auraMax * z.auraPct / 100)
		aura.Current = math.min(aura.Max, aura.Current + rec)
		-- Entra em modo Zetsu CONTINUO (nao e mais so um efeito pontual):
		-- fica assim ate ativar outro principio de Nen (ver abaixo, todo
		-- outro principio sai do Zetsu automaticamente -- fisicamente
		-- nao da pra manter aura zerada e usar outro principio ao mesmo
		-- tempo). Usado por HatsuService.ActivateHatsu pra bloquear
		-- ativacao de Hatsu enquanto em Zetsu.
		character.EmZetsu = true
		return {
			success = true,
			message = "Zetsu: +" .. rec .. " de aura recuperada (+" .. z.auraPct .. "%). Voce fica vulneravel: Hatsu bloqueado ate sair do Zetsu.",
			aura = aura.Current,
			conquista = conquistaAtivacao,
		}
	end

	-- Qualquer OUTRO principio de Nen tira automaticamente do modo Zetsu.
	character.EmZetsu = false

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

	return { success = true, message = message, aura = aura.Current, conquista = conquistaAtivacao }
end

function NenService.ClearSession(player)
	activeBuffs[player] = nil
end

return NenService
