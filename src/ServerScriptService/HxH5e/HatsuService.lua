--[[
    HxH5e HatsuService v9 (pre-requisito de efeito por nome + restricao
    extrema aumentando nivel de acesso cruzado)
    Diferenca da v8:
    - Pre-requisito de efeito por NOME agora e validado quando o texto
      apos o travessao do "req" bate EXATAMENTE com nome(s) de efeito
      conhecido(s) (regra propria, ALEM do webapp real, que so valida o
      numero do nivel - confirmado lendo hatsu-creator.js). Exige que o
      efeito pre-requisito esteja tambem selecionado NO MESMO Hatsu.
    - Restricoes extremas selecionadas no proprio Hatsu agora aumentam o
      nivel efetivo de acesso cruzado (cada extrema = +2 nivel, teto 12),
      igual ao webapp (extremeCount em hatsu-creator.js).

    Simplificacoes conhecidas (documentadas, nao bloqueiam testes basicos):
    - Acesso a Especializacao via regra especial (checkEspecializacaoAccess
      do webapp: piramide de restricoes de Manipulacao/Materializacao)
      AINDA NAO implementado — Especializacao so fica acessivel a
      personagens que JA sao da propria categoria Especializacao (100%).
    - Pre-requisito por nome so cobre o caso "puro" (so nome, ou lista
      "X ou Y" de nomes). Casos mistos com atributo/condicao customizada
      ("PRE 3+ e C.S.C", "custo > 10%", "3 restricoes pesadas" etc.)
      continuam so com a checagem de nivel, como o webapp faz.
    - O catalogo mostrado no WIZARD (GetCatalog) ainda usa extremeCount=0
      fixo (o jogador so ve o nivel de acesso boostado depois de criar o
      Hatsu de verdade em CreateHatsuV2/EditHatsu, nao em tempo real
      enquanto marca as restricoes no wizard). Ligar isso ao vivo no
      cliente fica como proxima expansao.
    - Atributo principal de cada categoria foi simplificado pra UM
      atributo so (a tabela real do webapp tem formulas mistas tipo
      "(PRE+INT+1)/2" pra Especializacao, ou "PRE (pessoas) / INT
      (objetos)" pra Manipulacao — aqui usamos so o atributo primario
      de cada uma pra manter o calculo de TR simples).
    - Os efeitos com comportamento mecanico especial na ativacao (cura,
      RD, critico, dano bonus) so estao mapeados pra Reforco (ids
      ri_e3, ri_e7, ri_e9, ri_e11 etc.).

    Fonte de verdade: o webapp. Ao atualizar hatsu-db.js, re-rodar o
    pipeline (fetch HTTP + parser JS->Lua) para atualizar o HatsuDB.
]]

local HatsuService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HatsuDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("HatsuDB"))
local NenService = require(script.Parent:WaitForChild("NenService"))

local PURE_PN = {
	leve = 1,
	moderada = 2,
	pesada = 3,
	extrema = 4,
}

local CATEGORY_LABEL = {
	["INTENSIFICAÇÃO"] = "Reforço",
	["TRANSMUTAÇÃO"] = "Transmutação",
	["MATERIALIZAÇÃO"] = "Materialização",
	["MANIPULAÇÃO"] = "Manipulação",
	["EMISSÃO"] = "Emissão",
	["ESPECIALIZAÇÃO"] = "Especialização",
}

local CATEGORY_ATTR = {
	["INTENSIFICAÇÃO"] = "FOR",
	["TRANSMUTAÇÃO"] = "SAB",
	["MATERIALIZAÇÃO"] = "INT",
	["MANIPULAÇÃO"] = "PRE",
	["EMISSÃO"] = "DES",
	["ESPECIALIZAÇÃO"] = "PRE",
}

local ALL_CATEGORIES = { "INTENSIFICAÇÃO", "TRANSMUTAÇÃO", "MATERIALIZAÇÃO", "MANIPULAÇÃO", "EMISSÃO", "ESPECIALIZAÇÃO" }

local DEFAULT_CATEGORY = "INTENSIFICAÇÃO"

local function getCategoryId(character)
	local id = character and character.Nen and character.Nen.Category
	if id and HatsuDB.categorias[id] then
		return id
	end
	return DEFAULT_CATEGORY
end

local CATEGORY_AFFINITY = {
	["INTENSIFICAÇÃO"] = { ["TRANSMUTAÇÃO"] = 80, ["EMISSÃO"] = 80, ["MATERIALIZAÇÃO"] = 60, ["MANIPULAÇÃO"] = 60 },
	["TRANSMUTAÇÃO"] = { ["INTENSIFICAÇÃO"] = 80, ["MATERIALIZAÇÃO"] = 80, ["EMISSÃO"] = 60, ["MANIPULAÇÃO"] = 40 },
	["MATERIALIZAÇÃO"] = { ["TRANSMUTAÇÃO"] = 80, ["INTENSIFICAÇÃO"] = 60, ["MANIPULAÇÃO"] = 60, ["EMISSÃO"] = 40 },
	["MANIPULAÇÃO"] = { ["EMISSÃO"] = 80, ["MATERIALIZAÇÃO"] = 60, ["INTENSIFICAÇÃO"] = 60, ["TRANSMUTAÇÃO"] = 40 },
	["EMISSÃO"] = { ["MANIPULAÇÃO"] = 80, ["INTENSIFICAÇÃO"] = 80, ["TRANSMUTAÇÃO"] = 60, ["MATERIALIZAÇÃO"] = 40 },
	["ESPECIALIZAÇÃO"] = { ["MATERIALIZAÇÃO"] = 80, ["MANIPULAÇÃO"] = 80, ["TRANSMUTAÇÃO"] = 60, ["EMISSÃO"] = 60, ["INTENSIFICAÇÃO"] = 40 },
}

local ACCESS_TABLE = {
	[0] = { 0, 0, 0, 0 },
	[1] = { 1, 0, 0, 0 },
	[2] = { 2, 0, 0, 0 },
	[3] = { 3, 1, 0, 0 },
	[4] = { 4, 2, 0, 0 },
	[5] = { 5, 3, 1, 0 },
	[6] = { 6, 4, 2, 0 },
	[7] = { 7, 5, 3, 1 },
	[8] = { 8, 6, 4, 2 },
	[9] = { 9, 7, 5, 3 },
	[10] = { 10, 8, 6, 4 },
	[11] = { 11, 9, 7, 5 },
	[12] = { 12, 10, 8, 6 },
}

local function calcCategoryAccess(charLevel, extremeRestrictionCount)
	local effectiveLevel = math.min(12, (charLevel or 0) + (extremeRestrictionCount or 0) * 2)
	local row = ACCESS_TABLE[effectiveLevel] or ACCESS_TABLE[0]
	return { pct100 = row[1], pct80 = row[2], pct60 = row[3], pct40 = row[4] }
end

local function getMaxLevelForCategory(myClass, targetClass, charLevel, extremeRestrictionCount)
	local access = calcCategoryAccess(charLevel, extremeRestrictionCount)
	if myClass == targetClass then
		return access.pct100
	end
	if targetClass == "ESPECIALIZAÇÃO" then
		return 0
	end
	local pct = (CATEGORY_AFFINITY[myClass] or {})[targetClass] or 0
	if pct >= 80 then
		return access.pct80
	end
	if pct >= 60 then
		return access.pct60
	end
	if pct >= 40 then
		return access.pct40
	end
	return 0
end

local function parseNivel(req)
	if type(req) ~= "string" then
		return 1
	end
	local n = req:match("(%d+)")
	return tonumber(n) or 1
end

local function parsePrereqNames(req, allEffectNames)
	if type(req) ~= "string" then
		return nil
	end
	local dashStart, dashEnd = req:find("—", 1, true)
	if not dashStart then
		dashStart, dashEnd = req:find("–", 1, true)
	end
	if not dashStart then
		return nil
	end
	local rest = req:sub(dashEnd + 1):gsub("^%s+", ""):gsub("%s+$", "")
	if #rest == 0 then
		return nil
	end
	local candidatos = {}
	for parte in (rest .. " ou "):gmatch("(.-)%s+[Oo][Uu]%s+") do
		table.insert(candidatos, parte)
	end
	for _, c in ipairs(candidatos) do
		if not allEffectNames[c] then
			return nil
		end
	end
	return candidatos
end

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

local globalEffectNamesCache = nil
local function getGlobalEffectNames()
	if globalEffectNamesCache then
		return globalEffectNamesCache
	end
	local names = {}
	for _, e in ipairs(HatsuDB.efeitos_gerais) do
		names[e.nome] = true
	end
	for _, catId in ipairs(ALL_CATEGORIES) do
		for _, e in ipairs(HatsuDB.categorias[catId].efeitos) do
			names[e.nome] = true
		end
	end
	globalEffectNamesCache = names
	return names
end

local function buildEffects(categoryId, label)
	local allNames = getGlobalEffectNames()
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
			prereqNomes = parsePrereqNames(e.req, allNames),
		})
	end
	local cat = HatsuDB.categorias[categoryId]
	for _, e in ipairs(cat.efeitos) do
		table.insert(all, {
			id = e.id,
			nome = e.nome,
			grupo = label,
			nivel = parseNivel(e.req),
			custo = e.pn,
			desc = e.desc,
			req = e.req,
			repetivel = e.repetivel or false,
			prereqNomes = parsePrereqNames(e.req, allNames),
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

local function buildRestrictions(categoryId, label)
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
	local cat = HatsuDB.categorias[categoryId]
	for _, r in ipairs(cat.restricoes) do
		table.insert(all, {
			id = r.id,
			nome = r.nome,
			peso = r.peso,
			pura = PURE_PN[r.peso],
			categoria = label,
			descricao = r.desc,
			beneficios = splitBeneficios(r.bnf),
		})
	end
	return all
end

local catalogCache = {}

local function getCategoryCatalog(categoryId)
	local cached = catalogCache[categoryId]
	if cached then
		return cached
	end
	local label = CATEGORY_LABEL[categoryId] or categoryId
	local built = {
		label = label,
		effects = buildEffects(categoryId, label),
		restrictions = buildRestrictions(categoryId, label),
	}
	catalogCache[categoryId] = built
	return built
end

local function getMergedCatalogForCharacter(character, extremeCount)
	local myClass = getCategoryId(character)
	local charLevel = (character and character.Level) or 0
	local ownCatalog = getCategoryCatalog(myClass)

	local effects = {}
	local seen = {}
	for _, e in ipairs(ownCatalog.effects) do
		local copy = table.clone(e)
		copy.origemCategoria = (e.grupo == "Gerais") and "Gerais" or myClass
		copy.nivelMaxAcessivel = charLevel
		table.insert(effects, copy)
		seen[e.id] = true
	end

	for _, otherClass in ipairs(ALL_CATEGORIES) do
		if otherClass ~= myClass then
			local maxLevel = getMaxLevelForCategory(myClass, otherClass, charLevel, extremeCount or 0)
			if maxLevel > 0 then
				local otherCatalog = getCategoryCatalog(otherClass)
				for _, e in ipairs(otherCatalog.effects) do
					if e.grupo ~= "Gerais" and not seen[e.id] then
						local copy = table.clone(e)
						copy.origemCategoria = otherClass
						copy.nivelMaxAcessivel = maxLevel
						table.insert(effects, copy)
						seen[e.id] = true
					end
				end
			end
		end
	end

	return {
		label = ownCatalog.label,
		effects = effects,
		restrictions = ownCatalog.restrictions,
	}
end

local function findEffect(catalog, id)
	for _, e in ipairs(catalog.effects) do
		if e.id == id then
			return e
		end
	end
	return nil
end

local function findRestriction(catalog, id)
	for _, r in ipairs(catalog.restrictions) do
		if r.id == id then
			return r
		end
	end
	return nil
end

function HatsuService.GetCatalog(character, excludeHatsuId)
	local catalog = getMergedCatalogForCharacter(character, 0)
	local pnDisponivel = 0
	if character then
		pnDisponivel = NenService.CalcPNDisponivelParaHatsu(character, excludeHatsuId)
	end
	return {
		effects = catalog.effects,
		restrictions = catalog.restrictions,
		purePN = PURE_PN,
		pnDisponivel = pnDisponivel,
		categoria = catalog.label,
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
	local categoryId = getCategoryId(character)
	local attrKey = CATEGORY_ATTR[categoryId] or "FOR"
	local mod = getAttributeMod(character, attrKey)

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

local function validatePrereqNames(efeitosEscolhidos)
	local nomesEscolhidos = {}
	for _, ef in ipairs(efeitosEscolhidos) do
		nomesEscolhidos[ef.nome] = true
	end
	for _, ef in ipairs(efeitosEscolhidos) do
		if ef.prereqNomes then
			local atendido = false
			for _, pn in ipairs(ef.prereqNomes) do
				if nomesEscolhidos[pn] then
					atendido = true
					break
				end
			end
			if not atendido then
				return "\"" .. tostring(ef.nome) .. "\" precisa que você também inclua " .. table.concat(ef.prereqNomes, " ou ") .. " nesse mesmo Hatsu."
			end
		end
	end
	return nil
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

	local myClass = getCategoryId(character)
	local restrictionCatalog = getCategoryCatalog(myClass)

	local pnRestaurado = 0
	local extremeCount = 0
	local restricoesAplicadas = {}
	for _, r in ipairs(build.restricoes or {}) do
		local restr = findRestriction(restrictionCatalog, r.id)
		if not restr then
			return { success = false, error = "Restrição desconhecida: " .. tostring(r.id) }
		end
		if restr.peso == "extrema" then
			extremeCount = extremeCount + 1
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

	local catalog = getMergedCatalogForCharacter(character, extremeCount)

	local pnDisponivel = NenService.CalcPNDisponivelParaHatsu(character, nil)
	local custoTotal = 0
	local efeitosEscolhidos = {}

	for _, eid in ipairs(build.efeitos) do
		local efeito = findEffect(catalog, eid)
		if not efeito then
			return { success = false, error = "Efeito desconhecido: " .. tostring(eid) }
		end
		if (efeito.nivel or 1) > (efeito.nivelMaxAcessivel or 0) then
			return {
				success = false,
				error = "Você ainda não tem acesso a \"" .. tostring(efeito.nome) .. "\" (precisa nível " .. efeito.nivel
					.. " nessa categoria; seu acesso vai até nível " .. tostring(efeito.nivelMaxAcessivel) .. ").",
			}
		end
		custoTotal = custoTotal + efeito.custo
		table.insert(efeitosEscolhidos, { id = efeito.id, nome = efeito.nome, custo = efeito.custo, trBonus = efeito.trBonus or 0, prereqNomes = efeito.prereqNomes })
	end

	local prereqErr = validatePrereqNames(efeitosEscolhidos)
	if prereqErr then
		return { success = false, error = prereqErr }
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
		Tipo = catalog.label,
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

	local myClass = getCategoryId(character)
	local restrictionCatalog = getCategoryCatalog(myClass)

	local pnRestaurado = 0
	local extremeCount = 0
	local restricoesAplicadas = {}
	for _, r in ipairs(build.restricoes or {}) do
		local restr = findRestriction(restrictionCatalog, r.id)
		if not restr then
			return { success = false, error = "Restrição desconhecida: " .. tostring(r.id) }
		end
		if restr.peso == "extrema" then
			extremeCount = extremeCount + 1
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

	local catalog = getMergedCatalogForCharacter(character, extremeCount)

	local pnDisponivel = NenService.CalcPNDisponivelParaHatsu(character, hatsuId)
	local custoTotal = 0
	local efeitosEscolhidos = {}
	for _, eid in ipairs(build.efeitos) do
		local efeito = findEffect(catalog, eid)
		if not efeito then
			return { success = false, error = "Efeito desconhecido: " .. tostring(eid) }
		end
		if (efeito.nivel or 1) > (efeito.nivelMaxAcessivel or 0) then
			return {
				success = false,
				error = "Você ainda não tem acesso a \"" .. tostring(efeito.nome) .. "\" (precisa nível " .. efeito.nivel
					.. " nessa categoria; seu acesso vai até nível " .. tostring(efeito.nivelMaxAcessivel) .. ").",
			}
		end
		custoTotal = custoTotal + efeito.custo
		table.insert(efeitosEscolhidos, { id = efeito.id, nome = efeito.nome, custo = efeito.custo, trBonus = efeito.trBonus or 0, prereqNomes = efeito.prereqNomes })
	end

	local prereqErr = validatePrereqNames(efeitosEscolhidos)
	if prereqErr then
		return { success = false, error = prereqErr }
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

	local categoryId = getCategoryId(character)
	local attrKey = CATEGORY_ATTR[categoryId] or "FOR"
	local natureza = hatsu.Natureza or detectarNatureza(hatsu.Efeitos or {})
	local attrs = character.Attributes or {}
	local principalVal = (attrs[attrKey] and attrs[attrKey].value) or 10
	local principalMod = math.max(0, math.floor((principalVal - 10) / 2))
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
	local dano = d1 + d2 + principalMod
	local partes = { "2d6=" .. (d1 + d2), attrKey .. "+" .. principalMod }
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
	local catalog = getMergedCatalogForCharacter(character, 0)
	local restr = findRestriction(catalog, restricaoId)
	if not restr then
		return { success = false, error = "Restrição desconhecida." }
	end
	hatsu.Restricoes = hatsu.Restricoes or {}
	table.insert(hatsu.Restricoes, { id = restr.id, nome = restr.nome, peso = restr.peso, pura = false, ganho = 0, trBonus = restr.trBonus or 0 })
	return { success = true, message = "Restrição adicionada: " .. restr.nome }
end

return HatsuService