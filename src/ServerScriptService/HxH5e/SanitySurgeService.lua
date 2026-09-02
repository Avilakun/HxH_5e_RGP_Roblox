--[[
    HxH5e SanitySurgeService (server) — motor do Surto de Sanidade,
    4 niveis por limiar de % (Curta/Longa/Leve/Pesado), baseado na
    tabela e nas respostas exatas do Lucas.

    Disparo: ao cruzar um limiar PRA BAIXO, dispara UMA VEZ (nao
    re-rola enquanto a Sanidade continuar baixa). Se a Sanidade subir
    de volta acima do limiar e cair de novo depois, dispara de novo.

    Curta/Longa: duracao FIXA por tempo (1d10 rodadas / 1d10 horas de
    jogo), independente da Sanidade -- expira sozinho. "1 rodada" =
    6 segundos reais (convencao documentada, nao ha rodadas formais
    no jogo).

    Leve/Pesado: duracao INDETERMINADA -- o efeito so termina quando a
    Sanidade volta a subir acima do limiar (confirmado com o Lucas).

    Automacao dos efeitos (pedido do Lucas: "deve ser automatico"):
    implementado de verdade onde ha um gancho mecanico claro
    (Envenenado, bloqueio de Hatsu/"balbucia", ataque automatico em
    aliado proximo, desvantagem por "tremores", penalidade de
    "compulsao", desvantagem de "talisma"). Efeitos puramente
    narrativos (alucinacao, amnesia, obedece comandos, a maioria dos
    resultados especiais do Pesado) ficam como um FLAG registrado +
    notificacao ao jogador, sem forcar comportamento que o jogo nao
    tem como simular direito (ex: "faz o que mandarem" exigiria um
    sistema de comandos de outros jogadores que nao existe).
]]

local SanitySurgeService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SanitySurgeDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("SanitySurgeDB"))
local TimeService = require(script.Parent:WaitForChild("TimeService"))

local CharacterService = nil
local CombatService = nil

function SanitySurgeService.Setup(charService, combatService)
	CharacterService = charService
	CombatService = combatService
end

local function rollFromTable(tabela, dado)
	local roll = math.random(1, dado)
	for _, entry in ipairs(tabela) do
		if roll >= entry.min and roll <= entry.max then
			return entry, roll
		end
	end
	return tabela[#tabela], roll
end

local function getPercentualSanidade(character)
	local san = character.Vitals and character.Vitals.Sanidade
	if not san or not san.Max or san.Max <= 0 then
		return 1
	end
	return (san.Current or 0) / san.Max
end

-- Ordem do mais severo pro menos severo (nao afeta a logica, so
-- organizacao).
local LIMIARES = {
	{ key = "pesado", pct = 0.25 },
	{ key = "leve", pct = 0.50 },
	{ key = "longa", pct = 0.75 },
	{ key = "curta", pct = 0.90 },
}

local function notify(player, dados)
	if SanitySurgeService.OnSurgeEvent then
		SanitySurgeService.OnSurgeEvent(player, dados)
	end
end

-- ================= Efeitos automatizados =================
local function aplicarEfeitoCurta(player, character, entry)
	if entry.tipo == "envenenado" then
		CharacterService.ApplyCondition(character, "envenenado", "Fraco")
	end
	-- amedrontado/obedece: ficam so como flag em SurtosAtivos.curta.tipo,
	-- consultado por quem quiser bloquear acoes ofensivas -- ver
	-- PodeAgirNormalmente abaixo.
end

local function aplicarEfeitoLonga(player, character, entry)
	if entry.tipo == "talisma" then
		local plrChar = player.Character
		local bestDist, nearestId = math.huge, nil
		if plrChar and plrChar.PrimaryPart then
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= player and other.Character and other.Character.PrimaryPart then
					local dist = (other.Character.PrimaryPart.Position - plrChar.PrimaryPart.Position).Magnitude
					if dist < bestDist then
						bestDist = dist
						nearestId = other.UserId
					end
				end
			end
		end
		character.SurtosAtivos.longa.talismaUserId = nearestId
	elseif entry.tipo == "compulsao" then
		character.UltimaAcaoPrincipalHoras = TimeService.GetTotalGameHours()
	end
end

-- Chamada em qualquer "acao principal" (ataque, Hatsu) pra resetar o
-- contador de Compulsao (Longa 01-20).
function SanitySurgeService.RegistrarAcaoPrincipal(character)
	if character.SurtosAtivos and character.SurtosAtivos.longa and character.SurtosAtivos.longa.tipo == "compulsao" then
		character.UltimaAcaoPrincipalHoras = TimeService.GetTotalGameHours()
	end
end

-- Bloqueia Hatsu ("balbucia") e checa Compulsao/Ataca-aliado num loop
-- periodico. Chamado a cada ~6s (1 rodada) pra cada jogador com surto
-- ativo.
local function loopEfeitosAtivos(player, character)
	local surtos = character.SurtosAtivos
	if not surtos then
		return
	end

	-- Ataca aliado (Curta 61-80 ou Pesado resultado 5): ataca
	-- automaticamente o jogador mais proximo, se houver um por perto.
	local ativo = (surtos.curta and surtos.curta.tipo == "ataca_aliado")
		or (surtos.pesado and surtos.pesado.tipo == "ataca_aliado")
	if ativo and CombatService and CombatService.ForceAttackNearestPlayer then
		CombatService.ForceAttackNearestPlayer(player, character)
	end

	-- Compulsao: se nao agiu numa acao principal nos ultimos 3 rodadas,
	-- perde 1 de Sanidade.
	if surtos.longa and surtos.longa.tipo == "compulsao" and character.UltimaAcaoPrincipalHoras then
		local rodadasSegundos = 3 * SanitySurgeDB.RODADA_SEGUNDOS
		local horasDesde = (TimeService.GetTotalGameHours() - character.UltimaAcaoPrincipalHoras) * 3600
		if horasDesde >= rodadasSegundos then
			character.UltimaAcaoPrincipalHoras = TimeService.GetTotalGameHours()
			if character.Vitals and character.Vitals.Sanidade then
				local san = character.Vitals.Sanidade
				san.Current = math.max(0, (san.Current or 0) - 1)
				SanitySurgeService.CheckThresholds(player, character)
			end
		end
	end
end

-- ================= Disparo e expiracao =================
function SanitySurgeService.TriggerSurge(player, character, key)
	character.SurtosAtivos = character.SurtosAtivos or {}

	if key == "curta" then
		local entry = rollFromTable(SanitySurgeDB.Curta, 100)
		local duracaoRodadas = math.random(1, 10)
		local duracaoSegundos = duracaoRodadas * SanitySurgeDB.RODADA_SEGUNDOS
		character.SurtosAtivos.curta = { tipo = entry.tipo, nome = entry.nome, desc = entry.desc }
		aplicarEfeitoCurta(player, character, entry)
		notify(player, { nivel = "curta", nome = entry.nome, desc = entry.desc, duracaoSegundos = duracaoSegundos })
		task.delay(duracaoSegundos, function()
			if character.SurtosAtivos then
				character.SurtosAtivos.curta = nil
			end
		end)
	elseif key == "longa" then
		local entry = rollFromTable(SanitySurgeDB.Longa, 100)
		local duracaoHoras = math.random(1, 10)
		character.SurtosAtivos.longa = { tipo = entry.tipo, nome = entry.nome, desc = entry.desc }
		aplicarEfeitoLonga(player, character, entry)
		notify(player, { nivel = "longa", nome = entry.nome, desc = entry.desc, duracaoHoras = duracaoHoras })
		local segundosReais = duracaoHoras * 60 -- 1h de jogo = 60s reais
		task.delay(segundosReais, function()
			if character.SurtosAtivos then
				character.SurtosAtivos.longa = nil
			end
		end)
	elseif key == "leve" then
		local entry = rollFromTable(SanitySurgeDB.Leve, 8)
		character.SurtosAtivos.leve = { inclinacao = entry.inclinacao }
		notify(player, { nivel = "leve", nome = entry.inclinacao, desc = "Inclinação Negativa concedida pelo Surto." })
	elseif key == "pesado" then
		local entry = rollFromTable(SanitySurgeDB.Pesado, 12)
		character.SurtosAtivos.pesado = { tipo = entry.tipo, nome = entry.nome, desc = entry.desc, inclinacao = entry.inclinacao }
		notify(player, { nivel = "pesado", nome = entry.nome or entry.inclinacao, desc = entry.desc or "Inclinação Negativa concedida pelo Surto." })
	end
end

function SanitySurgeService.ClearSurge(player, character, key)
	if character.SurtosAtivos then
		character.SurtosAtivos[key] = nil
	end
	notify(player, { nivel = key, cleared = true })
end

-- Chamado sempre que a Sanidade muda. Dispara novos surtos ao cruzar
-- limiares pra baixo; limpa os indeterminados (leve/pesado) quando a
-- sanidade volta a subir acima do limiar.
function SanitySurgeService.CheckThresholds(player, character)
	local pct = getPercentualSanidade(character)
	character.SurtosAtivos = character.SurtosAtivos or {}
	character.SurtoJaTriggado = character.SurtoJaTriggado or {}

	for _, limiar in ipairs(LIMIARES) do
		local key = limiar.key
		if pct <= limiar.pct then
			-- So dispara se ainda nao tiver sido "triggado" NESTA queda
			-- E nao houver um surto desse nivel ja rodando (evita
			-- sobrescrever/re-sortear um Curta ou Longa que ainda esta
			-- ativo por tempo, caso a Sanidade oscile pra cima e pra
			-- baixo do mesmo limiar repetidamente).
			if not character.SurtoJaTriggado[key] and not character.SurtosAtivos[key] then
				character.SurtoJaTriggado[key] = true
				SanitySurgeService.TriggerSurge(player, character, key)
			end
		else
			if character.SurtoJaTriggado[key] then
				character.SurtoJaTriggado[key] = false
			end
			if (key == "leve" or key == "pesado") and character.SurtosAtivos[key] then
				SanitySurgeService.ClearSurge(player, character, key)
			end
		end
	end
end

-- true se o Surto ativo bloqueia acoes de Nen (Hatsu) -- "balbucia"
-- (Curta ou Longa) ou "bloqueia_nen" (Pesado resultado 9).
function SanitySurgeService.BloqueiaHatsu(character)
	local surtos = character.SurtosAtivos
	if not surtos then
		return false
	end
	if surtos.curta and surtos.curta.tipo == "balbucia" then
		return true
	end
	if surtos.longa and surtos.longa.tipo == "balbucia" then
		return true
	end
	if surtos.pesado and surtos.pesado.tipo == "bloqueia_nen" then
		return true
	end
	return false
end

-- true se o personagem esta em desvantagem por "tremores" (Longa
-- 71-86) em testes de FOR/DES.
function SanitySurgeService.TemTremores(character)
	local surtos = character.SurtosAtivos
	return surtos and surtos.longa and surtos.longa.tipo == "tremores"
end

-- true se o personagem esta "preso" a um talisma e longe demais dele
-- (Longa 21-40) -- desvantagem em ataques/pericias/TRs.
function SanitySurgeService.LongeDoTalisma(player, character)
	local surtos = character.SurtosAtivos
	if not (surtos and surtos.longa and surtos.longa.tipo == "talisma" and surtos.longa.talismaUserId) then
		return false
	end
	local talismaPlayer = Players:GetPlayerByUserId(surtos.longa.talismaUserId)
	if not talismaPlayer or not talismaPlayer.Character or not talismaPlayer.Character.PrimaryPart then
		return false
	end
	local plrChar = player.Character
	if not plrChar or not plrChar.PrimaryPart then
		return false
	end
	local dist = (plrChar.PrimaryPart.Position - talismaPlayer.Character.PrimaryPart.Position).Magnitude
	return dist > 1.5
end

function SanitySurgeService.Start()
	task.spawn(function()
		while true do
			task.wait(SanitySurgeDB.RODADA_SEGUNDOS)
			for _, player in ipairs(Players:GetPlayers()) do
				local character = CharacterService and CharacterService.GetActiveCharacter(player)
				if character then
					local ok, err = pcall(loopEfeitosAtivos, player, character)
					if not ok then
						warn("SanitySurgeService loop erro: " .. tostring(err))
					end
				end
			end
		end
	end)
end

return SanitySurgeService
