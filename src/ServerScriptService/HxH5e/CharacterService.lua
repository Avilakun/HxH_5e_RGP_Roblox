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
local CharacterRepository = require(script.Parent:WaitForChild("CharacterRepository"))

local CharacterService = {}

-- ================= Config =================

local MAX_CHARACTERS = 6
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

function CharacterService.CreateCharacter(player, rawName)
	local session = getSession(player)

	local name = sanitizeName(rawName)
	if not name then
		return {
			success = false,
			error = "Nome inválido. Use de " .. NAME_MIN .. " a " .. NAME_MAX .. " caracteres, sem símbolos.",
		}
	end

	if #session.characters >= MAX_CHARACTERS then
		return {
			success = false,
			error = "Limite de " .. MAX_CHARACTERS .. " personagens atingido.",
		}
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

	table.insert(session.characters, character)
	session.activeCharacterId = character.Id

	return {
		success = true,
		character = character,
	}
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