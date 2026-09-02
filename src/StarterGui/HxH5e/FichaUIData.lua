--!strict
-- FichaUIData — de onde a ficha tira os números.
--
-- Tenta o servidor primeiro (ReplicatedStorage.HxH5e.GetCharacterUI, que
-- devolve o character REAL ja convertido pelo FichaUIAdapter.lua do
-- servidor). Se não achar, usa o personagem de exemplo, para a UI abrir
-- sozinha no Studio sem depender de nada. Todas as regras calculadas aqui
-- vêm do repositório:
--   capacidade   = 2 + 2 × mod FOR (mínimo 1) + espaco_gerado dos recipientes
--   acuidade     = usa o maior entre FOR e DES
--   P.N por nível e limiares de reputação = NenService / OrganizationService
--
-- ⚠️ PENDÊNCIA REAL (achada pelo Claude ao instalar): o remote de verdade
-- fica em ReplicatedStorage.HxH5e.GetCharacter (sem a subpasta "Remotes"),
-- e o formato retornado por ele é BEM diferente do que este arquivo espera
-- (ex: char.Vitals.HP eh uma tabela {Current,Max}, nao um numero "PV"; nao
-- existe char.Nen.Categorias nem char.Tracos). Precisa de um adaptador no
-- servidor ou aqui antes de ligar nos dados reais -- ver auditoria enviada
-- ao Lucas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = {}

Data.PNPorNivel = { 6, 8, 10, 12, 14, 7, 10, 13, 16, 19, 22, 25 }
Data.LimiaresReputacao = { [2] = 5, [3] = 15, [4] = 30 }

Data.Demo = {
	Nome = "Kairo",
	Jogador = "Jogador_01",
	Nivel = 6,
	XP = 300, XPProximo = 1500,
	Categoria = "Intensificação",
	Tendencia = "Heroico",
	Proficiencia = 2,
	Raca = "Meio-Orcs",
	Antecedente = "Guarda Costas",
	Deslocamento = "9m",
	Dinheiro = 4850,

	Vitals = {
		PV = 42, PVMax = 52,
		Aura = 74, AuraMax = 100,
		Sanidade = 88, SanidadeMax = 100,
		Reacoes = 7, ReacoesMax = 7,
		CA = 16, RDM = 4, Iniciativa = 2,
	},

	Atributos = {
		{ sigla = "FOR", nome = "Força",        valor = 18, mod = 4, tr = 4, grupo = "fisico" },
		{ sigla = "DES", nome = "Destreza",     valor = 15, mod = 2, tr = 5, grupo = "fisico" },
		{ sigla = "CON", nome = "Constituição", valor = 16, mod = 3, tr = 4, grupo = "fisico" },
		{ sigla = "INT", nome = "Inteligência", valor = 12, mod = 1, tr = 4, grupo = "mental" },
		{ sigla = "SAB", nome = "Sabedoria",    valor = 14, mod = 2, tr = 4, grupo = "mental" },
		{ sigla = "PRE", nome = "Presença",     valor = 17, mod = 3, tr = 3, grupo = "mental" },
	},

	Pericias = {
		FOR = { { "Atletismo", 6, true } },
		DES = { { "Acrobacia", 2, false }, { "Furtividade", 4, true }, { "Prestidigitação", 2, false } },
		CON = {},
		INT = { { "Arcanismo", 1, false }, { "História", 1, false }, { "Investigação", 1, false }, { "Natureza", 1, false }, { "Religião", 1, false } },
		SAB = { { "Intuição", 4, true }, { "Medicina", 2, false }, { "Percepção", 4, true }, { "Sobrevivência", 2, false }, { "Lidar c/ Animais", 2, false } },
		PRE = { { "Atuação", 3, false }, { "Enganação", 3, false }, { "Intimidação", 5, true }, { "Persuasão", 3, false } },
	},

	Condicoes = { { nome = "Sangramento", pilhas = 2 }, { nome = "Abalado", pilhas = 1 } },

	Nen = {
		Afinidade = { rolagem = 78, nome = "Alta" },
		Genialidade = { rolagem = 31, nome = "Gênio" },
		-- ordem do hexágono: topo e sentido horário
		Categorias = {
			{ nome = "Intensificação", afinidade = 100, efeitos = 4 },
			{ nome = "Transmutação",   afinidade = 80,  efeitos = 0 },
			{ nome = "Materialização", afinidade = 60,  efeitos = 0 },
			{ nome = "Especialização", afinidade = 0,   efeitos = 0 },
			{ nome = "Manipulação",    afinidade = 60,  efeitos = 0 },
			{ nome = "Emissão",        afinidade = 80,  efeitos = 3 },
		},
		Fundamentais = {
			{ sigla = "TEN",   nivel = 2, efeito = "RD 4 enquanto ativo", custo = "0%" },
			{ sigla = "REN",   nivel = 2, efeito = "+1 Grau de dano · +3 em testes de aura", custo = "10%" },
			{ sigla = "ZETSU", nivel = 2, efeito = "+10% aura · +3 furtividade · +1 reação", custo = "0%" },
		},
		Avancados = {
			{ sigla = "EN",  efeito = "detecta em 3m · 2 reações", custo = "5%",  requisito = "Zetsu 2", desbloqueado = true },
			{ sigla = "IN",  efeito = "oculta aura ou objeto",     custo = "10%", requisito = "Zetsu 2", desbloqueado = false },
			{ sigla = "GYO", efeito = "+3 FOR / DES / CON",        custo = "5%",  requisito = "Zetsu 2", desbloqueado = false },
			{ sigla = "SHU", efeito = "objeto envolto: +1d4",      custo = "5%",  requisito = "Ren 2",   desbloqueado = false },
			{ sigla = "KEN", efeito = "defesa máxima · 4 reações", custo = "30%", requisito = "Ren 2",   desbloqueado = false },
			{ sigla = "KO",  efeito = "golpe ×3 · CA −80%",        custo = "30%", requisito = "Ken",     desbloqueado = false, travado = true },
			{ sigla = "RYU", efeito = "redistribui aura",          custo = "15%", requisito = "Ken",     desbloqueado = false, travado = true },
		},
		Hatsus = {
			{
				nome = "Punho de Aço", categoria = "Intensificação", natureza = "Ofensivo", pn = 6,
				descricao = "Concentra aura nos punhos e no torso, endurecendo o corpo no mesmo golpe em que amplia o impacto.",
				efeitos = {
					{ nome = "Aumento de Atributo", origem = "Intensificação" },
					{ nome = "Golpe Reforçado", origem = "Intensificação" },
					{ nome = "Corpo de Aço", origem = "Intensificação" },
					{ nome = "Dano Fragilizante", origem = "Intensificação" },
					{ nome = "Aumento de Duração", origem = "Gerais" },
				},
				restricoes = {
					{ nome = "Golpe/Toque", peso = "Leve" },
					{ nome = "Condição Levemente Hostil", peso = "Leve" },
					{ nome = "Dano Antes de Usar", peso = "Média" },
				},
			},
			{
				nome = "Lança de Aura", categoria = "Emissão", natureza = "Ofensivo", pn = 3,
				descricao = "Projeta a aura endurecida à distância. Fora da categoria — paga 15% de aura ou 5 de sanidade por grau.",
				efeitos = {
					{ nome = "Acesso de Categoria", origem = "Emissão" },
					{ nome = "Aumento de Alcance", origem = "Gerais" },
					{ nome = "Dano/Cura Focal", origem = "Gerais" },
				},
				restricoes = {
					{ nome = "Objeto Canalizador", peso = "Leve" },
					{ nome = "Limitação de Alvos", peso = "Leve" },
				},
			},
		},
		Atalhos = { "TEN", "REN", "ZETSU", "EN" },
	},

	Bio = {
		Personality = "Fala pouco e observa muito. Sob pressão, decide rápido demais e depois carrega a conta.",
		Goals = "Encontrar quem mandou queimar a casa de leilões. Não morrer antes disso.",
		Historia = "Cresceu carregando engradado no porto de Yorknew até um Nen user cobrar proteção da vizinhança inteira. Aprendeu Ten sozinho, errado, e quase morreu por isso. Um velho do Clube da Luta corrigiu sua postura em troca de três vitórias no ringue — pagou as três em cinco meses.",
		Aliados = "O velho do Clube. Uma médica que não faz perguntas.",
		Inimigos = "O cobrador do porto, vivo. Um irmão dele, também.",
		Organizacoes = "Contato informal com um agente da Associação, fora do registro.",
	},
	GostosEscolhidos = { "vitoria_combate", "disciplina_nen", "descanso_seguro" },
	DesgostosEscolhidos = { "miseria", "derrota", "esgotamento" },

	Organizacoes = {
		{
			orgId = "clube_da_luta", nome = "Clube da Luta", tipo = "Criminosa", status = "Membro ativo",
			nivel = 3, reputacao = 18,
			titulos = { "Lutador", "Mão de Martelo", "Campeão", "Dono de Cinturão", "Apresentador" },
		},
		{
			orgId = "associacao_hunter", nome = "Associação Hunter", tipo = "Neutra", status = "Especial",
			nivel = 1, reputacao = 0, especial = "Entrada só por Licença Hunter",
			titulos = { "Hunter", "Hunter", "Hunter", "Hunter", "Hunter" },
		},
	},

	Tracos = {
		Raciais = {
			{ nome = "Visão na Penumbra", texto = "Enxerga na penumbra a até 18m no escuro." },
			{ nome = "Resistência Implacável", texto = "Quando reduzido a 0 pontos de vida sem morrer completamente, pode voltar para 1 ponto de vida. Utilizável um número de vezes por dia igual à sua proficiência." },
		},
		Antecedente = {
			{ nome = "Artista Marcial", texto = "Você treinou técnicas e desenvolveu seu corpo ao máximo para o combate corpo-a-corpo. Seus golpes desarmados causam 1d6 no lugar de 1d4." },
			{ nome = "Horário de Trabalho", texto = "Você consegue escolher uma pessoa para manter sua atenção de forma constante. Você tem vantagem e +2 em jogadas de percepção para encontrar essa pessoa." },
		},
		ProficienciasAntecedente = { "Atletismo", "Intimidação" },
		InclinacoesPositivas = {
			{ nome = "Corpo de Gigante", custo = 5, texto = "Você é enorme e por isso tem um nível a mais de vitalidade. +5 HP inicial e +3 por nível. O usuário tem que ficar com altura acima de 2,10m e não consegue utilizar armas leves e pequenas sem depender de uma técnica." },
			{ nome = "Visão no Escuro", custo = 2, texto = "Você pode ver 9m no escuro como se fosse dia e não sofre penalidades de escuridão que não conte como bloqueio ou aplique cegueira." },
		},
		InclinacoesNegativas = {
			{ nome = "Espírito de Lutador", valor = 3, texto = "Jamais desperdiça a chance de enfrentar alguém mais forte para provar que é o melhor — mesmo já tendo perdido várias vezes por esse impulso." },
			{ nome = "Teimosia", valor = 1, texto = "Sempre quer fazer as coisas do seu jeito — seus aliados podem precisar de vários testes de Persuasão para te convencer até de planos razoáveis." },
		},
		-- Ainda não existem no repositório: portar do livro/webapp
		InclinacoesCombate = {
			{ nome = "Sentinela", tier = 1, texto = "Provoca ataques de oportunidade mesmo que o inimigo use Desengajar." },
			{ nome = "Defensiva Bruta", tier = 1, texto = "3 em Redução de Dano (RD) contra qualquer fonte de dano de qualquer oponente em combate." },
		},
		PontosCombate = { usados = 2, total = 2 },
		Shingen = {},
		Equipamento = "Pistola · Qualquer arma simples ou Marcial",
		Linguagens = "Comum · Orc",
		Ferramentas = "Kit Médico · Kit de Armas",
	},

	-- Catálogo de itens: espelha ItemsDB + propriedades.
	-- ATENÇÃO: as propriedades (Acuidade, Pesada, Duas mãos…) ainda não estão
	-- no ItemsDB do repositório. Quando forem portadas, troque este catálogo
	-- por require(ReplicatedStorage.HxH5e.Shared.ItemsDB).
	Itens = {
		["Espada Exótica (Katana)"] = { slot = "mao", detalhe = "1d8 Corte", peso = 1.0, props = "Acuidade — usa DES ou FOR, o maior", acuidade = true },
		["Clava Grande"]            = { slot = "mao", detalhe = "1d8 Impacto", peso = 2.0, props = "Pesada · Duas mãos" },
		["Escudo Comum"]            = { slot = "mao", detalhe = "CA +1", peso = 1.0, props = "Escudo — ocupa uma mão" },
		["Colete Fino de Kevlar"]   = { slot = "torso", detalhe = "CA 12 + DES", peso = 0.3, props = "Leve · sem penalidade de furtividade" },
		["Máscara de Gás"]          = { slot = "cabeca", detalhe = "imune a gases", peso = 0.5, props = "", usos = 15 },
		["Mochila"]                 = { slot = "costas", detalhe = "espaço +1.5", peso = 0, props = "", espaco = 1.5 },
		["Pochete"]                 = { slot = "cintura", detalhe = "espaço +0.7", peso = 0, props = "", espaco = 0.7 },
		["Kit Médico"]              = { detalhe = "estabiliza e cura", peso = 0.8, props = "", usos = 5 },
		["Kit de Armas"]            = { detalhe = "manutenção de armas", peso = 1.5, props = "", usos = 5 },
		["Pílula Hemoglobina"]      = { detalhe = "Cura 2d4 + CON PV", peso = 0, props = "Consumível", consumivel = true },
		["Cartucho Pistola (12)"]   = { detalhe = "munição de pistola", peso = 0.5, props = "", usos = 12 },
	},

	Equipado = {
		cabeca = nil, torso = "Colete Fino de Kevlar", maoPrincipal = "Espada Exótica (Katana)",
		maoSecundaria = nil, costas = "Mochila", cintura = "Pochete", pernas = nil, acessorio = nil,
	},
	Bolsa = {
		{ nome = "Escudo Comum", qtd = 1 },
		{ nome = "Kit Médico", qtd = 1 },
		{ nome = "Pílula Hemoglobina", qtd = 3 },
		{ nome = "Cartucho Pistola (12)", qtd = 1 },
		{ nome = "Máscara de Gás", qtd = 1 },
	},
	Cargas = {},
}

Data.TagsSanidade = {
	{ id = "companhia_aliados", nome = "Companhia de aliados", tipo = "gosto" },
	{ id = "paz_diurna", nome = "Paz e solidão diurna", tipo = "gosto" },
	{ id = "vitoria_combate", nome = "Vitória em combate", tipo = "gosto" },
	{ id = "descanso_seguro", nome = "Descanso seguro", tipo = "gosto" },
	{ id = "disciplina_nen", nome = "Disciplina do Nen", tipo = "gosto" },
	{ id = "prosperidade", nome = "Prosperidade", tipo = "gosto" },
	{ id = "reconhecimento", nome = "Reconhecimento", tipo = "gosto" },
	{ id = "seguranca", nome = "Sensação de segurança", tipo = "gosto" },
	{ id = "superar_desafios", nome = "Superar desafios", tipo = "gosto" },
	{ id = "emocao_risco", nome = "Emoção do risco", tipo = "gosto" },
	{ id = "solidao_noturna", nome = "Solidão à noite", tipo = "desgosto" },
	{ id = "exaustao", nome = "Exaustão", tipo = "desgosto" },
	{ id = "beira_morte", nome = "À beira da morte", tipo = "desgosto" },
	{ id = "miseria", nome = "Miséria", tipo = "desgosto" },
	{ id = "rejeicao", nome = "Rejeição", tipo = "desgosto" },
	{ id = "perigo_constante", nome = "Perigo constante", tipo = "desgosto" },
	{ id = "derrota", nome = "Derrota", tipo = "desgosto" },
	{ id = "multidoes", nome = "Multidões", tipo = "desgosto" },
	{ id = "isolamento", nome = "Isolamento prolongado", tipo = "desgosto" },
	{ id = "esgotamento", nome = "Esgotamento", tipo = "desgosto" },
}

-- Capacidade de carga: 2 + 2 × mod FOR (mínimo 1) + espaco_gerado equipado
function Data.capacidade(ficha): number
	local forMod = 1
	for _, a in ipairs(ficha.Atributos) do
		if a.sigla == "FOR" then forMod = math.max(1, a.mod) end
	end
	local base = 2 + 2 * forMod
	local recipientes = 0
	for _, nome in pairs(ficha.Equipado) do
		local def = ficha.Itens[nome]
		if def and def.espaco then recipientes += def.espaco end
	end
	return base + recipientes, base, recipientes
end

function Data.pesoCarregado(ficha): number
	local peso = 0
	for _, it in ipairs(ficha.Bolsa) do
		local def = ficha.Itens[it.nome]
		if def then peso += (def.peso or 0) * it.qtd end
	end
	for _, nome in pairs(ficha.Equipado) do
		local def = ficha.Itens[nome]
		if def then peso += def.peso or 0 end
	end
	return peso
end

-- Acuidade: usa o maior entre FOR e DES
function Data.ataque(ficha): string
	local forMod, desMod = 0, 0
	for _, a in ipairs(ficha.Atributos) do
		if a.sigla == "FOR" then forMod = a.mod end
		if a.sigla == "DES" then desMod = a.mod end
	end
	local nome = ficha.Equipado.maoPrincipal
	local def = nome and ficha.Itens[nome]
	if not def then
		return string.format("desarmado 1d6 · FOR %+d", forMod)
	end
	if def.acuidade then
		if forMod >= desMod then
			return string.format("%s · FOR %+d (acuidade)", def.detalhe, forMod)
		end
		return string.format("%s · DES %+d (acuidade)", def.detalhe, desMod)
	end
	return string.format("%s · FOR %+d", def.detalhe, forMod)
end

function Data.tituloOrg(org): (string, number, string)
	local nivel = org.nivel
	local titulo = org.titulos[nivel] or org.titulos[1]
	local proximo
	if nivel >= 4 then
		proximo = "nível 5 só por promoção manual"
	else
		proximo = "próximo título em " .. tostring(Data.LimiaresReputacao[nivel + 1])
	end
	if org.reputacao <= -20 then proximo = "limiar de expulsão atingido" end
	return titulo, nivel, proximo
end

function Data.pnTotal(nivel: number): number
	return Data.PNPorNivel[math.clamp(nivel, 1, 12)] or 0
end

-- Busca no servidor; cai no exemplo se não houver remote.
-- Corrigido: o remote real fica em ReplicatedStorage.HxH5e.GetCharacterUI
-- (nao existe pasta "HxH5eRemotes" -- ver FichaUIAdapter.lua no servidor,
-- que converte o character real pro formato que este arquivo espera).
function Data.carregar()
	local hxh5e = ReplicatedStorage:FindFirstChild("HxH5e")
	if hxh5e then
		local get = hxh5e:FindFirstChild("GetCharacterUI")
		if get and get:IsA("RemoteFunction") then
			local ok, ficha = pcall(function() return get:InvokeServer() end)
			if ok and type(ficha) == "table" then
				return ficha, true
			end
		end
	end
	return Data.Demo, false
end

return Data
