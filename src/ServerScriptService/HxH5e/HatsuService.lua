--[[
    HxH5e HatsuService v6 (portado do webapp — dados reais)
    Diferenca da v5: nao tem mais tabelas digitadas a mao. Efeitos e
    restricoes vem de ReplicatedStorage.HxH5e.Shared.HatsuDB (porta fiel
    de js/data/hatsu-db.js do repo Criadores-HxH-5e/Ficha_HxH5e).

    Simplificacoes conhecidas em relacao ao webapp (documentadas no
    CLAUDE.md como pendencia, nao bloqueiam testes basicos):
    - Pre-requisito de efeito (ex.: "Nivel 2 - Recuperacao Veloz" exige
      TER comprado Recuperacao Veloz antes) so valida o NUMERO do nivel,
      nao o efeito-pre-requisito textual.
    - "Nivel 5 ou Acesso a Reforco" (Dano/Cura Focal) so valida o numero.
    - Sistema de acesso cruzado entre categorias (calcCategoryAccess do
      webapp, tabela 100/80/60/40% por afinidade) ainda nao implementado;
      hoje so processamos a categoria INTENSIFICACAO (Reforco) a 100%.
    - Fatores de repetivel/maxUsos (comprar o mesmo efeito 2x) ainda nao
      tem UI no wizard do Roblox.

    Fonte de verdade: o webapp. Ao atualizar hatsu-db.js, re-rodar o
    pipeline (fetch HTTP + parser JS->Lua) para atualizar o HatsuDB e
    nada aqui precisa mudar, a menos que os IDs hardcoded em
    ActivateHatsu (efeitos com comportamento especial) sejam renomeados
    no webapp.
]]

local HatsuService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HatsuDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("HatsuDB"))
local NenService = require(script.Parent:WaitForChild("NenService"))

--------------------------------------------------
-- P.N PURO POR PESO (confirmado identico ao webapp: hatsu-creator.js linha ~105
-- const PURE_PN = { leve:1, moderada:2, pesada:3, extrema:4 }; sem 'variavel'.)
--------------------------------------------------
local PURE_PN = {
	leve = 1,
	moderada = 2,
	pesada = 3,
	extrema = 4,
}

local CATEGORIA_ID = "INTENSIFICAÇÃO"
local CATEGORIA_LABEL = "Reforço"

-- "Nível 2 — Recuperação Veloz" -> 2 ; "Nível 5 ou Acesso a Reforço" -> 5
local function parseNivel(req)
	if type(req) ~= "string" then
		return 1
	end
	local n = req:match("(%d+)")
	return tonumber(n) or 1
end

-- Divide o campo bnf em alternativas quando contem " ou "/" Ou "/" OU "
local function splitBeneficios(bnf)
	if type(bnf) ~= "string" or #bnf == 0 then
		return {}
	end
	local partes = {}
	local resto = bnf
	while true do
		local s, e = resto:find("%s[Oo][Uu]%s")
		if not s then
			table.insert(partes, resto)
			break
		end
		table.insert(partes, resto:sub(1, s - 1))
		resto = resto:sub(e + 1)
	end
	return partes
end

local function buildEffects()
	local all = {}
	for _, e in ipairs(HatsuDB.efeitos_gerais) do
		table.insert(all, {
			id = e.id,
			nome = e.nome,
			grupo = "Gerais",
			nivel = parseNivel(e.req),
			custo = e.pn,
			desc = e.desc,
			req = e.req,
			repetivel = e.repetivel or false,
		})
	end
	local cat = HatsuDB.categorias[CATEGORIA_ID]
	for _, e in ipairs(cat.efeitos) do
		table.insert(all, {
			id = e.id,
			nome = e.nome,
			grupo = CATEGORIA_LABEL,
			nivel = parseNivel(e.req),
			custo = e.pn,
			desc = e.desc,
			req = e.req,
			repetivel = e.repetivel or false,
		})
	end
	return all
end

local PESO_KEY_MAP = {
	leves = "leve",
	moderadas = "moderada",
	pesadas = "pesada",
	variaveis = "variavel",
	extremas = "extrema",
}

local function buildRestrictions()
	local all = {}
	for dbKey, peso in pairs(PESO_KEY_MAP) do
		for _, r in ipairs(HatsuDB.restricoes_gerais[dbKey]) do
			table.insert(all, {
				id = r.id,
				nome = r.nome,
				peso = peso,
				pura = PURE_PN[peso],
				descricao = r.desc,
				beneficios = splitBeneficios(r.bnf),
				lore = r.lore,
			})
		end
	end
	local cat = HatsuDB.categorias[CATEGORIA_ID]
	for _, r in ipairs(cat.restricoes) do
		table.insert(all, {
			id = r.id,
			nome = r.nome,
			peso = r.peso,
			pura = PURE_PN[r.peso],
			categoria = CATEGORIA_LABEL,
			descricao = r.desc,
			beneficios = splitBeneficios(r.bnf),
		})
	end
	return all
end

local ALL_EFFECTS = buildEffects()
local RESTRICTIONS = buildRestrictions()

local function findEffect(id)
	for _, e in ipairs(ALL_EFFECTS) do
		if e.id == id then
			return e
		end
	end
	return nil
end

local function findRestriction(id)
	for _, r in ipairs(RESTRICTIONS) do
		if r.id == id then
			return r
		end
	end
	return nil
end

function HatsuService.GetCatalog(character, excludeHatsuId)
	local pnDisponivel = 0
	if character then
		pnDisponivel = NenService.CalcPNDisponivelParaHatsu(character, excludeHatsuId)
	end
	return {
		effects = ALL_EFFECTS,
		restrictions = RESTRICTIONS,
		purePN = PURE_PN,
		pnDisponivel = pnDisponivel,
	}
end

local function getAttributeMod(character, attr)
	local attrs = character.Attributes or {}
	local val = (attrs[attr] and attrs[attr].value) or 10
	return math.floor((val - 10) / 2)
end

function HatsuService.CalcTR(character, efeitos, restricoes)
	local level = character.Level or 1
	local base = 8 + math.max(1, math.floor(level / 2))
	local mod = getAttributeMod(character, "FOR")

	local efeitoBonus = 0
	for _, e in ipairs(efeitos or {}) do
		efeitoBonus = efeitoBonus + (e.trBonus or 0)
	end
	local restricaoBonus = 0
	for _, r in ipairs(restricoes or {}) do
		restricaoBonus = restricaoBonus + (r.trBonus or 0)
	end

	return {
		total = base + mod + efeitoBonus + restricaoBonus,
		base = base,
		atributo = mod,
		efeitos = efeitoBonus,
		restricoes = restricaoBonus,
	}
end

local function calcCustoAura(efeitosEscolhidos, restricoesAplicadas)
	local custo = 50
	local temExtrema = false
	local pesadas = 0

	for _, r in ipairs(restricoesAplicadas) do
		if r.peso == "extrema" then
			temExtrema = true
		elseif r.peso == "pesada" then
			pesadas = pesadas + 1
		end
	end

	for _, e in ipairs(efeitosEscolhidos) do
		if e.id == "eg8" then
			custo = custo - 5
		elseif e.id == "ri_e18" then
			custo = custo - 15
		end
	end

	if temExtrema then
		custo = custo - 25
	elseif pesadas >= 2 then
		custo = custo - 10
	end

	return math.max(5, custo)
end

local function detectarNatureza(efeitos)
	for _, eid in ipairs(efeitos or {}) do
		if eid == "eg15" then
			return "Hostil"
		end
	end
	return "Versatil"
end

function HatsuService.CreateHatsuV2(character, build)
	if (character and character.Level or 0) < 1 then
		return { success = false, error = "Nen ainda não foi despertado. Hatsus só podem ser criados a partir do nível 1 (Batismo e Despertar)." }
	end
	if not build or not build.nome or #build.nome == 0 then
		return { success = false, error = "Nome do Hatsu é obrigatório." }
	end
	if not build.efeitos or #build.efeitos == 0 then
		return { success = false, error = "Selecione pelo menos um efeito." }
	end

	local pnDisponivel = NenService.CalcPNDisponivelParaHatsu(character, nil)
	local custoTotal = 0
	local efeitosEscolhidos = {}

	for _, eid in ipairs(build.efeitos) do
		local efeito = findEffect(eid)
		if not efeito then
			return { success = false, error = "Efeito desconhecido: " .. tostring(eid) }
		end
		custoTotal = custoTotal + efeito.custo
		table.insert(efeitosEscolhidos, { id = efeito.id, nome = efeito.nome, custo = efeito.custo, trBonus = efeito.trBonus or 0 })
	end

	local pnRestaurado = 0
	local restricoesAplicadas = {}
	for _, r in ipairs(build.restricoes or {}) do
		local restr = findRestriction(r.id)
		if not restr then
			return { success = false, error = "Restrição desconhecida: " .. tostring(r.id) }
		end
		local pura = r.pura or false
		local ganho = 0
		if pura and restr.pura then
			ganho = restr.pura
			pnRestaurado = pnRestaurado + ganho
		end
		table.insert(restricoesAplicadas, {
			id = restr.id, nome = restr.nome, peso = restr.peso, pura = pura, ganho = ganho, trBonus = restr.trBonus or 0,
		})
	end

	local custoLiquido = math.max(0, custoTotal - pnRestaurado)
	if custoLiquido > pnDisponivel then
		return {
			success = false,
			error = "P.N insuficiente. Custo: " .. custoLiquido
				.. " (efeitos " .. custoTotal .. " - restrições " .. pnRestaurado .. "), disponível: " .. pnDisponivel,
		}
	end

	local custoAura = calcCustoAura(efeitosEscolhidos, restricoesAplicadas)
	local tr = HatsuService.CalcTR(character, efeitosEscolhidos, restricoesAplicadas)

	local hatsu = {
		Id = HatsuService.NextId(character),
		Nome = build.nome,
		Tipo = CATEGORIA_LABEL,
		Natureza = detectarNatureza(build.efeitos),
		Efeitos = efeitosEscolhidos,
		Restricoes = restricoesAplicadas,
		Graus = { Dano = 0 },
		CustoAura = custoAura,
		TR = tr.total,
		PNUsados = custoLiquido,
		Ativo = false,
	}
	table.insert(character.Hatsus, hatsu)

	local pnRestante = NenService.CalcPNDisponivelParaHatsu(character, nil)
	return {
		success = true,
		hatsu = hatsu,
		message = "Hatsu criado! Efeitos: " .. custoTotal .. " - Restrições: " .. pnRestaurado
			.. " = " .. custoLiquido .. " P.N. Restante: " .. tostring(pnRestante)
			.. ". Custo de aura: " .. custoAura .. "%. TR: " .. tr.total,
	}
end

function HatsuService.EditHatsu(character, hatsuId, build)
	local hatsu
	local index
	for i, h in ipairs(character.Hatsus or {}) do
		if h.Id == hatsuId then
			hatsu = h
			index = i
			break
		end
	end
	if not hatsu then
		return { success = false, error = "Hatsu não encontrado." }
	end
	if not build or not build.nome or #build.nome == 0 then
		return { success = false, error = "Nome do Hatsu é obrigatório." }
	end
	if not build.efeitos or #build.efeitos == 0 then
		return { success = false, error = "Selecione pelo menos um efeito." }
	end

	local pnDisponivel = NenService.CalcPNDisponivelParaHatsu(character, hatsuId)
	local custoTotal = 0
	local efeitosEscolhidos = {}
	for _, eid in ipairs(build.efeitos) do
		local efeito = findEffect(eid)
		if not efeito then
			return { success = false, error = "Efeito desconhecido: " .. tostring(eid) }
		end
		custoTotal = custoTotal + efeito.custo
		table.insert(efeitosEscolhidos, { id = efeito.id, nome = efeito.nome, custo = efeito.custo, trBonus = efeito.trBonus or 0 })
	end

	local pnRestaurado = 0
	local restricoesAplicadas = {}
	for _, r in ipairs(build.restricoes or {}) do
		local restr = findRestriction(r.id)
		if not restr then
			return { success = false, error = "Restrição desconhecida: " .. tostring(r.id) }
		end
		local pura = r.pura or false
		local ganho = 0
		if pura and restr.pura then
			ganho = restr.pura
			pnRestaurado = pnRestaurado + ganho
		end
		table.insert(restricoesAplicadas, {
			id = restr.id, nome = restr.nome, peso = restr.peso, pura = pura, ganho = ganho, trBonus = restr.trBonus or 0,
		})
	end

	local custoLiquido = math.max(0, custoTotal - pnRestaurado)
	if custoLiquido > pnDisponivel then
		return {
			success = false,
			error = "P.N insuficiente para editar. Custo: " .. custoLiquido .. ", disponível: " .. pnDisponivel,
		}
	end

	local custoAura = calcCustoAura(efeitosEscolhidos, restricoesAplicadas)
	local tr = HatsuService.CalcTR(character, efeitosEscolhidos, restricoesAplicadas)

	hatsu.Nome = build.nome
	hatsu.Natureza = detectarNatureza(build.efeitos)
	hatsu.Efeitos = efeitosEscolhidos
	hatsu.Restricoes = restricoesAplicadas
	hatsu.CustoAura = custoAura
	hatsu.TR = tr.total
	hatsu.PNUsados = custoLiquido

	local pnRestante = NenService.CalcPNDisponivelParaHatsu(character, nil)
	return {
		success = true,
		hatsu = hatsu,
		message = "Hatsu editado! Custo: " .. custoLiquido .. " P.N. Disponível: " .. tostring(pnRestante)
			.. ". Custo de aura: " .. custoAura .. "%. TR: " .. tr.total,
	}
end

function HatsuService.GetHatsus(character)
	return character.Hatsus or {}
end

function HatsuService.NextId(character)
	local max = 0
	for _, h in ipairs(character.Hatsus or {}) do
		local num = tonumber(tostring(h.Id):match("%d+$")) or 0
		if num > max then
			max = num
		end
	end
	return "H" .. (max + 1)
end

function HatsuService.DeleteHatsu(character, hatsuId)
	local index = nil
	local hatsu = nil
	for i, h in ipairs(character.Hatsus or {}) do
		if h.Id == hatsuId then
			index = i
			hatsu = h
			break
		end
	end
	if not hatsu then
		return { success = false, error = "Hatsu não encontrado." }
	end

	local nome = hatsu.Nome
	table.remove(character.Hatsus, index)

	local pnRestante = NenService.CalcPNDisponivelParaHatsu(character, nil)
	return {
		success = true,
		message = "Hatsu \"" .. tostring(nome) .. "\" excluído. P.N disponível: " .. tostring(pnRestante),
	}
end

function HatsuService.ActivateHatsu(character, hatsuId)
	local hatsu
	for _, h in ipairs(character.Hatsus or {}) do
		if h.Id == hatsuId then
			hatsu = h
			break
		end
	end
	if not hatsu then
		return { success = false, error = "Hatsu não encontrado." }
	end

	local aura = character.Vitals and character.Vitals.Aura
	local custo = hatsu.CustoAura or 50
	if aura and aura.Max and aura.Max > 0 then
		local custoReal = math.floor((aura.Max or 100) * custo / 100)
		if (aura.Current or 0) < custoReal then
			return { success = false, error = "Aura insuficiente (" .. custo .. "% do máximo = " .. custoReal .. ")." }
		end
		aura.Current = math.max(0, (aura.Current or 0) - custoReal)
	end

	local natureza = hatsu.Natureza or detectarNatureza(hatsu.Efeitos or {})
	local attrs = character.Attributes or {}
	local forVal = attrs.FOR and attrs.FOR.value or 10
	local forMod = math.max(0, math.floor((forVal - 10) / 2))
	local conVal = (attrs.CON and attrs.CON.value) or 10
	local conMod = math.max(0, math.floor((conVal - 10) / 2))

	local cura = 0
	local rd = 0
	local critico = 20
	for _, e in ipairs(hatsu.Efeitos or {}) do
		if e.id == "ri_e3" then
			cura = cura + math.random(1, 8) + conMod
		elseif e.id == "ri_e26" then
			cura = cura + math.random(1, 6) + conMod
		elseif e.id == "ri_e7" then
			rd = math.max(rd, 3)
		elseif e.id == "ri_e16" then
			rd = math.max(rd, 5)
		elseif e.id == "ri_e25" then
			rd = math.max(rd, 10)
		elseif e.id == "ri_e9" then
			critico = 19
		end
	end
	if cura > 0 and character.Vitals and character.Vitals.HP then
		local hp = character.Vitals.HP
		hp.Current = math.min(hp.Max or hp.Current, (hp.Current or 0) + cura)
	end

	if natureza ~= "Hostil" then
		local linhas = { "✨ " .. tostring(hatsu.Nome) .. " — " .. natureza }
		if cura > 0 then
			linhas[#linhas + 1] = "Cura: +" .. cura .. " PV"
		end
		if rd > 0 then
			linhas[#linhas + 1] = "RD: " .. rd
		end
		linhas[#linhas + 1] = "Sem rolagem de ataque (Hatsu de suporte)."
		return {
			success = true,
			resultado = {
				nome = hatsu.Nome,
				mensagem = table.concat(linhas, "\n"),
				natureza = natureza,
				cura = cura,
				rd = rd,
				rolagem = nil,
			},
			hatsu = hatsu,
		}
	end

	local d1 = math.random(1, 6)
	local d2 = math.random(1, 6)
	local dano = d1 + d2 + forMod
	local partes = { "2d6=" .. (d1 + d2), "FOR+" .. forMod }
	for _, e in ipairs(hatsu.Efeitos or {}) do
		if e.id == "ri_e11" then
			local d = math.random(1, 8)
			dano = dano + d
			table.insert(partes, "Golpe 1d8=" .. d)
		elseif e.id == "ri_e20" then
			local d = math.random(1, 6)
			dano = dano + d
			table.insert(partes, "Fúria 1d6=" .. d)
		elseif e.id == "ri_e27" then
			dano = dano + 5
			table.insert(partes, "Força Titânica +5")
		elseif e.id == "ri_e12" then
			dano = dano + 5
			table.insert(partes, "Penetração +5")
		end
	end
	local rolagem = math.random(1, 20)
	local ehCritico = rolagem >= critico
	if ehCritico then
		dano = dano * 2
		table.insert(partes, "CRÍTICO x2")
	end
	local linhas = { "🎲 " .. rolagem .. (ehCritico and " — CRÍTICO! (x2)" or "") }
	linhas[#linhas + 1] = "Dano: " .. dano
	linhas[#linhas + 1] = "Partes: " .. table.concat(partes, " + ")
	linhas[#linhas + 1] = "Aura: -" .. (aura and math.floor((aura.Max or 100) * custo / 100) or custo) .. " (" .. custo .. "%)"
	if rd > 0 then
		linhas[#linhas + 1] = "RD: " .. rd
	end
	if cura > 0 then
		linhas[#linhas + 1] = "Cura: +" .. cura .. " PV"
	end
	return {
		success = true,
		resultado = {
			nome = hatsu.Nome,
			rolagem = table.concat(linhas, "\n"),
			dano = dano,
			critico = ehCritico,
			rd = rd,
			cura = cura,
		},
		hatsu = hatsu,
	}
end

function HatsuService.AddGrau(character, hatsuId, caracteristica)
	local hatsu
	for _, h in ipairs(character.Hatsus or {}) do
		if h.Id == hatsuId then
			hatsu = h
			break
		end
	end
	if not hatsu then
		return { success = false, error = "Hatsu não encontrado." }
	end
	hatsu.Graus = hatsu.Graus or {}
	hatsu.Graus[caracteristica] = (hatsu.Graus[caracteristica] or 0) + 1
	return { success = true, message = "+1 grau em " .. tostring(caracteristica) .. "." }
end

function HatsuService.AddRestricao(character, hatsuId, restricaoId)
	local hatsu
	for _, h in ipairs(character.Hatsus or {}) do
		if h.Id == hatsuId then
			hatsu = h
			break
		end
	end
	if not hatsu then
		return { success = false, error = "Hatsu não encontrado." }
	end
	local restr = findRestriction(restricaoId)
	if not restr then
		return { success = false, error = "Restrição desconhecida." }
	end
	hatsu.Restricoes = hatsu.Restricoes or {}
	table.insert(hatsu.Restricoes, { id = restr.id, nome = restr.nome, peso = restr.peso, pura = false, ganho = 0, trBonus = restr.trBonus or 0 })
	return { success = true, message = "Restrição adicionada: " .. restr.nome }
end

return HatsuService