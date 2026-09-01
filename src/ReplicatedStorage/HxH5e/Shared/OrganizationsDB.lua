--[[
    HxH5e OrganizationsDB (Shared) — catalogo ESTATICO das organizacoes
    controladas por NPC (extraidas da documentacao do Lucas no Notion).
    Sempre existem no jogo, nao precisam ser criadas. Diferente das
    GUILDAS criadas por jogadores (essas ficam no OrganizationRepository,
    persistidas num DataStore global separado).

    Toda organizacao tem EXATAMENTE 5 titulos (niveis 1 a 5), regra
    confirmada com o Lucas e presente em TODOS os exemplos reais
    fornecidos, sem excecao. O tipo (Boa/Neutra/Criminosa/Maligna) e
    fixo, definido aqui.

    ⚠️ Faltam exemplos de organizacoes "Boas" na documentacao recebida
    -- categoria existe (ver OrganizationService.TIPOS) mas nenhuma
    organizacao estatica desse tipo foi cadastrada ainda. Tambem nao
    veio a hierarquia completa da "Familia Nostrade" (so o nome).
]]

local OrganizationsDB = {}

OrganizationsDB.Organizacoes = {
	{
		id = "pollos_hermanos",
		nome = "Pollos Hermanos",
		tipo = "Criminosa",
		titulos = { "Candidato", "Colaborador", "Coordenador", "Gerente", "Sócio" },
		tesouro = 10000, -- pedido do Lucas: toda organizacao pre-existente comeca com >=10k
	},
	{
		id = "clube_da_luta",
		nome = "Clube da Luta",
		tipo = "Criminosa",
		titulos = { "Lutador", "Mão de Martelo", "Campeão", "Dono de Cinturão", "Apresentador" },
		tesouro = 10000, -- pedido do Lucas: toda organizacao pre-existente comeca com >=10k
	},
	{
		id = "chess",
		nome = "Chess",
		tipo = "Maligna",
		titulos = { "Peão", "Cavaleiro", "Bispo", "Torre", "Rainha/Rei" },
		tesouro = 10000, -- pedido do Lucas: toda organizacao pre-existente comeca com >=10k
	},
	{
		id = "corvo_da_noite",
		nome = "Corvo da Noite",
		tipo = "Maligna",
		titulos = { "Amaldiçoado", "Assassino", "Sombra", "Flagelo das Raças", "Corvo da Noite" },
		tesouro = 10000, -- pedido do Lucas: toda organizacao pre-existente comeca com >=10k
	},
	{
		id = "instituto_maca",
		nome = "Instituto MACA",
		tipo = "Neutra",
		titulos = { "Aristóteles/Copérnico", "Tesla/Galileu Galilei", "Stephen H./Pasteur", "Darwin/Newton", "Einstein/Freud" },
		tesouro = 10000, -- pedido do Lucas: toda organizacao pre-existente comeca com >=10k
	},
	{
		id = "vampiros",
		nome = "Vampiros",
		tipo = "Neutra",
		-- Titulos usados aqui como marco simbolico de reconhecimento
		-- entre a comunidade de vampiros -- nivel 5 = "aceito pelos
		-- demais Condes e Vampiros" (requisito real de Imperador,
		-- documentado com o Lucas). Nao substitui a Casta em si
		-- (character.VampiroCasta), e um rastreamento PARALELO de
		-- reputacao/aceitacao social.
		titulos = { "Recém-Transformado", "Reconhecido", "Respeitado", "Temido", "Aceito por Todos" },
		tesouro = 10000, -- pedido do Lucas: toda organizacao pre-existente comeca com >=10k
	},
	{
		id = "associacao_hunter",
		nome = "Associação Hunter",
		tipo = "Neutra",
		titulos = { "Hunter", "Hunter", "Hunter", "Hunter", "Hunter" }, -- sem hierarquia de rank definida pelo Lucas ainda
		tesouro = 10000, -- pedido do Lucas: toda organizacao pre-existente comeca com >=10k
		especial = true, -- NAO entra pelo fluxo normal de JoinOrganization -- so via Licenca Hunter (comprada ou Exame Hunter, pendente)
	},
	{
		id = "a_horda",
		nome = "A Horda",
		tipo = "Neutra",
		titulos = { "Batedor", "Esmaga Ossos", "Aniquilador", "Machado Sanguinário", "The Ruller" },
		tesouro = 10000, -- pedido do Lucas: toda organizacao pre-existente comeca com >=10k
	},
}

local byId = {}
for _, o in ipairs(OrganizationsDB.Organizacoes) do
	byId[o.id] = o
end
OrganizationsDB.ById = byId

function OrganizationsDB.Get(id)
	return byId[id]
end

return OrganizationsDB
