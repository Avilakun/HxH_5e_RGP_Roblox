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

local CharacterService = {}

-- ================= Config =================

local NAME_MIN = 1
local NAME_MAX = 24
local NAME_FORBIDDEN = "[<>%[%]{}|/\:\";%?%*%c]"

-- ================= Tabelas do app (js/data/nen-affinity.js) =================
local NEN_CATEGORY_ROLL_TABLE = {
	{ min = 1,  max = 18,  classId = "INTENSIFICAÇÃO" },
	{ min = 19, max = 36,  classId = "TRANSMUTAÇÃO" },
	{ min = 37, max = 54,  classId = "MATERIALIZAÇÃO" },
	{ min = 55, max = 72,  classId = "EMISSÃO" },
	{ min = 73, max = 90,  classId = "MANIPULAÇÃO" },
	{ min = 91, max = 100, classId = "ESPECIALIZAÇÃO" },
}

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
		})
	end
	return list
end

-- ================= Atributos: compra de pontos (point buy) =================
local POINT_BUY_MAX = 20
local ATTR_KEYS = { "FOR", "DES", "CON", "INT", "SAB", "PRE" }

local function pointBuyCost(value)
	return SystemDB.pointBuyCosts[value] or 0
end

-- ================= Limite de atributo (sem Hatsu) =================
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

function CharacterService.GetBackgrounds()
	local list = {}
	for _, bg in ipairs(SystemDB.antecedentes) do
		table.insert(list, {
			nome = bg.nome,
			descricao = bg.descricao,
			proficiencias = bg.proficiencias,
			caracteristicas = bg.caracteristicas,
		})
	end
	return list
end

-- ================= Inclinações (SystemDB) =================
local GENERAL_INC_BASIC_MAX_CUSTO = 3
local NEGATIVE_MAX_TOTAL = 10

-- ================= Restrição: só básicas na criação =================
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
	if type(char.Inclinations) ~= "table" then
		char.Inclinations = { Positive = {}, Negative = {} }
	end
	if type(char.Bio) ~= "table" then
		char.Bio = deepCopy(defaults.Bio)
	end

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
		if dominio.Inp == nil then
			dominio.Inp = dominio.In
			dominio.Inp_sup = dominio.In_sup or false
			dominio.Inp_pn = dominio.In_pn or 0
		end
		dominio.In = nil
		dominio.In_sup = nil
		dominio.In_pn = nil
	end

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
local function attrMod(value)
	return math.floor(((value or 10) - 10) / 2)
end

local function initVitals(character)
	local modCon = attrMod(character.Attributes.CON.value)
	local modSab = attrMod(character.Attributes.SAB.value)
	local hpInicial = 15 + modCon
	character.Vitals.HP = { Current = hpInicial, Max = hpInicial }
	character.Vitals.Aura = { Current = 100, Max = 100 }
	character.Vitals.Sanidade = { Current = 100, Max = 100 }
	character.Vitals.CA = 10 + modCon
	character.Vitals.Reacoes = 7 + modSab
	character.Vitals.Deslocamento = 9
end

function CharacterService.CreateCharacter(player, rawName, raceName, attributesBuild, backgroundName, backgroundFeature, positiveInclinations, negativeInclinations, chosenSkills, chosenOtherSkills)
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
		local validated, attrErr = validateAttributesBuild(attrs)
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

	if attrs then
		for _, key in ipairs(ATTR_KEYS) do
			character.Attributes[key].value = attrs[key]
		end
	end

	applyRaceBonus(character, race)

	local capOk, capErr = validateAttributeCap(character)
	if not capOk then
		return { success = false, error = capErr }
	end

	if background then
		character.Background = background.nome
		character.BackgroundFeature = backgroundFeature
		character.BackgroundProficiencias = background.proficiencias
	end

	character.Inclinations = { Positive = positiveList, Negative = negativeList }
	character.Skills = skillsFinal
	character.OtherSkills = otherSkillsFinal

	character.Level = 0
	character.CharacterType = "PLAYER"
	character.ControlMode = "PLAYER"
	character.CreatedAt = now
	character.UpdatedAt = now

	local category, tier, roll = rollNenAffinity()
	character.Class = category
	character.Nen.Category = category
	character.Nen.Affinity.Roll = roll
	character.Nen.Affinity.Tier = tier

	local geniusTier, geniusRoll = rollNenGenius()
	character.Nen.Genius = { Roll = geniusRoll, Tier = geniusTier }

	initVitals(character)

	table.insert(session.characters, character)
	session.activeCharacterId = character.Id

	return {
		success = true,
		character = character,
	}
end

-- ================= Exclusao =================

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