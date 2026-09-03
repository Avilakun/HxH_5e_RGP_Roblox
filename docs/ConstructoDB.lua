-- ConstructoDB.lua -- gerado automaticamente a partir de constructo-db.js
-- do webapp (github.com/Criadores-HxH-5e/Ficha_HxH5e).
-- Tabelas de regras pra montar a "ficha do Constructo" (golem/invocacao),
-- geradas quando um Hatsu de Materializacao/Emissao compra efeitos que
-- criam um constructo. Fonte original: Manual de Hatsus, secao "Criando
-- a ficha da Materializacao".
--
-- Contem: PV/CA base por Tamanho x Durabilidade x Material, bonus por
-- efeito de Hatsu comprado (EFEITO_PV/EFEITO_CA/EFEITO_CARACTERISTICAS,
-- chaveados pelo ID do efeito no HatsuDB), escala de Caracteristicas de
-- Invocacao, slots/tipos de pericia, e acoes prontas (simples/complexas)
-- que o constructo pode usar em combate.

local ConstructoDB = {
	CONSTRUCTO_DB = {
		TAMANHO_ORDEM = {
			"Minúsculo",
			"Pequeno",
			"Médio",
			"Grande",
			"Enorme",
			"Colossal",
		},
		PV_POR_TAMANHO = {
			["Minúsculo"] = {
				fragil = 4,
				resistente = 9,
			},
			Pequeno = {
				fragil = 5,
				resistente = 13,
			},
			["Médio"] = {
				fragil = 6,
				resistente = 17,
			},
			Grande = {
				fragil = 7,
				resistente = 20,
			},
			Enorme = {
				fragil = 8,
				resistente = 23,
			},
			Colossal = {
				fragil = 12,
				resistente = 25,
			},
		},
		CA_POR_MATERIAL = {
			["Tecido/Papel"] = 11,
			["Cristal/Vidro"] = 12,
			["Madeira/Orgânico"] = 13,
			["Mineral/Pedra"] = 14,
			["Líquido/Gel"] = 14,
			Metal = 15,
			Gasoso = nil,
		},
		EFEITO_PV = {
			rm_e2 = 5,
			rm_e14 = 10,
			rc_e2 = 5,
			rc_e5 = 10,
			rc_e7 = 10,
			rc_e10 = 15,
			rc_e13 = 20,
			em_e1 = 6,
		},
		EFEITO_CA = {
			rm_e14 = 2,
			rc_e2 = 1,
			rc_e5 = 2,
			rc_e7 = 2,
			rc_e10 = 2,
			rc_e13 = 3,
			em_e1 = 12,
		},
		EFEITO_CARACTERISTICAS = {
			rm_e2 = 1,
			rm_e3 = 1,
			rm_e14 = 1,
			rc_e5 = 1,
			rc_e7 = 1,
			rc_e10 = 2,
		},
		RESTRICAO_PV = {
			rc_p3 = 10,
		},
		RESTRICAO_CA = {
			rc_l1 = 1,
			rc_p3 = 2,
		},
		CARACTERISTICA_SCALE = {
			Robustez = {
				5,
				10,
				15,
				25,
			},
			["Carapaça/Armadura"] = {
				2,
				3,
				4,
				5,
			},
			Furtivo = {
				2,
				3,
				4,
				5,
			},
			Atento = {
				2,
				3,
				4,
				5,
			},
			Perturbador = {
				2,
				3,
				4,
				5,
			},
			Defensor = {
				2,
				3,
				4,
				5,
			},
			["Móvel/Veloz"] = {
				3,
				4.5,
				6,
				7.5,
				9,
			},
		},
		PERICIA_SLOTS = 5,
		PERICIA_TIPOS = {
			{
				id = "tr",
				label = "Teste de Resistência",
				valores = {
					"FOR",
					"DES",
					"CON",
					"INT",
					"SAB",
					"PRE",
				},
			},
			{
				id = "pericia",
				label = "Perícia",
				valores = {
					"Atletismo",
					"Acrobacia",
					"Furtividade",
					"Prestidigitação",
					"Arcanismo",
					"História",
					"Investigação",
					"Natureza",
					"Religião",
					"Lidar com Animais",
					"Intuição",
					"Medicina",
					"Percepção",
					"Sobrevivência",
					"Atuação",
					"Enganação",
					"Intimidação",
					"Persuasão",
				},
			},
			{
				id = "arma",
				label = "Armas/Equipamentos",
				valores = {
					"Armas de Cerco",
					"Proteção Média",
					"Proteção Pesada",
					"Improvisados/Manufaturados",
					"Científicas/Explosivas",
					"Marciais corpo-a-corpo",
					"Marciais à distância",
					"Simples corpo-a-corpo",
					"Simples à distância",
				},
			},
		},
		ACOES_SIMPLES = {
			{
				nome = "Arma Natural",
				desc = "Golpe corpo-a-corpo: 2d6 + atributo (normalmente FOR) em um acerto.",
			},
			{
				nome = "Ataque Simples",
				desc = "Realiza um ataque simples e direto.",
			},
			{
				nome = "Auxílio Rápido",
				desc = "Concede a ação de Ajuda a um aliado a até 1,5m para Testes ou Ataques.",
			},
			{
				nome = "Desarme Simples",
				desc = "Ataque vs Atletismo do alvo; vencendo, o alvo derruba o item em 1,5m.",
			},
			{
				nome = "Focar em Precisão",
				desc = "Durante 1 rodada, todo ataque recebe +2 para acertar.",
			},
			{
				nome = "Levantar Guarda",
				desc = "Durante 1 rodada, recebe 2 de RD contra qualquer dano.",
			},
			{
				nome = "Observar Alvo",
				desc = "+2 em TR contra ataques/efeitos daquele alvo na próxima rodada.",
			},
			{
				nome = "Preparar Ataque",
				desc = "O próximo ataque causa 1d4 de dano adicional.",
			},
			{
				nome = "Provocação",
				desc = "Alvo em TR de SAB/PRE vs Intimidação; se falhar, vantagem pra atacar o constructo.",
			},
			{
				nome = "Reposicionamento Tático",
				desc = "Move até 3m sem provocar ataques de oportunidade.",
			},
		},
		ACOES_COMPLEXAS = {
			{
				nome = "Acompanhar Golpe",
				desc = "Próximo ataque de um aliado a 3m: +2 para acertar e +1d4 de dano.",
			},
			{
				nome = "Ataque com Sangue-Frio",
				desc = "Ataque corpo-a-corpo com desvantagem; em acerto, +2d6 de dano crítico.",
			},
			{
				nome = "Combo Coordenado",
				desc = "Dois ataques corpo-a-corpo contra o mesmo alvo, cada um com −1 grau/passo de dano.",
			},
			{
				nome = "Empurrar e Ferir",
				desc = "Atletismo vs Atletismo — se vencer, derruba (Caído) e ainda desfere um ataque.",
			},
			{
				nome = "Investida Poderosa",
				desc = "Move até 3m em linha reta + ataque com +2 para acertar; em acerto, +mod de atributo em dano.",
			},
			{
				nome = "Rasgar Defesa",
				desc = "Em acerto, além do dano normal, alvo recebe −2 de CA até o fim do próximo turno.",
			},
		},
	},
	CONSTRUCT_EFFECT_IDS = {
		"rm_e2",
		"rm_e14",
		"rc_e2",
		"rc_e5",
		"rc_e7",
		"rc_e10",
		"rc_e13",
		"em_e1",
		"rm_e3",
	},
}

return ConstructoDB
