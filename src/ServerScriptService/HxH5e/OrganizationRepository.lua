--[[
    HxH5e OrganizationRepository (server) — persistencia das GUILDAS
    criadas por jogadores (diferente das organizacoes de NPC, que sao
    dados estaticos em OrganizationsDB.lua). Usa uma UNICA chave global
    no DataStore (nao por jogador, ja que uma guilda e compartilhada
    entre varios personagens) -- mesmo padrao do CharacterRepository.
]]

local DataStoreService = game:GetService("DataStoreService")

local GuildStore = DataStoreService:GetDataStore("HxH5e_Guilds_v1")
local GLOBAL_KEY = "AllGuilds"

local OrganizationRepository = {}

function OrganizationRepository.Load()
	local success, data = pcall(function()
		return GuildStore:GetAsync(GLOBAL_KEY)
	end)
	if not success then
		warn("Erro ao carregar guildas: " .. tostring(data))
		return nil
	end
	return data
end

function OrganizationRepository.Save(data)
	local success, errorMessage = pcall(function()
		GuildStore:SetAsync(GLOBAL_KEY, data)
	end)
	if not success then
		warn("Erro ao salvar guildas: " .. tostring(errorMessage))
		return false
	end
	return true
end

return OrganizationRepository
