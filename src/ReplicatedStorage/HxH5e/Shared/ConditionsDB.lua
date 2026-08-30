--[[
    HxH5e ConditionsDB (Shared) — catalogo de Condicoes Mecanicas
    Fonte: material "Condicoes.txt" fornecido pelo Lucas.

    Cada condicao: { id, nome, nivel (Fraca/Media/Forte/Extrema),
    desc (resumo mecanico), concede (lista de ids de outras condicoes
    aplicadas automaticamente junto), variavel (bool, tem graus), }

    NIVEL DE CONDICAO (regra "Condicao Perigosa" + Acesso a Niveis de
    Efeito, ainda nao conectado a criacao de Hatsu):
      Nivel de efeito 1-3  -> Condicoes Fracas
      Nivel de efeito 3-6  -> Condicoes Medias
      Nivel de efeito 7-10 -> Condicoes Fortes
      Nivel de efeito 11-12 -> Condicoes Extremas

    Efeitos numericos JA conectados no jogo (ver CharacterService
    ApplyCondition/RemoveCondition e HatsuService calcCustoAura):
      - CA: Inconsciente e Paralisado dao -10 de CA.
      - Deslocamento: Lento e Enredado reduzem a metade; Imovel e
        Paralisado zeram; Cado restringe (registrado, nao recalcula
        deslocamento automatico por ora, ver nota no proprio dado).
      - Custo de Aura: Condenado da +5% em qualquer tecnica de Nen.

    PENDENTE (sem sistema de suporte ainda no jogo, so descritivo por
    ora): vantagem/desvantagem em testes/ataques, ataque-vs-alvo (CA
    comparada a rolagem de acerto), dano por rodada (Envenenado,
    Sangramento, Queimando), testes de resistencia por perícia
    especifica, e a tabela completa de Desmembrado por parte do corpo
    (fica só como condicao generica registrada por enquanto — o
    Lucas quer ver o impacto pratico em combate antes de detalhar).
]]

local ConditionsDB = {}

ConditionsDB.NIVEL_POR_ACESSO = {
	{ min = 1, max = 3, nivel = "Fraca" },
	{ min = 3, max = 6, nivel = "Media" },
	{ min = 7, max = 10, nivel = "Forte" },
	{ min = 11, max = 12, nivel = "Extrema" },
}

ConditionsDB.Condicoes = {
	-- ===== FRACAS =====
	{ id = "abalado", nome = "Abalado", nivel = "Fraca",
		desc = "-2 em testes de pericia. Se ficar Abalado de novo, a penalidade sobe pra -3 ou pode virar Amedrontado." },
	{ id = "afogado_natural", nome = "Afogado/Asfixiado (Natural)", nivel = "Fraca",
		desc = "Prender a respiracao por meios naturais: 1+CON em minutos (minimo 30s). Depois, CON (minimo 1) rodadas pra respirar antes de ficar Inconsciente." },
	{ id = "caido", nome = "Caido", nivel = "Fraca",
		desc = "Desvantagem em ataques corpo-a-corpo e reacoes. So se move 4,5m rastejando, ou usa metade do deslocamento pra levantar. Ataques corpo-a-corpo contra o alvo tem vantagem; ataques a distancia sofrem desvantagem." },
	{ id = "desorientado", nome = "Desorientado", nivel = "Fraca",
		desc = "Incapaz de usar reacoes." },
	{ id = "desprevenido", nome = "Desprevenido", nivel = "Fraca",
		desc = "Ataques contra o alvo tem vantagem. Desvantagem em testes de destreza." },
	{ id = "empurrado_puxado", nome = "Empurrado/Puxado", nivel = "Fraca",
		desc = "TR de Atletismo ou Destreza pra nao ser movido 1,5m contra a vontade. Falha: cai (fica Caido).", concede = { "caido" } },
	{ id = "envenenado", nome = "Envenenado", nivel = "Fraca", variavel = true,
		desc = "Desvantagem em ataques e testes de pericia enquanto durar, + dano inicial do veneno. Condicao variavel (Fraco/Medio/Forte/Extremo, ver graus).",
		graus = {
			Fraco = { desc = "Condicao Envenenado" },
			Medio = { desc = "Envenenado + 2d4", dano = "2d4", concede = { "enjoado" } },
			Forte = { desc = "Envenenado + 2d10", dano = "2d10", concede = { "enjoado" } },
			Extremo = { desc = "Envenenado + 3d12", dano = "3d12", concede = { "enjoado" } },
		} },
	{ id = "lento", nome = "Lento", nivel = "Fraca",
		desc = "Todo deslocamento reduzido pela metade. Nao pode usar a acao Disparar." },
	{ id = "molhado", nome = "Molhado", nivel = "Fraca",
		desc = "Vulneravel a dano eletrico. Imune a ser queimado, mas so Resistente a dano de fogo." },
	{ id = "mudo", nome = "Mudo", nivel = "Fraca",
		desc = "Impedido de se comunicar verbalmente ou emitir sons com a boca." },
	{ id = "ofuscado", nome = "Ofuscado", nivel = "Fraca",
		desc = "Barreira visual atrapalha o ataque. Normalmente da 1/2 cobertura ao alvo (CA +2) ou -2 ao atacante." },
	{ id = "sangramento", nome = "Sangramento", nivel = "Fraca", variavel = true,
		desc = "20+ de dano cortante direto/somado no turno exige TR CON (dificuldade metade do dano ou 10, o maior) ou fica sangrando. Condicao variavel (Fraco/Medio/Forte/Extremo).",
		graus = {
			Fraco = { desc = "2d4 por rodada ate superar o teste", dano = "2d4" },
			Medio = { desc = "2d8 por rodada ate superar o teste", dano = "2d8" },
			Forte = { desc = "2d10 por rodada ate superar o teste", dano = "2d10" },
			Extremo = { desc = "3d12 por rodada ate superar o teste", dano = "3d12" },
		} },

	-- ===== MEDIAS =====
	{ id = "afogado_combate", nome = "Afogado/Asfixiado (Combate)", nivel = "Media",
		desc = "1+CON inicial ja conta em rodadas pra chegar ao desmaio. Falar reduz em 1 rodada o tempo restante." },
	{ id = "agarrado", nome = "Agarrado", nivel = "Media",
		desc = "Fica Desprevenido e Imovel. Ataques a distancia contra alguem envolvido num agarrao tem 50% de acertar o alvo errado (1-5 em 1d10). Termina se: soltarem/perderem o teste, ficar Incapacitado, ou for removido do alcance.",
		concede = { "desprevenido", "imovel" } },
	{ id = "amedrontado", nome = "Amedrontado/Assustado", nivel = "Media",
		desc = "Desvantagem em testes de pericia e ataque contra a fonte do medo. Nao pode se aproximar voluntariamente dela." },
	{ id = "confuso", nome = "Confuso", nivel = "Media",
		desc = "Comportamento aleatorio: rola 1d6 no inicio do turno (1: move aleatorio; 2-3: sem acoes; 4-5: ataca o mais proximo ou a si mesmo; 6: condicao termina)." },
	{ id = "esmagado", nome = "Esmagado", nivel = "Media",
		desc = "TR de Constituicao. Sucesso: so dano normal. Falha: fica Caido e +5 ao sofrer dano. Falha por 5+: +1d6 de dano de esmagamento. Ken reduz o dano pela metade.",
		concede = { "caido" } },
	{ id = "enjoado", nome = "Enjoado (Mal estar)", nivel = "Media",
		desc = "So pode fazer uma acao principal OU se mover (nao ambos) por rodada." },
	{ id = "enredado", nome = "Enredado/Preso", nivel = "Media",
		desc = "Deslocamento reduzido a metade. Nao pode usar Disparar. Ataques contra o alvo tem vantagem; o alvo tem desvantagem em ataques." },
	{ id = "exausto", nome = "Exausto", nivel = "Media", variavel = true,
		desc = "3 niveis acumulativos. Descanso curto remove 1 nivel; descanso longo remove 2; o 3o exige descanso longo + (Zetsu por 2 dias OU nao usar Nen por 1 semana).",
		graus = {
			["1"] = { desc = "Desvantagem em Testes de Habilidade e Resistencia" },
			["2"] = { desc = "Nivel 1 + Desvantagem em ataque (vantagem contra voce) + deslocamento pela metade" },
			["3"] = { desc = "Nivel 2 + PV maximo reduzido a metade pelo dia + deslocamento 0" },
		} },
	{ id = "furtivo", nome = "Furtivo/Oculto", nivel = "Media",
		desc = "Escondido de criaturas que nao o veem/ouvem. Ataca com vantagem, mas revela a posicao apos o ataque (acerte ou erre)." },
	{ id = "imovel", nome = "Imovel (parcialmente paralisado)", nivel = "Media",
		desc = "Deslocamento vira 0 (exceto voo). Ainda pode mexer membros/tronco/cabeca, com -2 em ataques." },
	{ id = "queimado", nome = "Queimado/Queimando/Em chamas", nivel = "Media",
		desc = "Dano de fogo direto acima de 15 (ou arma/efeito com esse descritor) queima. Fogo continuo: 1d10 de fogo por turno (ou o dano do efeito, o maior). Apagar exige 1 acao principal ou 2 rodadas pra remover equipamento em chamas." },
	{ id = "surdo", nome = "Surdo", nivel = "Media",
		desc = "Falha em testes de audicao. Desvantagem em iniciativa. Imune a efeitos auditivos de Hatsu." },

	-- ===== FORTES =====
	{ id = "cego", nome = "Cego", nivel = "Forte",
		desc = "Fica Desprevenido e Lento. Falha em testes de visao (exceto com percepcao as cegas). Imune a efeitos visuais de Hatsu.",
		concede = { "desprevenido", "lento" } },
	{ id = "condenado", nome = "Condenado", nivel = "Forte",
		desc = "Consome +5% de aura em TODOS os principios e tecnicas de Nen e Hatsus." },
	{ id = "exposto", nome = "Exposto", nivel = "Forte",
		desc = "Dano recebido soma o valor do nivel do atacante em CADA rolagem de dano." },
	{ id = "fascinado", nome = "Fascinado", nivel = "Forte",
		desc = "Fica Imovel e Mudo. Quem fascina tem vantagem de Presenca pra manipular/influenciar o alvo.",
		concede = { "imovel", "mudo" } },
	{ id = "flanqueado", nome = "Flanqueado", nivel = "Forte",
		desc = "Entre 2 inimigos opostos corpo-a-corpo: da vantagem aos atacantes. 3o inimigo (Cercando): vantagem +1. 4o (Encurralando): vantagem +2." },
	{ id = "fragilizado", nome = "Fragilizado", nivel = "Forte",
		desc = "Incapaz de receber reducao de dano (RD) de qualquer fonte." },
	{ id = "invisivel", nome = "Invisivel", nivel = "Forte",
		desc = "+5 em furtividade. Nao pode ser alvo de habilidades que exigem visao. Ao atacar, o alvo fica Desprevenido (a menos que perceba)." },
	{ id = "manipulado", nome = "Manipulado", nivel = "Forte",
		desc = "Obrigado a obedecer comandos do manipulador. Fica Imune a outras manipulacoes. Nao rola pra sair no fim do turno -- dura o tempo do Hatsu do usuario." },
	{ id = "resistente", nome = "Resistente", nivel = "Forte",
		desc = "Vantagem pra nao sofrer a condicao/efeito, ou sofre so metade do dano especificado." },

	-- ===== EXTREMAS =====
	{ id = "amaldicoado", nome = "Amaldicoado", nivel = "Extrema",
		desc = "Ver secao especifica de maldicoes de Nen (nao detalhado aqui)." },
	{ id = "atordoado", nome = "Atordoado", nivel = "Extrema",
		desc = "Perde todas as acoes do proximo turno e perde concentracao." },
	{ id = "desmembrado", nome = "Desmembrado", nivel = "Extrema",
		desc = "Parte do corpo prejudicada (Descanso Longo remove) ou perdida definitivamente, com perda de funcao mecanica especifica da parte afetada. PENDENTE: tabela detalhada por parte do corpo (maos, pes, torso, cabeca etc.) ainda nao implementada -- fica registrada como condicao generica ate testarmos o impacto em combate." },
	{ id = "imune", nome = "Imune", nivel = "Extrema",
		desc = "Nao pode ser afetado pelo tipo de dano/condicao/efeito descrito. Oposto de Vulneravel." },
	{ id = "incapacitado", nome = "Incapacitado", nivel = "Extrema",
		desc = "Nao pode realizar acoes ou reacoes. Perde a concentracao." },
	{ id = "inconsciente", nome = "Inconsciente", nivel = "Extrema",
		desc = "Fica Incapacitado e Caido. Larga tudo, nao pode falar. Falha automaticamente em TRs. -10 de CA. Todo ataque que acerta e critico.",
		concede = { "incapacitado", "caido" } },
	{ id = "paralisado", nome = "Paralisado (completamente)", nivel = "Extrema",
		desc = "Fica Imovel e Incapacitado (mas MANTEM concentracao). So acoes mentais. -10 de CA. Todo ataque que acerta e critico.",
		concede = { "imovel", "incapacitado" } },
	{ id = "possuido", nome = "Possuido", nivel = "Extrema",
		desc = "Fisicamente incapacitado, controlado pelo possuidor, sem TR pra se livrar. Conexao direta: cada 20 PV perdidos = -1 sanidade no possuidor. Conexao indireta: sem dano ao possuidor. Reversivel com +10% de aura (nao redutivel)." },
	{ id = "selado", nome = "Selado", nivel = "Extrema",
		desc = "Nao pode usar aura. Fica em modo de Zetsu forcado." },
	{ id = "vulneravel", nome = "Vulneravel", nivel = "Extrema",
		desc = "Recebe dano dobrado ou desvantagem sobre o dano/efeito descrito. Oposto de Imune ou Resistente." },

	-- ===== NAO CLASSIFICADA (nao apareceu nas 4 listas de nivel do documento) =====
	{ id = "eletrocutado", nome = "Eletrocutado", nivel = nil,
		desc = "Recebendo dano eletrico; pode compartilhar metade do dano ao tocar/ser tocado por alguem. (Nivel nao especificado no material original.)" },
}

local byId = {}
for _, c in ipairs(ConditionsDB.Condicoes) do
	byId[c.id] = c
end
ConditionsDB.ById = byId

function ConditionsDB.Get(id)
	return byId[id]
end

function ConditionsDB.NivelPorAcesso(nivelEfeito)
	for _, faixa in ipairs(ConditionsDB.NIVEL_POR_ACESSO) do
		if nivelEfeito >= faixa.min and nivelEfeito <= faixa.max then
			return faixa.nivel
		end
	end
	if nivelEfeito and nivelEfeito > 12 then
		return "Extrema"
	end
	return "Fraca"
end

return ConditionsDB
