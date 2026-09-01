--[[
    HxH5e SanityTagService (server) — motor de Gostos/Desgostos
    conectados a Sanidade de verdade, baseado no que aconteceu na
    conversa com o Lucas.

    GOSTOS: quando a condicao acontece, recupera 2d6+INT de Sanidade
    (formula real do livro, gatilho "Realizando/Cumprindo o que
    gosta"). Cooldown de 3h de JOGO por tag (via TimeService).

    DESGOSTOS: quando a condicao acontece, causa 1 de Estresse (dano
    fixo, confirmado com o Lucas -- nao rola dado). Mesma cooldown de
    3h de jogo. NAO recupera automaticamente so porque a situacao
    mudou -- so recupera pelos metodos normais (Descanso Longo,
    Gostos, Nat 20).

    Tags "continuas" (estado, ex: solidao) sao avaliadas num loop
    periodico. Tags "de evento" (ex: vitoria em combate) sao
    disparadas por ganchos chamados de outros servicos
    (CombatService, RestService, etc.) -- ver as funcoes OnXxx no
    final do arquivo.
]]

local SanityTagService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SanityTagsDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("SanityTagsDB"))
local TimeService = require(script.Parent:WaitForChild("TimeService"))

local CharacterService = nil
local CombatService = nil

local COOLDOWN_HORAS = 3
local DESGOSTO_ESTRESSE = 1
local PROXIMIDADE_PERTO = 15
local PROXIMIDADE_DETECCAO = 40
local ISOLAMENTO_HORAS = 2

function SanityTagService.Setup(charService, combatService)
	CharacterService = charService
	CombatService = combatService
end

local function attrMod(character, key)
	local val = character.Attributes and character.Attributes[key] and character.Attributes[key].value or 10
	return math.floor((val - 10) / 2)
end

local function rollDice(count, sides)
	local total = 0
	for _ = 1, count do total = total + math.random(1, sides) end
	return total
end

local function podeDisparar(character, tagId)
	character.TagCooldowns = character.TagCooldowns or {}
	local ultimo = character.TagCooldowns[tagId]
	if not ultimo then return true end
	return (TimeService.GetTotalGameHours() - ultimo) >= COOLDOWN_HORAS
end

local function aplicarGosto(player, character, tagId)
	if not podeDisparar(character, tagId) then return end
	character.TagCooldowns[tagId] = TimeService.GetTotalGameHours()
	local intMod = attrMod(character, "INT")
	local recuperado = rollDice(2, 6) + intMod
	if character.Vitals and character.Vitals.Sanidade then
		local san = character.Vitals.Sanidade
		san.Current = math.min(san.Max, (san.Current or 0) + recuperado)
	end
	CharacterService.SavePlayer(player)
	if SanityTagService.OnTagTriggered then
		SanityTagService.OnTagTriggered(player, tagId, "gosto", recuperado)
	end
end

local function aplicarDesgosto(player, character, tagId)
	if not podeDisparar(character, tagId) then return end
	character.TagCooldowns[tagId] = TimeService.GetTotalGameHours()
	if character.Vitals and character.Vitals.Sanidade then
		local san = character.Vitals.Sanidade
		san.Current = math.max(0, (san.Current or 0) - DESGOSTO_ESTRESSE)
	end
	CharacterService.SavePlayer(player)
	if SanityTagService.OnTagTriggered then
		SanityTagService.OnTagTriggered(player, tagId, "desgosto", DESGOSTO_ESTRESSE)
	end
end

local function temTag(character, tagId, tipo)
	local lista = tipo == "gosto" and character.GostosEscolhidos or character.DesgostosEscolhidos
	return lista and table.find(lista, tagId) ~= nil
end

local function contarJogadoresProximos(origem, raio, excluirPlayer)
	local count = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= excluirPlayer then
			local c = plr.Character
			if c and c.PrimaryPart then
				local dist = (c.PrimaryPart.Position - origem).Magnitude
				if dist <= raio then count = count + 1 end
			end
		end
	end
	return count
end

-- ================= Avaliacao continua (loop) =================
local function avaliarTagsContinuas(player, character)
	local plrChar = player.Character
	if not plrChar or not plrChar.PrimaryPart then return end
	local pos = plrChar.PrimaryPart.Position
	local proximosDeteccao = contarJogadoresProximos(pos, PROXIMIDADE_DETECCAO, player)
	local proximosPerto = contarJogadoresProximos(pos, PROXIMIDADE_PERTO, player)
	local hora = TimeService.GetClockTime()
	local ehDia = hora >= 6 and hora <= 18
	local naZonaSegura = CombatService.IsInSafeZone and CombatService.IsInSafeZone(pos)

	if temTag(character, "paz_diurna", "gosto") and proximosDeteccao == 0 and ehDia then
		aplicarGosto(player, character, "paz_diurna")
	end
	if temTag(character, "seguranca", "gosto") and naZonaSegura then
		aplicarGosto(player, character, "seguranca")
	end
	if temTag(character, "companhia_aliados", "gosto") and proximosPerto > 0 then
		aplicarGosto(player, character, "companhia_aliados")
	end

	if temTag(character, "solidao_noturna", "desgosto") and proximosDeteccao == 0 and not ehDia then
		aplicarDesgosto(player, character, "solidao_noturna")
	end
	if temTag(character, "exaustao", "desgosto") then
		local temExaustao = false
		for _, c in ipairs(character.Conditions or {}) do
			if c.id == "exausto" then temExaustao = true break end
		end
		if temExaustao then aplicarDesgosto(player, character, "exaustao") end
	end
	if temTag(character, "miseria", "desgosto") and (character.Money or 0) <= 0 then
		aplicarDesgosto(player, character, "miseria")
	end
	if temTag(character, "multidoes", "desgosto") and proximosPerto >= 3 then
		aplicarDesgosto(player, character, "multidoes")
	end
	if temTag(character, "perigo_constante", "desgosto") and CombatService.IsBeingChased and CombatService.IsBeingChased(player) then
		aplicarDesgosto(player, character, "perigo_constante")
	end
	if temTag(character, "esgotamento", "desgosto") and character.Vitals and character.Vitals.Aura then
		local aura = character.Vitals.Aura
		if aura.Max and aura.Max > 0 and (aura.Current or 0) / aura.Max < 0.2 then
			aplicarDesgosto(player, character, "esgotamento")
		end
	end
	if temTag(character, "isolamento", "desgosto") then
		if proximosDeteccao == 0 then
			if not character.SozinhoDesde then
				character.SozinhoDesde = TimeService.GetTotalGameHours()
			elseif (TimeService.GetTotalGameHours() - character.SozinhoDesde) >= ISOLAMENTO_HORAS then
				aplicarDesgosto(player, character, "isolamento")
			end
		else
			character.SozinhoDesde = nil
		end
	end
end

function SanityTagService.Start()
	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in ipairs(Players:GetPlayers()) do
				local character = CharacterService and CharacterService.GetActiveCharacter(player)
				if character then
					local ok, err = pcall(avaliarTagsContinuas, player, character)
					if not ok then
						warn("SanityTagService loop erro: " .. tostring(err))
					end
				end
			end
		end
	end)
end

-- ================= Ganchos de evento (chamados de outros servicos) =================
function SanityTagService.OnCombatVictory(player, character)
	if temTag(character, "vitoria_combate", "gosto") then
		aplicarGosto(player, character, "vitoria_combate")
	end
end

function SanityTagService.OnRestComplete(player, character)
	if temTag(character, "descanso_seguro", "gosto") then
		aplicarGosto(player, character, "descanso_seguro")
	end
end

function SanityTagService.OnPrincipleUsed(player, character)
	if temTag(character, "disciplina_nen", "gosto") then
		aplicarGosto(player, character, "disciplina_nen")
	end
end

function SanityTagService.OnMoneyReceived(player, character)
	if temTag(character, "prosperidade", "gosto") then
		aplicarGosto(player, character, "prosperidade")
	end
end

function SanityTagService.OnReputationLevelUp(player, character)
	if temTag(character, "reconhecimento", "gosto") then
		aplicarGosto(player, character, "reconhecimento")
	end
end

function SanityTagService.OnAchievementUnlocked(player, character)
	if temTag(character, "superar_desafios", "gosto") then
		aplicarGosto(player, character, "superar_desafios")
	end
end

function SanityTagService.OnSurvivedLowHP(player, character)
	if temTag(character, "emocao_risco", "gosto") then
		aplicarGosto(player, character, "emocao_risco")
	end
	if temTag(character, "beira_morte", "desgosto") then
		aplicarDesgosto(player, character, "beira_morte")
	end
end

function SanityTagService.OnReputationExpelled(player, character)
	if temTag(character, "rejeicao", "desgosto") then
		aplicarDesgosto(player, character, "rejeicao")
	end
end

function SanityTagService.OnDeath(player, character)
	if temTag(character, "derrota", "desgosto") then
		aplicarDesgosto(player, character, "derrota")
	end
end

-- ================= Selecao de tags (criacao / edicao) =================
function SanityTagService.SetTags(character, gostos, desgostos)
	for _, id in ipairs(gostos or {}) do
		local tag = SanityTagsDB.Get(id)
		if not tag or tag.tipo ~= "gosto" then
			return { success = false, error = "Gosto inválido: " .. tostring(id) }
		end
	end
	for _, id in ipairs(desgostos or {}) do
		local tag = SanityTagsDB.Get(id)
		if not tag or tag.tipo ~= "desgosto" then
			return { success = false, error = "Desgosto inválido: " .. tostring(id) }
		end
	end
	character.GostosEscolhidos = gostos or {}
	character.DesgostosEscolhidos = desgostos or {}
	return { success = true }
end

function SanityTagService.GetCatalog()
	return SanityTagsDB.Tags
end

return SanityTagService
