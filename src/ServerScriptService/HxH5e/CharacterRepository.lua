local DataStoreService = game:GetService("DataStoreService")

local CharacterStore = DataStoreService:GetDataStore("HxH5e_Characters_v1")

local CharacterRepository = {}


function CharacterRepository.Load(player)

	local key = "Player_" .. player.UserId

	local success, data = pcall(function()

		return CharacterStore:GetAsync(key)

	end)


	if not success then

		warn("Erro ao carregar personagens de " .. player.Name)

		return nil

	end


	return data

end


function CharacterRepository.Save(player, data)

	local key = "Player_" .. player.UserId


	local success, errorMessage = pcall(function()

		CharacterStore:SetAsync(key, data)

	end)


	if not success then

		warn(
			"Erro ao salvar personagens de "
				.. player.Name
				.. ": "
				.. tostring(errorMessage)
		)

		return false

	end


	return true

end


return CharacterRepository