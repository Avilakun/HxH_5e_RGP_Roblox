--[[
    HxH5e FichaUIAdapter (server) — converte o character REAL
    (CharacterService) pro formato que a FichaUI (Claude Design)
    espera, ver FichaUIData.lua no cliente pra conferir o "contrato"
    exato de campos.

    Existe porque os dois lados foram construidos em paralelo: a UI
    foi desenhada em cima de um mock "ideal" (Data.Demo), e o
    character real tem uma estrutura bem diferente (ex: Vitals.HP e
    uma tabela {Current,Max}, nao um numero "PV"; nao existe
    Nen.Categorias nem Tracos). Este adaptador faz a ponte NUM LUGAR
    SO, sem precisar reescrever a UI nem o backend.

    ⚠️ Partes que NAO EXISTEM no backend ainda, preenchidas com
    valores vazios/default pra UI nao quebrar (documentado aqui, nao
    escondido):
    - Sistema de "equipar item num slot" (cabeca/torso/mao/etc) --
      todo o Inventory vira "Bolsa" solta, Equipado fica todo nil.
    - Inclinacoes de Combate, Instancia Shingen-Ryu, Pontos de
      Combate -- ver auditoria de materiais, sistemas que existem no
      webapp mas nunca foram portados. Ficam vazios/zerados.
    - Traços raciais nomeados (a maioria das racas so tem bonus de
      atributo + 1 descricao geral no SystemDB, nao uma lista de
      tracos individuais) -- vira 1 traco unico com a descricao da
      raca.
    - Proficiencia (bonus numerico) -- nao calculado em lugar nenhum
      hoje, fixo em +2 (documentado, ver SkillSystem.lua sobre a
      mesma pendencia).
]]

local FichaUIAdapter = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SystemDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("SystemDB"))
local ItemsDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("ItemsDB"))
local ConditionsDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("ConditionsDB"))

local CharacterService = nil
local SkillSystem = nil
local OrganizationService = nil

function FichaUIAdapter.Setup(charService, skillSystem, orgService)
	CharacterService = charService
	SkillSystem = skillSystem
	OrganizationService = orgService
end

-- Protecao contra condicao de corrida real: o cliente as vezes chama o
-- remote GetCharacterUI ANTES do ServerBootstrap terminar de rodar
-- FichaUIAdapter.Setup (o LocalScript do cliente carrega mais rapido
-- que o servidor termina de configurar todos os modulos). Sem isso, a
-- ficha caia pro fallback Kairo na primeira abertura e NUNCA mais
-- tentava de novo (Data.carregar() so roda 1x no cliente).
function FichaUIAdapter.WaitReady(timeoutSegundos)
	local limite = os.clock() + (timeoutSegundos or 5)
	while CharacterService == nil and os.clock() < limite do
		task.wait()
	end
	return CharacterService ~= nil
end

local TIPO_PARA_CATEGORIA = {
	["Reforço"] = "INTENSIFICAÇÃO",
	["Intensificação"] = "INTENSIFICAÇÃO",
	["Transmutação"] = "TRANSMUTAÇÃO",
	["Materialização"] = "MATERIALIZAÇÃO",
	["Especialização"] = "ESPECIALIZAÇÃO",
	["Manipulação"] = "MANIPULAÇÃO",
	["Emissão"] = "EMISSÃO",
}

local ATRIBUTOS_ORDEM = { "FOR", "DES", "CON", "INT", "SAB", "PRE" }
local ATRIBUTOS_NOMES = { FOR = "Força", DES = "Destreza", CON = "Constituição", INT = "Inteligência", SAB = "Sabedoria", PRE = "Presença" }
local ATRIBUTOS_GRUPO = { FOR = "fisico", DES = "fisico", CON = "fisico", INT = "mental", SAB = "mental", PRE = "mental" }

local function attrMod(character, sigla)
	local v = character.Attributes and character.Attributes[sigla] and character.Attributes[sigla].value or 10
	return math.floor((v - 10) / 2)
end

local function findRaca(nome)
	for _, r in ipairs(SystemDB.racas or {}) do
		if r.nome == nome then return r end
	end
	return nil
end

local function findAntecedente(nome)
	for _, b in ipairs(SystemDB.antecedentes or {}) do
		if b.nome == nome then return b end
	end
	return nil
end

function FichaUIAdapter.Build(character, player)
	local ficha = {}

	ficha.Id = character.Id
	ficha.Nome = character.Name or "?"
	ficha.Jogador = player and player.Name or "?"
	ficha.Nivel = character.Level or 0
	ficha.XP = character.XP or 0
	local xpTable = SystemDB.xpTable or {}
	ficha.XPProximo = xpTable[math.max(1, math.min(ficha.Nivel + 1, #xpTable))] or 100
	ficha.Categoria = (character.Nen and character.Nen.Category) or "Intensificação"
	ficha.Tendencia = character.Alignment or "Neutro"
	ficha.Proficiencia = 2 -- ⚠️ nao calculado em lugar nenhum ainda, ver nota no topo
	ficha.Raca = character.Race or "?"
	ficha.Antecedente = character.Background or "?"
	ficha.Deslocamento = tostring(CharacterService.GetEffectiveDeslocamento(character)) .. "m"
	ficha.Dinheiro = character.Money or 0

	-- ================= VITAIS =================
	local hp = (character.Vitals and character.Vitals.HP) or { Current = 0, Max = 0 }
	local aura = (character.Vitals and character.Vitals.Aura) or { Current = 0, Max = 100 }
	local san = (character.Vitals and character.Vitals.Sanidade) or { Current = 0, Max = 100 }
	ficha.Vitals = {
		PV = hp.Current or 0,
		PVMax = CharacterService.GetEffectiveMaxHP(character),
		Aura = aura.Current or 0,
		AuraMax = aura.Max or 100,
		Sanidade = san.Current or 0,
		SanidadeMax = san.Max or 100,
		Reacoes = (character.Vitals and character.Vitals.Reacoes) or 7,
		ReacoesMax = (character.Vitals and character.Vitals.Reacoes) or 7,
		CA = CharacterService.GetEffectiveCA(character),
		RDM = (character.Vitals and character.Vitals.RDM) or 0,
		Iniciativa = attrMod(character, "DES"),
	}

	-- ================= ATRIBUTOS =================
	ficha.Atributos = {}
	for _, sigla in ipairs(ATRIBUTOS_ORDEM) do
		local valor = (character.Attributes and character.Attributes[sigla] and character.Attributes[sigla].value) or 10
		table.insert(ficha.Atributos, {
			sigla = sigla,
			nome = ATRIBUTOS_NOMES[sigla],
			valor = valor,
			mod = attrMod(character, sigla),
			tr = attrMod(character, sigla),
			grupo = ATRIBUTOS_GRUPO[sigla],
		})
	end

	-- ================= PERICIAS =================
	ficha.Pericias = { FOR = {}, DES = {}, CON = {}, INT = {}, SAB = {}, PRE = {} }
	for sigla, lista in pairs(SystemDB.skillMap or {}) do
		if ficha.Pericias[sigla] then
			for _, nome in ipairs(lista) do
				local bonus = SkillSystem.GetSkillBonus(character, nome)
				local treinada = false
				for _, s in ipairs(character.Skills or {}) do
					if s == nome then treinada = true break end
				end
				table.insert(ficha.Pericias[sigla], { nome, bonus, treinada })
			end
		end
	end

	-- ================= CONDICOES =================
	ficha.Condicoes = {}
	for _, c in ipairs(character.Conditions or {}) do
		local nomeExibicao = c.id
		for _, cond in ipairs(ConditionsDB.Condicoes) do
			if cond.id == c.id then nomeExibicao = cond.nome break end
		end
		table.insert(ficha.Condicoes, { nome = nomeExibicao, pilhas = 1 })
	end

	-- ================= NEN =================
	local nen = character.Nen or {}
	local dominio = nen.Dominio or {}
	ficha.Nen = {
		Afinidade = { rolagem = (nen.Affinity and nen.Affinity.Roll) or 0, nome = (nen.Affinity and nen.Affinity.Tier) or "?" },
		Genialidade = { rolagem = (nen.Genius and nen.Genius.Roll) or 0, nome = (nen.Genius and nen.Genius.Tier) or "?" },
		Categorias = {},
		Fundamentais = {
			{ sigla = "TEN", nivel = dominio.Ten or 0, efeito = "ver Dominio de NEN", custo = "-" },
			{ sigla = "REN", nivel = dominio.Ren or 0, efeito = "ver Dominio de NEN", custo = "-" },
			{ sigla = "ZETSU", nivel = dominio.Zetsu or 0, efeito = "ver Dominio de NEN", custo = "-" },
		},
		Avancados = {
			{ sigla = "EN", efeito = "-", custo = "-", requisito = "Ren 2 / Ten 1", desbloqueado = dominio.En == true },
			{ sigla = "IN", efeito = "-", custo = "-", requisito = "Zetsu 2", desbloqueado = dominio.Inp == true },
			{ sigla = "GYO", efeito = "-", custo = "-", requisito = "Zetsu 2 / Ren maestria", desbloqueado = dominio.Gyo == true },
			{ sigla = "SHU", efeito = "-", custo = "-", requisito = "Ten maestria", desbloqueado = dominio.Shu == true },
			{ sigla = "KEN", efeito = "-", custo = "-", requisito = "Ten + Ren maestria", desbloqueado = dominio.Ken == true },
			{ sigla = "KO", efeito = "-", custo = "-", requisito = "Ren + Zetsu maestria, Ten 1", desbloqueado = dominio.Ko == true },
			{ sigla = "RYU", efeito = "-", custo = "-", requisito = "Ten + Ren + Zetsu maestria", desbloqueado = dominio.Ryu == true },
		},
		Hatsus = {},
		Atalhos = { "TEN", "REN", "ZETSU" },
	}
	for _, catId in ipairs({ "INTENSIFICAÇÃO", "TRANSMUTAÇÃO", "MATERIALIZAÇÃO", "ESPECIALIZAÇÃO", "MANIPULAÇÃO", "EMISSÃO" }) do
		local efeitosNessaCategoria = 0
		for _, h in ipairs(character.Hatsus or {}) do
			if (TIPO_PARA_CATEGORIA[h.Tipo] or h.Tipo) == catId then
				efeitosNessaCategoria += #(h.Efeitos or {})
			end
		end
		table.insert(ficha.Nen.Categorias, {
			nome = catId:sub(1, 1) .. catId:sub(2):lower(), -- Sentenca case pra bater com Theme.Categories
			afinidade = (catId == ficha.Categoria) and 100 or 0, -- ⚠️ nao tenho afinidade cruzada calculada aqui
			efeitos = efeitosNessaCategoria,
		})
	end
	for _, h in ipairs(character.Hatsus or {}) do
		local efeitos = {}
		for _, e in ipairs(h.Efeitos or {}) do
			table.insert(efeitos, { nome = e.nome or "?", origem = h.Tipo })
		end
		local restricoes = {}
		for _, r in ipairs(h.Restricoes or {}) do
			table.insert(restricoes, { nome = r.nome or "?", peso = r.peso or "Leve" })
		end
		table.insert(ficha.Nen.Hatsus, {
			nome = h.Nome,
			categoria = TIPO_PARA_CATEGORIA[h.Tipo] or h.Tipo,
			natureza = h.Natureza or "Versatil",
			pn = h.PNUsados or 0,
			descricao = string.format("Custo de aura %s%% · TR %s.", tostring(h.CustoAura or 0), tostring(h.TR or 0)),
			efeitos = efeitos,
			restricoes = restricoes,
		})
	end

	-- ================= BIO =================
	local bio = character.Bio or {}
	ficha.Bio = {
		Personality = bio.Personality or "",
		Goals = bio.Goals or "",
		Historia = bio.Historia or "",
		Aliados = bio.Aliados or "",
		Inimigos = bio.Inimigos or "",
		Organizacoes = bio.Organizacoes or "",
	}
	ficha.GostosEscolhidos = character.GostosEscolhidos or {}
	ficha.DesgostosEscolhidos = character.DesgostosEscolhidos or {}

	-- ⚠️ Dados disponiveis, mas a UI (Claude Design) ainda nao tem um
	-- elemento visual dedicado pra isso -- fica pronto pra quando for
	-- adicionado. Ver CharacterSchema.lua pra contexto completo.
	ficha.FocoDeCaca = character.FocoDeCaca or ""
	ficha.AcaoProtagonistaDisponivel = character.AcaoProtagonistaDisponivel ~= false

	-- Slots de hotkey (menu radial) -- array de nomes de principio
	-- (ou false = vazio), na mesma ordem/tamanho salvos no character.
	ficha.HotkeySlots = character.HotkeySlots or {}

	-- ================= ORGANIZACOES =================
	ficha.Organizacoes = {}
	for _, membership in ipairs(character.Organizacoes or {}) do
		local org = OrganizationService.FindOrganization(membership.orgId)
		if org then
			table.insert(ficha.Organizacoes, {
				orgId = membership.orgId,
				nome = org.nome,
				tipo = org.tipo,
				status = membership.status or "Membro",
				nivel = membership.nivel or 1,
				reputacao = membership.reputacao or 0,
				especial = org.especial,
				titulos = org.titulos or { "?", "?", "?", "?", "?" },
			})
		end
	end

	-- ================= TRACOS =================
	local raca = findRaca(character.Race)
	local antecedente = findAntecedente(character.Background)
	local tracosRaciais = {}
	if raca then
		table.insert(tracosRaciais, { nome = "Traço Racial", texto = raca.descricao or "" })
	end
	local tracosAntecedente = {}
	local proficienciasAntecedente = {}
	if antecedente then
		for _, c in ipairs(antecedente.caracteristicas or {}) do
			table.insert(tracosAntecedente, { nome = c.nome, texto = c.efeito or "" })
		end
		if antecedente.proficiencias then
			table.insert(proficienciasAntecedente, antecedente.proficiencias)
		end
	end
	local incPos, incNeg = {}, {}
	for _, inc in ipairs((character.Inclinations and character.Inclinations.Positive) or {}) do
		table.insert(incPos, { nome = inc.Nome, custo = inc.Custo or 0, texto = "" })
	end
	for _, inc in ipairs((character.Inclinations and character.Inclinations.Negative) or {}) do
		table.insert(incNeg, { nome = inc.Nome, valor = inc.Valor or 0, texto = "" })
	end
	ficha.Tracos = {
		Raciais = tracosRaciais,
		Antecedente = tracosAntecedente,
		ProficienciasAntecedente = proficienciasAntecedente,
		InclinacoesPositivas = incPos,
		InclinacoesNegativas = incNeg,
		-- ⚠️ Sistemas que nao existem no backend ainda (ver topo do arquivo)
		InclinacoesCombate = {},
		PontosCombate = { usados = 0, total = 0 },
		Shingen = {},
		Equipamento = table.concat(character.Inventory and (function()
			local nomes = {}
			for _, it in ipairs(character.Inventory) do table.insert(nomes, it.Name) end
			return nomes
		end)() or {}, " · "),
		Linguagens = "Comum",
		Ferramentas = "",
	}

	-- ================= ITENS / INVENTARIO =================
	-- ⚠️ Sem sistema de "equipar num slot" no backend ainda -- tudo
	-- vira "Bolsa" solta, Equipado fica vazio (ver nota no topo).
	ficha.Itens = {}
	ficha.Bolsa = {}
	ficha.Equipado = {
		cabeca = nil, torso = nil, maoPrincipal = nil, maoSecundaria = nil,
		costas = nil, cintura = nil, pernas = nil, acessorio = nil,
	}
	ficha.Cargas = {}
	for _, it in ipairs(character.Inventory or {}) do
		local realItem = ItemsDB.FindItem(it.Name)
		local detalhe, peso, props = "", 0, ""
		if realItem then
			peso = realItem.peso or 0
			if realItem.dano then
				detalhe = string.format("%s %s", realItem.dano, realItem.tipo_dano or "")
			elseif realItem.ca then
				detalhe = "CA " .. tostring(realItem.ca)
			end
			if realItem.tags then
				props = table.concat(realItem.tags, " · ")
			end
		end
		ficha.Itens[it.Name] = { detalhe = detalhe, peso = peso, props = props }
		table.insert(ficha.Bolsa, { nome = it.Name, qtd = it.Qty or 1 })
	end

	return ficha
end

return FichaUIAdapter
