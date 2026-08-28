--[[
    HxH5e HatsuService v5 (Reforço + Gerais)
    - Restrições de categoria (Reforço) marcadas com campo "categoria"
    - Fórmula de TR: 8 + piso(nível/2, mín 1) + mod. atributo + bônus de efeitos + bônus de restrições
    - Consumo de aura na ativação (base 50%)
    - EditHatsu: editar nome/efeitos/restrições (recalcula custo e reembolsa a diferença)
]]

local HatsuService = {}

--------------------------------------------------
-- EFICIÊNCIA DE CATEGORIA
--------------------------------------------------
local CATEGORY_EFFICIENCY = {
	[100] = 1.0,
	[80]  = 1.25,
	[60]  = 1.67,
	[40]  = 2.5,
}

--------------------------------------------------
-- P.N PURO POR PESO
--------------------------------------------------
local PURE_PN = {
	Leve = 1,
	Media = 2,
	Pesada = 3,
	Variavel = 0,
	Extrema = 4,
}

--------------------------------------------------
-- EFEITOS GERAIS
--------------------------------------------------
local GERAIS_EFFECTS = {
	{ id = "geral_aumento_alcance", nome = "Aumento de Alcance", grupo = "Gerais", nivel = 1, custo = 1, desc = "Aumenta o alcance do Hatsu em +1,5 metros (Máximo: 3 usos)." },
	{ id = "geral_aumento_duracao", nome = "Aumento de Duração", grupo = "Gerais", nivel = 1, custo = 1, desc = "Permite que o Hatsu dure 1 rodada extra por escolha." },
	{ id = "geral_condicao_perigosa", nome = "Condição Perigosa", grupo = "Gerais", nivel = 1, custo = 1, desc = "Permite ao Hatsu aplicar 1 condição por 1 rodada (mín.)." },
	{ id = "geral_efeito_alternativo", nome = "Efeito Alternativo", grupo = "Gerais", nivel = 1, custo = 1, desc = "Permite aplicar a compra dos efeitos em diferentes 'modos' de uso do Hatsu." },
	{ id = "geral_esforco_sacrificial", nome = "Esforço Sacrificial (Memória Esgotada)", grupo = "Gerais", nivel = 1, custo = 1, desc = "Permite ao Hatsu acessar graus de potência de outra categoria. Cada grau consome 15% de aura ou 5 de sanidade." },
	{ id = "geral_poder_intencao", nome = "Poder é Intenção", grupo = "Gerais", nivel = 1, custo = 1, desc = "O efeito é adicionado no Hatsu, mas aplicado em outro alvo." },
	{ id = "geral_poder_valioso", nome = "Poder Valioso", grupo = "Gerais", nivel = 1, custo = 2, desc = "+1 Grau de potência sobre um efeito comprado do Hatsu." },
	{ id = "geral_reducao_custo", nome = "Redução de Custo", grupo = "Gerais", nivel = 1, custo = 1, desc = "Reduza 5% do custo do Hatsu. -10% ao ter 2+ Restrições Pesadas (1x). -25% ao ter uma Restrição Extrema." },
	{ id = "geral_dano_cura_focal", nome = "Dano/Cura Focal", grupo = "Gerais", nivel = 1, custo = 1, desc = "Aumenta o dano/cura básico do Hatsu em 1 grau/passo. Torna o Hatsu Hostil ou de Suporte (2d6+FOR ou CON iniciais)." },
	{ id = "geral_ajuste_forma", nome = "Ajuste de Forma (Área)", grupo = "Gerais", nivel = 2, custo = 1, desc = "Aplica uma área de 1,5m ao efeito do Hatsu (cone, linha ou esfera). Máximo: 3 usos." },
	{ id = "geral_flagelo_mente", nome = "Flagelo da Mente", grupo = "Gerais", nivel = 2, custo = 1, desc = "O Hatsu causa dano psíquico (reduz a sanidade). Começa com 1d10+Atributo." },
	{ id = "geral_ativacao_rapida", nome = "Ativação Rápida", grupo = "Gerais", nivel = 3, custo = 2, desc = "Permite usar o Hatsu como Ação Bônus em vez de Ação Principal." },
	{ id = "geral_efeito_cuidadoso", nome = "Efeito Cuidadoso", grupo = "Gerais", nivel = 3, custo = 2, desc = "Um Hatsu que funcione em área pode agora selecionar os alvos." },
	{ id = "geral_reacao_defensiva", nome = "Reação Defensiva", grupo = "Gerais", nivel = 3, custo = 2, desc = "Permite usar o Hatsu como reação para se defender ou proteger um aliado. (Sabedoria 3+)" },
	{ id = "geral_reacao_ofensiva", nome = "Reação Ofensiva", grupo = "Gerais", nivel = 3, custo = 2, desc = "Permite usar o Hatsu como reação ao ser atacado. (Sabedoria 4+)" },
	{ id = "geral_exercito_homem", nome = "Exército de um homem só", grupo = "Gerais", nivel = 5, custo = 3, desc = "Permite alternar efeitos entre alvos marcados ou dividir dano/cura. (Requer Emissão ou Manipulação)" },
	{ id = "geral_dor_disgrama", nome = "Dor pra disgrama!", grupo = "Gerais", nivel = 5, custo = 3, desc = "O último dano/cura se torna Contínuo (repetindo a cada rodada). (Duração > 3 rodadas)" },
	{ id = "geral_experiencia_comprovada", nome = "Experiência Comprovada", grupo = "Gerais", nivel = 6, custo = 3, desc = "Permite evoluir a duração de minutos -> horas -> dias -> semanas -> meses -> anos." },
	{ id = "geral_aura_tatica", nome = "Aura tática", grupo = "Gerais", nivel = 6, custo = 3, desc = "Permite imbuir e aplicar EN ou GYO no Hatsu." },
	{ id = "geral_visao_seletiva", nome = "Visão Seletiva", grupo = "Gerais", nivel = 7, custo = 4, desc = "Adiciona passivamente a propriedade Furtiva ao Hatsu." },
}

--------------------------------------------------
-- EFEITOS DE REFORÇO
--------------------------------------------------
local REFORCO_EFFECTS = {
	{ id = "aumento_atributo", nome = "Aumento de Atributo", grupo = "Reforço", nivel = 1, custo = 1, desc = "Aumenta o valor de atributo em 2 (mod. +1) (Máximo: bônus +5)." },
	{ id = "intensificacao", nome = "Intensificação", grupo = "Reforço", nivel = 1, custo = 1, desc = "+1 Grau de Potência no Hatsu." },
	{ id = "recuperacao_veloz", nome = "Recuperação Veloz", grupo = "Reforço", nivel = 1, custo = 1, desc = "Cura 1d8 + CON." },
	{ id = "mais_de_8000", nome = "Mais de 8000", grupo = "Reforço", nivel = 1, custo = 1, desc = "Sua aura pode ser dada a outras pessoas (5% por escolha). A aura dada se perde e só é recuperada com Zetsu." },
	{ id = "estabilizar_aliado", nome = "Estabilizar Aliado", grupo = "Reforço", nivel = 2, custo = 1, desc = "Impede morte de aliado adjacente, mantendo-o em 1 PV ao consumir uma Reação." },
	{ id = "impacto_pesado", nome = "Impacto Pesado", grupo = "Reforço", nivel = 2, custo = 1, desc = "Provoca um TR de FOR e empurra em 3m o(s) alvo(s) que falhe(m), independente do dano.", trBonus = 0 },
	{ id = "pele_de_pedra", nome = "Pele de Pedra", grupo = "Reforço", nivel = 2, custo = 1, desc = "Aplica 3 de Redução de Dano (RD) contra danos de Impacto, Perfurante e Cortantes." },
	{ id = "postura_de_ferro", nome = "Postura de Ferro", grupo = "Reforço", nivel = 2, custo = 1, desc = "Imune a ser empurrado ou derrubado." },
	{ id = "aura_afiada", nome = "Aura Afiada", grupo = "Reforço", nivel = 3, custo = 2, desc = "Reduz a margem de acerto crítico em 1 (máx. 2 usos)." },
	{ id = "explosao_de_aura", nome = "Explosão de Aura", grupo = "Reforço", nivel = 3, custo = 2, desc = "Causa dano em área de pelo menos 1,5m ao seu redor." },
	{ id = "golpe_reforcado", nome = "Golpe Reforçado", grupo = "Reforço", nivel = 3, custo = 2, desc = "Permite adicionar 1d8 extra ao dano do Hatsu." },
	{ id = "penetracao_dolorosa", nome = "Penetração Dolorosa", grupo = "Reforço", nivel = 3, custo = 2, desc = "Causa +5 de dano perfurante e impõe Desvantagem na próxima jogada de resistência física do alvo." },
	{ id = "onda_surda", nome = "Onda Surda", grupo = "Reforço", nivel = 4, custo = 2, desc = "Seus golpes ignoram parte da defesa física ou defesa com aura." },
	{ id = "socos_chutes", nome = "Socos e Chutes", grupo = "Reforço", nivel = 4, custo = 2, desc = "Golpes desarmados aplicam Perfurante ou Condição Atordoado ao tirar 18+ no acerto." },
	{ id = "concentracao_total", nome = "Concentração Total", grupo = "Reforço", nivel = 4, custo = 2, desc = "Permite +1 rodada por acerto ininterrupto ou +1 Grau/Passo de dano. (Sabedoria 3+)" },
	{ id = "barreira_interna", nome = "Barreira Interna", grupo = "Reforço", nivel = 5, custo = 3, desc = "Aplica 5 de RD contra danos de Energia e Elementais (+2 a cada nova escolha)." },
	{ id = "cerebro_evoluido", nome = "Cérebro Evoluído", grupo = "Reforço", nivel = 5, custo = 3, desc = "Durante o uso, faz uso dos efeitos de um dos atributos evoluídos entre INT, SAB ou PRE." },
	{ id = "estabilizacao_aura", nome = "Estabilização de Aura", grupo = "Reforço", nivel = 5, custo = 3, desc = "Diminui o custo de aura do Hatsu em 15% (mínimo = 10%)." },
	{ id = "soco_demolidor", nome = "Soco Demolidor", grupo = "Reforço", nivel = 5, custo = 3, desc = "Gasta 10% de aura para ter vantagem no próximo ataque e ignorar resistências físicas." },
	{ id = "furia_potencializada", nome = "Fúria Potencializada", grupo = "Reforço", nivel = 6, custo = 3, desc = "Ataques causam +1d6 de dano." },
	{ id = "folego_infinito", nome = "Fôlego Infinito", grupo = "Reforço", nivel = 6, custo = 3, desc = "Imunidade à condição de Exaustão até o fim do combate." },
	{ id = "equiparacao", nome = "Equiparação", grupo = "Reforço", nivel = 7, custo = 4, desc = "Permite equiparar um atributo escolhido ao de um alvo engajado em combate. (INT ou SAB 3+ ou 3 restrições pesadas)" },
	{ id = "vigor_continuo", nome = "Vigor Contínuo", grupo = "Reforço", nivel = 7, custo = 4, desc = "Reduz um grau de Exaustão em combate e adiciona 2 Reações." },
	{ id = "carga_energia", nome = "Carga de Energia", grupo = "Reforço", nivel = 8, custo = 4, desc = "Armazena energia e dobra o dano do próximo ataque (1x por combate)." },
	{ id = "corpo_de_aco", nome = "Corpo de Aço", grupo = "Reforço", nivel = 8, custo = 4, desc = "Aplica 10 de RD contra um tipo de dano entre: Explosivo, Balístico ou Mortal." },
	{ id = "vitalidade_extra", nome = "Vitalidade Extra", grupo = "Reforço", nivel = 8, custo = 4, desc = "Recupera 1d6 + CON PV ao cair abaixo de 50% da vida (1x por combate)." },
	{ id = "forca_titanica", nome = "Força Titânica", grupo = "Reforço", nivel = 9, custo = 5, desc = "Seus ataques físicos recebem +5 de dano." },
	{ id = "trabalho_equipe", nome = "Trabalho em Equipe ou Simbiose", grupo = "Reforço", nivel = 9, custo = 5, desc = "Utiliza aura de aliados (10%) para ampliar dano/cura ou reduzir TRs e danos de inimigos em 1 grau de potência." },
	{ id = "dano_fragilizante", nome = "Dano Fragilizante", grupo = "Reforço", nivel = 10, custo = 5, desc = "Dano superior a 20 pode reduzir durabilidade de armadura, aplicar -2 nos ataques ou -2 em reações defensivas." },
	{ id = "potencial_liberado", nome = "Potencial Liberado", grupo = "Reforço", nivel = 10, custo = 5, desc = "Escolha uma vez por uso qualquer efeito da tabela de Potencial Liberado." },
	{ id = "forca_descomunal", nome = "Força Descomunal", grupo = "Reforço", nivel = 12, custo = 6, desc = "Ao gastar 15% de aura, dobra sua Força (bônus) para Testes ou Ataques." },
	{ id = "resiliencia_suprema", nome = "Resiliência Suprema", grupo = "Reforço", nivel = 12, custo = 6, desc = "1x por dia, quando cairia a 0 PV, recupera imediatamente 30% da vida máxima." },
}

local ALL_EFFECTS = {}
for _, e in ipairs(GERAIS_EFFECTS) do table.insert(ALL_EFFECTS, e) end
for _, e in ipairs(REFORCO_EFFECTS) do table.insert(ALL_EFFECTS, e) end

--------------------------------------------------
-- RESTRIÇÕES (gerais + categoria Reforço)
-- Campo "categoria" marca as de categoria; "trBonus" soma na fórmula de TR
--------------------------------------------------
local RESTRICTIONS = {
	-- ===== LEVES =====
	{ id = "leve_calculo_pensado1", nome = "Cálculo Pensado Básico 1", peso = "Leve", pura = PURE_PN.Leve, descricao = "Gasta +10% de aura.", beneficios = { "+1(-1) em Jogadas de Acerto", "+1 Grau/Passo de Dano/Cura" } },
	{ id = "leve_calculo_pensado2", nome = "Cálculo Pensado Básico 2", peso = "Leve", pura = PURE_PN.Leve, descricao = "Reduz 2 Grau/Passos de dano.", beneficios = { "Reduz em 5% o custo de aura do Hatsu" } },
	{ id = "leve_calculo_pensado3", nome = "Cálculo Pensado Básico 3", peso = "Leve", pura = PURE_PN.Leve, descricao = "-1 Grau de Potência.", beneficios = { "+1(-1) em Teste de Concentração" } },
	{ id = "leve_condicao_levemente_hostil", nome = "Condição Levemente Hostil", peso = "Leve", pura = PURE_PN.Leve, descricao = "Só pode ativar ou manter caso alguém inicie um conflito com o alvo (contra aliados).", beneficios = { "+1 em Acerto ou dano contra o Alvo", "-1 em Acerto ou dano do Alvo" } },
	{ id = "leve_conhecimento_alvo", nome = "Conhecimento do Alvo", peso = "Leve", pura = PURE_PN.Leve, descricao = "Saber nome ou histórico (contado pelo alvo) ou ter interação prévia (mínimo 1min.).", beneficios = { "+1(-1) na CD do TR" }, trBonus = 1 },
	{ id = "leve_calibragem", nome = "Calibragem", peso = "Leve", pura = PURE_PN.Leve, descricao = "Impõe um Teste ou TR próprio para ativar o Hatsu.", beneficios = { "+1(-1) em Testes e TRs Realizados" } },
	{ id = "leve_dano_antes_usar", nome = "Dano Antes de Usar", peso = "Leve", pura = PURE_PN.Leve, descricao = "Deve sofrer 15% de dano em Vida ou Sanidade para ativar.", beneficios = { "+1(-1) em Testes de Concentração (TR de CON)" } },
	{ id = "leve_dialogo", nome = "Diálogo", peso = "Leve", pura = PURE_PN.Leve, descricao = "A ativação e a duração dependem de uma Arma Específica em posse constante.", beneficios = { "+1 Grau/Passo de Dano com esta arma no Hatsu" } },
	{ id = "leve_efeitos_neg_pre1", nome = "Efeitos Negativos Pré-Ativação 1", peso = "Leve", pura = PURE_PN.Leve, descricao = "Receber condições leves/fracas.", beneficios = { "Após falhar no TR, a condição funciona uma rodada sem testes para se libertar" } },
	{ id = "leve_efeitos_neg_exaustao1", nome = "Efeitos Negativos Exaustão 1", peso = "Leve", pura = PURE_PN.Leve, descricao = "Receber 1 nível de exaustão após, durante ou antes da ativação.", beneficios = { "+1(-1) Grau/Passo no Alcance", "+1(-1) Grau/Passo na Área" } },
	{ id = "leve_golpe_toque", nome = "Golpe/Toque", peso = "Leve", pura = PURE_PN.Leve, descricao = "O Hatsu depende de acertar/receber um golpe físico (ou toque hostil) do alvo para ativar.", beneficios = { "+1(-1) na CD do TR" }, trBonus = 1 },
	{ id = "leve_interacao_sensorial", nome = "Interação Sensorial Simples", peso = "Leve", pura = PURE_PN.Leve, descricao = "Ver, ouvir, tocar o alvo (não hostil) ou ser visto, ouvido, tocado. Máx. últimos 30 segundos (5 rodadas).", beneficios = { "Aplica 3m no Alcance", "Aplica 1,5m na Área" } },
	{ id = "leve_limitacao_alvos", nome = "Limitação de Alvos", peso = "Leve", pura = PURE_PN.Leve, descricao = "Limitar alvos entre 3–5 com Hatsus contínuos ou de Alcance/Área superior a 6m.", beneficios = { "+1 Grau/passo de dano/cura", "Aplica +1 condição" } },
	{ id = "leve_limitacao_mov1", nome = "Limitação de Movimento 1", peso = "Leve", pura = PURE_PN.Leve, descricao = "Cumprir ação livre e não se mover no turno.", beneficios = { "+1(-1) em Jogadas de Acerto" } },
	{ id = "leve_limitacao_mov2", nome = "Limitação de Movimento 2", peso = "Leve", pura = PURE_PN.Leve, descricao = "Consome movimento + Teste de Aptidão (perícia).", beneficios = { "+1(-1) em Jogadas de Acerto", "+1(-1) na CD do TR" }, trBonus = 1 },
	{ id = "leve_maos_livres", nome = "Mãos Livres", peso = "Leve", pura = PURE_PN.Leve, descricao = "O usuário não pode estar segurando ou portando nada em suas mãos.", beneficios = { "+1(-1) em Jogadas de Acerto", "Reações Defensivas" } },
	{ id = "leve_objeto_canalizador", nome = "Objeto Canalizador", peso = "Leve", pura = PURE_PN.Leve, descricao = "Só ativa ou se mantém com objeto específico em posse.", beneficios = { "Objeto recebe +2 CA", "Objeto recebe +5 PV" } },
	{ id = "leve_posicao_corporal", nome = "Posição Corporal", peso = "Leve", pura = PURE_PN.Leve, descricao = "Manter pose específica (ex.: mãos juntas) para ativar ou durante o uso.", beneficios = { "+1(-1) em Testes de Resistência para manter o efeito" } },
	{ id = "leve_tempo_carregamento", nome = "Tempo de Carregamento", peso = "Leve", pura = PURE_PN.Leve, descricao = "Ativa 1 rodada após declaração de ativação.", beneficios = { "+1 Grau/passo de dano/cura", "+1 em Testes de Concentração (TR de CON)" } },

	-- ===== MODERADAS =====
	{ id = "mod_alvo_unico", nome = "Alvo Único em combate", peso = "Media", pura = PURE_PN.Media, descricao = "Só pode usar o Hatsu em um único alvo escolhido (até vencê-lo) ou acabar o combate.", beneficios = { "+2(-2) Grau/Passo de Dano/Cura" } },
	{ id = "mod_area_definida", nome = "Área Definida", peso = "Media", pura = PURE_PN.Media, descricao = "Hatsu só funciona em 1/3 ou menos da área ou alcance total.", beneficios = { "Reduz custo de ativação em 10%", "Anula manutenção" } },
	{ id = "mod_chuck_norris", nome = "Chuck Norris", peso = "Media", pura = PURE_PN.Media, descricao = "Não pode utilizar armas de fogo ou comuns dentro ou fora do Hatsu.", beneficios = { "Dano em Golpes Desarmados recebe a propriedade de Mortal x4" } },
	{ id = "mod_conhecimento_profundo", nome = "Conhecimento Profundo", peso = "Media", pura = PURE_PN.Media, descricao = "Entender o funcionamento e funções de um objeto, criatura ou mecanismo usado no Hatsu.", beneficios = { "Habilita Materialização com Alterações Físicas de Funções" } },
	{ id = "mod_conhecimento_profundo_alvo", nome = "Conhecimento Profundo do Alvo", peso = "Media", pura = PURE_PN.Media, descricao = "Entender/descobrir o funcionamento do Hatsu do alvo.", beneficios = { "Ignora Resistências Físicas", "+2 na CD do TR" }, trBonus = 2 },
	{ id = "mod_perda_membros_temp", nome = "Perda de Membros (Temporário)", peso = "Media", pura = PURE_PN.Media, descricao = "Perder/inutilizar temporariamente (Descanso Longo) um membro(s) do usuário.", beneficios = { "A cada Acerto ou TR imposto com sucesso, recupera 10% da aura gasta no hatsu" } },
	{ id = "mod_efeitos_neg_pre2", nome = "Efeitos Negativos Pré-Ativação 2", peso = "Media", pura = PURE_PN.Media, descricao = "Estar amedrontado, imóvel, ou outra condição média (enquanto consciente).", beneficios = { "Pode refazer 2 rolagens de ataque ou defesa enquanto o Hatsu estiver ativo" } },
	{ id = "mod_efeitos_neg_exaustao2", nome = "Efeitos Negativos Exaustão 2", peso = "Media", pura = PURE_PN.Media, descricao = "Receber 2 níveis de exaustão durante ou antes da ativação.", beneficios = { "Pode escolher 1 Efeito novo (fixo) de até 2 níveis acima" } },
	{ id = "mod_explicar_hatsu", nome = "Explicar o Hatsu", peso = "Media", pura = PURE_PN.Media, descricao = "Requer explicar o funcionamento do Hatsu e seus efeitos e restrições antes da ativação (dura 1 turno).", beneficios = { "Após atingir um alvo ou o alvo falhar em um TR, aplica Condição Média coerente" } },
	{ id = "mod_principio_elementar", nome = "Princípio Elementar", peso = "Media", pura = PURE_PN.Media, descricao = "O Hatsu depende de um Princípio de nen para funcionamento.", beneficios = { "O princípio dura por +2 Rodadas" } },
	{ id = "mod_limite_emocional", nome = "Limite Emocional", peso = "Media", pura = PURE_PN.Media, descricao = "Só ativa com emoção intensa (falhando em um TR de SAB contra raiva, medo, etc.).", beneficios = { "+2(-2) em Jogadas de Acerto" } },
	{ id = "mod_produto_fragil", nome = "Produto Frágil", peso = "Media", pura = PURE_PN.Media, descricao = "O personagem é vulnerável a 3 tipos de dano (mesmo fora do Hatsu).", beneficios = { "Torna o usuário e alvos do Hatsu resistentes a um tipo de dano" } },
	{ id = "mod_tempo_marcado", nome = "Tempo Marcado", peso = "Media", pura = PURE_PN.Media, descricao = "Só pode ser ativado após 4 rodadas em combate ou iniciativa marcada.", beneficios = { "Dobra o alcance do Hatsu", "Dobra a duração do Hatsu" } },
	{ id = "mod_zetsu_protetivo", nome = "Zetsu protetivo", peso = "Media", pura = PURE_PN.Media, descricao = "O(s) alvo(s) utilizar(em) Zetsu interrompe ou anula o efeito do Hatsu.", beneficios = { "+2 Grau/Passo em Rodadas", "+2 Grau/Passo em Acerto", "+2 Grau/Passo em Dano" } },

	-- ===== PESADAS =====
	{ id = "pes_alto_risco", nome = "Alto Risco...", peso = "Pesada", pura = PURE_PN.Pesada, descricao = "Ter perdido 50% (não auto-imposto) do PV para ativar o Hatsu.", beneficios = { "Adicione 3 Graus de Potência em qualquer característica da Categoria no Hatsu" } },
	{ id = "pes_boneca_russa", nome = "Boneca Russa", peso = "Pesada", pura = PURE_PN.Pesada, descricao = "O Hatsu depende de outro Hatsu para sua ativação ou é requerido para ativação de outro.", beneficios = { "+3 rodadas de duração (se a ativação não ocorrer, 30% de aura é consumida)" } },
	{ id = "pes_dano_permanente", nome = "Dano Permanente", peso = "Pesada", pura = PURE_PN.Pesada, descricao = "Perder 1d10 de vida/sanidade permanentemente.", beneficios = { "Adicione 3 Graus de Potência em qualquer característica da Categoria no Hatsu" } },
	{ id = "pes_efeitos_aleatorios", nome = "Efeitos Aleatórios", peso = "Pesada", pura = PURE_PN.Pesada, descricao = "Efeitos comprados e pré-definidos, mas não escolhidos na ativação (aleatória).", beneficios = { "Margem de Crítico reduz em 1 (mín. 18)", "Adicione 3 Graus de Potência em qualquer característica da Categoria" } },
	{ id = "pes_limite_eficiencia_aura", nome = "Limite de Eficiência de Aura", peso = "Pesada", pura = PURE_PN.Pesada, descricao = "Não aplica eficiência de aura em princípios e Técnicas de Nen.", beneficios = { "Hatsu ignora efeitos defensivos de nen com RD ou CA" } },
	{ id = "pes_limite_principios", nome = "Limite de Princípios de Nen", peso = "Pesada", pura = PURE_PN.Pesada, descricao = "Não pode usar os princípios e técnicas de Nen na Maestria ou modo Superior.", beneficios = { "+3 ou -3 na CD de TRs Impostos ou Enfrentados" }, trBonus = 3 },
	{ id = "pes_limite_uso_definitivo", nome = "Limite de Uso Definitivo", peso = "Pesada", pura = PURE_PN.Pesada, descricao = "Só pode ser usado 1x por combate.", beneficios = { "+2 Rodadas", "-15% de aura" } },
	{ id = "pes_local_condicao", nome = "Local / Condição Específica", peso = "Pesada", pura = PURE_PN.Pesada, descricao = "Hatsu só funciona em local ou condição específica não descrita em outras restrições.", beneficios = { "Aura usada é reduzida pela metade (mínimo 5%)" } },
	{ id = "pes_proibicao_permanente", nome = "Proibição Permanente", peso = "Pesada", pura = PURE_PN.Pesada, descricao = "Após a duração, não pode usá-lo novamente no combate/dia.", beneficios = { "Rolar um crítico durante o uso permite utilizá-lo sem custo de aura" } },
	{ id = "pes_segredo_mortal", nome = "Segredo Mortal", peso = "Pesada", pura = PURE_PN.Pesada, descricao = "Se descoberto, visto ou percebido, o Hatsu se torna inutilizável contra o alvo.", beneficios = { "Enquanto secreto, Jogadas de acerto e Concentração funcionam com vantagem" } },
	{ id = "pes_tecnica_elementar", nome = "Técnica Elementar", peso = "Pesada", pura = PURE_PN.Pesada, descricao = "O Hatsu depende de uma Técnica de nen para funcionamento.", beneficios = { "A técnica custa metade da aura" } },

	-- ===== VARIÁVEIS =====
	{ id = "var_calculo_pensado1", nome = "Cálculo Pensado Variável 1", peso = "Variavel", pura = 0, descricao = "Gasta +x% de aura.", beneficios = { "+1(-1) em Jogadas de Acerto para cada 10% gasto", "+1 Grau/Passo de Dano/Cura para cada 10% gasto" } },
	{ id = "var_calculo_pensado2", nome = "Cálculo Pensado Variável 2", peso = "Variavel", pura = 0, descricao = "Reduz x Grau/Passos de dano/cura.", beneficios = { "Reduz em 5% o custo de aura para cada 2 Graus/Passos reduzidos" } },
	{ id = "var_calculo_pensado3", nome = "Cálculo Pensado Variável 3", peso = "Variavel", pura = 0, descricao = "-x Grau de Potência.", beneficios = { "+1(-1) em Teste de Concentração para cada Grau de Potência removido" } },
	{ id = "var_canalizar_zetsu", nome = "Canalizar rodadas em Zetsu", peso = "Variavel", pura = 0, descricao = "Ficar X rodadas em Zetsu (em combate) antes de ativar.", beneficios = { "+x Grau de Potência (variável por uso)" } },
	{ id = "var_canalizar_concentracao", nome = "Canalizar com Concentração", peso = "Variavel", pura = 0, descricao = "Canalizar por x rodadas sem ser interrompido (em combate).", beneficios = { "Adiciona +x Rodadas na Duração", "+x(-x) Grau/Passo de Dano/Cura" } },
	{ id = "var_confirmacao_duas_etapas", nome = "Confirmação de duas etapas", peso = "Variavel", pura = 0, descricao = "Impõe um Teste ou TR próprio a cada rodada pela duração do Hatsu.", beneficios = { "Aumenta a duração em 1 rodada por sucesso" } },
	{ id = "var_contrato_simples", nome = "Contrato Simples", peso = "Variavel", pura = 0, descricao = "Acordo verbal ou escrito que liga os participantes ao custo de ficarem em Zetsu ao descumprirem.", beneficios = { "O tempo em zetsu depende do acordo. Não pode ser forçada a outros diretamente" } },
	{ id = "var_dano_momentaneo", nome = "Dano Momentâneo Variável", peso = "Variavel", pura = 0, descricao = "Perder 1d10 de vida/sanidade máxima temporariamente: a) para ativar ou b) por rodadas.", beneficios = { "Causa o valor correspondente em dano: a) em um Ataque; b) a cada ataque" } },
	{ id = "var_efeito_rebote", nome = "Efeito Rebote", peso = "Variavel", pura = 0, descricao = "Usuário sofre até 3 efeitos ou condições do Hatsu.", beneficios = { "Por até 3 rodadas, alvos rolam com desvantagem para superar seus TRs" } },
	{ id = "var_exposicao_desnecessaria", nome = "Exposição Desnecessária", peso = "Variavel", pura = 0, descricao = "Os alvos recebem +x (máx. = nível/2) em 2 características contra o usuário.", beneficios = { "O usuário adiciona +x Grau de Potência no Hatsu (máx. = nível/2)" } },
	{ id = "var_limite_uso_continuo", nome = "Limite de Uso Contínuo", peso = "Variavel", pura = 0, descricao = "O Hatsu só pode ser usado X vezes (até 4) pela duração, ou repetir uma restrição a cada X rodadas.", beneficios = { "X=1 -> 4 P.N", "X=2 -> 3 P.N", "X=3 -> 2 P.N", "X=4 -> 1 P.N" } },
	{ id = "var_sorte_reves", nome = "Sorte ou Revés", peso = "Variavel", pura = 0, descricao = "Ao receber uma falha crítica role 1d4 (1: Hatsu desativado; 2: +25% de aura; 3: dano crítico; 4: -30 de Sanidade).", beneficios = { "Ao receber um sucesso crítico role 1d4 (1: uso/alvo extra; 2: +25% de aura; 3: princípio por 2 rodadas; 4: -5 de sanidade do alvo)" } },
	{ id = "var_troca_perigosa", nome = "Troca Perigosa (Reações)", peso = "Variavel", pura = 0, descricao = "O Hatsu consome suas reações como Recurso para ativação, além de aura.", beneficios = { "Custo de aura reduzido ou aumentado em 5% por reação", "+1 Alvo por 2 reações" } },
	{ id = "var_zetsu_penalizante", nome = "Zetsu Penalizante", peso = "Variavel", pura = 0, descricao = "Após a duração, fica em Zetsu por horas correspondentes à duração ou até o fim da batalha contra mais de um alvo.", beneficios = { "Reduz em x os resultados de TR dos alvos" } },
	{ id = "var_zetsu_por_falha", nome = "Zetsu por falha", peso = "Variavel", pura = 0, descricao = "Impõe Zetsu no usuário caso o Hatsu não seja concluído com sucesso.", beneficios = { "Grau/Passo em Alcance ou Área adicionados = Rodadas em Zetsu após a falha" } },

	-- ===== EXTREMAS =====
	{ id = "ext_condicao_alheia", nome = "Condição Alheia ou Simbiótica", peso = "Extrema", pura = PURE_PN.Extrema, descricao = "O Hatsu só pode ser ativado, desativado ou mantido utilizando aura de um aliado.", beneficios = { "+4 Rodadas por membro da condição", "-10% de custo por membro" } },
	{ id = "ext_condicao_hostil", nome = "Condição Hostil", peso = "Extrema", pura = PURE_PN.Extrema, descricao = "Só pode ser ativado se um aliado morrer ou sofrer dano pré-letal.", beneficios = { "Os dados de dano são maximizados e a área de efeito é dobrada" } },
	{ id = "ext_condicao_unica", nome = "Condição Única de Ativação", peso = "Extrema", pura = PURE_PN.Extrema, descricao = "Só pode ser usado uma única vez em toda a vida do usuário.", beneficios = { "Permite uma Reencarnação ou Ressuscitação. Após isso, se perde o Hatsu" } },
	{ id = "ext_dano_permanente_constante", nome = "Dano Permanente Constante", peso = "Extrema", pura = PURE_PN.Extrema, descricao = "Perder 5 de vida/sanidade (por ativação) permanentemente.", beneficios = { "+4 em Testes de Concentração (TR de CON)", "+4 Rodadas" } },
	{ id = "ext_juramento_imutavel", nome = "Juramento Imutável", peso = "Extrema", pura = PURE_PN.Extrema, descricao = "Voto limitador, público, inviolável e absoluto sobre seu foco de caça. A quebra causa morte instantânea.", beneficios = { "+4 Graus de potência em todas as características possíveis de sua categoria" } },
	{ id = "ext_kamikaze", nome = "Kamikaze", peso = "Extrema", pura = PURE_PN.Extrema, descricao = "Rolar Acertos com Desvantagem e TRs provocados rolados com vantagem pelo alvo.", beneficios = { "Ignore pré-requisitos de efeitos (exceto requisitos de níveis)" } },
	{ id = "ext_perda_membros", nome = "Perda de Membros", peso = "Extrema", pura = PURE_PN.Extrema, descricao = "Perder/inutilizar permanentemente um membro(s) do usuário.", beneficios = { "A cada Acerto ou TR imposto com sucesso, recupera metade da aura gasta no hatsu" } },
	{ id = "ext_sacrificio_nen", nome = "Sacrifício de Nen", peso = "Extrema", pura = PURE_PN.Extrema, descricao = "Perde permanentemente todos os princípios e Técnicas de Nen (exceto Hatsus).", beneficios = { "O efeito do Hatsu ignora qualquer regra de resistência ou imunidade" } },
	{ id = "ext_vida_ou_morte", nome = "Vida ou Morte", peso = "Extrema", pura = PURE_PN.Extrema, descricao = "Só ativa enquanto o usuário estiver com menos de 10% PV ou Sanidade.", beneficios = { "Dobra o resultado de todos os dados de dano" } },
	{ id = "ext_vida_por_poder", nome = "Vida por Poder", peso = "Extrema", pura = PURE_PN.Extrema, descricao = "O usuário regride 1 nível ao usar o Hatsu. Os P.N não são perdidos, mas os efeitos do nível superior são bloqueados.", beneficios = { "Selecione 4 Efeitos da Categoria e 3 Efeitos Gerais" } },

	-- ===== REFORÇO (categoria) =====
	{ id = "ref_leve_pv_baixo", nome = "Só pode usar com menos de 75% dos PV", peso = "Leve", pura = PURE_PN.Leve, categoria = "Reforço", descricao = "Só pode usar com menos de 75% dos PV.", beneficios = { "+1 grau/passo no dano do Hatsu (Ex: 1d6 → 1d8)" } },
	{ id = "ref_leve_corpo_a_corpo", nome = "Exige ataque corpo a corpo para ativar", peso = "Leve", pura = PURE_PN.Leve, categoria = "Reforço", descricao = "Exige ataque corpo a corpo para ativar.", beneficios = { "O alvo sofre desvantagem em reação contra o Hatsu" } },
	{ id = "ref_leve_sem_defensivas", nome = "Sem habilidades ou reações Defensivas", peso = "Leve", pura = PURE_PN.Leve, categoria = "Reforço", descricao = "Não pode usar habilidades ou reações Defensivas durante o uso do Hatsu.", beneficios = { "+1 na jogada de ataque com o Hatsu" } },
	{ id = "ref_mod_aumento_rodada", nome = "Aumento por rodada", peso = "Media", pura = PURE_PN.Media, categoria = "Reforço", descricao = "Efeitos de atributo, dano, cura ou RD comprados são ativados parcialmente, não de uma vez.", beneficios = { "+2 Graus de Potência nos efeitos afetados" } },
	{ id = "ref_mod_sem_buffs", nome = "Só pode ser usado sem buffs ativos", peso = "Media", pura = PURE_PN.Media, categoria = "Reforço", descricao = "Só pode ser usado sem buffs ativos.", beneficios = { "Ignora resistências a dano físico do alvo (uso por dia = proficiência)" } },
	{ id = "ref_mod_aura_max50", nome = "Inutilizável com mais de 50% da aura", peso = "Media", pura = PURE_PN.Media, categoria = "Reforço", descricao = "Inutilizável com mais de 50% da aura.", beneficios = { "+1 Grau de Potência no Hatsu" } },
	{ id = "ref_pes_dano_aura", nome = "Causa 5% da aura como dano ao usuário", peso = "Pesada", pura = PURE_PN.Pesada, categoria = "Reforço", descricao = "Causa 5% da aura como dano ao usuário (equivalente a 1d6 com REN).", beneficios = { "Pode rerrolar um dos dados de dano" } },
	{ id = "ref_pes_desvantagem_tr", nome = "Desvantagem em testes de resistência após uso", peso = "Pesada", pura = PURE_PN.Pesada, categoria = "Reforço", descricao = "Desvantagem em testes de resistência após uso (durante o restante do dia).", beneficios = { "O Hatsu ignora imunidade a dano (uso por dia = proficiência)" } },
	{ id = "ref_pes_1x_combate", nome = "Só pode ser usado 1x por combate", peso = "Pesada", pura = PURE_PN.Pesada, categoria = "Reforço", descricao = "Só pode ser usado 1x por combate.", beneficios = { "+3 Pontos de Nen (P.N)" } },
}

--------------------------------------------------
-- CATEGORIA → eficiência
--------------------------------------------------
local function getEfficiency(character)
	local nen = character.Nen or {}
	local category = nen.Category or character.Class
	if category == "Reforço" then
		return 100
	end
	return 60
end

local function effectCost(effect, efficiency)
	local mult = CATEGORY_EFFICIENCY[efficiency] or 1.0
	return math.ceil(effect.custo * mult)
end

--------------------------------------------------
-- CATÁLOGO (para o wizard)
--------------------------------------------------
function HatsuService.GetCatalog(category)
	return {
		effects = ALL_EFFECTS,
		restrictions = RESTRICTIONS,
		efficiency = category == "Reforço" and 100 or 60,
		purePN = PURE_PN,
	}
end

--------------------------------------------------
-- CÁLCULO DE TR (fórmula do Manual)
-- 8 + piso(nível/2, mín 1) + mod. atributo + bônus efeitos + bônus restrições
--------------------------------------------------
local function getAttributeMod(character, attr)
	local attrs = character.Attributes or {}
	local val = (attrs[attr] and attrs[attr].value) or 10
	return math.floor((val - 10) / 2)
end

function HatsuService.CalcTR(character, efeitos, restricoes)
	local level = character.Level or 1
	local base = 8 + math.max(1, math.floor(level / 2))
	-- Atributo do Hatsu/Ataque: Reforço usa FOR
	local mod = getAttributeMod(character, "FOR")

	local efeitoBonus = 0
	for _, e in ipairs(efeitos or {}) do
		efeitoBonus = efeitoBonus + (e.trBonus or 0)
	end
	local restricaoBonus = 0
	for _, r in ipairs(restricoes or {}) do
		restricaoBonus = restricaoBonus + (r.trBonus or 0)
	end

	return {
		total = base + mod + efeitoBonus + restricaoBonus,
		base = base,
		atributo = mod,
		efeitos = efeitoBonus,
		restricoes = restricaoBonus,
	}
end

--------------------------------------------------
-- CÁLCULO DE CUSTO DE AURA
--------------------------------------------------
local function calcCustoAura(efeitosEscolhidos, restricoesAplicadas)
	local custo = 50 -- base (Hatsus sem restrições específicas começam com 50%)
	local temExtrema = false
	local pesadas = 0

	for _, r in ipairs(restricoesAplicadas) do
		if r.peso == "Extrema" then
			temExtrema = true
		elseif r.peso == "Pesada" then
			pesadas = pesadas + 1
		end
	end

	for _, e in ipairs(efeitosEscolhidos) do
		if e.id == "geral_reducao_custo" then
			custo = custo - 5
		elseif e.id == "estabilizacao_aura" then
			custo = custo - 15
		end
	end

	if temExtrema then
		custo = custo - 25
	elseif pesadas >= 2 then
		custo = custo - 10
	end

	for _, r in ipairs(restricoesAplicadas) do
		if r.id == "mod_area_definida" then
			custo = custo - 10
		elseif r.id == "pes_local_condicao" then
			custo = math.floor(custo / 2)
		elseif r.id == "pes_limite_uso_definitivo" and r.pura == false then
			custo = custo - 15
		end
	end

	return math.max(5, custo)
end

--------------------------------------------------
-- CRIAÇÃO GUIADA
--------------------------------------------------
--------------------------------------------------
-- NATUREZA DO HATSU (derivada dos efeitos)
-- Hostil = tem "Dano/Cura focal" (rola ataque 2d6+atributo)
-- Versatil = buff/suporte (sem rolagem de ataque)
--------------------------------------------------
local function detectarNatureza(efeitos)
	for _, eid in ipairs(efeitos or {}) do
		if eid == "geral_dano_cura_focal" then
			return "Hostil"
		end
	end
	return "Versatil"
end

function HatsuService.CreateHatsuV2(character, build)
	if not build or not build.nome or #build.nome == 0 then
		return { success = false, error = "Nome do Hatsu é obrigatório." }
	end
	if not build.efeitos or #build.efeitos == 0 then
		return { success = false, error = "Selecione pelo menos um efeito." }
	end

	local efficiency = getEfficiency(character)
	local pnDisponivel = character.PN or 0
	local custoTotal = 0
	local efeitosEscolhidos = {}

	for _, eid in ipairs(build.efeitos) do
		local efeito
		for _, e in ipairs(ALL_EFFECTS) do
			if e.id == eid then
				efeito = e
				break
			end
		end
		if not efeito then
			return { success = false, error = "Efeito desconhecido: " .. tostring(eid) }
		end
		local custo = effectCost(efeito, efficiency)
		custoTotal = custoTotal + custo
		table.insert(efeitosEscolhidos, { id = efeito.id, nome = efeito.nome, custo = custo, trBonus = efeito.trBonus or 0 })
	end

	local pnRestaurado = 0
	local restricoesAplicadas = {}
	for _, r in ipairs(build.restricoes or {}) do
		local restr
		for _, rc in ipairs(RESTRICTIONS) do
			if rc.id == r.id then
				restr = rc
				break
			end
		end
		if not restr then
			return { success = false, error = "Restrição desconhecida: " .. tostring(r.id) }
		end
		local pura = r.pura or false
		local ganho = 0
		if pura then
			ganho = restr.pura
			if restr.peso == "Variavel" then
				ganho = r.valor or 0
			end
			pnRestaurado = pnRestaurado + ganho
		end
		table.insert(restricoesAplicadas, {
			id = restr.id, nome = restr.nome, peso = restr.peso, pura = pura, ganho = ganho, trBonus = restr.trBonus or 0,
		})
	end

	local custoLiquido = custoTotal - pnRestaurado
	if custoLiquido > pnDisponivel then
		return {
			success = false,
			error = "P.N insuficiente. Custo: " .. custoLiquido
				.. " (efeitos " .. custoTotal .. " - restrições " .. pnRestaurado .. "), disponível: " .. pnDisponivel,
		}
	end

	character.PN = pnDisponivel - custoLiquido

	local custoAura = calcCustoAura(efeitosEscolhidos, restricoesAplicadas)
	local tr = HatsuService.CalcTR(character, efeitosEscolhidos, restricoesAplicadas)

	local hatsu = {
		Id = HatsuService.NextId(character),
		Nome = build.nome,
		Tipo = "Reforço",
		Natureza = detectarNatureza(build.efeitos),
		Efeitos = efeitosEscolhidos,
		Restricoes = restricoesAplicadas,
		Graus = { Dano = 0 },
		CustoAura = custoAura,
		TR = tr.total,
		Ativo = false,
	}
	table.insert(character.Hatsus, hatsu)

	return {
		success = true,
		hatsu = hatsu,
		message = "Hatsu criado! Efeitos: " .. custoTotal .. " - Restrições: " .. pnRestaurado
			.. " = " .. custoLiquido .. " P.N. Restante: " .. tostring(character.PN)
			.. ". Custo de aura: " .. custoAura .. "%. TR: " .. tr.total,
	}
end

--------------------------------------------------
-- EDIÇÃO DE HATSU (recalcula custo e reembolsa a diferença)
--------------------------------------------------
function HatsuService.EditHatsu(character, hatsuId, build)
	local hatsu
	local index
	for i, h in ipairs(character.Hatsus or {}) do
		if h.Id == hatsuId then
			hatsu = h
			index = i
			break
		end
	end
	if not hatsu then
		return { success = false, error = "Hatsu não encontrado." }
	end
	if not build or not build.nome or #build.nome == 0 then
		return { success = false, error = "Nome do Hatsu é obrigatório." }
	end
	if not build.efeitos or #build.efeitos == 0 then
		return { success = false, error = "Selecione pelo menos um efeito." }
	end

	-- Reembolsa o custo líquido do Hatsu antigo
	local custoAntigo = 0
	for _, e in ipairs(hatsu.Efeitos or {}) do
		custoAntigo = custoAntigo + (e.custo or 0)
	end
	local ganhoAntigo = 0
	for _, r in ipairs(hatsu.Restricoes or {}) do
		if r.pura then
			ganhoAntigo = ganhoAntigo + (r.ganho or 0)
		end
	end
	character.PN = (character.PN or 0) + math.max(0, custoAntigo - ganhoAntigo)

	-- Remove e recria com os novos dados
	table.remove(character.Hatsus, index)
	local novo = HatsuService.CreateHatsuV2(character, build)
	if not novo.success then
		return novo
	end
	novo.message = "Hatsu editado! " .. novo.message
	return novo
end

function HatsuService.GetHatsus(character)
	return character.Hatsus or {}
end

function HatsuService.NextId(character)
	local max = 0
	for _, h in ipairs(character.Hatsus or {}) do
		local num = tonumber(tostring(h.Id):match("%d+$")) or 0
		if num > max then
			max = num
		end
	end
	return "H" .. (max + 1)
end

--------------------------------------------------
-- EXCLUSÃO COM REEMBOLSO
--------------------------------------------------
function HatsuService.DeleteHatsu(character, hatsuId)
	local index = nil
	local hatsu = nil
	for i, h in ipairs(character.Hatsus or {}) do
		if h.Id == hatsuId then
			index = i
			hatsu = h
			break
		end
	end
	if not hatsu then
		return { success = false, error = "Hatsu não encontrado." }
	end

	local custoTotal = 0
	for _, e in ipairs(hatsu.Efeitos or {}) do
		custoTotal = custoTotal + (e.custo or 0)
	end
	local ganhoRestricoes = 0
	for _, r in ipairs(hatsu.Restricoes or {}) do
		if r.pura then
			ganhoRestricoes = ganhoRestricoes + (r.ganho or 0)
		end
	end
	local reembolso = math.max(0, custoTotal - ganhoRestricoes)
	character.PN = (character.PN or 0) + reembolso
	table.remove(character.Hatsus, index)

	return {
		success = true,
		message = "Hatsu removido. P.N restituído: +" .. reembolso .. " (total: " .. tostring(character.PN) .. ")",
	}
end

--------------------------------------------------
-- ATIVAÇÃO (consome aura — base 50%)
--------------------------------------------------
function HatsuService.ActivateHatsu(character, hatsuId)
	local hatsu
	for _, h in ipairs(character.Hatsus or {}) do
		if h.Id == hatsuId then
			hatsu = h
			break
		end
	end
	if not hatsu then
		return { success = false, error = "Hatsu não encontrado." }
	end
	-- Consumo de aura
	local aura = character.Vitals and character.Vitals.Aura
	local custo = hatsu.CustoAura or 50
	if aura and aura.Max and aura.Max > 0 then
		local custoReal = math.floor((aura.Max or 100) * custo / 100)
		if (aura.Current or 0) < custoReal then
			return { success = false, error = "Aura insuficiente (" .. custo .. "% do máximo = " .. custoReal .. ")." }
		end
		aura.Current = math.max(0, (aura.Current or 0) - custoReal)
	end
	local natureza = hatsu.Natureza or detectarNatureza(hatsu.Efeitos or {})
	local attrs = character.Attributes or {}
	local forVal = attrs.FOR and attrs.FOR.value or 10
	local forMod = math.max(0, math.floor((forVal - 10) / 2))
	local conVal = (attrs.CON and attrs.CON.value) or 10
	local conMod = math.max(0, math.floor((conVal - 10) / 2))
	-- Efeitos de suporte (cura/RD) valem para qualquer natureza
	local cura = 0
	local rd = 0
	local critico = 20
	for _, e in ipairs(hatsu.Efeitos or {}) do
		if e.id == "recuperacao_veloz" then
			cura = cura + math.random(1, 8) + conMod
		elseif e.id == "vitalidade_extra" then
			cura = cura + math.random(1, 6) + conMod
		elseif e.id == "pele_de_pedra" then
			rd = math.max(rd, 3)
		elseif e.id == "barreira_interna" then
			rd = math.max(rd, 5)
		elseif e.id == "corpo_de_aco" then
			rd = math.max(rd, 10)
		elseif e.id == "aura_afiada" then
			critico = 19
		end
	end
	if cura > 0 and character.Vitals and character.Vitals.HP then
		local hp = character.Vitals.HP
		hp.Current = math.min(hp.Max or hp.Current, (hp.Current or 0) + cura)
	end
	-- Hatsu NÃO Hostil (Buff/Versátil): sem rolagem de ataque
	if natureza ~= "Hostil" then
		local linhas = { "✨ " .. tostring(hatsu.Nome) .. " — " .. natureza }
		if cura > 0 then
			linhas[#linhas + 1] = "Cura: +" .. cura .. " PV"
		end
		if rd > 0 then
			linhas[#linhas + 1] = "RD: " .. rd
		end
		linhas[#linhas + 1] = "Sem rolagem de ataque (Hatsu de suporte)."
		return {
			success = true,
			resultado = {
				nome = hatsu.Nome,
				mensagem = table.concat(linhas, "\n"),
				natureza = natureza,
				cura = cura,
				rd = rd,
				rolagem = nil,
			},
			hatsu = hatsu,
		}
	end
	-- Hatsu Hostil: rolagem de ataque 2d6 + atributo (FOR)
	local d1 = math.random(1, 6)
	local d2 = math.random(1, 6)
	local dano = d1 + d2 + forMod
	local partes = { "2d6=" .. (d1 + d2), "FOR+" .. forMod }
	for _, e in ipairs(hatsu.Efeitos or {}) do
		if e.id == "golpe_reforcado" then
			local d = math.random(1, 8)
			dano = dano + d
			table.insert(partes, "Golpe 1d8=" .. d)
		elseif e.id == "furia_potencializada" then
			local d = math.random(1, 6)
			dano = dano + d
			table.insert(partes, "Fúria 1d6=" .. d)
		elseif e.id == "forca_titanica" then
			dano = dano + 5
			table.insert(partes, "Força Titânica +5")
		elseif e.id == "penetracao_dolorosa" then
			dano = dano + 5
			table.insert(partes, "Penetração +5")
		end
	end
	local rolagem = math.random(1, 20)
	local ehCritico = rolagem >= critico
	if ehCritico then
		dano = dano * 2
		table.insert(partes, "CRÍTICO x2")
	end
	local linhas = { "🎲 " .. rolagem .. (ehCritico and " — CRÍTICO! (x2)" or "") }
	linhas[#linhas + 1] = "Dano: " .. dano
	linhas[#linhas + 1] = "Partes: " .. table.concat(partes, " + ")
	linhas[#linhas + 1] = "Aura: -" .. (aura and math.floor((aura.Max or 100) * custo / 100) or custo) .. " (" .. custo .. "%)"
	if rd > 0 then
		linhas[#linhas + 1] = "RD: " .. rd
	end
	if cura > 0 then
		linhas[#linhas + 1] = "Cura: +" .. cura .. " PV"
	end
	return {
		success = true,
		resultado = {
			nome = hatsu.Nome,
			rolagem = table.concat(linhas, "\n"),
			dano = dano,
			critico = ehCritico,
			rd = rd,
			cura = cura,
		},
		hatsu = hatsu,
	}
end

--------------------------------------------------
-- GRAUS E RESTRIÇÕES (compatibilidade)
--------------------------------------------------
function HatsuService.AddGrau(character, hatsuId, caracteristica)
	local hatsu
	for _, h in ipairs(character.Hatsus or {}) do
		if h.Id == hatsuId then
			hatsu = h
			break
		end
	end
	if not hatsu then
		return { success = false, error = "Hatsu não encontrado." }
	end
	hatsu.Graus = hatsu.Graus or {}
	hatsu.Graus[caracteristica] = (hatsu.Graus[caracteristica] or 0) + 1
	return { success = true, message = "+1 grau em " .. tostring(caracteristica) .. "." }
end

function HatsuService.AddRestricao(character, hatsuId, restricaoId)
	local hatsu
	for _, h in ipairs(character.Hatsus or {}) do
		if h.Id == hatsuId then
			hatsu = h
			break
		end
	end
	if not hatsu then
		return { success = false, error = "Hatsu não encontrado." }
	end
	local restr
	for _, rc in ipairs(RESTRICTIONS) do
		if rc.id == restricaoId then
			restr = rc
			break
		end
	end
	if not restr then
		return { success = false, error = "Restrição desconhecida." }
	end
	hatsu.Restricoes = hatsu.Restricoes or {}
	table.insert(hatsu.Restricoes, { id = restr.id, nome = restr.nome, peso = restr.peso, pura = false, ganho = 0, trBonus = restr.trBonus or 0 })
	return { success = true, message = "Restrição adicionada: " .. restr.nome }
end

return HatsuService