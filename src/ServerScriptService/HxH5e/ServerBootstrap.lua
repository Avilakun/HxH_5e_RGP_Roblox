--[[
    HxH5e ServerBootstrap (M1.6.2 — Wizard + DeleteHatsu + Combate + Buffs)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HxH5e = ReplicatedStorage:WaitForChild("HxH5e")

--------------------------------------------------
-- REMOTES + EVENTOS (criados primeiro)
--------------------------------------------------

local function getOrCreateRemote(name)
	local remote = HxH5e:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = HxH5e
	end
	return remote
end

local function getOrCreateEvent(name)
	local event = HxH5e:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = HxH5e
	end
	return event
end

local GetCharacter = getOrCreateRemote("GetCharacter")
local GetCharacters = getOrCreateRemote("GetCharacters")
local SetActiveCharacter = getOrCreateRemote("SetActiveCharacter")
local CreateCharacter = getOrCreateRemote("CreateCharacter")
local GetNenStatus = getOrCreateRemote("GetNenStatus")
local TrainPrinciple = getOrCreateRemote("TrainPrinciple")
local ActivatePrinciple = getOrCreateRemote("ActivatePrinciple")
local CreateHatsu = getOrCreateRemote("CreateHatsu")
local GetHatsus = getOrCreateRemote("GetHatsus")
local ActivateHatsu = getOrCreateRemote("ActivateHatsu")
local DeleteHatsu = getOrCreateRemote("DeleteHatsu")
local GainXP = getOrCreateRemote("GainXP")
local AddGrau = getOrCreateRemote("AddGrau")
local AddRestricao = getOrCreateRemote("AddRestricao")
local BasicAttack = getOrCreateRemote("BasicAttack")
local GetHatsuCatalog = getOrCreateRemote("GetHatsuCatalog")
local CreateHatsuV2 = getOrCreateRemote("CreateHatsuV2")
local GetRaces = getOrCreateRemote("GetRaces")
local DeleteCharacter = getOrCreateRemote("DeleteCharacter")
local GetBackgrounds = getOrCreateRemote("GetBackgrounds")
local GetPointBuyInfo = getOrCreateRemote("GetPointBuyInfo")
local GetInclinations = getOrCreateRemote("GetInclinations")
local GetSkillsInfo = getOrCreateRemote("GetSkillsInfo")
local BuffTick = getOrCreateEvent("BuffTick")
local EditHatsu = getOrCreateRemote("EditHatsu")

--------------------------------------------------
-- MÓDULOS (agora que os remotes existem)
--------------------------------------------------

local CharacterService = require(script.Parent:WaitForChild("CharacterService"))
local NenService = require(script.Parent:WaitForChild("NenService"))
local HatsuService = require(script.Parent:WaitForChild("HatsuService"))
local BuffManager = require(script.Parent:WaitForChild("BuffManager"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))

-- ================= DEBOUNCE DE SAVE (evita flood no DataStore) =================
local lastSaveTime = {}
local savePending = {}
local SAVE_INTERVAL = 5 -- segundos entre saves

local function throttledSave(player)
	local key = player.UserId
	local now = os.clock()
	savePending[key] = true
	if not lastSaveTime[key] or (now - lastSaveTime[key]) >= SAVE_INTERVAL then
		lastSaveTime[key] = now
		savePending[key] = false
		CharacterService.SavePlayer(player)
	end
end

task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for key, pending in pairs(savePending) do
			if pending and lastSaveTime[key] and (now - lastSaveTime[key]) >= SAVE_INTERVAL then
				lastSaveTime[key] = now
				savePending[key] = false
				local plr = Players:GetPlayerByUserId(key)
				if plr then
					CharacterService.SavePlayer(plr)
				end
			end
		end
	end
end)

--------------------------------------------------
-- TABELA DE XP (confirmada com o Manual)
--------------------------------------------------

local XP_PARA_PROXIMO = {
	[0] = 50, [1] = 150, [2] = 350, [3] = 500, [4] = 800,
	[5] = 1000, [6] = 1500, [7] = 2500, [8] = 3200, [9] = 4000,
	[10] = 5000, [11] = 6500, [12] = nil,
}

--------------------------------------------------
-- AUMENTO DE ATRIBUTO/AURA (coluna do Manual)
--------------------------------------------------

local EVOLUCAO_MARCOS = {
	[1] = 1,
	[3] = 2,
	[6] = 2,
	[12] = 3,
}

local function getEvolucaoReward(level)
	return EVOLUCAO_MARCOS[level] or 0
end

--------------------------------------------------
-- XP (função compartilhada)
--------------------------------------------------

local function applyXP(player, character, amount)
	character.XP = (character.XP or 0) + amount
	local leveled = false
	local novosPontos = 0
	while true do
		local need = XP_PARA_PROXIMO[character.Level]
		if not need then
			break
		end
		if character.XP >= need then
			character.XP = character.XP - need
			character.Level = character.Level + 1
			leveled = true
			novosPontos = novosPontos + getEvolucaoReward(character.Level)
		else
			break
		end
	end
	character.XPNext = XP_PARA_PROXIMO[character.Level]
	if novosPontos > 0 then
		character.PontosEvolucao = (character.PontosEvolucao or 0) + novosPontos
	end
	character.UpdatedAt = os.time()
	throttledSave(player)
	local msg = "+" .. amount .. " XP. Nível " .. character.Level
	if leveled then
		msg = msg .. " — SUBIU DE NÍVEL!"
		if novosPontos > 0 then
			msg = msg .. " (+" .. novosPontos .. " Ponto(s) de Evolução — total: " .. (character.PontosEvolucao or 0) .. ")"
		end
	end
	return msg
end

--------------------------------------------------
-- PLAYER ENTROU / SAIU
--------------------------------------------------

local function onPlayerAdded(player)
	CharacterService.LoadPlayer(player)

	local character = CharacterService.GetActiveCharacter(player)
	if character then
		local nen = character.Nen or {}
		print("======================================")
		print("HxH5e Engine — Character Bootstrap")
		print("Olá, " .. player.DisplayName .. "!")
		print("HxH5e Character: " .. character.Name)
		print("Nível: " .. character.Level)
		print("Categoria: " .. tostring(nen.Category or character.Class or "?"))
		if nen.Affinity then
			print("Afinidade: " .. tostring(nen.Affinity.Tier) .. " (" .. tostring(nen.Affinity.Roll) .. ")")
		end
		if nen.Genius then
			print("Genialidade: " .. tostring(nen.Genius.Tier) .. " (" .. tostring(nen.Genius.Roll) .. ")")
		end
		print("Pontos de Evolução: " .. tostring(character.PontosEvolucao or 0))
		print("Characters disponíveis: " .. #CharacterService.GetCharacters(player))
		print("======================================")
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	BuffManager.Clear(player)
	Players.PlayerRemoving:Connect(function(player)
		BuffManager.Clear(player)
		-- Salva o estado final ao sair (garante que nada se perca)
		local character = CharacterService.GetActiveCharacter(player)
		if character then
			CharacterService.SavePlayer(player)
		end
	end)
end)

CombatService.Setup(CharacterService)

--------------------------------------------------
-- FICHA
--------------------------------------------------

GetCharacter.OnServerInvoke = function(player)
	return CharacterService.GetActiveCharacter(player)
end

GetCharacters.OnServerInvoke = function(player)
	return CharacterService.GetCharacters(player)
end

SetActiveCharacter.OnServerInvoke = function(player, characterId)
	local success = CharacterService.SetActiveCharacter(player, characterId)
	if success then
		throttledSave(player)
	end
	return success
end

CreateCharacter.OnServerInvoke = function(player, rawName, raceName, attributesBuild, backgroundName, backgroundFeature, positiveInclinations, negativeInclinations, chosenSkills, chosenOtherSkills)
	local result = CharacterService.CreateCharacter(player, rawName, raceName, attributesBuild, backgroundName, backgroundFeature, positiveInclinations, negativeInclinations, chosenSkills, chosenOtherSkills)
	if result and result.success then
		throttledSave(player)
	end
	return result
end

GetRaces.OnServerInvoke = function(player)
	return CharacterService.GetRaces()
end

GetBackgrounds.OnServerInvoke = function(player)
	return CharacterService.GetBackgrounds()
end

GetPointBuyInfo.OnServerInvoke = function(player)
	return CharacterService.GetPointBuyInfo()
end

GetInclinations.OnServerInvoke = function(player)
	return CharacterService.GetInclinations()
end

GetSkillsInfo.OnServerInvoke = function(player, backgroundName)
	return CharacterService.GetSkillsInfo(backgroundName)
end

DeleteCharacter.OnServerInvoke = function(player, characterId)
	local result = CharacterService.DeleteCharacter(player, characterId)
	if result.success then
		throttledSave(player)
	end
	return result
end

--------------------------------------------------
-- NEN
--------------------------------------------------

GetNenStatus.OnServerInvoke = function(player)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return nil
	end
	return NenService.GetNenStatus(character)
end

TrainPrinciple.OnServerInvoke = function(player, principle)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = NenService.TrainPrinciple(character, principle)
	if result.success then
		throttledSave(player)
	end
	return result
end

ActivatePrinciple.OnServerInvoke = function(player, principle)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = NenService.ActivatePrinciple(player, character, principle)
	if result.success then
		if principle ~= "Zetsu" then
			BuffManager.Start(player, principle, 6)
		end
		throttledSave(player)
	end
	return result
end

--------------------------------------------------
-- HATSU
--------------------------------------------------

CreateHatsu.OnServerInvoke = function(player, nome, tipo)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local build = {
		nome = nome,
		tipo = tipo or "Reforço",
		efeitos = { "intensificacao" },
		restricoes = {},
	}
	local result = HatsuService.CreateHatsuV2(character, build)
	if result.success then
		throttledSave(player)
	end
	return result
end

EditHatsu.OnServerInvoke = function(player, hatsuId, build)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = HatsuService.EditHatsu(character, hatsuId, build)
	if result.success then
		throttledSave(player)
	end
	return result
end

GetHatsus.OnServerInvoke = function(player)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return {}
	end
	return HatsuService.GetHatsus(character)
end

ActivateHatsu.OnServerInvoke = function(player, hatsuId)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = HatsuService.ActivateHatsu(character, hatsuId)
	if result.success then
		throttledSave(player)
	end
	return result
end

DeleteHatsu.OnServerInvoke = function(player, hatsuId)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = HatsuService.DeleteHatsu(character, hatsuId)
	if result.success then
		throttledSave(player)
	end
	return result
end

GetHatsuCatalog.OnServerInvoke = function(player, excludeHatsuId)
	local character = CharacterService.GetActiveCharacter(player)
	return HatsuService.GetCatalog(character, excludeHatsuId)
end

CreateHatsuV2.OnServerInvoke = function(player, build)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = HatsuService.CreateHatsuV2(character, build)
	if result.success then
		throttledSave(player)
	end
	return result
end

--------------------------------------------------
-- XP / NÍVEL
--------------------------------------------------

GainXP.OnServerInvoke = function(player, amount)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	amount = tonumber(amount) or 0
	if amount <= 0 then
		return { success = false, error = "Valor de XP inválido." }
	end
	local msg = applyXP(player, character, amount)
	return {
		success = true,
		message = msg,
		level = character.Level,
		xp = character.XP,
		pontosEvolucao = character.PontosEvolucao or 0,
	}
end

--------------------------------------------------
-- COMBATE
--------------------------------------------------

BasicAttack.OnServerInvoke = function(player)
	local result = CombatService.BasicAttack(player)
	if result and result.success and result.killed then
		local character = CharacterService.GetActiveCharacter(player)
		if character then
			result.xpMsg = applyXP(player, character, 10)
		end
	end
	return result
end

--------------------------------------------------
-- GRAUS DE POTÊNCIA
--------------------------------------------------

AddGrau.OnServerInvoke = function(player, hatsuId, caracteristica)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = HatsuService.AddGrau(character, hatsuId, caracteristica)
	if result.success then
		throttledSave(player)
	end
	return result
end

--------------------------------------------------
-- RESTRIÇÕES DE HATSU
--------------------------------------------------

AddRestricao.OnServerInvoke = function(player, hatsuId, restricaoId)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = HatsuService.AddRestricao(character, hatsuId, restricaoId)
	if result.success then
		throttledSave(player)
	end
	return result
end