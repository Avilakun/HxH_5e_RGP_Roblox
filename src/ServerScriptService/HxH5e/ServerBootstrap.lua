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
local AttemptReaction = getOrCreateRemote("AttemptReaction")
local EnemyTelegraph = getOrCreateEvent("EnemyTelegraph")
local EnemyAttackResult = getOrCreateEvent("EnemyAttackResult")
local GetHatsuCatalog = getOrCreateRemote("GetHatsuCatalog")
local GetGrauOptions = getOrCreateRemote("GetGrauOptions")
local SetBioField = getOrCreateRemote("SetBioField")
local ApplyCondition = getOrCreateRemote("ApplyCondition")
local RemoveCondition = getOrCreateRemote("RemoveCondition")
local GetConditionsCatalog = getOrCreateRemote("GetConditionsCatalog")
local BuyItem = getOrCreateRemote("BuyItem")
local SellItem = getOrCreateRemote("SellItem")
local GetItemsCatalog = getOrCreateRemote("GetItemsCatalog")
local RollAttributePool = getOrCreateRemote("RollAttributePool")
local GetStandardArray = getOrCreateRemote("GetStandardArray")
local GetNextPendingLevel = getOrCreateRemote("GetNextPendingLevel")
local RollHitDie = getOrCreateRemote("RollHitDie")
local GetMediaHitDie = getOrCreateRemote("GetMediaHitDie")
local ConfirmLevelUp = getOrCreateRemote("ConfirmLevelUp")
local CreateHatsuV2 = getOrCreateRemote("CreateHatsuV2")
local GetRaces = getOrCreateRemote("GetRaces")
local GetRaceBonusInfo = getOrCreateRemote("GetRaceBonusInfo")
local DeleteCharacter = getOrCreateRemote("DeleteCharacter")
local GetBackgrounds = getOrCreateRemote("GetBackgrounds")
local GetPointBuyInfo = getOrCreateRemote("GetPointBuyInfo")
local GetInclinations = getOrCreateRemote("GetInclinations")
local GetSkillsInfo = getOrCreateRemote("GetSkillsInfo")
local BuffTick = getOrCreateEvent("BuffTick")
local EditHatsu = getOrCreateRemote("EditHatsu")
local AchievementUnlocked = getOrCreateEvent("AchievementUnlocked")
local GetAchievementsCatalog = getOrCreateRemote("GetAchievementsCatalog")
local GetOrganizations = getOrCreateRemote("GetOrganizations")
local JoinOrganization = getOrCreateRemote("JoinOrganization")
local CreateGuild = getOrCreateRemote("CreateGuild")
local SetAlignment = getOrCreateRemote("SetAlignment")
local SugarAura = getOrCreateRemote("SugarAura")
local PromoteVampiroCasta = getOrCreateRemote("PromoteVampiroCasta")
local GetEffectiveStats = getOrCreateRemote("GetEffectiveStats")
local StartRest = getOrCreateRemote("StartRest")
local CancelRest = getOrCreateRemote("CancelRest")
local RestComplete = getOrCreateEvent("RestComplete")
local GetSanityTagsCatalog = getOrCreateRemote("GetSanityTagsCatalog")
local SetSanityTags = getOrCreateRemote("SetSanityTags")
local SanityTagTriggered = getOrCreateEvent("SanityTagTriggered")

--------------------------------------------------
-- MÓDULOS (agora que os remotes existem)
--------------------------------------------------

local CharacterService = require(script.Parent:WaitForChild("CharacterService"))
local NenService = require(script.Parent:WaitForChild("NenService"))
local HatsuService = require(script.Parent:WaitForChild("HatsuService"))
local BuffManager = require(script.Parent:WaitForChild("BuffManager"))
local LevelUpService = require(script.Parent:WaitForChild("LevelUpService"))
local AchievementService = require(script.Parent:WaitForChild("AchievementService"))
local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))
local TimeService = require(script.Parent:WaitForChild("TimeService"))
local RestService = require(script.Parent:WaitForChild("RestService"))
local SanityTagService = require(script.Parent:WaitForChild("SanityTagService"))
local OrganizationService = require(script.Parent:WaitForChild("OrganizationService"))
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

--------------------------------------------------
-- XP (função compartilhada) -- ver LevelUpService.lua pra tabela
-- completa de recompensas por nivel, dado de vida, RDM etc. Ganhar XP
-- so ENFILEIRA os niveis (character.PendingLevelUps); cada nivel so e
-- efetivado quando o cliente chamar ConfirmLevelUp (depois de rolar o
-- dado de vida e escolher atributo-ou-aura quando aplicavel).
--------------------------------------------------

GetAchievementsCatalog.OnServerInvoke = function(player)
	return AchievementService.GetCatalog()
end

GetOrganizations.OnServerInvoke = function(player)
	return OrganizationService.GetAllOrganizations()
end

-- Reforco intencional (pedido do Lucas): o jogador NUNCA pode mudar
-- a propria reputacao em organizacoes por conta propria -- so sobe/desce
-- automaticamente (ex: futuro sistema de missao, falhar/recusar).
-- OrganizationService.AddReputation existe, mas NUNCA foi exposto como
-- remote publico de proposito -- so chamavel server-side.
local VALID_ALIGNMENTS = { ["Heróico"] = true, ["Caótico"] = true, ["Neutro"] = true, ["Maligno"] = true }
SetAlignment.OnServerInvoke = function(player, alignment)
	if not VALID_ALIGNMENTS[alignment] then
		return { success = false, error = "Tendência inválida." }
	end
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	character.Alignment = alignment
	throttledSave(player)
	return { success = true, alignment = alignment }
end

SugarAura.OnServerInvoke = function(player, modo)
	local result = CombatService.SugarAuraOnDummy(player, modo)
	if result.success then
		throttledSave(player)
	end
	return result
end

PromoteVampiroCasta.OnServerInvoke = function(player, force)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = CharacterService.PromoteVampiroCasta(character, force)
	if result.success then
		throttledSave(player)
	end
	return result
end

-- Expoe os valores EFETIVOS (apos condicoes tipo Exaustao) pro cliente
-- poder mostrar na Ficha/HUD -- ex: deslocamento zerado, HP maximo
-- reduzido, sem precisar recalcular a mesma logica no cliente.
GetEffectiveStats.OnServerInvoke = function(player)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local mods = CharacterService.GetConditionModifiers(character)
	return {
		success = true,
		ca = CharacterService.GetEffectiveCA(character),
		deslocamento = CharacterService.GetEffectiveDeslocamento(character),
		hpMax = CharacterService.GetEffectiveMaxHP(character),
		mods = mods,
	}
end

StartRest.OnServerInvoke = function(player, tipo, periciaEscolhida)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = RestService.IniciarDescanso(player, character, tipo, periciaEscolhida)
	return result
end

CancelRest.OnServerInvoke = function(player)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	return RestService.CancelarDescanso(character)
end

RestService.OnRestComplete = function(player, relatorio)
	RestComplete:FireClient(player, relatorio)
end

GetSanityTagsCatalog.OnServerInvoke = function(player)
	return SanityTagService.GetCatalog()
end

SetSanityTags.OnServerInvoke = function(player, gostos, desgostos)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = SanityTagService.SetTags(character, gostos, desgostos)
	if result.success then
		throttledSave(player)
	end
	return result
end

SanityTagService.OnTagTriggered = function(player, tagId, tipo, valor)
	SanityTagTriggered:FireClient(player, { tagId = tagId, tipo = tipo, valor = valor })
end

JoinOrganization.OnServerInvoke = function(player, orgId)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = OrganizationService.JoinOrganization(character, orgId)
	if result.success then
		throttledSave(player)
	end
	return result
end

CreateGuild.OnServerInvoke = function(player, nome, tipo, tipoEconomico, titulosCustom)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = OrganizationService.CreateGuild(character, nome, tipo, tipoEconomico, titulosCustom)
	if result.success then
		throttledSave(player)
	end
	return result
end

-- Le result.conquista (uma so) e/ou result.conquistas (lista) e dispara
-- o evento de badge pro jogador certo, pra cada conquista NOVA.
local function notificarConquistas(player, result)
	if not result then return end
	if result.conquista then
		AchievementUnlocked:FireClient(player, result.conquista)
		local character = CharacterService.GetActiveCharacter(player)
		if character then
			SanityTagService.OnAchievementUnlocked(player, character)
		end
	end
	if result.conquistas then
		for _, ach in ipairs(result.conquistas) do
			AchievementUnlocked:FireClient(player, ach)
		end
		if #result.conquistas > 0 then
			local character = CharacterService.GetActiveCharacter(player)
			if character then
				SanityTagService.OnAchievementUnlocked(player, character)
			end
		end
	end
end

local function applyXP(player, character, amount)
	local resultado = LevelUpService.QueueLevelUps(character, amount)
	if not resultado.success then
		return resultado.error
	end
	character.UpdatedAt = os.time()
	throttledSave(player)
	local msg = "+" .. resultado.ganho .. " XP"
	if resultado.multiplicador > 1 then
		msg = msg .. " (x" .. resultado.multiplicador .. ")"
	end
	if #resultado.niveisEnfileirados > 0 then
		msg = msg .. " — Nível(is) disponível(is) para confirmar: " .. table.concat(resultado.niveisEnfileirados, ", ") .. "!"
	end
	return msg
end

--------------------------------------------------
-- GUILDAS: pagamento semanal automatico (nunca via remote do jogador,
-- pra evitar trapaça -- so um loop do proprio servidor, que checa se
-- ja passou 1 semana REAL pra cada guilda mercenaria).
--------------------------------------------------

task.spawn(function()
	while true do
		task.wait(3600) -- checa a cada 1h de tempo real (o gatilho real e semanal)
		local ok, orgs = pcall(OrganizationService.GetAllOrganizations)
		if ok then
			for _, org in ipairs(orgs) do
				if org.tipoEconomico == "Mercenaria" then
					pcall(function()
						OrganizationService.ProcessWeeklyPayout(org.id, false, CharacterService.GetActiveCharacter)
					end)
				end
			end
		end
	end
end)

--------------------------------------------------
-- PLAYER ENTROU / SAIU
--------------------------------------------------

-- ================= Pericias: efeito passivo de movimento =================
-- Regra de ouro (ver SkillSystem.lua): Atletismo afeta o movimento no
-- MUNDO de forma passiva, sem rolagem nenhuma -- so aplica direto no
-- Humanoid. Base do Roblox: WalkSpeed=16, JumpHeight=7.2.
-- Formula (provisoria, ver nota de pendencia em SkillSystem.lua sobre
-- a escala de proficiencia): +0.5 WalkSpeed e +5% JumpHeight por ponto
-- de bonus de Atletismo (minimo 0, nunca penaliza).
local function applyPassiveMovement(player)
	local avatarChar = player.Character
	if not avatarChar then return end
	local humanoid = avatarChar:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local rpgChar = CharacterService.GetActiveCharacter(player)
	if not rpgChar then return end
	local bonus = math.max(0, SkillSystem.GetSkillBonus(rpgChar, "Atletismo"))
	humanoid.WalkSpeed = 16 + bonus * 0.5
	humanoid.JumpHeight = 7.2 * (1 + bonus * 0.05)
end

local function onPlayerAdded(player)
	CharacterService.LoadPlayer(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.1) -- garante que o Humanoid ja existe
		applyPassiveMovement(player)
	end)

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
SkillSystem.Setup(CharacterService)
TimeService.Start()
RestService.Setup(CharacterService, CombatService)
SanityTagService.Setup(CharacterService, CombatService)
SanityTagService.Start()

--------------------------------------------------
-- FICHA
--------------------------------------------------

GetCharacter.OnServerInvoke = function(player)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then return nil end

	-- Aliados/Inimigos vindos das Inclinacoes escolhidas na criacao
	-- (pedido do Lucas): "Aliado" (positiva) e "Inimigo"/"Legião de
	-- Inimigos" (negativas) contam, qualquer opcao. Calculado aqui,
	-- NUNCA salvo no character persistido -- por isso uma copia rasa,
	-- pra nao poluir o dado real com um campo derivado.
	-- ⚠️ LIMITACAO: as inclinacoes com opcoes (ex: "Inimigo" tem
	-- Fraco/Medio/Forte) so guardam o NOME generico hoje, nao qual
	-- opcao especifica foi escolhida -- entao aparece so "Inimigo",
	-- sem o detalhe de qual gravidade.
	local aliadosInc, inimigosInc = {}, {}
	for _, inc in ipairs((character.Inclinations and character.Inclinations.Positive) or {}) do
		if inc.Nome == "Aliado" then
			table.insert(aliadosInc, inc.Nome)
		end
	end
	for _, inc in ipairs((character.Inclinations and character.Inclinations.Negative) or {}) do
		if inc.Nome == "Inimigo" or inc.Nome == "Legião de Inimigos" then
			table.insert(inimigosInc, inc.Nome)
		end
	end

	if #aliadosInc == 0 and #inimigosInc == 0 then
		return character
	end

	local copia = table.clone(character)
	copia.Bio = table.clone(character.Bio or {})
	copia.Bio.AliadosInclinacoes = aliadosInc
	copia.Bio.InimigosInclinacoes = inimigosInc
	return copia
end

GetCharacters.OnServerInvoke = function(player)
	return CharacterService.GetCharacters(player)
end

SetActiveCharacter.OnServerInvoke = function(player, characterId)
	local success = CharacterService.SetActiveCharacter(player, characterId)
	if success then
		throttledSave(player)
		applyPassiveMovement(player)
	end
	return success
end

CreateCharacter.OnServerInvoke = function(player, rawName, raceName, attributesBuild, backgroundName, backgroundFeature, positiveInclinations, negativeInclinations, chosenSkills, chosenOtherSkills, raceBonusAllocations, attrMethod, fqData, raceCaracteristicaEscolhida, equipmentChoices)
	local result = CharacterService.CreateCharacter(player, rawName, raceName, attributesBuild, backgroundName, backgroundFeature, positiveInclinations, negativeInclinations, chosenSkills, chosenOtherSkills, raceBonusAllocations, attrMethod, fqData, raceCaracteristicaEscolhida, equipmentChoices)
	if result and result.success then
		throttledSave(player)
		applyPassiveMovement(player)
	end
	return result
end

RollAttributePool.OnServerInvoke = function(player)
	return CharacterService.RollAttributePool(player)
end

GetStandardArray.OnServerInvoke = function(player)
	return CharacterService.GetStandardArray(player)
end

GetRaces.OnServerInvoke = function(player)
	return CharacterService.GetRaces()
end

GetRaceBonusInfo.OnServerInvoke = function(player, raceName)
	return CharacterService.GetRaceBonusInfo(raceName)
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
		notificarConquistas(player, result)
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
		if principle == "Ten" or principle == "Ren" or principle == "Zetsu" then
			SanityTagService.OnPrincipleUsed(player, character)
		end
		throttledSave(player)
		notificarConquistas(player, result)
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
		notificarConquistas(player, result)
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

GetGrauOptions.OnServerInvoke = function(player)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then return { opcoes = {}, total = 5 } end
	return HatsuService.GetGrauOptions(character)
end

SetBioField.OnServerInvoke = function(player, characterId, field, value)
	local result = CharacterService.SetBioField(player, characterId, field, value)
	if result.success then
		throttledSave(player)
	end
	return result
end
ApplyCondition.OnServerInvoke = function(player, condId, grau)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then return { success = false, error = "Nenhum personagem ativo." } end
	local result = CharacterService.ApplyCondition(character, condId, grau)
	if result.success then
		throttledSave(player)
	end
	return result
end

RemoveCondition.OnServerInvoke = function(player, condId)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then return { success = false, error = "Nenhum personagem ativo." } end
	local result = CharacterService.RemoveCondition(character, condId)
	if result.success then
		throttledSave(player)
	end
	return result
end

GetConditionsCatalog.OnServerInvoke = function(player)
	local ConditionsDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("ConditionsDB"))
	return ConditionsDB.Condicoes
end
BuyItem.OnServerInvoke = function(player, itemNome, quantidade)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then return { success = false, error = "Nenhum personagem ativo." } end
	local result = CharacterService.BuyItem(character, itemNome, quantidade)
	if result.success then
		throttledSave(player)
	end
	return result
end

SellItem.OnServerInvoke = function(player, itemNome, quantidade)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then return { success = false, error = "Nenhum personagem ativo." } end
	local result = CharacterService.SellItem(character, itemNome, quantidade)
	if result.success then
		throttledSave(player)
	end
	return result
end

GetItemsCatalog.OnServerInvoke = function(player)
	local ItemsDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("ItemsDB"))
	return ItemsDB.Todos
end

CreateHatsuV2.OnServerInvoke = function(player, build)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo." }
	end
	local result = HatsuService.CreateHatsuV2(character, build)
	if result.success then
		throttledSave(player)
		notificarConquistas(player, result)
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
		pendingLevelUps = character.PendingLevelUps or {},
	}
end

GetNextPendingLevel.OnServerInvoke = function(player)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then return nil end
	return LevelUpService.GetNextPendingLevel(character)
end

RollHitDie.OnServerInvoke = function(player)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then return { success = false, error = "Nenhum personagem ativo." } end
	return LevelUpService.RollHitDie(character)
end

GetMediaHitDie.OnServerInvoke = function(player)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then return { success = false, error = "Nenhum personagem ativo." } end
	return LevelUpService.GetMediaHitDie(character)
end

ConfirmLevelUp.OnServerInvoke = function(player, hitGain, attrChoice)
	local character = CharacterService.GetActiveCharacter(player)
	if not character then return { success = false, error = "Nenhum personagem ativo." } end
	local result = LevelUpService.ConfirmLevelUp(character, hitGain, attrChoice)
	if result.success then
		throttledSave(player)
		notificarConquistas(player, result)
	end
	return result
end

--------------------------------------------------
-- COMBATE
--------------------------------------------------

BasicAttack.OnServerInvoke = function(player)
	local result = CombatService.BasicAttack(player)
	if result and result.success then
		notificarConquistas(player, result)
		if result.killed then
			local character = CharacterService.GetActiveCharacter(player)
			if character then
				result.xpMsg = applyXP(player, character, 10)
			end
		end
	end
	return result
end

AttemptReaction.OnServerInvoke = function(player, reactionType)
	return CombatService.AttemptReaction(player, reactionType)
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
