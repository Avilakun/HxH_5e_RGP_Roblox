--[[
    HxH5e SanitySurgeDB (Shared) — catalogo dos 4 niveis de Surto de
    Sanidade, baseado na tabela exata do Lucas.

    Limiares (% de Sanidade Atual/Maxima):
      <=90% -> Curta Duracao (1d100, efeito dura 1d10 RODADAS)
      <=75% -> Longa Duracao (1d100, efeito dura 1d10 HORAS de jogo)
      <=50% -> Indeterminado Leve (1d8, concede Inclinacao Negativa,
               dura ate a Sanidade voltar a subir acima de 50%)
      <=25% -> Indeterminado Pesado (1d12, dura ate a Sanidade voltar
               a subir acima de 25%)

    "1 rodada" = 6 segundos reais (convencao padrao, documentada --
    o sistema nao tem rodadas formais de combate, entao uso essa
    equivalencia pra converter "1d10 rodadas" em tempo real).
]]

local SanitySurgeDB = {}

SanitySurgeDB.RODADA_SEGUNDOS = 6

-- ================= CURTA DURACAO (1d100, dura 1d10 rodadas) =================
SanitySurgeDB.Curta = {
	{ min = 1, max = 20, tipo = "envenenado", nome = "Come coisas estranhas",
		desc = "Vontade avassaladora de comer terra, limo ou restos. Fica Envenenado." },
	{ min = 21, max = 40, tipo = "amedrontado", nome = "Amedrontado",
		desc = "Fica amedrontado, deve usar a acao pra fugir da fonte do medo a cada rodada." },
	{ min = 41, max = 60, tipo = "balbucia", nome = "Balbucia",
		desc = "Incapaz de falar ou usar Hatsu que dependa de comandos verbais." },
	{ min = 61, max = 80, tipo = "ataca_aliado", nome = "Ataca o mais proximo",
		desc = "Deve usar a acao pra atacar a criatura mais proxima a cada rodada." },
	{ min = 81, max = 100, tipo = "obedece", nome = "Obedece comandos",
		desc = "Faz o que qualquer um mandar, desde que nao seja obviamente suicida." },
}

-- ================= LONGA DURACAO (1d100, dura 1d10 horas de jogo) =================
SanitySurgeDB.Longa = {
	{ min = 1, max = 20, tipo = "compulsao", nome = "Compulsao",
		desc = "Precisa repetir uma atividade irrelevante ao combate a cada 3 rodadas (custa a acao principal), ou perde 1 de Sanidade." },
	{ min = 21, max = 40, tipo = "talisma", nome = "Talisma da sorte",
		desc = "Fica ligado a alguem como talisma -- desvantagem em ataques, pericias e TRs a mais de 1,5m dessa pessoa." },
	{ min = 41, max = 55, tipo = "alucinacao", nome = "Alucinacao poderosa",
		desc = "Se ve sofrendo (ou apaixonado, etc.) no contexto da cena, desligado do que acontece ao redor." },
	{ min = 56, max = 70, tipo = "balbucia", nome = "Balbucia",
		desc = "Incapaz de falar ou usar Hatsu que dependa de comandos verbais." },
	{ min = 71, max = 86, tipo = "tremores", nome = "Tremores e tiques",
		desc = "Desvantagem em todas as jogadas de FOR ou DES." },
	{ min = 87, max = 100, tipo = "amnesia", nome = "Amnesia parcial",
		desc = "Desconfia e nao reconhece ninguem alem de si mesmo e suas proprias habilidades/equipamentos." },
}

-- ================= INDETERMINADO LEVE (1d8, concede Inclinacao Negativa) =================
SanitySurgeDB.Leve = {
	{ min = 1, max = 1, inclinacao = "Avareza" },
	{ min = 2, max = 2, inclinacao = "Cleptomania" },
	{ min = 3, max = 3, inclinacao = "Desvio de Atenção" },
	{ min = 4, max = 4, inclinacao = "Megalomania" },
	{ min = 5, max = 5, inclinacao = "Mente de Criança" },
	{ min = 6, max = 6, inclinacao = "Paranoia" },
	{ min = 7, max = 7, inclinacao = "Pesadelos" },
	{ min = 8, max = 8, inclinacao = "Visões de Morte" },
}

-- ================= INDETERMINADO PESADO (1d12) =================
SanitySurgeDB.Pesado = {
	{ min = 1, max = 1, inclinacao = "Covardia" },
	{ min = 2, max = 2, inclinacao = "Dupla Personalidade" },
	{ min = 3, max = 3, inclinacao = "Impulsividade" },
	{ min = 4, max = 4, inclinacao = "Instinto Assassino" },
	{ min = 5, max = 5, tipo = "ataca_aliado", nome = "Nao reconhece aliados",
		desc = "Nao reconhece nenhum aliado (todos viram inimigos) OU reconhece o inimigo como melhor amigo." },
	{ min = 6, max = 6, tipo = "narrativo", nome = "Pavor",
		desc = "Arranca os cabelos gritando de horror (Fascinado)." },
	{ min = 7, max = 7, tipo = "narrativo", nome = "Automutilacao ocular",
		desc = "Machuca os olhos tentando arranca-los enquanto grita (Ataque mirado)." },
	{ min = 8, max = 8, tipo = "narrativo", nome = "Estrangulamento",
		desc = "Tenta estrangular um aliado ou a si mesmo (se lutando sozinho)." },
	{ min = 9, max = 9, tipo = "bloqueia_nen", nome = "Esquecimento da identidade",
		desc = "Esquece a propria identidade, perdendo o Hatsu ate retomar a memoria ou a sanidade." },
	{ min = 10, max = 10, tipo = "narrativo", nome = "Atitude suicida",
		desc = "Tenta se matar ou se jogar no perigo que causou a insanidade." },
	{ min = 11, max = 11, tipo = "narrativo", nome = "Sugestionavel",
		desc = "Sem acao propria e totalmente sugestionavel, faz o que os outros mandam." },
	{ min = 12, max = 12, tipo = "dano_conta_sanidade", nome = "Fragilidade mental",
		desc = "Sempre que sofrer dano, TR de Sabedoria CD 15 ou o dano tambem reduz a Sanidade." },
}

return SanitySurgeDB
