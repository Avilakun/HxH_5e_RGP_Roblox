--[[
    HxH5e OrganizationService (server) — motor de Organizacoes/Guildas.

    2 fontes de organizacao: estaticas de NPC (OrganizationsDB.lua,
    sempre existem) e guildas criadas por jogadores (OrganizationRepository,
    DataStore global, persistem entre sessoes).

    Sistema de reputacao (combinado com o Lucas):
    - Entrar: hoje LIVRE (⚠️ PENDENTE: deveria exigir completar uma
      missao primeiro, mas o sistema de missao ainda nao existe).
    - Subir de nivel: automatico nos limiares de reputacao 5/15/30
      (niveis 2/3/4). O nivel 5 (Lider/chefe) NUNCA e automatico --
      precisa de "desafiar o chefe" ou "votacao", que dependem de
      combate PvP e sistema de votacao (nenhum dos dois existe ainda)
      -- por isso fica como promocao MANUAL (PromoteToLeader, uso do
      mestre) por enquanto.
    - Perder reputacao: completar missao de tipo incompativel com o
      tipo da organizacao (⚠️ SO O GANCHO existe, ApplyMissionTypeMismatchPenalty,
      sem gatilho automatico ainda -- depende do sistema de missao).
    - Expulsao automatica se a reputacao cair muito (limiar provisorio,
      ver REP_EXPULSAO_LIMIAR).

    ⚠️ NUMEROS PROVISORIOS (o Lucas nao especificou, documentado pra
    confirmar depois): perda de reputacao por missao incompativel
    (-10), limiar de expulsao (-20), nivel minimo pra fundar guilda (4).

    ================= 3 formas de "formar guilda" (Lucas) =================
    1) MERCENARIA (com dinheiro): custa 12.000 pra fundar (vira o
       "Tesouro" inicial da guilda). Cada missao feita por um membro
       contribui 20% do valor da missao pro Tesouro (crescimento
       passivo). Uma vez por semana (em tempo REAL, ja que nao existe
       calendario de jogo ainda -- ver WEEK_SECONDS), 25% do Tesouro e
       dividido IGUALMENTE entre os membros que fizeram PELO MENOS 1
       missao naquela semana (quem nao fez, nao recebe -- mas continua
       na guilda, nao e expulso so por isso). Matematica confirmada com
       o Lucas: com 5 membros e 50k de tesouro, cada um recebe 5% (2500),
       batendo exato o exemplo dele. Escala sem quebrar com mais
       membros (fatia total fixa, dividida, nunca ultrapassa 100%).
    2) AFINIDADE: sem custo, sem Tesouro, sem renda passiva nenhuma --
       so pertencimento por alinhamento (organizacoes Boas/Malignas
       tipicamente). O lucro de missao fica 100% com quem fez, nada
       vai pra organizacao.
    3) ASSOCIACAO HUNTER: caso unico e especial, NAO fundavel por
       jogador (ver OrganizationsDB.lua, entrada "associacao_hunter",
       especial=true). Adquirida via item "Licenca Hunter" (ver
       ItemsDB.lua, ja compravel pela loja normal por 3 bilhoes -- a
       "compra pelo valor exorbitante" que o Lucas descreveu) OU pelo
       Exame Hunter (⚠️ PENDENTE, nao implementado ainda). Beneficios
       (viagem primeira classe, hospedagem gratis, missoes exclusivas)
       ficam documentados aqui mas SEM mecanica ainda -- dependem de
       sistemas de viagem/hospedagem/missao que nao existem.
]]

local OrganizationService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local OrganizationsDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("OrganizationsDB"))
local OrganizationRepository = require(script.Parent:WaitForChild("OrganizationRepository"))
local CharacterRepository = require(script.Parent:WaitForChild("CharacterRepository"))

OrganizationService.TIPOS = { "Boa", "Neutra", "Criminosa", "Maligna" }
OrganizationService.TIPOS_ECONOMICOS = { "Mercenaria", "Afinidade" }

local REP_THRESHOLDS = { [2] = 5, [3] = 15, [4] = 30 }
local REP_LOSS_TIPO_INCOMPATIVEL = -10
local REP_EXPULSAO_LIMIAR = -20
-- Nivel minimo pra fundar guilda DEPENDE do tipo economico (ajuste do
-- Lucas): Mercenaria (dinheiro) nao exige nivel nenhum -- o dinheiro
-- ja "compra" o direito de fundar. Afinidade (sem custo) exige nivel 3
-- -- sem capital envolvido, precisa ter alguma experiencia provada.
local GUILD_CREATE_MIN_LEVEL = {
	Mercenaria = 0,
	Afinidade = 3,
}

local GUILD_FOUNDING_COST = 12000
local MISSION_CONTRIBUTION_PCT = 0.20 -- % do valor da missao que vai pro Tesouro
local WEEKLY_PAYOUT_PCT = 0.25 -- % do Tesouro dividido entre membros ativos por semana
local WEEK_SECONDS = 7 * 24 * 60 * 60 -- 1 semana em tempo REAL (sem calendario de jogo ainda)

local guilds = {}
local guildsLoaded = false

local function ensureGuildsLoaded()
	if guildsLoaded then return end
	local data = OrganizationRepository.Load()
	guilds = data or {}
	guildsLoaded = true
end

function OrganizationService.GetAllOrganizations()
	ensureGuildsLoaded()
	local list = {}
	for _, o in ipairs(OrganizationsDB.Organizacoes) do
		table.insert(list, o)
	end
	for _, g in pairs(guilds) do
		table.insert(list, g)
	end
	return list
end

function OrganizationService.FindOrganization(orgId)
	ensureGuildsLoaded()
	local static = OrganizationsDB.Get(orgId)
	if static then return static end
	return guilds[orgId]
end

-- Cria uma nova guilda (jogador). tipoEconomico = "Mercenaria" (custa
-- GUILD_FOUNDING_COST, vira Tesouro inicial, gera renda passiva) ou
-- "Afinidade" (gratis, sem Tesouro/renda). Exige nivel minimo, tipo
-- (Boa/Neutra/Criminosa/Maligna) valido, e automaticamente entra o
-- criador como Lider (nivel 5) dela.
function OrganizationService.CreateGuild(character, nome, tipo, tipoEconomico, titulosCustom)
	ensureGuildsLoaded()
	local tipoEcoValido = false
	for _, t in ipairs(OrganizationService.TIPOS_ECONOMICOS) do
		if t == tipoEconomico then tipoEcoValido = true break end
	end
	if not tipoEcoValido then
		return { success = false, error = "Tipo econômico inválido. Use: " .. table.concat(OrganizationService.TIPOS_ECONOMICOS, ", ") }
	end
	local minLevel = GUILD_CREATE_MIN_LEVEL[tipoEconomico] or 0
	if (character.Level or 0) < minLevel then
		return { success = false, error = "Precisa ser nível " .. minLevel .. " pra fundar uma guilda de " .. tipoEconomico .. "." }
	end
	local tipoValido = false
	for _, t in ipairs(OrganizationService.TIPOS) do
		if t == tipo then tipoValido = true break end
	end
	if not tipoValido then
		return { success = false, error = "Tipo inválido. Use: " .. table.concat(OrganizationService.TIPOS, ", ") }
	end
	if not nome or #nome < 3 then
		return { success = false, error = "Nome da guilda precisa ter pelo menos 3 caracteres." }
	end

	local tesouroInicial = 0
	if tipoEconomico == "Mercenaria" then
		if (character.Money or 0) < GUILD_FOUNDING_COST then
			return { success = false, error = "Precisa de $" .. GUILD_FOUNDING_COST .. " pra fundar uma guilda mercenária (você tem $" .. tostring(character.Money or 0) .. ")." }
		end
		character.Money = character.Money - GUILD_FOUNDING_COST
		tesouroInicial = GUILD_FOUNDING_COST
	end

	local id = "guild_" .. nome:lower():gsub("%s+", "_") .. "_" .. tostring(os.time())
	local titulos = titulosCustom
	if not titulos or #titulos ~= 5 then
		titulos = { "Recruta", "Membro", "Veterano", "Elite", "Líder" }
	end
	local guild = {
		id = id,
		nome = nome,
		tipo = tipo,
		tipoEconomico = tipoEconomico,
		titulos = titulos,
		criadaEm = os.time(),
		tesouro = tesouroInicial,
		ultimoPagamento = os.time(),
		atividade = {}, -- [characterId] = { userId, missoesNaSemana }
	}
	guilds[id] = guild
	OrganizationRepository.Save(guilds)

	character.Organizacoes = character.Organizacoes or {}
	table.insert(character.Organizacoes, { orgId = id, nivel = 5, reputacao = 999, status = "membro" })

	return { success = true, organizacao = guild }
end

function OrganizationService.JoinOrganization(character, orgId)
	local org = OrganizationService.FindOrganization(orgId)
	if not org then
		return { success = false, error = "Organização não encontrada." }
	end
	if org.especial then
		return { success = false, error = org.nome .. " não é uma organização que se entra normalmente -- veja como adquirir acesso a ela." }
	end
	character.Organizacoes = character.Organizacoes or {}
	for _, m in ipairs(character.Organizacoes) do
		if m.orgId == orgId then
			return { success = false, error = "Você já faz parte de " .. org.nome .. "." }
		end
	end
	-- PENDENTE: exigir completar uma missao antes de entrar -- sistema
	-- de missao ainda nao existe, entao por ora a entrada e livre.
	table.insert(character.Organizacoes, { orgId = orgId, nivel = 1, reputacao = 0, status = "membro" })
	return { success = true, organizacao = org, message = "Entrou em " .. org.nome .. " como " .. org.titulos[1] .. "." }
end

-- Nunca promove sozinho pro nivel 5, e nunca REBAIXA de nivel so por
-- perder reputacao (so a expulsao remove, ver AddReputation).
local function recalcularNivel(membership)
	local rep = membership.reputacao
	local novoNivel = 1
	if rep >= REP_THRESHOLDS[4] then
		novoNivel = 4
	elseif rep >= REP_THRESHOLDS[3] then
		novoNivel = 3
	elseif rep >= REP_THRESHOLDS[2] then
		novoNivel = 2
	end
	if membership.nivel == 5 then
		return
	end
	membership.nivel = math.max(membership.nivel, novoNivel)
end

function OrganizationService.AddReputation(character, orgId, amount)
	local org = OrganizationService.FindOrganization(orgId)
	if not org then
		return { success = false, error = "Organização não encontrada." }
	end
	local membership = nil
	for _, m in ipairs(character.Organizacoes or {}) do
		if m.orgId == orgId then
			membership = m
			break
		end
	end
	if not membership then
		return { success = false, error = "Você não faz parte de " .. org.nome .. "." }
	end

	membership.reputacao = (membership.reputacao or 0) + amount
	local nivelAntes = membership.nivel
	recalcularNivel(membership)

	if membership.reputacao <= REP_EXPULSAO_LIMIAR and membership.nivel < 5 then
		for i, m in ipairs(character.Organizacoes) do
			if m.orgId == orgId then
				table.remove(character.Organizacoes, i)
				break
			end
		end
		return { success = true, expelled = true, message = "Você foi expulso de " .. org.nome .. " (reputação muito baixa)." }
	end

	local subiu = membership.nivel > nivelAntes
	return {
		success = true,
		reputacao = membership.reputacao,
		nivel = membership.nivel,
		titulo = org.titulos[membership.nivel],
		subiuDeNivel = subiu,
		message = subiu and ("Você subiu para " .. org.titulos[membership.nivel] .. " em " .. org.nome .. "!") or nil,
	}
end

-- Gancho pronto pra quando o sistema de missao existir. SEM GATILHO
-- automatico ainda.
function OrganizationService.ApplyMissionTypeMismatchPenalty(character, orgId)
	return OrganizationService.AddReputation(character, orgId, REP_LOSS_TIPO_INCOMPATIVEL)
end

-- Promocao manual pro nivel 5 (Lider) -- substitui "desafiar o chefe"
-- ou "receber votacao" (nenhum dos dois existe ainda). Uso do mestre.
function OrganizationService.PromoteToLeader(character, orgId)
	local org = OrganizationService.FindOrganization(orgId)
	if not org then
		return { success = false, error = "Organização não encontrada." }
	end
	for _, m in ipairs(character.Organizacoes or {}) do
		if m.orgId == orgId then
			m.nivel = 5
			return { success = true, message = "Promovido a " .. org.titulos[5] .. " de " .. org.nome .. "!" }
		end
	end
	return { success = false, error = "Você não faz parte de " .. org.nome .. "." }
end

-- ================= Economia da guilda MERCENARIA =================
-- Gancho pronto pra quando o sistema de missao existir. SEM GATILHO
-- automatico ainda -- alguem (o futuro sistema de missao) precisa
-- chamar isso quando um membro completar uma missao de verdade.
function OrganizationService.RegisterMissionCompletion(player, character, orgId, missionValue)
	ensureGuildsLoaded()
	local guild = guilds[orgId]
	if not guild or guild.tipoEconomico ~= "Mercenaria" then
		return { success = false, error = "Organização não é uma guilda mercenária." }
	end
	local membership = nil
	for _, m in ipairs(character.Organizacoes or {}) do
		if m.orgId == orgId then membership = m break end
	end
	if not membership then
		return { success = false, error = "Você não faz parte dessa guilda." }
	end

	local contribuicao = math.floor((missionValue or 0) * MISSION_CONTRIBUTION_PCT)
	guild.tesouro = (guild.tesouro or 0) + contribuicao

	local charId = character.Id
	guild.atividade[charId] = guild.atividade[charId] or { userId = player and player.UserId, missoesNaSemana = 0 }
	guild.atividade[charId].missoesNaSemana = guild.atividade[charId].missoesNaSemana + 1
	if player then
		guild.atividade[charId].userId = player.UserId
	end

	OrganizationRepository.Save(guilds)
	return { success = true, contribuicao = contribuicao, tesouro = guild.tesouro }
end

-- Distribui WEEKLY_PAYOUT_PCT do Tesouro entre os membros que fizeram
-- >=1 missao na semana, igualmente. So processa se ja passou 1 semana
-- REAL desde o ultimo pagamento (forceNow=true ignora essa checagem,
-- uso interno de teste). Credita o dinheiro direto na sessao do
-- personagem se o jogador estiver ONLINE; se estiver OFFLINE, carrega
-- o personagem do DataStore, credita, e salva de volta.
function OrganizationService.ProcessWeeklyPayout(orgId, forceNow, getActiveCharacterFn)
	ensureGuildsLoaded()
	local guild = guilds[orgId]
	if not guild or guild.tipoEconomico ~= "Mercenaria" then
		return { success = false, error = "Organização não é uma guilda mercenária." }
	end

	local agora = os.time()
	if not forceNow and (agora - (guild.ultimoPagamento or 0)) < WEEK_SECONDS then
		return { success = false, error = "Ainda não passou uma semana desde o último pagamento." }
	end

	local elegiveis = {}
	for charId, atividade in pairs(guild.atividade) do
		if atividade.missoesNaSemana >= 1 then
			table.insert(elegiveis, { charId = charId, userId = atividade.userId })
		end
	end

	if #elegiveis == 0 then
		guild.ultimoPagamento = agora
		OrganizationRepository.Save(guilds)
		return { success = true, pago = 0, elegiveis = 0, message = "Nenhum membro ativo essa semana -- ninguém recebeu." }
	end

	local totalPagar = math.floor((guild.tesouro or 0) * WEEKLY_PAYOUT_PCT)
	local porPessoa = math.floor(totalPagar / #elegiveis)
	local pagos = {}

	for _, e in ipairs(elegiveis) do
		local creditado = false
		local playerOnline = e.userId and Players:GetPlayerByUserId(e.userId)
		if playerOnline and getActiveCharacterFn then
			local liveChar = getActiveCharacterFn(playerOnline)
			if liveChar and liveChar.Id == e.charId then
				liveChar.Money = (liveChar.Money or 0) + porPessoa
				creditado = true
			end
		end
		if not creditado and e.userId then
			-- Jogador offline (ou personagem nao ativo agora): carrega,
			-- credita, salva de volta direto no DataStore.
			local fakePlayer = { UserId = e.userId }
			local data = CharacterRepository.Load(fakePlayer)
			if data and data.characters then
				for _, c in ipairs(data.characters) do
					if c.Id == e.charId then
						c.Money = (c.Money or 0) + porPessoa
						creditado = true
						break
					end
				end
				if creditado then
					CharacterRepository.Save(fakePlayer, data)
				end
			end
		end
		table.insert(pagos, { charId = e.charId, valor = porPessoa, creditado = creditado })
	end

	guild.tesouro = (guild.tesouro or 0) - totalPagar
	guild.ultimoPagamento = agora
	guild.atividade = {} -- zera contadores semanais
	OrganizationRepository.Save(guilds)

	return {
		success = true,
		pago = totalPagar,
		porPessoa = porPessoa,
		elegiveis = #elegiveis,
		pagos = pagos,
		tesouroRestante = guild.tesouro,
	}
end

return OrganizationService
