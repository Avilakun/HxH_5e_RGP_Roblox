--[[
    HxH5e HatsuService v13 (Graus de Potencia iniciais: 5 gratis no 1o
    Hatsu, restritos por categoria)
    Diferenca da v12: adiciona CATEGORY_GRAU_OPTIONS (lista do que cada
    categoria pode investir; "Reducao de Custo" e universal) e
    validateGrauAlocacao. Conectado em 3 mecanicas reais: Reducao de
    Custo (-5%/ponto no custo de aura), Dano (avanca a tabela de dados
    do Dano/Cura Focal), CD do TR (+1/ponto no TR final). As demais
    (Acerto, Atributos, Duracao, Alcance/Area, Numero de Alvos) ficam
    registradas em hatsu.GrauInicial mas ainda sem mecanica de suporte
    no jogo. So se aplica no PRIMEIRO Hatsu do personagem (checado via
    #character.Hatsus == 0 no momento da criacao). Testado: alocacao
    valida aplica corretamente, categoria invalida e excesso de pontos
    sao rejeitados, 2o Hatsu nao recebe os pontos gratis de novo.
    Diferenca da v11 (bonus mecanico generico: cura/RD/critico/dano-
    bonus por qualquer categoria, via leitura da descricao):
    - ActivateHatsu nao depende mais de IDs hardcoded "ri_*" (so Reforco).
      Uma funcao parseMechanicalEffect(desc) interpreta o texto da
      descricao de QUALQUER efeito selecionado (propria categoria ou
      emprestada por acesso cruzado) e aplica cura/RD/reducao de margem
      de critico/dano bonus (em dado ou fixo) automaticamente. Testado:
      efeitos ja existentes em Reforco continuam identicos (regressao
      OK) e um efeito de Materializacao (Forja Avancada, nunca mapeado
      antes) passou a dar bonus de dano corretamente sem nenhum codigo
      novo especifico pra ele.
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
    - parseMechanicalEffect e um parser HEURISTICO de texto, nao uma
      tabela curada. Pode ter falso-negativo (efeito com fraseado
      incomum nao reconhecido, fica sem bonus mecanico) mas foi
      testado pra nao dar falso-positivo nos casos reais do banco
      (ex.: "Dano/Cura Focal" descreve a formula BASE do Hatsu, nao um
      bonus, e foi explicitamente excluido do parser de dano).

    Fonte de verdade: o webapp. Ao atualizar hatsu-db.js, re-rodar o
    pipeline (fetch HTTP + parser JS->Lua) para atualizar o HatsuDB.
]]

local HatsuService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HatsuDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("HatsuDB"))
local NenService = require(script.Parent:WaitForChild("NenService"))
local CharacterServiceRef = require(script.Parent:WaitForChild("CharacterService"))
local AchievementService = require(script.Parent:WaitForChild("AchievementService"))

-- Restricoes que obrigam escolher entre perder PV ou Sanidade
-- permanentemente: "rg_p3" (Dano Permanente, perda UNICA de 1d10 na
-- criacao do Hatsu) e "rg_e4" (Dano Permanente Constante, perde 5 A
-- CADA ATIVACAO bem-sucedida, ver ActivateHatsu).
local RESTRICOES_ESCOLHA_VITAL = { rg_p3 = true, rg_e4 = true }

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

-- Reconhece a parte de ATRIBUTO MINIMO num requisito misto (ex:
-- "Nivel 5 — SAB 3+ e Projetil de Aura", "Nivel 7 — INT ou SAB 3+ ou
-- 3 restricoes pesadas"). So extrai a condicao de ATRIBUTO -- o resto
-- (siglas de efeito tipo "C.S.O"/"C.S.C", contagem de restricoes)
-- continua sem suporte automatico, igual o webapp real tambem nao
-- resolve isso (confirmado lendo hatsu-creator.js). Suporta multiplos
-- atributos alternativos ("INT ou SAB 3+" = qualquer um dos dois).
local ATRIBUTOS_VALIDOS = { FOR = true, DES = true, CON = true, INT = true, SAB = true, PRE = true, CAR = true }
local function parsePrereqAttrMin(req)
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
	local rest = req:sub(dashEnd + 1)
	-- Casa "SIGLA (ou SIGLA)* N+" -- ex: "SAB 3+", "INT ou SAB 3+"
	local trechoAttrs, valor = rest:match("([%u]+ *[Oo][Uu]? *[%u]*[%u]) *(%d+)%+")
	if not trechoAttrs then
		trechoAttrs, valor = rest:match("(%u%u%u) *(%d+)%+")
	end
	if not trechoAttrs or not valor then
		return nil
	end
	local attrs = {}
	for sigla in trechoAttrs:gmatch("%u%u%u") do
		if ATRIBUTOS_VALIDOS[sigla] then
			table.insert(attrs, sigla)
		end
	end
	if #attrs == 0 then
		return nil
	end
	return { attrs = attrs, min = tonumber(valor) }
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
			prereqAttrMin = parsePrereqAttrMin(e.req),
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
			prereqAttrMin = parsePrereqAttrMin(e.req),
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

-- Regra especial de acesso a Especializacao (extraida fielmente do
-- webapp real, js/data/nen-affinity.js:checkEspecializacaoAccess) --
-- so Manipulacao/Materializacao podem acessar, e exige:
-- 1) Pelo menos 3 restricoes selecionadas (+1 pra cada efeito de
--    Especializacao ja escolhido no mesmo Hatsu -- quanto mais
--    efeitos de Especializacao, mais restricoes exige).
-- 2) "Piramide de pesos": nunca pode ter mais restricoes de peso
--    menor do que de peso imediatamente maior (ex: nao pode ter mais
--    Leves que Moderadas, se houver Moderadas; nao pode ter mais
--    Moderadas que Pesadas, se houver Pesadas). "Variavel" nao conta
--    pra piramide.
local function checkEspecializacaoAccess(myClass, pesosRestricoesSelecionadas, efeitosEscolhidosIds)
	if myClass ~= "MANIPULAÇÃO" and myClass ~= "MATERIALIZAÇÃO" then
		return { ok = false }
	end

	local espCatalog = HatsuDB.categorias["ESPECIALIZAÇÃO"]
	local espIds = {}
	for _, e in ipairs((espCatalog and espCatalog.efeitos) or {}) do
		espIds[e.id] = true
	end
	local specEfeitos = 0
	for _, id in ipairs(efeitosEscolhidosIds or {}) do
		if espIds[id] then
			specEfeitos = specEfeitos + 1
		end
	end
	local needed = 3 + specEfeitos

	local counts = { leve = 0, moderada = 0, pesada = 0, extrema = 0 }
	local totalRestr = 0
	for _, peso in ipairs(pesosRestricoesSelecionadas or {}) do
		if counts[peso] ~= nil then
			counts[peso] = counts[peso] + 1
		end
		totalRestr = totalRestr + 1
	end

	local pyramidOk = true
	if counts.leve > counts.moderada and counts.moderada > 0 then
		pyramidOk = false
	end
	if counts.moderada > counts.pesada and counts.pesada > 0 then
		pyramidOk = false
	end

	local ok = totalRestr >= needed and pyramidOk
	return { ok = ok, specEfeitos = specEfeitos, totalRestr = totalRestr, needed = needed, counts = counts, pyramidOk = pyramidOk }
end
HatsuService.CheckEspecializacaoAccess = checkEspecializacaoAccess

local function getMergedCatalogForCharacter(character, extremeCount, pesosRestricoesSelecionadas, efeitosEscolhidosIds)
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
			local maxLevel
			if otherClass == "ESPECIALIZAÇÃO" then
				local espCheck = checkEspecializacaoAccess(myClass, pesosRestricoesSelecionadas, efeitosEscolhidosIds)
				maxLevel = espCheck.ok and charLevel or 0
			else
				maxLevel = getMaxLevelForCategory(myClass, otherClass, charLevel, extremeCount or 0)
			end
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

-- ================= Graus de Potencia iniciais (5 gratis no 1o Hatsu) =================
-- Cada categoria so pode investir nas caracteristicas listadas abaixo.
-- "Reducao de Custo" e universal (todas as categorias). Confirmado com
-- o Lucas. So as 3 primeiras (Reducao de Custo, Dano/Cura, CD do TR)
-- estao conectadas a uma mecanica de verdade agora -- as outras
-- (Acerto, Atributos, Duracao, Alcance/Area, Numero de Alvos) ficam
-- registradas no Hatsu pra transparencia, mas ainda SEM efeito
-- mecanico (pendencia: nao existe sistema de duracao de buff, alcance/
-- area de efeito, numero de alvos, nem rolagem de acerto separada da
-- TR ainda no jogo).
local CATEGORY_GRAU_OPTIONS = {
	["INTENSIFICAÇÃO"] = { "Acerto", "Atributos", "Dano/Cura", "Redução de Custo" },
	["TRANSMUTAÇÃO"] = { "Área", "Dano", "Redução de Custo" },
	["MATERIALIZAÇÃO"] = { "Alcance/Área", "Duração", "Redução de Custo" },
	["ESPECIALIZAÇÃO"] = { "Alcance/Área", "Dano", "Duração", "CD do TR", "Redução de Custo" },
	["MANIPULAÇÃO"] = { "Alcance/Área", "Número de Alvos", "Duração", "CD do TR", "Redução de Custo" },
	["EMISSÃO"] = { "Acerto", "Alcance/Área", "Redução de Custo" },
}

local GRAU_INICIAL_TOTAL = 5

local function validateGrauAlocacao(categoryId, grauAlocacao)
	if type(grauAlocacao) ~= "table" then
		return nil, nil
	end
	local permitidas = {}
	for _, nome in ipairs(CATEGORY_GRAU_OPTIONS[categoryId] or {}) do
		permitidas[nome] = true
	end
	local total = 0
	for caracteristica, pontos in pairs(grauAlocacao) do
		if not permitidas[caracteristica] then
			return nil, "\"" .. tostring(caracteristica) .. "\" não é uma característica permitida pra sua categoria."
		end
		if type(pontos) ~= "number" or pontos < 0 or pontos ~= math.floor(pontos) then
			return nil, "Valor inválido em \"" .. tostring(caracteristica) .. "\"."
		end
		total = total + pontos
	end
	if total > GRAU_INICIAL_TOTAL then
		return nil, "Você alocou " .. total .. " pontos, o máximo grátis é " .. GRAU_INICIAL_TOTAL .. "."
	end
	return grauAlocacao, nil
end

function HatsuService.GetGrauOptions(character)
	local categoryId = getCategoryId(character)
	return {
		opcoes = CATEGORY_GRAU_OPTIONS[categoryId] or {},
		total = GRAU_INICIAL_TOTAL,
	}
end

function HatsuService.GetCatalog(character, excludeHatsuId)
	local catalog = getMergedCatalogForCharacter(character, 0)
	local pnDisponivel = 0
	if character then
		pnDisponivel = NenService.CalcPNDisponivelParaHatsu(character, excludeHatsuId)
	end
	local categoryId = getCategoryId(character)
	return {
		effects = catalog.effects,
		restrictions = catalog.restrictions,
		purePN = PURE_PN,
		pnDisponivel = pnDisponivel,
		categoria = catalog.label,
		grauOptions = CATEGORY_GRAU_OPTIONS[categoryId] or {},
		grauTotal = GRAU_INICIAL_TOTAL,
		ehPrimeiroHatsu = character and character.Hatsus and #character.Hatsus == 0,
	}
end

-- ================= Atributo principal por categoria (regra do Lucas) =================
-- Reforco = FOR (padrao). Transmutacao = SAB ou INT (usa o maior).
-- Materializacao (=Conjuracao) = INT. Manipulacao = PRE pra manipular
-- SERES VIVOS (efeito C.S.C) ou INT pra OBJETOS (efeito C.S.O); sem
-- nenhum dos dois no Hatsu, usa o maior entre PRE/INT. Emissao = DES.
-- Especializacao = media (PRE+INT+1)/2 arredondada pra baixo, ANTES de
-- calcular o modificador. O Lucas avisou que isso pode variar por Hatsu
-- no futuro -- por ora essa e a regra padrao por categoria.
local function getPrincipalAttrInfo(character, categoryId, efeitosEscolhidos)
	local attrs = character.Attributes or {}
	local function modOf(key)
		local val = (attrs[key] and attrs[key].value) or 10
		return math.floor((val - 10) / 2)
	end

	if categoryId == "TRANSMUTAÇÃO" then
		local sab, intt = modOf("SAB"), modOf("INT")
		if sab >= intt then
			return sab, "SAB"
		end
		return intt, "INT"
	elseif categoryId == "MATERIALIZAÇÃO" then
		return modOf("INT"), "INT"
	elseif categoryId == "MANIPULAÇÃO" then
		local usaCriatura, usaObjeto = false, false
		for _, e in ipairs(efeitosEscolhidos or {}) do
			if e.id == "ma_e2" then
				usaCriatura = true
			elseif e.id == "ma_e1" then
				usaObjeto = true
			end
		end
		if usaCriatura and not usaObjeto then
			return modOf("PRE"), "PRE"
		elseif usaObjeto and not usaCriatura then
			return modOf("INT"), "INT"
		end
		local pre, intt2 = modOf("PRE"), modOf("INT")
		if pre >= intt2 then
			return pre, "PRE"
		end
		return intt2, "INT"
	elseif categoryId == "EMISSÃO" then
		return modOf("DES"), "DES"
	elseif categoryId == "ESPECIALIZAÇÃO" then
		local preVal = (attrs.PRE and attrs.PRE.value) or 10
		local intVal = (attrs.INT and attrs.INT.value) or 10
		local mediaVal = math.floor((preVal + intVal + 1) / 2)
		return math.floor((mediaVal - 10) / 2), "PRE/INT"
	end
	return modOf("FOR"), "FOR"
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
	local mod = getPrincipalAttrInfo(character, categoryId, efeitos)

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

local function calcCustoAura(efeitosEscolhidos, restricoesAplicadas, character)
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

	-- Condicao "Condenado" (ver ConditionsDB.lua): +5% de aura em
	-- QUALQUER tecnica de Nen enquanto ativa.
	if character and character.Conditions then
		for _, entry in ipairs(character.Conditions) do
			if entry.id == "condenado" then
				custo = custo + 5
				break
			end
		end
	end

	return math.max(5, custo)
end

-- ================= Tabela de progressao de dados (Grau de Potencia em Dano) =================
-- Sequencia UNICA e compartilhada (confirmada com o Lucas): qualquer
-- progressao de dado de dano -- seja o dado BASE de "Dano/Cura Focal"
-- (que comeca mais a frente, na posicao 6 = 2d6, representando o salto
-- por já ter investido 50% de aura) ou o dado de um efeito qualquer tipo
-- "Golpe Reforcado" (que comeca mais atras, ex.: posicao 3 = 1d8) --
-- percorre essa MESMA tabela. Cada grau investido avanca 1 posicao.
-- Ao passar da posicao 54, cada grau extra vira +5 de dano fixo.
local DIE_TABLE = {
	{ n = 1, d = 4 }, { n = 1, d = 6 }, { n = 1, d = 8 }, { n = 1, d = 10 }, { n = 1, d = 12 }, { n = 2, d = 6 },
	{ n = 2, d = 8 }, { n = 2, d = 10 }, { n = 2, d = 12 }, { n = 3, d = 10 }, { n = 4, d = 8 }, { n = 3, d = 12 },
	{ n = 4, d = 10 }, { n = 4, d = 12 }, { n = 5, d = 10 }, { n = 7, d = 8 }, { n = 6, d = 10 }, { n = 8, d = 8 },
	{ n = 7, d = 10 }, { n = 6, d = 12 }, { n = 8, d = 10 }, { n = 7, d = 12 }, { n = 9, d = 10 }, { n = 8, d = 12 },
	{ n = 10, d = 10 }, { n = 9, d = 12 }, { n = 11, d = 10 }, { n = 10, d = 12 }, { n = 13, d = 10 }, { n = 11, d = 12 },
	{ n = 14, d = 10 }, { n = 12, d = 12 }, { n = 15, d = 10 }, { n = 13, d = 12 }, { n = 16, d = 10 }, { n = 14, d = 12 },
	{ n = 17, d = 10 }, { n = 15, d = 12 }, { n = 19, d = 10 }, { n = 16, d = 12 }, { n = 20, d = 10 }, { n = 17, d = 12 },
	{ n = 18, d = 12 }, { n = 19, d = 12 }, { n = 20, d = 12 }, { n = 13, d = 20 }, { n = 14, d = 20 }, { n = 15, d = 20 },
	{ n = 16, d = 20 }, { n = 18, d = 20 }, { n = 20, d = 20 }, { n = 20, d = 20, flat = 5 }, { n = 20, d = 20, flat = 10 }, { n = 20, d = 20, flat = 15 },
}

local DIE_TABLE_START_DANO_CURA_FOCAL = 6 -- posicao do 2d6 (o "salto" do Dano/Cura Focal)

-- Acha a posicao de um {n,d} conhecido na tabela (pra efeitos que ja
-- comecam com um dado especifico, tipo Golpe Reforcado = 1d8).
local function findDieTableIndex(n, d)
	for i, entry in ipairs(DIE_TABLE) do
		if entry.n == n and entry.d == d and not entry.flat then
			return i
		end
	end
	return nil
end

-- Retorna o dado (e bonus fixo, se ja passou do fim da tabela) na
-- posicao startIndex + graus, com o "alem do fim" virando +5 fixo por
-- grau extra (regra confirmada: "ao fim da tabela, REN vira +5 fixo").
local function stepDieTable(startIndex, graus)
	local targetIndex = startIndex + (graus or 0)
	if targetIndex <= #DIE_TABLE then
		local entry = DIE_TABLE[targetIndex]
		return entry.n, entry.d, entry.flat or 0
	end
	local last = DIE_TABLE[#DIE_TABLE]
	local overflow = targetIndex - #DIE_TABLE
	return last.n, last.d, (last.flat or 0) + overflow * 5
end

-- ================= Efeitos mecanicos genericos (cura/RD/critico/dano bonus) =================
-- Em vez de mapear efeito por ID por categoria (nao escala pras 6
-- categorias), interpretamos o texto da propria descricao pra descobrir
-- a mecanica. Cobre os padroes reais confirmados no banco: cura/RD/
-- reducao de margem de critico estao hoje quase exclusivos em Reforco,
-- mas dano-bonus ja aparece em outras categorias tambem (ex.:
-- Materializacao "Adiciona 1d8 extra ao dano") -- por isso vale ser
-- generico em vez de so ri_*. Roda sobre QUALQUER efeito selecionado,
-- de qualquer categoria (propria ou emprestada por acesso cruzado).
local function parseMechanicalEffect(desc)
	if type(desc) ~= "string" then
		return nil
	end
	local lower = desc:lower()

	local nDados, dado, attr = desc:match("[Cc]ura%s+(%d*)d(%d+)%s*%+?%s*(%u%u%u)")
	if not dado then
		nDados, dado, attr = desc:match("[Rr]ecupera%s+(%d*)d(%d+)%+?(%u%u%u)%s*PV")
	end
	if dado then
		local n = tonumber(nDados)
		if not n or n == 0 then n = 1 end
		return { tipo = "cura", n = n, dado = tonumber(dado), attr = attr }
	end

	local rdVal = desc:match("(%d+)%s*RD%f[%A]")
	if rdVal and lower:find("reduz") == nil then
		return { tipo = "rd", valor = tonumber(rdVal) }
	end

	local critVal = lower:match("reduz margem de crítico em (%d+)")
	if critVal then
		return { tipo = "critico", valor = tonumber(critVal) }
	end

	if lower:find("dano") and not lower:find("grau") and not lower:find("básico") and not lower:find("basico") and not lower:find("passo") then
		local n2, d2 = desc:match("(%d*)d(%d+)")
		if d2 then
			local n = tonumber(n2)
			if not n or n == 0 then n = 1 end
			return { tipo = "dano_dado", n = n, dado = tonumber(d2) }
		end
		local flat = desc:match("%+%s*(%d+)")
		if flat then
			return { tipo = "dano_fixo", valor = tonumber(flat) }
		end
	end

	return nil
end

local function detectarNatureza(efeitosEscolhidos)
	for _, e in ipairs(efeitosEscolhidos or {}) do
		if e.id == "eg15" or e.id == "eg10" then
			return "Hostil"
		end
		local mec = parseMechanicalEffect(e.desc)
		if mec and (mec.tipo == "dano_dado" or mec.tipo == "dano_fixo") then
			return "Hostil"
		end
	end
	return "Versatil"
end

local function validatePrereqNames(efeitosEscolhidos, character)
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
		-- Parte de ATRIBUTO MINIMO de requisitos mistos (ex: "SAB 3+ e
		-- C.S.O") -- so a parte de atributo e checada de verdade; o
		-- resto (siglas de efeito, contagem de restricoes) continua
		-- sem validacao automatica, igual o webapp de referencia.
		if ef.prereqAttrMin then
			local atendeuAttr = false
			for _, sigla in ipairs(ef.prereqAttrMin.attrs) do
				local val = (character.Attributes and character.Attributes[sigla] and character.Attributes[sigla].value) or 10
				if val >= ef.prereqAttrMin.min then
					atendeuAttr = true
					break
				end
			end
			if not atendeuAttr then
				return "\"" .. tostring(ef.nome) .. "\" exige " .. table.concat(ef.prereqAttrMin.attrs, " ou ") .. " " .. ef.prereqAttrMin.min .. "+."
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
	local pesosSelecionados = {}
	local restricoesAplicadas = {}
	for _, r in ipairs(build.restricoes or {}) do
		local restr = findRestriction(restrictionCatalog, r.id)
		if not restr then
			return { success = false, error = "Restrição desconhecida: " .. tostring(r.id) }
		end
		if restr.peso == "extrema" then
			extremeCount = extremeCount + 1
		end
		table.insert(pesosSelecionados, restr.peso)
		local pura = r.pura or false
		local ganho = 0
		if pura and restr.pura then
			ganho = restr.pura
			pnRestaurado = pnRestaurado + ganho
		end
		local penalidadeVital = nil
		if RESTRICOES_ESCOLHA_VITAL[restr.id] then
			penalidadeVital = r.penalidadeVital
			if penalidadeVital ~= "PV" and penalidadeVital ~= "Sanidade" then
				return { success = false, error = "\"" .. restr.nome .. "\" exige escolher entre perder PV ou Sanidade permanentemente." }
			end
		end
		table.insert(restricoesAplicadas, {
			id = restr.id, nome = restr.nome, peso = restr.peso, pura = pura, ganho = ganho, trBonus = restr.trBonus or 0, penalidadeVital = penalidadeVital,
		})
	end

	-- "Dano Permanente" (rg_p3): perda UNICA de 1d10 de PV/Sanidade,
	-- aplicada agora mesmo (so na criacao -- editar um Hatsu existente
	-- que ja tinha essa restricao nao reaplica a perda de novo).
	for _, r in ipairs(restricoesAplicadas) do
		if r.id == "rg_p3" then
			local perda = math.random(1, 10)
			CharacterServiceRef.ApplyPermanentVitalLoss(character, r.penalidadeVital, perda)
		end
	end

	local catalog = getMergedCatalogForCharacter(character, extremeCount, pesosSelecionados, build.efeitos)

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
		table.insert(efeitosEscolhidos, { id = efeito.id, nome = efeito.nome, custo = efeito.custo, trBonus = efeito.trBonus or 0, prereqNomes = efeito.prereqNomes, prereqAttrMin = efeito.prereqAttrMin, desc = efeito.desc })
	end

	local prereqErr = validatePrereqNames(efeitosEscolhidos, character)
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

	local custoAura = calcCustoAura(efeitosEscolhidos, restricoesAplicadas, character)
	local tr = HatsuService.CalcTR(character, efeitosEscolhidos, restricoesAplicadas)

	-- Graus de Potencia iniciais: so se aplicam no PRIMEIRO Hatsu do
	-- personagem (este ainda nao foi inserido em character.Hatsus, entao
	-- #character.Hatsus == 0 aqui significa "este e o primeiro").
	local grauAlocacao = nil
	local grauDano = 0
	if character.Hatsus and #character.Hatsus == 0 and build.grauAlocacao then
		local validado, grauErr = validateGrauAlocacao(myClass, build.grauAlocacao)
		if grauErr then
			return { success = false, error = grauErr }
		end
		grauAlocacao = validado
		if grauAlocacao then
			local reducaoCusto = grauAlocacao["Redução de Custo"] or 0
			if reducaoCusto > 0 then
				custoAura = math.max(5, custoAura - reducaoCusto * 5)
			end
			local cdTR = grauAlocacao["CD do TR"] or 0
			if cdTR > 0 then
				tr.total = tr.total + cdTR
			end
			grauDano = (grauAlocacao["Dano"] or grauAlocacao["Dano/Cura"] or 0)
		end
	end

	local hatsu = {
		Id = HatsuService.NextId(character),
		Nome = build.nome,
		Tipo = catalog.label,
		Natureza = detectarNatureza(efeitosEscolhidos),
		Efeitos = efeitosEscolhidos,
		Restricoes = restricoesAplicadas,
		Graus = { Dano = grauDano },
		GrauInicial = grauAlocacao,
		CustoAura = custoAura,
		TR = tr.total,
		PNUsados = custoLiquido,
		Ativo = false,
	}
	table.insert(character.Hatsus, hatsu)

	local pnRestante = NenService.CalcPNDisponivelParaHatsu(character, nil)
	local conquistas = AchievementService.CheckAllLiveAchievements(character)
	return {
		success = true,
		hatsu = hatsu,
		conquistas = conquistas,
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
	local pesosSelecionados = {}
	local restricoesAplicadas = {}
	for _, r in ipairs(build.restricoes or {}) do
		local restr = findRestriction(restrictionCatalog, r.id)
		if not restr then
			return { success = false, error = "Restrição desconhecida: " .. tostring(r.id) }
		end
		if restr.peso == "extrema" then
			extremeCount = extremeCount + 1
		end
		table.insert(pesosSelecionados, restr.peso)
		local pura = r.pura or false
		local ganho = 0
		if pura and restr.pura then
			ganho = restr.pura
			pnRestaurado = pnRestaurado + ganho
		end
		local penalidadeVital = nil
		if RESTRICOES_ESCOLHA_VITAL[restr.id] then
			penalidadeVital = r.penalidadeVital
			if penalidadeVital ~= "PV" and penalidadeVital ~= "Sanidade" then
				return { success = false, error = "\"" .. restr.nome .. "\" exige escolher entre perder PV ou Sanidade permanentemente." }
			end
		end
		table.insert(restricoesAplicadas, {
			id = restr.id, nome = restr.nome, peso = restr.peso, pura = pura, ganho = ganho, trBonus = restr.trBonus or 0, penalidadeVital = penalidadeVital,
		})
	end
	-- Nota: "Dano Permanente" (rg_p3) NAO reaplica a perda de PV/Sanidade
	-- aqui -- so acontece uma vez, na criacao (HatsuService.CreateHatsuV2).
	-- Editar um Hatsu que ja tinha essa restricao so atualiza o registro.

	local catalog = getMergedCatalogForCharacter(character, extremeCount, pesosSelecionados, build.efeitos)

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
		table.insert(efeitosEscolhidos, { id = efeito.id, nome = efeito.nome, custo = efeito.custo, trBonus = efeito.trBonus or 0, prereqNomes = efeito.prereqNomes, prereqAttrMin = efeito.prereqAttrMin, desc = efeito.desc })
	end

	local prereqErr = validatePrereqNames(efeitosEscolhidos, character)
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

	local custoAura = calcCustoAura(efeitosEscolhidos, restricoesAplicadas, character)
	local tr = HatsuService.CalcTR(character, efeitosEscolhidos, restricoesAplicadas)

	hatsu.Nome = build.nome
	hatsu.Natureza = detectarNatureza(efeitosEscolhidos)
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

	if character.EmZetsu then
		return { success = false, error = "Você está em Zetsu (aura zerada) e não pode ativar Hatsus. Ative outro princípio de Nen para sair do Zetsu primeiro." }
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

	-- "Dano Permanente Constante" (rg_e4): perde 5 de PV ou Sanidade
	-- PERMANENTEMENTE a cada ativacao bem-sucedida (ja passou do gate
	-- de aura acima, entao a ativacao vai mesmo acontecer).
	for _, r in ipairs(hatsu.Restricoes or {}) do
		if r.id == "rg_e4" and r.penalidadeVital then
			CharacterServiceRef.ApplyPermanentVitalLoss(character, r.penalidadeVital, 5)
		end
	end

	local categoryId = getCategoryId(character)
	local natureza = hatsu.Natureza or detectarNatureza(hatsu.Efeitos or {})
	local attrs = character.Attributes or {}
	local principalModRaw, attrKey = getPrincipalAttrInfo(character, categoryId, hatsu.Efeitos)
	local principalMod = math.max(0, principalModRaw)
	local conVal = (attrs.CON and attrs.CON.value) or 10
	local conMod = math.max(0, math.floor((conVal - 10) / 2))

	local cura = 0
	local rd = 0
	local critico = 20
	for _, e in ipairs(hatsu.Efeitos or {}) do
		local mec = parseMechanicalEffect(e.desc)
		if mec then
			if mec.tipo == "cura" then
				local rolagemCura = 0
				for _ = 1, mec.n do
					rolagemCura = rolagemCura + math.random(1, mec.dado)
				end
				local attrMod = (mec.attr == "CON" or not mec.attr) and conMod or math.max(0, math.floor(((attrs[mec.attr] and attrs[mec.attr].value or 10) - 10) / 2))
				cura = cura + rolagemCura + attrMod
			elseif mec.tipo == "rd" then
				rd = math.max(rd, mec.valor)
			elseif mec.tipo == "critico" then
				critico = math.max(2, critico - mec.valor)
			end
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

	-- Base de dano: SO existe (2d6+atributo) se o Hatsu tiver "Dano/Cura
	-- Focal" (eg15) -- confirmado com o Lucas. Sem esse efeito, o dano
	-- vem SO da soma dos efeitos comprados (sem base fixa nenhuma).
	local temDanoCuraFocal = false
	for _, e in ipairs(hatsu.Efeitos or {}) do
		if e.id == "eg15" then
			temDanoCuraFocal = true
			break
		end
	end

	local dano = 0
	local partes = {}
	if temDanoCuraFocal then
		-- Grau 0 por enquanto (compra repetida/REN/graus de restricao
		-- ainda nao alimentam isto -- pendencia da proxima etapa).
		local nBase, dBase = stepDieTable(DIE_TABLE_START_DANO_CURA_FOCAL, (hatsu.Graus and hatsu.Graus.Dano) or 0)
		local rolagemBase = 0
		for _ = 1, nBase do
			rolagemBase = rolagemBase + math.random(1, dBase)
		end
		dano = rolagemBase + principalMod
		table.insert(partes, nBase .. "d" .. dBase .. "=" .. rolagemBase)
		table.insert(partes, tostring(principalMod))
	end
	for _, e in ipairs(hatsu.Efeitos or {}) do
		local mec = parseMechanicalEffect(e.desc)
		if mec then
			if mec.tipo == "dano_dado" then
				local rolagemExtra = 0
				for _ = 1, mec.n do
					rolagemExtra = rolagemExtra + math.random(1, mec.dado)
				end
				dano = dano + rolagemExtra
				table.insert(partes, tostring(e.nome) .. " " .. mec.n .. "d" .. mec.dado .. "=" .. rolagemExtra)
			elseif mec.tipo == "dano_fixo" then
				dano = dano + mec.valor
				table.insert(partes, tostring(e.nome) .. " +" .. mec.valor)
			end
		end
	end
	local rolagem = math.random(1, 20)
	local ehCritico = rolagem >= critico
	local conquistaCritico = AchievementService.CheckCritico(character, rolagem)
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
		conquista = conquistaCritico,
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
