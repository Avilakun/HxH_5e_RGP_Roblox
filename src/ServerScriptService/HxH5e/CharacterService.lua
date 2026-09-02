--[[
    HxH5e CharacterService (M0.8 + Afinidade/Genialidade exatas)
    Lógica server-authoritative. O ServerBootstrap é o orquestrador.
    Criação: nome + afinidade de Nen (1d100) + genialidade (2d20).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local HxH5e = ReplicatedStorage:WaitForChild("HxH5e")
local CharacterSchema = require(HxH5e:WaitForChild("Shared"):WaitForChild("CharacterSchema"))
local SystemDB = require(HxH5e:WaitForChild("Shared"):WaitForChild("SystemDB"))
local CharacterRepository = require(script.Parent:WaitForChild("CharacterRepository"))
local ConditionsDB = require(HxH5e:WaitForChild("Shared"):WaitForChild("ConditionsDB"))
local ItemsDB = require(HxH5e:WaitForChild("Shared"):WaitForChild("ItemsDB"))

local CharacterService = {}

-- ================= Config =================

local NAME_MIN = 1
local NAME_MAX = 24
local NAME_FORBIDDEN = "[<>%[%]{}|/\:\";%?%*%c]"

-- ================= Tabelas do app (js/data/nen-affinity.js) =================
-- CATEGORY_ROLL_TABLE EXATA (1d100) — conferida no arquivo enviado.

local NEN_CATEGORY_ROLL_TABLE = {
	{ min = 1,  max = 18,  classId = "INTENSIFICAÇÃO" },
	{ min = 19, max = 36,  classId = "TRANSMUTAÇÃO" },
	{ min = 37, max = 54,  classId = "MATERIALIZAÇÃO" },
	{ min = 55, max = 72,  classId = "EMISSÃO" },
	{ min = 73, max = 90,  classId = "MANIPULAÇÃO" },
	{ min = 91, max = 100, classId = "ESPECIALIZAÇÃO" },
}

-- Genialidade (2d20). Limites derivados da distribuição de 2d20 (400 combinações),
-- batendo com as % do app (creator.js): Normal ~78,5% / Talentoso ~18,5% / Gênio ~2,5% / Ultimate ~0,25%.
-- ⚠️ Se o app tiver uma tabela própria de genialidade, ajustar aqui (1 lugar só).
local NEN_GENIUS_TABLE = {
	{ min = 40, max = 40, tier = "Ultimate",  efeito = "XP dobrado + 5 Graus de Potência para distribuir livremente." },
	{ min = 37, max = 39, tier = "Genio",     efeito = "Recebe XP 1,5x maior em qualquer situação." },
	{ min = 29, max = 36, tier = "Talentoso", efeito = "+2 Graus de Potência para distribuir na criação do Primeiro Hatsu." },
	{ min = 2,  max = 28, tier = "Normal",    efeito = "Segue a evolução padrão do sistema." },
}

local function rollNenAffinity()
	local roll = math.random(1, 100)
	local category = "INTENSIFICAÇÃO"
	for _, entry in ipairs(NEN_CATEGORY_ROLL_TABLE) do
		if roll >= entry.min and roll <= entry.max then
			category = entry.classId
			break
		end
	end
	local tier
	if roll <= 20 then
		tier = "Baixa"
	elseif roll <= 50 then
		tier = "Media"
	elseif roll <= 80 then
		tier = "Alta"
	else
		tier = "Excepcional"
	end
	return category, tier, roll
end

local function rollNenGenius()
	local d1 = math.random(1, 20)
	local d2 = math.random(1, 20)
	local roll = d1 + d2
	local tier = "Normal"
	local efeito = "Segue a evolução padrão do sistema."
	for _, entry in ipairs(NEN_GENIUS_TABLE) do
		if roll >= entry.min and roll <= entry.max then
			tier = entry.tier
			efeito = entry.efeito
			break
		end
	end
	return tier, roll, efeito
end

-- ================= Sessões em memória =================

local sessions = {}

local function getSession(player)
	local session = sessions[player]
	if not session then
		session = { characters = {}, activeCharacterId = nil, loaded = false }
		sessions[player] = session
	end
	return session
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, item in pairs(value) do
		copy[key] = deepCopy(item)
	end
	return copy
end

local function sanitizeName(rawName)
	if type(rawName) ~= "string" then
		return nil
	end
	local name = rawName:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if #name < NAME_MIN or #name > NAME_MAX then
		return nil
	end
	if name:match(NAME_FORBIDDEN) then
		return nil
	end
	return name
end

-- ================= Racas (SystemDB) =================

local function findRaceByName(raceName)
	if type(raceName) ~= "string" then
		return nil
	end
	for _, race in ipairs(SystemDB.racas) do
		if race.nome == raceName then
			return race
		end
	end
	return nil
end

-- Aplica aumento_atributo da raca ao character.Attributes.
-- Só aplica quando aumento_atributo é uma tabela de {ATTR = delta}.
-- Quando é um texto ("Escolha +2", "Distribua 3 pontos...", etc.) fica
-- registrado em character.RaceBonusPending para o jogador escolher depois
-- (wizard de escolha ainda não implementado — pendência conhecida).
local function applyRaceBonus(character, race)
	if not race then
		return
	end
	local bonus = race.aumento_atributo
	if type(bonus) == "table" then
		for attr, delta in pairs(bonus) do
			local entry = character.Attributes[attr]
			if entry then
				entry.value = entry.value + delta
			else
				-- Atributo especial da raca (ex.: INT_ou_SAB, Fisico) que nao
				-- existe no schema padrao: guarda para revisao manual.
				character.RaceBonusPending = character.RaceBonusPending or {}
				table.insert(character.RaceBonusPending, attr .. " +" .. tostring(delta))
			end
		end
	elseif type(bonus) == "string" and bonus ~= "Nenhum" then
		character.RaceBonusPending = character.RaceBonusPending or {}
		table.insert(character.RaceBonusPending, bonus)
	end
end

function CharacterService.GetRaces()
	local list = {}
	for _, race in ipairs(SystemDB.racas) do
		table.insert(list, {
			nome = race.nome,
			descricao = race.descricao,
			categoria = race.categoria,
			fonte = race.fonte,
			aumento_atributo = race.aumento_atributo,
			caracteristicas = race.caracteristicas,
			opcoes_caracteristica = race.opcoes_caracteristica,
		})
	end
	return list
end

-- ================= Escolha manual de bonus racial em texto livre =================
-- Identico ao webapp (supabase.js: getBonusRequirements). Duas formas:
-- "wildcard": distribui N pontos livremente entre quaisquer atributos
--   ("Escolha +2" = 2 pontos; "Distribua 3 pontos..." = 3 pontos).
-- "choice": escolhe UM atributo de uma lista restrita e ganha o valor
--   cheio nele (ex.: Kurta escolhe INT ou SAB, ganha +2 no escolhido).
local function getRaceBonusRequirement(race)
	if not race then
		return nil
	end
	local bonus = race.aumento_atributo
	if bonus == "Distribua 3 pontos em qualquer atributo" then
		return { type = "wildcard", amount = 3 }
	end
	if bonus == "Escolha +2" then
		return { type = "wildcard", amount = 2 }
	end
	if type(bonus) == "table" then
		if bonus.INT_ou_SAB then
			return { type = "choice", keys = { "INT", "SAB" }, amount = bonus.INT_ou_SAB }
		end
		if bonus["Físico"] then
			return { type = "choice", keys = { "FOR", "DES", "CON" }, amount = bonus["Físico"] }
		end
	end
	return nil
end

function CharacterService.GetRaceBonusInfo(raceName)
	local race = findRaceByName(raceName)
	return getRaceBonusRequirement(race)
end

local function applyRaceBonusAllocations(character, req, allocations)
	local validAttrs = { FOR = true, DES = true, CON = true, INT = true, SAB = true, PRE = true }
	if type(allocations) ~= "table" then
		return false, "Alocação de bônus racial inválida."
	end
	if req.type == "wildcard" then
		local total = 0
		for attr, amt in pairs(allocations) do
			if not validAttrs[attr] then
				return false, "Atributo inválido: " .. tostring(attr)
			end
			if type(amt) ~= "number" or amt < 0 or amt ~= math.floor(amt) then
				return false, "Valor de bônus inválido para " .. tostring(attr)
			end
			total = total + amt
		end
		if total ~= req.amount then
			return false, "A soma dos pontos alocados (" .. total .. ") precisa ser exatamente " .. req.amount .. "."
		end
		for attr, amt in pairs(allocations) do
			if amt > 0 then
				character.Attributes[attr].value = character.Attributes[attr].value + amt
			end
		end
	elseif req.type == "choice" then
		local chosenAttr, chosenAmt
		local count = 0
		for attr, amt in pairs(allocations) do
			count = count + 1
			chosenAttr, chosenAmt = attr, amt
		end
		if count ~= 1 then
			return false, "Escolha exatamente um atributo."
		end
		if not table.find(req.keys, chosenAttr) then
			return false, "Atributo " .. tostring(chosenAttr) .. " não é uma opção válida (permitido: " .. table.concat(req.keys, ", ") .. ")."
		end
		if chosenAmt ~= req.amount then
			return false, "O bônus deve ser exatamente +" .. req.amount .. "."
		end
		character.Attributes[chosenAttr].value = character.Attributes[chosenAttr].value + chosenAmt
	end
	return true, nil
end

-- ================= Atributos: compra de pontos (point buy) =================
-- Identico ao webapp (creator.js/buyStat): cada atributo comeca em 10,
-- SYSTEM_DB.pointBuyCosts[valor] da o custo (pode ser negativo, ou seja,
-- baixar o atributo devolve pontos), soma total nao pode passar de 20.
-- Faixa permitida: 1 a 30 (igual ao webapp, sem clamp mais apertado).
local POINT_BUY_MAX = 20
local ATTR_KEYS = { "FOR", "DES", "CON", "INT", "SAB", "PRE" }

local function pointBuyCost(value)
	return SystemDB.pointBuyCosts[value] or 0
end

-- ================= Limite de atributo (sem Hatsu) =================
-- Regra do sistema (confirmada com o Lucas): sem bonus de Hatsu, nenhum
-- atributo pode passar de 22 (modificador +6). Validado APOS o bonus racial
-- ser aplicado, ja que ele pode empurrar o valor acima do que o point-buy
-- sozinho permitiria.
local ATTR_HARD_CAP = 22

local function validateAttributeCap(character)
	for _, key in ipairs(ATTR_KEYS) do
		local value = character.Attributes[key].value
		if value > ATTR_HARD_CAP then
			return false, key .. " ficaria em " .. value .. ", acima do limite de " .. ATTR_HARD_CAP .. " (mod +" .. math.floor((ATTR_HARD_CAP - 10) / 2) .. ") sem uso de Hatsu. Reduza a compra de pontos nesse atributo."
		end
	end
	return true, nil
end

function CharacterService.GetPointBuyInfo()
	return {
		costs = SystemDB.pointBuyCosts,
		maxCost = POINT_BUY_MAX,
		defaultValue = 10,
	}
end

-- Valida e retorna a tabela de atributos final (ou nil + erro).
-- attributesBuild = { FOR=15, DES=10, ... } (todas as 6 chaves obrigatorias)
local function validateAttributesBuild(attributesBuild)
	if type(attributesBuild) ~= "table" then
		return nil, "Atributos não enviados."
	end
	local totalCost = 0
	for _, key in ipairs(ATTR_KEYS) do
		local value = attributesBuild[key]
		if type(value) ~= "number" or value < 1 or value > 30 or value ~= math.floor(value) then
			return nil, "Valor inválido para " .. key .. "."
		end
		totalCost = totalCost + pointBuyCost(value)
	end
	if totalCost > POINT_BUY_MAX then
		return nil, "Pontos gastos (" .. totalCost .. ") excedem o máximo de " .. POINT_BUY_MAX .. "."
	end
	return attributesBuild, nil
end

-- ================= Atributos: Rolagem e Array Padrao =================
-- Identico ao webapp (sheet.js): rollAllStats / applyStandardArray.
-- Rolagem: 6x rola 4d6 (cada resultado 1 é re-rolado UMA vez), soma os
-- 3 maiores dos 4, descarta o menor. Array Padrao: banco fixo.
-- Em ambos os casos o jogador distribui os 6 valores livremente entre
-- os atributos (nao é ordem fixa) -- por isso o servidor guarda o banco
-- "pendente" na sessao e so aceita a distribuicao final se ela for
-- EXATAMENTE uma permutacao do banco (nunca confia em valores enviados
-- pelo cliente sem conferir contra o que foi realmente sorteado aqui).

local STANDARD_ARRAY = { 15, 14, 13, 12, 10, 8 }

local function rollAttributePool()
	local pool = {}
	for i = 1, 6 do
		local dice = {}
		for j = 1, 4 do
			local d = math.random(1, 6)
			if d == 1 then
				d = math.random(1, 6) -- re-rola 1 uma unica vez
			end
			table.insert(dice, d)
		end
		table.sort(dice, function(a, b) return a > b end)
		table.insert(pool, dice[1] + dice[2] + dice[3]) -- soma os 3 maiores, descarta o menor
	end
	table.sort(pool, function(a, b) return a > b end)
	return pool
end

function CharacterService.RollAttributePool(player)
	local session = getSession(player)
	-- Trava anti-farm: so pode rolar UMA VEZ por tentativa de criacao de
	-- personagem (pedido explicito do Lucas -- sem isso, o jogador
	-- poderia clicar repetidamente ate sair um resultado bom). A trava
	-- reseta quando um personagem e criado com sucesso (proxima
	-- tentativa comeca livre de novo).
	if session.attrPoolLocked then
		return { locked = true, error = "Você já rolou os atributos para este personagem. Não é possível rolar de novo." }
	end
	local pool = rollAttributePool()
	session.pendingAttrPool = pool
	session.attrPoolLocked = true
	return pool
end

function CharacterService.GetStandardArray(player)
	local session = getSession(player)
	session.pendingAttrPool = deepCopy(STANDARD_ARRAY)
	return session.pendingAttrPool
end

-- Confere se attributesBuild (mapa atributo->valor) é EXATAMENTE uma
-- permutacao de "pool" (mesmos 6 numeros, cada um usado uma vez).
local function validatePoolAssignment(attributesBuild, pool)
	if type(attributesBuild) ~= "table" then
		return nil, "Atributos não enviados."
	end
	if type(pool) ~= "table" or #pool ~= 6 then
		return nil, "Nenhuma rolagem ou array pendente. Role os atributos ou use o array padrão antes de confirmar."
	end
	local poolCount = {}
	for _, v in ipairs(pool) do
		poolCount[v] = (poolCount[v] or 0) + 1
	end
	for _, key in ipairs(ATTR_KEYS) do
		local value = attributesBuild[key]
		if type(value) ~= "number" then
			return nil, "Valor inválido para " .. key .. "."
		end
		if not poolCount[value] or poolCount[value] <= 0 then
			return nil, "Os valores enviados não batem com a rolagem/array atual. Role de novo."
		end
		poolCount[value] = poolCount[value] - 1
	end
	return attributesBuild, nil
end

-- ================= Antecedentes (SystemDB) =================

local function findBackgroundByName(bgName)
	if type(bgName) ~= "string" then
		return nil
	end
	for _, bg in ipairs(SystemDB.antecedentes) do
		if bg.nome == bgName then
			return bg
		end
	end
	return nil
end

-- ================= Equipamento do antecedente (com escolha) =================
-- Cada entrada de background.equipamento e um TEXTO. 3 formatos:
-- 1) "Qualquer arma simples" / "Qualquer arma" -- exige escolha do
--    jogador entre as armas do catalogo. ⚠️ LIMITACAO: o ItemsDB.lua
--    atual nao tem a distincao Simples/Marcial (foi simplificado ao
--    portar do webapp) -- por ora aceita QUALQUER arma do catalogo,
--    nao so as "simples" de verdade. Documentado pra revisar se
--    precisar filtrar direito depois.
-- 2) "X ou Y" (sem "Qualquer") -- exige escolha entre as opcoes
--    exatas separadas por " ou ".
-- 3) Texto fixo (ex: "Roupas Comuns") -- sem escolha. Se bater com um
--    item real do ItemsDB, usa ele; senao, vira uma entrada narrativa
--    (sem peso/custo mecanico).
local function isChoiceEntry(texto)
	return texto:find("Qualquer", 1, true) ~= nil or texto:find(" ou ", 1, true) ~= nil
end

local function getChoiceOptions(texto)
	if texto:find("Qualquer arma simples", 1, true) then
		-- Agora que ItemsDB.armas tem subcategoria (simples_*/marciais_*/
		-- cientificas_*/cerco), filtra de verdade pelas simples -- antes
		-- listava TODAS as armas indiscriminadamente (limitacao
		-- documentada e resolvida junto com o resgate das tags do
		-- webapp).
		local opcoes = {}
		for _, arma in ipairs(ItemsDB.armas) do
			if arma.subcategoria and arma.subcategoria:find("simples", 1, true) then
				table.insert(opcoes, arma.nome)
			end
		end
		return opcoes
	end
	if texto:find("Qualquer arma", 1, true) then
		local opcoes = {}
		for _, arma in ipairs(ItemsDB.armas) do
			table.insert(opcoes, arma.nome)
		end
		return opcoes
	end
	if texto:find(" ou ", 1, true) then
		local opcoes = {}
		for parte in (texto .. " ou "):gmatch("(.-) ou ") do
			table.insert(opcoes, parte)
		end
		return opcoes
	end
	return { texto }
end

-- Resolve UMA entrada de equipamento (com a escolha do jogador se for
-- o caso) num item de inventario { Name, Qty }. Retorna nil + erro se
-- invalido.
local function resolveEquipmentEntry(texto, escolhaJogador)
	if isChoiceEntry(texto) then
		local opcoes = getChoiceOptions(texto)
		if not escolhaJogador then
			return nil, "Precisa escolher uma opção para: " .. texto
		end
		local valido = false
		for _, opt in ipairs(opcoes) do
			if opt == escolhaJogador then valido = true break end
		end
		if not valido then
			return nil, "Escolha inválida para \"" .. texto .. "\": " .. tostring(escolhaJogador)
		end
		return { Name = escolhaJogador, Qty = 1 }
	end
	return { Name = texto, Qty = 1 }
end

function CharacterService.GetBackgrounds()
	local list = {}
	for _, bg in ipairs(SystemDB.antecedentes) do
		table.insert(list, {
			nome = bg.nome,
			descricao = bg.descricao,
			proficiencias = bg.proficiencias,
			caracteristicas = bg.caracteristicas,
			equipamento = bg.equipamento,
		})
	end
	return list
end

-- ================= Inclinações (SystemDB) =================
-- Regra identica ao webapp (sheet.js): GENERAL_INC_BASIC_MAX_CUSTO = 3.
-- freeCost = MAIOR custo entre as positivas selecionadas com custo <= 3
-- (nao soma, so a maior; zero se nenhuma qualificar).
-- paidCost = max(0, somaCustoPositivas - freeCost)
-- balance = somaValorNegativas - paidCost; precisa ser >= 0 pra ser valido.
-- somaValorNegativas tem teto de 10 pontos.
local GENERAL_INC_BASIC_MAX_CUSTO = 3
local NEGATIVE_MAX_TOTAL = 10

-- ================= Restrição: só básicas na criação =================
-- Divergência conhecida entre o Manual e o webapp atual (o webapp ainda
-- não filtra isso, mas vai ser corrigido numa atualização futura dele).
-- Confirmado com o Lucas: na CRIAÇÃO do personagem só as Inclinações
-- Gerais Básicas ficam disponíveis (o resto — Ambidestria, Aleijado etc. —
-- são desbloqueadas depois, via progressão de nível: "Inclinações de
-- Combate/Gerais" nos níveis 2, 4, 7 e 11). Lista fixa, por segurança
-- (não inferida por posição no array, que não bate 1:1 pros dois lados).
local BASIC_POSITIVE_NAMES = {
	["Aliado"] = true,
	["Contatos"] = true,
	["Corpo de Gigante"] = true,
	["Empatia com Animais"] = true,
	["Fôlego"] = true,
	["Inventor"] = true,
	["Ligação com a Máfia"] = true,
	["Sentidos Aguçados"] = true,
	["Sorte Grande"] = true,
	["Tempo de Vida Estendido (Anomalia)"] = true,
	["Visão no Escuro"] = true,
}
local BASIC_NEGATIVE_NAMES = {
	["Avareza"] = true,
	["Azar Grande"] = true,
	["Desatencioso"] = true,
	["Dívida"] = true,
	["Esquecido"] = true,
	["Honestidade"] = true,
	["Indeciso"] = true,
	["Inimigo"] = true,
	["Inveja"] = true,
	["Veracidade"] = true,
	["Nanismo"] = true,
}

local function getBasicPositivas()
	local list = {}
	for _, inc in ipairs(SystemDB.inclinacoes.positivas) do
		if BASIC_POSITIVE_NAMES[inc.nome] then
			table.insert(list, inc)
		end
	end
	return list
end

local function getBasicNegativas()
	local list = {}
	for _, inc in ipairs(SystemDB.inclinacoes.negativas) do
		if BASIC_NEGATIVE_NAMES[inc.nome] then
			table.insert(list, inc)
		end
	end
	return list
end

function CharacterService.GetInclinations()
	return {
		positivas = getBasicPositivas(),
		negativas = getBasicNegativas(),
		basicMaxCusto = GENERAL_INC_BASIC_MAX_CUSTO,
		negativeMaxTotal = NEGATIVE_MAX_TOTAL,
	}
end

-- ================= Pericias / Treinamentos =================
-- Identico ao webapp (creator.js, step 5 "Treinamentos"):
-- - Pericias do antecedente (texto livre em background.proficiencias) sao
--   detectadas por substring e adicionadas automaticamente, sem contar
--   contra o limite manual.
-- - Ate 5 pericias PRINCIPAIS (SystemDB.skills) manuais, alem das do
--   antecedente.
-- - "Outros Treinamentos" (SystemDB.otherSkills): limite de 4, ou 5 se o
--   antecedente ja mencionar "Kit" ou "Ferramenta" no texto (hasBgKit).
--   Quando hasBgKit, o item "Kits" fica travado (concedido automaticamente,
--   nao pode ser escolhido manualmente de novo).
local MAIN_SKILLS_MAX_MANUAL = 5

local function getBgSkillsText(background)
	return (background and background.proficiencias) or ""
end

local function computeAutoSkills(bgText)
	local autoSkills = {}
	for _, skill in ipairs(SystemDB.skills) do
		if bgText ~= "" and bgText:find(skill, 1, true) then
			table.insert(autoSkills, skill)
		end
	end
	return autoSkills
end

local function hasBgKit(bgText)
	return bgText ~= "" and (bgText:find("Kit", 1, true) ~= nil or bgText:find("Ferramenta", 1, true) ~= nil)
end

function CharacterService.GetSkillsInfo(backgroundName)
	local background = findBackgroundByName(backgroundName)
	local bgText = getBgSkillsText(background)
	local autoSkills = computeAutoSkills(bgText)
	local kitFromBg = hasBgKit(bgText)
	return {
		skills = SystemDB.skills,
		otherSkills = SystemDB.otherSkills,
		autoSkills = autoSkills,
		maxMain = MAIN_SKILLS_MAX_MANUAL,
		maxOther = kitFromBg and 5 or 4,
		kitsLocked = kitFromBg,
		bgProficienciasText = bgText,
	}
end

-- Valida pericias escolhidas. Retorna (skillsFinais, otherSkillsFinais, erro)
local function validateSkills(background, chosenSkills, chosenOtherSkills)
	local bgText = getBgSkillsText(background)
	local autoSkills = computeAutoSkills(bgText)
	local autoSet = {}
	for _, s in ipairs(autoSkills) do
		autoSet[s] = true
	end

	local validSkillSet = {}
	for _, s in ipairs(SystemDB.skills) do
		validSkillSet[s] = true
	end

	local manualSkills = {}
	for _, s in ipairs(chosenSkills or {}) do
		if not validSkillSet[s] then
			return nil, nil, "Perícia desconhecida: " .. tostring(s)
		end
		if not autoSet[s] then
			table.insert(manualSkills, s)
		end
	end
	if #manualSkills > MAIN_SKILLS_MAX_MANUAL then
		return nil, nil, "Você escolheu " .. #manualSkills .. " perícias manuais, o máximo é " .. MAIN_SKILLS_MAX_MANUAL .. " (perícias do antecedente não contam)."
	end

	-- combina auto + manual, sem duplicar
	local skillsFinal = {}
	local seen = {}
	for _, s in ipairs(autoSkills) do
		if not seen[s] then table.insert(skillsFinal, s); seen[s] = true end
	end
	for _, s in ipairs(manualSkills) do
		if not seen[s] then table.insert(skillsFinal, s); seen[s] = true end
	end

	local kitLocked = hasBgKit(bgText)
	local maxOther = kitLocked and 5 or 4
	local validOtherSet = {}
	for _, s in ipairs(SystemDB.otherSkills) do
		validOtherSet[s] = true
	end

	local otherSkillsFinal = {}
	for _, s in ipairs(chosenOtherSkills or {}) do
		if not validOtherSet[s] then
			return nil, nil, "Treinamento desconhecido: " .. tostring(s)
		end
		if s == "Kits" and kitLocked then
			return nil, nil, "\"Kits\" já é concedido automaticamente pelo antecedente, não precisa (nem pode) escolher de novo."
		end
		table.insert(otherSkillsFinal, s)
	end
	if #otherSkillsFinal > maxOther then
		return nil, nil, "Você escolheu " .. #otherSkillsFinal .. " outros treinamentos, o máximo é " .. maxOther .. "."
	end
	if kitLocked then
		table.insert(otherSkillsFinal, "Kits")
	end

	return skillsFinal, otherSkillsFinal, nil
end

-- Acha uma inclinacao (ou uma opcao dela) pelo "nome completo" enviado
-- pelo cliente. Para itens com hasOptions, o nome completo e "Pai: Opcao"
-- (igual ao webapp: `${inc.nome}: ${opt.label}`).
local function findInclination(catalogList, fullName)
	for _, inc in ipairs(catalogList) do
		if inc.hasOptions then
			for _, opt in ipairs(inc.options or {}) do
				if (inc.nome .. ": " .. opt.label) == fullName then
					return { nome = fullName, custo = opt.custo, valor = opt.valor }
				end
			end
		elseif inc.nome == fullName then
			return { nome = inc.nome, custo = inc.custo, valor = inc.valor }
		end
	end
	return nil
end

-- Valida a lista de inclinacoes escolhidas e retorna as listas finais
-- (com custo/valor resolvidos do catalogo, nunca confiando em valores
-- enviados pelo cliente) ou nil + erro.
local function validateInclinations(positiveNames, negativeNames)
	local positiveList = {}
	local posCost = 0
	for _, name in ipairs(positiveNames or {}) do
		local inc = findInclination(getBasicPositivas(), name)
		if not inc then
			return nil, nil, "Inclinação positiva desconhecida ou não disponível na criação: " .. tostring(name)
		end
		table.insert(positiveList, { Nome = inc.nome, Custo = inc.custo })
		posCost = posCost + inc.custo
	end

	local negativeList = {}
	local negVal = 0
	for _, name in ipairs(negativeNames or {}) do
		local inc = findInclination(getBasicNegativas(), name)
		if not inc then
			return nil, nil, "Inclinação negativa desconhecida ou não disponível na criação: " .. tostring(name)
		end
		table.insert(negativeList, { Nome = inc.nome, Valor = inc.valor })
		negVal = negVal + inc.valor
	end

	if negVal > NEGATIVE_MAX_TOTAL then
		return nil, nil, "Pontos negativos (" .. negVal .. ") excedem o máximo de " .. NEGATIVE_MAX_TOTAL .. "."
	end

	local freeCost = 0
	for _, item in ipairs(positiveList) do
		if item.Custo <= GENERAL_INC_BASIC_MAX_CUSTO and item.Custo > freeCost then
			freeCost = item.Custo
		end
	end
	local paidCost = math.max(0, posCost - freeCost)

	if paidCost > negVal then
		return nil, nil, "Positivas custam " .. paidCost .. " P.N (após desconto), mas suas negativas só cobrem " .. negVal .. ". Adicione mais negativas ou remova positivas."
	end

	return positiveList, negativeList, nil
end

local function findCharacterByName(session, name)
	local lowerName = name:lower()
	for _, character in ipairs(session.characters) do
		if character.Name:lower() == lowerName then
			return character
		end
	end
	return nil
end

local function findCharacterById(session, characterId)
	for _, character in ipairs(session.characters) do
		if character.Id == characterId then
			return character
		end
	end
	return nil
end

local function getActiveCharacterFromSession(session)
	return findCharacterById(session, session.activeCharacterId)
end

-- ================= Normalização (formato antigo → v0.3) =================

local function normalizeCharacter(char)
	if type(char) ~= "table" then
		return char
	end
	local defaults = deepCopy(CharacterSchema.Defaults)

	if type(char.Attributes) == "table" then
		for _, key in ipairs({ "FOR", "DES", "CON", "INT", "SAB", "PRE" }) do
			local current = char.Attributes[key]
			if type(current) == "number" then
				char.Attributes[key] = { value = current, save = false }
			elseif type(current) == "table" then
				char.Attributes[key] = {
					value = current.value or defaults.Attributes[key].value,
					save = current.save or false,
				}
			else
				char.Attributes[key] = deepCopy(defaults.Attributes[key])
			end
		end
	else
		char.Attributes = deepCopy(defaults.Attributes)
	end

	local oldVitals = char.Vitals
	char.Vitals = deepCopy(defaults.Vitals)
	if type(oldVitals) == "table" then
		if type(oldVitals.HP) == "table" then
			char.Vitals.HP = { Current = oldVitals.HP.Current or 0, Max = oldVitals.HP.Max or 0 }
		elseif type(oldVitals.HP) == "number" then
			char.Vitals.HP = { Current = oldVitals.HP, Max = oldVitals.HP }
		end
		if type(oldVitals.Aura) == "table" then
			char.Vitals.Aura = { Current = oldVitals.Aura.Current or 100, Max = oldVitals.Aura.Max or 100 }
		elseif type(oldVitals.Aura) == "number" then
			char.Vitals.Aura = { Current = oldVitals.Aura, Max = oldVitals.Aura }
		end
		local oldSan = oldVitals.Sanidade or oldVitals.Sanity
		if type(oldSan) == "table" then
			char.Vitals.Sanidade = { Current = oldSan.Current or 100, Max = oldSan.Max or 100 }
		elseif type(oldSan) == "number" then
			char.Vitals.Sanidade = { Current = oldSan, Max = oldSan }
		end
		char.Vitals.RDM = oldVitals.RDM or 0
		char.Vitals.CA = oldVitals.CA or defaults.Vitals.CA
		char.Vitals.Reacoes = oldVitals.Reacoes or oldVitals.Rea or defaults.Vitals.Reacoes
		char.Vitals.Deslocamento = oldVitals.Deslocamento or oldVitals.Desl or defaults.Vitals.Deslocamento
		char.Vitals.DeslocamentoPlanar = oldVitals.DeslocamentoPlanar or 0
	end
	if char.Race == "Vampiros" and not char.VampiroCasta then
		-- Vampiro criado antes desse campo existir: entra na casta base.
		char.VampiroCasta = "Vampiro"
		char.Vitals.DeslocamentoPlanar = 3
	end

	local function ensureArray(name)
		if type(char[name]) ~= "table" then
			char[name] = {}
		end
	end
	ensureArray("Hatsus")
	ensureArray("Skills")
	ensureArray("Expertise")
	ensureArray("Inventory")
	ensureArray("Conditions")
	ensureArray("History")
	ensureArray("Organizacoes")
	ensureArray("VampiroSeresDrenados")
	ensureArray("GostosEscolhidos")
	ensureArray("DesgostosEscolhidos")
	if type(char.TagCooldowns) ~= "table" then
		char.TagCooldowns = {}
	end
	if type(char.VampiroAuraTotalDrenada) ~= "number" then
		char.VampiroAuraTotalDrenada = 0
	end
	if type(char.Alignment) ~= "string" then
		char.Alignment = "Neutro"
	end
	if type(char.Money) ~= "number" then
		char.Money = defaults.Money or 0
	end
	if type(char.Inclinations) ~= "table" then
		char.Inclinations = { Positive = {}, Negative = {} }
	end
	if type(char.Bio) ~= "table" then
		char.Bio = deepCopy(defaults.Bio)
	else
		-- Preenche campos novos (Historia/Organizacoes/Inimigos/Aliados)
		-- em personagens que ja tinham Bio de antes dessa expansao.
		for key, defaultVal in pairs(defaults.Bio) do
			if char.Bio[key] == nil then
				char.Bio[key] = defaultVal
			end
		end
	end

	-- Nen: garante estrutura + migra formato antigo
	if type(char.Nen) ~= "table" then
		char.Nen = deepCopy(defaults.Nen)
	end
	if type(char.Nen.Affinity) ~= "table" then
		char.Nen.Affinity = deepCopy(defaults.Nen.Affinity)
	end
	if type(char.Nen.Dominio) ~= "table" then
		char.Nen.Dominio = deepCopy(defaults.Nen.Dominio)
	end
	local dominio = char.Nen.Dominio
	if dominio.In ~= nil then
		-- migração In → Inp (app usa inp para não conflitar com keyword)
		if dominio.Inp == nil then
			dominio.Inp = dominio.In
			dominio.Inp_sup = dominio.In_sup or false
			dominio.Inp_pn = dominio.In_pn or 0
		end
		dominio.In = nil
		dominio.In_sup = nil
		dominio.In_pn = nil
	end

	-- Personagens antigos sem categoria/genialidade: rola agora (M0.9 precisa)
	if not char.Nen.Category then
		local category, tier, roll = rollNenAffinity()
		char.Nen.Category = category
		char.Class = category
		char.Nen.Affinity.Roll = roll
		char.Nen.Affinity.Tier = tier
	end
	if not char.Nen.Genius or not char.Nen.Genius.Tier then
		local geniusTier, geniusRoll = rollNenGenius()
		char.Nen.Genius = { Roll = geniusRoll, Tier = geniusTier }
	end

	char.Name = char.Name or "Personagem"
	char.Level = char.Level or defaults.Level
	char.CharacterType = char.CharacterType or defaults.CharacterType
	char.ControlMode = char.ControlMode or defaults.ControlMode

	return char
end

-- ================= Persistência =================

function CharacterService.SavePlayer(player)
	local session = sessions[player]
	if not session then
		return
	end
	CharacterRepository.Save(player, {
		characters = session.characters,
		activeCharacterId = session.activeCharacterId,
	})
end

-- ================= Carregamento (chamado pelo Bootstrap) =================

function CharacterService.LoadPlayer(player)
	local session = getSession(player)
	if session.loaded then
		return
	end
	session.loaded = true

	local data = CharacterRepository.Load(player)

	if data and type(data.characters) == "table" and #data.characters > 0 then
		session.characters = data.characters

		for i, character in ipairs(session.characters) do
			session.characters[i] = normalizeCharacter(character)
		end

		local activeId = data.activeCharacterId
		if type(activeId) ~= "string" or not findCharacterById(session, activeId) then
			local index = data.activeIndex
			if type(index) == "number" and session.characters[index] then
				activeId = session.characters[index].Id
			else
				activeId = session.characters[1].Id
			end
		end
		session.activeCharacterId = activeId
	else
		session.characters = {}
		session.activeCharacterId = nil
	end
end

-- ================= Consultas =================

function CharacterService.GetActiveCharacter(player)
	local session = getSession(player)
	return getActiveCharacterFromSession(session)
end

function CharacterService.GetCharacters(player)
	local session = getSession(player)
	local list = {}
	for _, character in ipairs(session.characters) do
		table.insert(list, {
			Id = character.Id,
			Name = character.Name,
			Level = character.Level,
			IsActive = (character.Id == session.activeCharacterId),
		})
	end
	return list
end

-- ================= Ações =================

function CharacterService.SetActiveCharacter(player, characterId)
	if type(characterId) ~= "string" then
		return false
	end
	local session = getSession(player)
	if findCharacterById(session, characterId) then
		session.activeCharacterId = characterId
		return true
	end
	return false
end

-- ================= Vitais na criação (formula confirmada no webapp: sheet.js) =================
-- HP inicial = 15 + mod(CON) | CA = 10 + mod(CON) | Reações = 7 + mod(SAB)
-- Aura e Sanidade sempre começam fixas em 100/100. Deslocamento padrao 9m
-- (racas com deslocamento diferente, ex. Formiga Quimera com fqPreset,
-- ainda nao aplicam esse ajuste aqui — pendencia conhecida).
local function attrMod(value)
	return math.floor(((value or 10) - 10) / 2)
end

-- Deslocamento base por raca (identico ao webapp: a maioria das racas
-- nao menciona deslocamento, entao usa o padrao 9m -- so estas 3 tem um
-- valor diferente documentado explicitamente no texto da caracteristica
-- "Tamanho Pequeno"/"Deslocamento" de cada uma. Golias tambem tem uma
-- caracteristica "Deslocamento de 9m" mas isso ja bate com o padrao,
-- entao nao precisa de entrada aqui. Formiga Quimera e Vampiros tem
-- deslocamento variavel/condicional (por preset escolhido ou por
-- evolucao de casta) -- pendencia documentada, nao coberta por este
-- mapa simples.
local RACE_DESLOCAMENTO = {
	["Anões"] = 7.5,
	["Halflings"] = 7.5,
	["Gnomos"] = 7.5,
}

-- ================= Vampiros: Casta e Deslocamento Planar =================
-- "Tamanho Médio. Deslocamento de 9m comum e 3m planar (aumenta em 3m
-- para cada casta que sobe: Vampiro, Lorde Vampiro, Conde Vampiro,
-- Imperador Vampiro)." -- todo Vampiro comeca na casta mais baixa
-- (Vampiro) com 3m planar; sobe de casta depois da criacao (decisao do
-- mestre/narrativa), nao e algo que o jogador escolhe ao criar.
local VAMPIRO_CASTA_ORDEM = { "Vampiro", "Lorde Vampiro", "Conde Vampiro", "Imperador Vampiro" }
local VAMPIRO_CASTA_PLANAR = { ["Vampiro"] = 3, ["Lorde Vampiro"] = 6, ["Conde Vampiro"] = 9, ["Imperador Vampiro"] = 12 }

-- Requisitos REAIS de cada promocao (documento do Lucas, extraido do
-- livro de Vampiros). Cada requisito checavel automaticamente vira
-- uma funcao que le o estado do personagem; os que dependem de coisas
-- narrativas/fora do alcance do sistema ficam documentados como tal
-- e sao pulados na checagem automatica (o mestre decide via
-- PromoteVampiroCasta mesmo assim, mas agora ve o que falta).
--
-- "Vampiro -> Lorde": sobreviver Exaustao Severa (3o nivel) [SEM
-- rastreamento de exaustao no sistema ainda -- nao checavel],
-- absorver aura de 5 seres diferentes [checavel via VampiroSeresDrenados],
-- Ten e Ren maestria [checavel via Nen.Dominio].
--
-- "Lorde -> Conde": sobreviver ferimento quase-fatal 10%-5% PV depois
-- de virar Lorde [checavel via VampiroSobreviveuFerimentoFatal, setado
-- pelo mesmo gancho do CheckPVBaixo], drenar 300% de aura somada
-- [checavel via VampiroAuraTotalDrenada], aprender Gyo e In [checavel
-- via Nen.Dominio.Gyo e Nen.Dominio.Inp].
--
-- "Conde -> Imperador": todos os principios de Nen [checavel],
-- derrotar 2 Condes Vampiros [SEM PvP/inimigos nomeados -- nao
-- checavel automaticamente, fica pra confirmacao manual do mestre
-- via Conquista], "ser aceito pelos demais condes e vampiros"
-- [mapeado pra reputacao maxima na organizacao "Vampiros" -- ver
-- OrganizationsDB.lua].
local function checarRequisitosPromocao(character, proxima)
	local faltando = {}
	local dominio = (character.Nen and character.Nen.Dominio) or {}

	if proxima == "Lorde Vampiro" then
		if (character.VampiroSeresDrenados and #character.VampiroSeresDrenados or 0) < 5 then
			table.insert(faltando, "Absorver aura de 5 seres diferentes (tem " .. (character.VampiroSeresDrenados and #character.VampiroSeresDrenados or 0) .. ")")
		end
		if (dominio.Ten or 0) < 3 or (dominio.Ren or 0) < 3 then
			table.insert(faltando, "Ten e Ren em maestria (grau 3)")
		end
		table.insert(faltando, "⚠️ Sobreviver a Exaustão Severa (3º nível) -- sem rastreamento de exaustão no sistema, confirme manualmente")
	elseif proxima == "Conde Vampiro" then
		if not character.VampiroSobreviveuFerimentoFatal then
			table.insert(faltando, "Sobreviver a um ferimento quase-fatal (5%-10% de PV) como Lorde Vampiro")
		end
		if (character.VampiroAuraTotalDrenada or 0) < 300 then
			table.insert(faltando, "Drenar 300% de aura somada (tem " .. math.floor(character.VampiroAuraTotalDrenada or 0) .. "%)")
		end
		if not dominio.Gyo or not dominio.Inp then
			table.insert(faltando, "Aprender Gyo e In")
		end
	elseif proxima == "Imperador Vampiro" then
		local todos = { "Ten", "Ren", "Zetsu", "En", "Inp", "Gyo", "Shu", "Ken", "Ko", "Ryu" }
		for _, p in ipairs(todos) do
			if not dominio[p] or dominio[p] <= 0 then
				table.insert(faltando, "Aprender todos os princípios de Nen (falta " .. p .. ")")
				break
			end
		end
		table.insert(faltando, "⚠️ Derrotar 2 outros Condes Vampiros -- sem PvP, confirme manualmente (Conquista)")
		local orgVampiros = false
		for _, m in ipairs(character.Organizacoes or {}) do
			if m.orgId == "vampiros" and m.nivel >= 5 then
				orgVampiros = true
			end
		end
		if not orgVampiros then
			table.insert(faltando, "Ser aceito pelos demais Condes/Vampiros (nível 5 na organização Vampiros)")
		end
	end

	return faltando
end

-- Promove o Vampiro pra proxima casta (uso do mestre/narrativa, fora do
-- fluxo de criacao). Retorna { success, message/error, faltando }.
-- force=true ignora a checagem de requisitos (override do mestre).
function CharacterService.PromoteVampiroCasta(character, force)
	if not character or character.Race ~= "Vampiros" then
		return { success = false, error = "Só personagens da raça Vampiros têm casta." }
	end
	local atual = character.VampiroCasta or "Vampiro"
	local indiceAtual = table.find(VAMPIRO_CASTA_ORDEM, atual) or 1
	if indiceAtual >= #VAMPIRO_CASTA_ORDEM then
		return { success = false, error = "Já está na casta máxima (Imperador Vampiro)." }
	end
	local proxima = VAMPIRO_CASTA_ORDEM[indiceAtual + 1]

	if not force then
		local faltando = checarRequisitosPromocao(character, proxima)
		if #faltando > 0 then
			return { success = false, error = "Requisitos pendentes para " .. proxima .. ":", faltando = faltando }
		end
	end

	character.VampiroCasta = proxima
	character.Vitals.DeslocamentoPlanar = VAMPIRO_CASTA_PLANAR[proxima]
	if proxima == "Conde Vampiro" then
		character.VampiroSobreviveuFerimentoFatal = false -- reseta pro proximo requisito (Lorde->Conde ja consumido)
	end
	return { success = true, message = "Promovido para " .. proxima .. " (+" .. VAMPIRO_CASTA_PLANAR[proxima] .. "m de deslocamento planar)." }
end

-- Corpo de Gigante (inclinacao positiva, ver SystemDB): "+5 HP inicial
-- e +3 por nivel". O +3 por nivel ja esta conectado no LevelUpService
-- (giantBonus no dado de vida). O +5 inicial e aplicado aqui.
local function hasCorpoDeGigante(character)
	for _, inc in ipairs((character.Inclinations and character.Inclinations.Positive) or {}) do
		if inc.Nome == "Corpo de Gigante" then
			return true
		end
	end
	return false
end

-- ================= Perda permanente de PV/Sanidade =================
-- Reutilizavel por qualquer fonte (restricoes de Hatsu como "Dano
-- Permanente"/"Dano Permanente Constante", itens, maldicoes futuras
-- etc.). Reduz o MAXIMO pra sempre (nao so o atual), e ajusta o atual
-- pra baixo se ele tiver ficado acima do novo maximo.
function CharacterService.ApplyPermanentVitalLoss(character, tipo, quantidade)
	if quantidade <= 0 then
		return
	end
	if tipo == "PV" then
		character.Vitals.HP.Max = math.max(1, character.Vitals.HP.Max - quantidade)
		character.Vitals.HP.Current = math.min(character.Vitals.HP.Current, character.Vitals.HP.Max)
	elseif tipo == "Sanidade" then
		character.Vitals.Sanidade.Max = math.max(0, character.Vitals.Sanidade.Max - quantidade)
		character.Vitals.Sanidade.Current = math.min(character.Vitals.Sanidade.Current, character.Vitals.Sanidade.Max)
	end
end

-- Aura Gigantesca (inclinacao positiva, ver SystemDB): "+30% de Aura
-- maxima" -- a OUTRA forma (alem da escolha de evolucao por nivel) de
-- a Aura maxima do personagem sair de 100%. IMPORTANTE: "Aura
-- Gigantesca" NAO esta na lista de inclinacoes basicas (so liberam na
-- criacao "Aliado", "Corpo de Gigante" etc, ver BASIC_POSITIVE_NAMES) --
-- entao essa funcao nunca dispara de verdade NA CRIACAO hoje. Fica
-- pronta pro futuro: quando existir um fluxo de "adicionar inclinacao
-- depois via P.I" (Pontos de Inclinacao do level-up), esse fluxo vai
-- precisar CHAMAR essa mesma logica de novo (ou recalcular a Aura Max
-- do zero) pra aplicar o bonus -- initVitals so roda uma vez, na
-- criacao, entao ganhar essa inclinacao DEPOIS nao aplica o +30%
-- sozinho ainda.
local function hasAuraGigantesca(character)
	for _, inc in ipairs((character.Inclinations and character.Inclinations.Positive) or {}) do
		if inc.Nome == "Aura Gigantesca" then
			return true
		end
	end
	return false
end

local function initVitals(character, race)
	local modCon = attrMod(character.Attributes.CON.value)
	local modSab = attrMod(character.Attributes.SAB.value)
	local hpInicial = 15 + modCon
	if hasCorpoDeGigante(character) then
		hpInicial = hpInicial + 5
	end
	character.Vitals.HP = { Current = hpInicial, Max = hpInicial }
	local auraInicial = 100
	if hasAuraGigantesca(character) then
		auraInicial = auraInicial + 30
	end
	character.Vitals.Aura = { Current = auraInicial, Max = auraInicial }
	character.Vitals.Sanidade = { Current = 100, Max = 100 }
	character.Vitals.CA = 10 + modCon
	character.Vitals.Reacoes = 7 + modSab
	character.Vitals.Deslocamento = (race and RACE_DESLOCAMENTO[race.nome]) or 9
	if race and race.nome == "Vampiros" then
		character.VampiroCasta = "Vampiro"
		character.Vitals.DeslocamentoPlanar = VAMPIRO_CASTA_PLANAR["Vampiro"]
	else
		character.Vitals.DeslocamentoPlanar = 0
	end
end

-- ================= Formiga Quimera (regra especial, sem Antecedente) =================
-- Identico ao webapp (creator.js): a raca "Formiga Quimera" nao segue o
-- fluxo normal de aumento_atributo. Em vez disso: escolhe uma "Origem
-- da Fagogenese" (visual predominante, de SystemDB.racas[].fagogenese_options),
-- um Tamanho (Miudo/Pequeno/Medio, cada um com efeito de atributo
-- diferente) e ate 3 Caracteristicas da Especie (de
-- SystemDB.racas[].caracteristicas, algumas com sub-opcao obrigatoria
-- quando tem campo "opcoes"). Referencias prontas (fqPresets) e a
-- escolha extra de Voo/Escalada pra Insetos ficam de fora por ora
-- (sao so cosmeticas/preenchimento automatico no webapp, nao travam
-- nada -- pendencia de baixa prioridade).
local FQ_TAMANHOS = { ["Miúdo"] = true, ["Pequeno"] = true, ["Médio"] = true }

local function applyFormigaQuimera(character, race, fqData)
	if not fqData then
		return true, nil
	end
	local origem = fqData.fagogenese
	local opcoesOrigem = race.fagogenese_options or {}
	local origemValida = false
	for _, o in ipairs(opcoesOrigem) do
		if o == origem then origemValida = true break end
	end
	if not origemValida then
		return false, "Origem da Fagogênese inválida. Opções: " .. table.concat(opcoesOrigem, ", ")
	end
	character.Fagogenese = origem

	local tamanho = fqData.tamanho or "Médio"
	if not FQ_TAMANHOS[tamanho] then
		return false, "Tamanho inválido (use Miúdo, Pequeno ou Médio)."
	end
	character.FqTamanho = tamanho
	if tamanho == "Miúdo" then
		character.Attributes.DES.value = character.Attributes.DES.value + 2
		character.Attributes.FOR.value = character.Attributes.FOR.value - 1
		character.Attributes.CON.value = character.Attributes.CON.value - 1
	elseif tamanho == "Pequeno" then
		character.Attributes.DES.value = character.Attributes.DES.value + 1
		local penalidade = fqData.pequenoPenalidade or "FOR"
		if penalidade ~= "FOR" and penalidade ~= "CON" then
			return false, "Penalidade de Tamanho Pequeno precisa ser FOR ou CON."
		end
		character.Attributes[penalidade].value = character.Attributes[penalidade].value - 1
		character.FqPequenoPenalidade = penalidade
	end

	local tracosDisponiveis = {}
	for _, c in ipairs(race.caracteristicas or {}) do
		tracosDisponiveis[c.nome] = c
	end
	local tracosEscolhidos = fqData.traits or {}
	if #tracosEscolhidos > 3 then
		return false, "Escolha no máximo 3 Características da Espécie."
	end
	local tracosFinal = {}
	local detalhesFinal = {}
	for _, nomeTraco in ipairs(tracosEscolhidos) do
		local def = tracosDisponiveis[nomeTraco]
		if not def then
			return false, "Característica de espécie desconhecida: " .. tostring(nomeTraco)
		end
		table.insert(tracosFinal, nomeTraco)
		if def.opcoes and #def.opcoes > 0 then
			local detalhe = (fqData.traitDetails or {})[nomeTraco]
			local detalheValido = false
			for _, op in ipairs(def.opcoes) do
				if op == detalhe then detalheValido = true break end
			end
			if not detalheValido then
				return false, "Escolha uma opção válida para \"" .. nomeTraco .. "\": " .. table.concat(def.opcoes, ", ")
			end
			detalhesFinal[nomeTraco] = detalhe
		end
	end
	character.RaceTraits = tracosFinal
	character.TraitDetails = detalhesFinal

	return true, nil
end

function CharacterService.CreateCharacter(player, rawName, raceName, attributesBuild, backgroundName, backgroundFeature, positiveInclinations, negativeInclinations, chosenSkills, chosenOtherSkills, raceBonusAllocations, attrMethod, fqData, raceCaracteristicaEscolhida, equipmentChoices)
	local session = getSession(player)

	local name = sanitizeName(rawName)
	if not name then
		return {
			success = false,
			error = "Nome inválido. Use de " .. NAME_MIN .. " a " .. NAME_MAX .. " caracteres, sem símbolos.",
		}
	end

	local race = findRaceByName(raceName)
	if raceName and not race then
		return {
			success = false,
			error = "Raça desconhecida: " .. tostring(raceName),
		}
	end
	if not race then
		race = findRaceByName("Humano Comum")
	end

	local attrs = attributesBuild
	if attrs then
		local validated, attrErr
		if attrMethod == "rolagem" or attrMethod == "array" then
			local session2 = getSession(player)
			validated, attrErr = validatePoolAssignment(attrs, session2.pendingAttrPool)
		else
			validated, attrErr = validateAttributesBuild(attrs)
		end
		if not validated then
			return { success = false, error = attrErr }
		end
		attrs = validated
	end

	local background = nil
	if backgroundName then
		background = findBackgroundByName(backgroundName)
		if not background then
			return { success = false, error = "Antecedente desconhecido: " .. tostring(backgroundName) }
		end
		if backgroundFeature then
			local featureOk = false
			for _, c in ipairs(background.caracteristicas or {}) do
				if c.nome == backgroundFeature then
					featureOk = true
					break
				end
			end
			if not featureOk then
				return { success = false, error = "Característica de antecedente inválida." }
			end
		end
	end

	local positiveList, negativeList, incErr = validateInclinations(positiveInclinations, negativeInclinations)
	if incErr then
		return { success = false, error = incErr }
	end

	local skillsFinal, otherSkillsFinal, skillErr = validateSkills(background, chosenSkills, chosenOtherSkills)
	if skillErr then
		return { success = false, error = skillErr }
	end

	-- Resolve o equipamento do antecedente (com escolha quando aplicavel).
	-- equipmentChoices e uma tabela indexada 1..N alinhada com
	-- background.equipamento, com a escolha do jogador so nas entradas
	-- que sao "de escolha" (as demais podem vir nil).
	local resolvedEquipment = {}
	if background and background.equipamento then
		local porNome = {}
		for i, entradaTexto in ipairs(background.equipamento) do
			local escolha = equipmentChoices and equipmentChoices[i]
			local item, eqErr = resolveEquipmentEntry(entradaTexto, escolha)
			if not item then
				return { success = false, error = eqErr }
			end
			-- Consolida duplicatas (ex: "Qualquer arma simples" 2x e o
			-- jogador escolheu a mesma arma nas duas -- vira 1 entrada
			-- com Qty=2, nao duas entradas separadas).
			if porNome[item.Name] then
				porNome[item.Name].Qty = porNome[item.Name].Qty + item.Qty
			else
				porNome[item.Name] = item
				table.insert(resolvedEquipment, item)
			end
		end
	end

	if findCharacterByName(session, name) then
		return {
			success = false,
			error = "Já existe um personagem com esse nome.",
		}
	end

	local character = deepCopy(CharacterSchema.Defaults)
	local now = os.time()

	character.Id = HttpService:GenerateGUID(false)
	character.OwnerUserId = player.UserId
	character.Name = name
	character.Race = race and race.nome or nil

	-- Point buy (ou padrao 10 em tudo, se nao enviado)
	if attrs then
		for _, key in ipairs(ATTR_KEYS) do
			character.Attributes[key].value = attrs[key]
		end
	end

	applyRaceBonus(character, race)

	-- Caracteristica de raca ESCOLHIDA (ex.: Anao precisa escolher 1
	-- entre Resiliencia Ana / Estabilidade de Aura / Instinto de Forja).
	-- So exigido se a raca de fato tiver essa lista de opcoes.
	if race and race.opcoes_caracteristica and #race.opcoes_caracteristica > 0 then
		local opcaoValida = nil
		for _, op in ipairs(race.opcoes_caracteristica) do
			if op.nome == raceCaracteristicaEscolhida then
				opcaoValida = op
				break
			end
		end
		if not opcaoValida then
			local nomes = {}
			for _, op in ipairs(race.opcoes_caracteristica) do
				table.insert(nomes, op.nome)
			end
			return { success = false, error = "Escolha uma característica de raça: " .. table.concat(nomes, ", ") }
		end
		character.RaceCaracteristicaEscolhida = opcaoValida.nome
	end

	if race and race.nome == "Formiga Quimera" then
		local fqOk, fqErr = applyFormigaQuimera(character, race, fqData)
		if not fqOk then
			return { success = false, error = fqErr }
		end
	end

	local bonusReq = getRaceBonusRequirement(race)
	if bonusReq and raceBonusAllocations then
		local allocOk, allocErr = applyRaceBonusAllocations(character, bonusReq, raceBonusAllocations)
		if not allocOk then
			return { success = false, error = allocErr }
		end
		character.RaceBonusPending = nil
	end

	local capOk, capErr = validateAttributeCap(character)
	if not capOk then
		return { success = false, error = capErr }
	end

	if background then
		-- Caracteristica do antecedente (ex.: Guarda Costas escolhe entre
		-- "Artista Marcial" ou "Horario de Trabalho") -- SEMPRE uma
		-- escolha (diferente de raca, que pode ter "recebe todas" +
		-- "escolhe 1" separados). Obrigatoria se o antecedente listar
		-- caracteristicas.
		if background.caracteristicas and #background.caracteristicas > 0 then
			local featValida = nil
			for _, c in ipairs(background.caracteristicas) do
				if c.nome == backgroundFeature then
					featValida = c
					break
				end
			end
			if not featValida then
				local nomes = {}
				for _, c in ipairs(background.caracteristicas) do
					table.insert(nomes, c.nome)
				end
				return { success = false, error = "Escolha uma característica do antecedente: " .. table.concat(nomes, ", ") }
			end
			backgroundFeature = featValida.nome
		end

		character.Background = background.nome
		character.BackgroundFeature = backgroundFeature
		character.BackgroundProficiencias = background.proficiencias

		-- Equipamento inicial do antecedente: so itens FIXOS (nome exato
		-- que bate com o catalogo) entram automaticamente. Entradas tipo
		-- "Qualquer arma simples" ou "X ou Y" (escolha) NAO sao auto-
		-- resolvidas ainda -- ficam pendentes de uma tela de escolha
		-- futura (o webapp tem "classifyEquipSlot" pra isso, ainda nao
		-- portado aqui).
		character.Inventory = character.Inventory or {}
		for _, eqNome in ipairs(background.equipamento or {}) do
			if ItemsDB.FindItem(eqNome) then
				local jaTem = nil
				for _, invItem in ipairs(character.Inventory) do
					if invItem.Name == eqNome then jaTem = invItem break end
				end
				if jaTem then
					jaTem.Qty = jaTem.Qty + 1
				else
					table.insert(character.Inventory, { Name = eqNome, Qty = 1 })
				end
			end
		end
	end

	-- Dinheiro inicial. Regra padrao: 1d10 x 100. Excecoes (cada uma
	-- concede dinheiro por um caminho proprio, substituindo a regra
	-- padrao em vez de somar a ela):
	-- - Negociante: ja tem "orcamento de 2.000 $" embutido no proprio
	--   equipamento (nao rola nada).
	-- - Aristocrata + caracteristica "Mauricinho / Patricinha": rola a
	--   Tabela de Playboyzisse (1d4 pra classe social, depois a faixa
	--   de valor semanal daquela classe).
	-- - Criminoso + caracteristica "Traficante": maco fixo de 1.500 $.
	do
		local jaConcedeuDinheiro = false

		if background and background.nome == "Negociante" then
			for _, eqNome in ipairs(background.equipamento or {}) do
				if eqNome:find("$", 1, true) then
					jaConcedeuDinheiro = true
					break
				end
			end
		end

		if not jaConcedeuDinheiro and background and background.nome == "Aristocrata" and backgroundFeature == "Mauricinho / Patricinha" then
			local classeSocial = math.random(1, 4)
			local faixas = {
				{ 50, 150 },   -- 1: Classe Media Alta
				{ 200, 500 },  -- 2: Classe Alta
				{ 600, 1500 }, -- 3: Rico
				{ 2000, 5000 },-- 4: Jogador de aviaozinho de nota de 100 $
			}
			local faixa = faixas[classeSocial]
			character.Money = math.random(faixa[1], faixa[2])
			jaConcedeuDinheiro = true
		end

		if not jaConcedeuDinheiro and background and background.nome == "Criminoso" and backgroundFeature == "Traficante" then
			character.Money = 1500
			jaConcedeuDinheiro = true
		end

		if not jaConcedeuDinheiro then
			character.Money = math.random(1, 10) * 100
		end
	end

	character.Inclinations = { Positive = positiveList, Negative = negativeList }
	character.Skills = skillsFinal
	character.OtherSkills = otherSkillsFinal
	character.Inventory = resolvedEquipment

	character.Level = 0
	character.CharacterType = "PLAYER"
	character.ControlMode = "PLAYER"
	character.CreatedAt = now
	character.UpdatedAt = now

	-- Afinidade de Nen (1d100) — server-authoritative
	local category, tier, roll = rollNenAffinity()
	character.Class = category
	character.Nen.Category = category
	character.Nen.Affinity.Roll = roll
	character.Nen.Affinity.Tier = tier

	-- Genialidade (2d20) — pronta para o M1.0 (Hatsu)
	local geniusTier, geniusRoll = rollNenGenius()
	character.Nen.Genius = { Roll = geniusRoll, Tier = geniusTier }

	initVitals(character, race)

	table.insert(session.characters, character)
	session.activeCharacterId = character.Id
	session.attrPoolLocked = false -- proxima criacao comeca livre pra rolar de novo

	return {
		success = true,
		character = character,
	}
end

-- ================= Bio (texto livre) =================

local BIO_FIELDS = {
	Personality = true, Goals = true, Likes = true, Hates = true,
	Historia = true, Organizacoes = true, Inimigos = true, Aliados = true,
}
local BIO_FIELD_MAX_LEN = 2000

-- ================= Foco de Caça e Ação Protagonista =================
local FOCO_CACA_MAX_LEN = 500

function CharacterService.SetFocoDeCaca(player, characterId, texto)
	if type(texto) ~= "string" then
		return { success = false, error = "Valor inválido." }
	end
	if #texto > FOCO_CACA_MAX_LEN then
		return { success = false, error = "Texto muito longo (máximo " .. FOCO_CACA_MAX_LEN .. " caracteres)." }
	end
	local session = getSession(player)
	local character = findCharacterById(session, characterId)
	if not character then
		return { success = false, error = "Personagem não encontrado." }
	end
	character.FocoDeCaca = texto
	character.UpdatedAt = os.time()
	return { success = true, focoDeCaca = texto }
end

-- So pode usar se: (1) o recurso estiver disponivel e (2) ja tiver um
-- Foco de Caça definido (a mecanica so vale quando ligada a ele, ver
-- CharacterSchema). O EFEITO em si (rerolar com vantagem/desvantagem
-- ou aplicar 3d6) e resolvido manualmente pelo mestre/jogador -- este
-- remote so controla a disponibilidade do recurso.
function CharacterService.UsarAcaoProtagonista(character)
	if character.FocoDeCaca == nil or character.FocoDeCaca == "" then
		return { success = false, error = "Defina um Foco de Caça antes de usar a Ação Protagonista -- ela só vale quando ligada a ele." }
	end
	if not character.AcaoProtagonistaDisponivel then
		return { success = false, error = "Ação Protagonista já usada. Só volta a ficar disponível no início da próxima sessão." }
	end
	character.AcaoProtagonistaDisponivel = false
	character.UpdatedAt = os.time()
	return {
		success = true,
		message = "Ação Protagonista usada. Escolha um efeito com o mestre: (1) inimigo rerola com desvantagem, (2) você rerola com vantagem, ou (3) aplique 3d6 pra diminuir a rolagem do inimigo ou aumentar a sua rolagem anterior.",
	}
end

-- Reset manual (mestre), pro inicio de cada nova sessao -- o sistema
-- nao tem um conceito automatico de "sessao de jogo".
function CharacterService.ResetarAcaoProtagonista(character)
	character.AcaoProtagonistaDisponivel = true
	character.UpdatedAt = os.time()
	return { success = true }
end

function CharacterService.SetBioField(player, characterId, field, value)
	if not BIO_FIELDS[field] then
		return { success = false, error = "Campo de biografia desconhecido: " .. tostring(field) }
	end
	if type(value) ~= "string" then
		return { success = false, error = "Valor inválido." }
	end
	if #value > BIO_FIELD_MAX_LEN then
		return { success = false, error = "Texto muito longo (máximo " .. BIO_FIELD_MAX_LEN .. " caracteres)." }
	end
	local session = getSession(player)
	local character = findCharacterById(session, characterId)
	if not character then
		return { success = false, error = "Personagem não encontrado." }
	end
	character.Bio = character.Bio or {}
	character.Bio[field] = value
	return { success = true }
end

-- ================= Condicoes Mecanicas (ver ConditionsDB.lua) =================
-- character.Conditions e uma lista de { id, grau (so p/ condicoes
-- variaveis), autoGrantedBy (nil = aplicada diretamente, ou o id da
-- condicao que concedeu essa automaticamente, ex.: Cego concede
-- Desprevenido+Lento). Remover uma condicao tambem remove tudo que ELA
-- concedeu, a nao ser que aquilo tambem esteja aplicado por outra fonte.

local function hasConditionId(character, condId)
	for _, entry in ipairs(character.Conditions or {}) do
		if entry.id == condId then
			return true
		end
	end
	return false
end

local function applyConditionInternal(character, condId, grau, autoGrantedBy, visited)
	visited = visited or {}
	if visited[condId] then
		return -- evita loop caso o catalogo algum dia tenha um ciclo
	end
	visited[condId] = true

	local def = ConditionsDB.Get(condId)
	if not def then
		return false, "Condição desconhecida: " .. tostring(condId)
	end

	character.Conditions = character.Conditions or {}

	if def.variavel then
		-- Condicao variavel (Envenenado/Sangramento/Exausto): uma nova
		-- aplicacao IMPOE o novo grau (substitui), como descrito no
		-- material -- nao acumula varias entradas da mesma condicao.
		local jaExiste = nil
		for _, entry in ipairs(character.Conditions) do
			if entry.id == condId then
				jaExiste = entry
				break
			end
		end
		if jaExiste then
			jaExiste.grau = grau
			jaExiste.autoGrantedBy = autoGrantedBy or jaExiste.autoGrantedBy
		else
			table.insert(character.Conditions, { id = condId, grau = grau, autoGrantedBy = autoGrantedBy })
		end
		local grauInfo = def.graus and def.graus[grau]
		if grauInfo and grauInfo.concede then
			for _, subId in ipairs(grauInfo.concede) do
				applyConditionInternal(character, subId, nil, condId, visited)
			end
		end
	else
		-- Condicao fixa: nao duplica a MESMA combinacao (id + fonte), mas
		-- permite fontes independentes concederem o mesmo id (ex.:
		-- Desprevenido vindo de Cego E de Agarrado ao mesmo tempo) --
		-- assim remover uma fonte nao apaga o efeito concedido pela outra.
		local duplicado = false
		for _, entry in ipairs(character.Conditions) do
			if entry.id == condId and entry.autoGrantedBy == autoGrantedBy then
				duplicado = true
				break
			end
		end
		if not duplicado then
			table.insert(character.Conditions, { id = condId, grau = nil, autoGrantedBy = autoGrantedBy })
		end
		if def.concede then
			for _, subId in ipairs(def.concede) do
				applyConditionInternal(character, subId, nil, condId, visited)
			end
		end
	end
	return true
end

function CharacterService.ApplyCondition(character, condId, grau)
	local def = ConditionsDB.Get(condId)
	if not def then
		return { success = false, error = "Condição desconhecida: " .. tostring(condId) }
	end
	if def.variavel and (not grau or not (def.graus and def.graus[grau])) then
		local opcoes = {}
		for g in pairs(def.graus or {}) do table.insert(opcoes, g) end
		return { success = false, error = "\"" .. def.nome .. "\" exige um grau válido: " .. table.concat(opcoes, ", ") }
	end
	local ok, err = applyConditionInternal(character, condId, grau, nil, {})
	if not ok then
		return { success = false, error = err }
	end
	return { success = true, message = def.nome .. " aplicada" .. (grau and (" (" .. grau .. ")") or "") .. "." }
end

function CharacterService.RemoveCondition(character, condId)
	if not character.Conditions then
		return { success = true, message = "Nenhuma condição ativa." }
	end
	-- Remove a condicao pedida (id == condId) E qualquer sub-condicao
	-- QUE ELA TENHA CONCEDIDO (autoGrantedBy == condId). So 1 nivel de
	-- cascata (o catalogo atual nao tem condicoes concedidas que, por
	-- sua vez, concedem outras). Importante: NAO marca o id da
	-- sub-condicao removida como "removido" pra frente -- isso evitaria
	-- por engano remover a mesma sub-condicao concedida por OUTRA fonte
	-- ainda ativa (ex.: Desprevenido concedido tanto por Cego quanto
	-- por Agarrado -- remover Cego nao deve tirar o Desprevenido do
	-- Agarrado).
	for i = #character.Conditions, 1, -1 do
		local entry = character.Conditions[i]
		if entry.id == condId or entry.autoGrantedBy == condId then
			table.remove(character.Conditions, i)
		end
	end
	return { success = true, message = "Condição removida." }
end

-- Efeitos numericos JA conectados (CA e Deslocamento). Nunca mutam o
-- valor base salvo em character.Vitals -- calculam por cima, sob
-- demanda, pra poder aplicar/remover condicoes livremente sem perder
-- o valor original.
function CharacterService.GetConditionModifiers(character)
	local caPenalty = 0
	local deslocFactor = 1
	local deslocZero = false
	local auraCostExtra = 0
	local hpMaxFactor = 1
	local desvantagemHabilidade = false
	local desvantagemAtaque = false
	local vantagemInimigoContra = false
	local ativos = {}
	local graus = {}
	for _, entry in ipairs(character.Conditions or {}) do
		ativos[entry.id] = true
		graus[entry.id] = entry.grau
	end
	if ativos["inconsciente"] or ativos["paralisado"] then
		caPenalty = caPenalty - 10
	end
	if ativos["imovel"] or ativos["paralisado"] then
		deslocZero = true
	end
	if ativos["lento"] or ativos["enredado"] then
		deslocFactor = deslocFactor * 0.5
	end
	if ativos["condenado"] then
		auraCostExtra = auraCostExtra + 5
	end

	-- Exaustao (condicao variavel, ver ConditionsDB): efeitos
	-- cumulativos por nivel (2 e 3 incluem os anteriores).
	local exaustaoGrau = ativos["exausto"] and graus["exausto"]
	if exaustaoGrau == "1" or exaustaoGrau == "2" or exaustaoGrau == "3" then
		desvantagemHabilidade = true
	end
	if exaustaoGrau == "2" or exaustaoGrau == "3" then
		desvantagemAtaque = true
		vantagemInimigoContra = true
		deslocFactor = deslocFactor * 0.5
	end
	if exaustaoGrau == "3" then
		hpMaxFactor = hpMaxFactor * 0.5
		deslocZero = true
	end

	return {
		caPenalty = caPenalty,
		deslocFactor = deslocFactor,
		deslocZero = deslocZero,
		auraCostExtra = auraCostExtra,
		hpMaxFactor = hpMaxFactor,
		desvantagemHabilidade = desvantagemHabilidade,
		desvantagemAtaque = desvantagemAtaque,
		vantagemInimigoContra = vantagemInimigoContra,
	}
end

function CharacterService.GetEffectiveMaxHP(character)
	local mods = CharacterService.GetConditionModifiers(character)
	local base = (character.Vitals and character.Vitals.HP and character.Vitals.HP.Max) or 0
	return math.floor(base * mods.hpMaxFactor)
end

function CharacterService.GetEffectiveCA(character)
	local mods = CharacterService.GetConditionModifiers(character)
	return ((character.Vitals and character.Vitals.CA) or 10) + mods.caPenalty
end

function CharacterService.GetEffectiveDeslocamento(character)
	local mods = CharacterService.GetConditionModifiers(character)
	local base = (character.Vitals and character.Vitals.Deslocamento) or 9
	if mods.deslocZero then
		return 0
	end
	return base * mods.deslocFactor

end

-- ================= Dano recebido (central, generico) =================
-- Usado por QUALQUER fonte de dano contra um personagem -- ataque de
-- inimigo/monstro, condicao, Hatsu hostil, etc. A MESMA funcao serve
-- pra jogador atacado por boneco, monstro, ou (futuramente) PvP --
-- pedido do Lucas: "as mecanicas de acerto e dano devem ser
-- EXATAMENTE iguais para inimigos e personagens".
--
-- RD (Reducao de Dano, ex.: TEN) e calculada por quem chama e passada
-- ja pronta -- CharacterService nao conhece NenService de proposito,
-- pra evitar dependencia circular (CombatService, que ja usa
-- NenService, calcula a RD e passa aqui).
--
-- NAO dispara hooks de conquista/SanityTag/morte -- isso fica a cargo
-- de quem chama (ver CombatService), que ja tem os requires certos.
-- Aqui so o numero muda, puro e testavel.
function CharacterService.ApplyDamage(character, dano, rd)
	dano = math.max(0, dano or 0)
	local danoBloqueado = math.min(dano, rd or 0)
	local danoFinal = dano - danoBloqueado
	local vit = character.Vitals and character.Vitals.HP
	if not vit then
		return { danoFinal = 0, danoBloqueado = danoBloqueado, hpAtual = 0, hpMax = 0, morreu = false }
	end
	local hpMaxEfetivo = CharacterService.GetEffectiveMaxHP(character)
	local hpAntes = math.min(vit.Current, hpMaxEfetivo)
	vit.Current = math.max(0, hpAntes - danoFinal)
	return {
		danoFinal = danoFinal,
		danoBloqueado = danoBloqueado,
		hpAtual = vit.Current,
		hpMax = hpMaxEfetivo,
		morreu = vit.Current <= 0,
	}
end

-- ================= Loja: comprar/vender itens (ver ItemsDB.lua) =================
-- Regra confirmada no webapp (sheet.js): comprar desconta o custo cheio
-- de character.Money; vender devolve METADE do custo original,
-- arredondado pra baixo (math.floor), e decrementa 1 unidade (remove a
-- entrada se Qty chegar a 0). No Roblox isso vai coexistir com NPCs de
-- loja no futuro, mas a logica de base (moeda, inventario, catalogo)
-- fica pronta aqui independente disso.

function CharacterService.BuyItem(character, itemNome, quantidade)
	quantidade = quantidade or 1
	if type(quantidade) ~= "number" or quantidade < 1 or quantidade ~= math.floor(quantidade) then
		return { success = false, error = "Quantidade inválida." }
	end
	local item = ItemsDB.FindItem(itemNome)
	if not item then
		return { success = false, error = "Item desconhecido: " .. tostring(itemNome) }
	end
	local custoTotal = item.custo * quantidade
	character.Money = character.Money or 0
	if character.Money < custoTotal then
		return { success = false, error = "Dinheiro insuficiente. Custo: " .. custoTotal .. ", disponível: " .. character.Money }
	end
	character.Money = character.Money - custoTotal
	character.Inventory = character.Inventory or {}
	local existente = nil
	for _, invItem in ipairs(character.Inventory) do
		if invItem.Name == itemNome then
			existente = invItem
			break
		end
	end
	if existente then
		existente.Qty = existente.Qty + quantidade
	else
		table.insert(character.Inventory, { Name = itemNome, Qty = quantidade })
	end
	return { success = true, message = "Comprou " .. quantidade .. "x " .. itemNome .. " por " .. custoTotal .. ". Dinheiro restante: " .. character.Money }
end

function CharacterService.SellItem(character, itemNome, quantidade)
	quantidade = quantidade or 1
	if type(quantidade) ~= "number" or quantidade < 1 or quantidade ~= math.floor(quantidade) then
		return { success = false, error = "Quantidade inválida." }
	end
	character.Inventory = character.Inventory or {}
	local index, entry = nil, nil
	for i, invItem in ipairs(character.Inventory) do
		if invItem.Name == itemNome then
			index, entry = i, invItem
			break
		end
	end
	if not entry then
		return { success = false, error = "Você não tem \"" .. tostring(itemNome) .. "\" no inventário." }
	end
	if entry.Qty < quantidade then
		return { success = false, error = "Você só tem " .. entry.Qty .. "x, não pode vender " .. quantidade .. "x." }
	end
	local item = ItemsDB.FindItem(itemNome)
	local valorUnitario = item and math.floor(item.custo / 2) or 0
	local valorTotal = valorUnitario * quantidade
	character.Money = (character.Money or 0) + valorTotal
	entry.Qty = entry.Qty - quantidade
	if entry.Qty <= 0 then
		table.remove(character.Inventory, index)
	end
	return { success = true, message = "Vendeu " .. quantidade .. "x " .. itemNome .. " por " .. valorTotal .. ". Dinheiro: " .. character.Money }
end

function CharacterService.DeleteCharacter(player, characterId)
	if type(characterId) ~= "string" then
		return { success = false, error = "ID invalido." }
	end
	local session = getSession(player)
	local index
	local deletedName
	for i, character in ipairs(session.characters) do
		if character.Id == characterId then
			index = i
			deletedName = character.Name
			break
		end
	end
	if not index then
		return { success = false, error = "Personagem nao encontrado." }
	end
	table.remove(session.characters, index)
	if session.activeCharacterId == characterId then
		session.activeCharacterId = session.characters[1] and session.characters[1].Id or nil
	end
	return { success = true, message = "Personagem \"" .. tostring(deletedName) .. "\" excluido." }
end

-- ================= Sair do jogo =================

Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if session then
		CharacterService.SavePlayer(player)
		sessions[player] = nil
	end
end)

return CharacterService
