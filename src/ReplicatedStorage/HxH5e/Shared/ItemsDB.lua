--[[
    HxH5e ItemsDB (Shared) — catalogo de equipamentos/armas/itens (loja)
    HxH5e ItemsDB (Shared) — catalogo de equipamentos/armas/itens (loja)
    Portado de js/data/config.js (ITEM_DB) do webapp, incluindo tags
    (propriedades: Leve, Acuidade, Alcance, Duas Maos, Bloqueio, etc.)
    e detalhe (texto de flavor) -- resgatados do repositorio original
    depois de terem sido cortados numa portagem anterior.
]]

local ItemsDB = {}

ItemsDB.armas = {
	-- ===== simples_corpo_a_corpo =====
	{ nome = "Adaga", subcategoria = "simples_corpo_a_corpo", custo = 10, dano = "1d4", tipo_dano = "Corte", peso = 0.5, tags = { "Acuidade", "Arremesso (6m/18m)" }, detalhe = "Lâmina versátil para combate ou arremesso." },
	{ nome = "Azagaia", subcategoria = "simples_corpo_a_corpo", custo = 25, dano = "1d6", tipo_dano = "Perfuração", peso = 1.0, tags = { "Arremesso (6m/18m)", "Perfuração" }, detalhe = "Uma lança curta projetada para ser lançada." },
	{ nome = "Cajado / Bastão", subcategoria = "simples_corpo_a_corpo", custo = 5, dano = "1d6", tipo_dano = "Impacto", peso = 1.0, tags = { "Versátil (1d8)", "Finta" }, detalhe = "Pode ser usado com uma ou duas mãos." },
	{ nome = "Clava Grande", subcategoria = "simples_corpo_a_corpo", custo = 150, dano = "1d8", tipo_dano = "Impacto", peso = 2.0, tags = { "Pesada", "Duas Mãos" }, detalhe = "Uma arma bruta que exige força e ambas as mãos." },
	{ nome = "Foice Curta", subcategoria = "simples_corpo_a_corpo", custo = 30, dano = "1d4", tipo_dano = "Corte", peso = 1.0, tags = { "Leve", "Mortal x3" }, detalhe = "Eficiente em causar cortes profundos e críticos." },
	{ nome = "Lança", subcategoria = "simples_corpo_a_corpo", custo = 120, dano = "1d6", tipo_dano = "Perfuração", peso = 1.0, tags = { "Versátil (1d8)", "Arremesso (9m/36m)" }, detalhe = "Arma de haste clássica para estocar ou arremessar." },
	{ nome = "Maça", subcategoria = "simples_corpo_a_corpo", custo = 120, dano = "1d6", tipo_dano = "Impacto", peso = 1.0, tags = { "Bloqueio" }, detalhe = "Arma contundente que auxilia na defesa." },
	{ nome = "Machadinha", subcategoria = "simples_corpo_a_corpo", custo = 20, dano = "1d6", tipo_dano = "Corte", peso = 0.5, tags = { "Leve", "Arremesso (6m/18m)" }, detalhe = "Machado pequeno e equilibrado." },
	{ nome = "Martelo Leve", subcategoria = "simples_corpo_a_corpo", custo = 10, dano = "1d4", tipo_dano = "Impacto", peso = 0.5, tags = { "Leve", "Arremesso (6m/18m)" }, detalhe = "Ferramenta de impacto fácil de manusear." },
	{ nome = "Porrete Pogamoggan", subcategoria = "simples_corpo_a_corpo", custo = 80, dano = "1d4", tipo_dano = "Impacto", peso = 0.5, tags = { "Leve", "Versátil (1d6)", "Bloqueio" }, detalhe = "Bastão reforçado para defesa e ataque." },
	-- ===== simples_distancia =====
	{ nome = "Agulha Senbon (1)", subcategoria = "simples_distancia", custo = 30, dano = "1d4", tipo_dano = "Perfuração", peso = 0.1, tags = { "Arremesso (9m/18m)", "Ataque Múltiplo", "Munição" }, detalhe = "Pequenos projéteis precisos e leves." },
	{ nome = "Arco Curto", subcategoria = "simples_distancia", custo = 60, dano = "1d6", tipo_dano = "Perfuração", peso = 1.0, tags = { "Munição (6m/18m)", "Perfuração", "Duas Mãos" }, detalhe = "Arco compacto para disparos rápidos." },
	{ nome = "Corrente Pesada", subcategoria = "simples_distancia", custo = 60, dano = "1d8", tipo_dano = "Impacto", peso = 1.0, tags = { "Alcance (3m)", "Agarrar", "Tropeçar", "Duas Mãos", "Pesada" }, detalhe = "Utilizada para controle de área e imobilização." },
	{ nome = "Dardo / Zarabatana", subcategoria = "simples_distancia", custo = 20, dano = "1d4", tipo_dano = "Perfuração", peso = 0.5, tags = { "Arremesso (6m/12m)", "Duas Mãos", "Munição" }, detalhe = "Armas silenciosas para aplicação de toxinas." },
	{ nome = "Funda / Estilingue", subcategoria = "simples_distancia", custo = 20, dano = "1d4", tipo_dano = "Impacto", peso = 0.3, tags = { "Arremesso (6m/18m)", "Duas Mãos", "Munição" }, detalhe = "Usa pedras ou esferas como munição." },
	{ nome = "Rede", subcategoria = "simples_distancia", custo = 30, dano = "-", tipo_dano = "Sem dano", peso = 1.0, tags = { "Alcance (3m)", "Agarrar/Prender", "Duas Mãos" }, detalhe = "Projetada apenas para incapacitar o oponente." },
	{ nome = "Shuriken", subcategoria = "simples_distancia", custo = 30, dano = "1d4", tipo_dano = "Corte", peso = 0.1, tags = { "Arremesso (6m/18m)", "Ataque Múltiplo" }, detalhe = "Estrelas de arremesso para ataques em sequência." },
	-- ===== marciais_corpo_a_corpo =====
	{ nome = "Alabarda", subcategoria = "marciais_corpo_a_corpo", custo = 400, dano = "1d12", tipo_dano = "Corte", peso = 1.5, tags = { "Alcance", "Duas Mãos", "Pesada" } },
	{ nome = "Bastão de 3 partes", subcategoria = "marciais_corpo_a_corpo", custo = 300, dano = "1d8", tipo_dano = "Impacto", peso = 1.0, tags = { "Bloqueio", "Derrubar", "Finta" } },
	{ nome = "Bumerangue", subcategoria = "marciais_corpo_a_corpo", custo = 150, dano = "1d6", tipo_dano = "Impacto", peso = 0.5, tags = { "Arremesso (6m/18m)", "Finta", "Leve", "Retorno" } },
	{ nome = "Chakram", subcategoria = "marciais_corpo_a_corpo", custo = 150, dano = "1d6", tipo_dano = "Corte", peso = 1.0, tags = { "Arremesso (6m/18m)", "Finta", "Leve", "Retorno" } },
	{ nome = "Chicote", subcategoria = "marciais_corpo_a_corpo", custo = 120, dano = "1d4", tipo_dano = "Corte", peso = 0.5, tags = { "Acuidade", "Alcance", "Desarmar" } },
	{ nome = "Cimitarra", subcategoria = "marciais_corpo_a_corpo", custo = 120, dano = "1d6", tipo_dano = "Corte", peso = 1.0, tags = { "Acuidade", "Leve" } },
	{ nome = "Espada Curta", subcategoria = "marciais_corpo_a_corpo", custo = 120, dano = "1d6", tipo_dano = "Corte", peso = 1.0, tags = { "Leve" } },
	{ nome = "Espada Exótica (Katana)", subcategoria = "marciais_corpo_a_corpo", custo = 180, dano = "1d8", tipo_dano = "Corte", peso = 1.0, tags = { "Acuidade" } },
	{ nome = "Espada Grande", subcategoria = "marciais_corpo_a_corpo", custo = 450, dano = "2d6", tipo_dano = "Corte", peso = 1.5, tags = { "Bloqueio", "Duas Mãos", "Pesada" } },
	{ nome = "Espada Longa", subcategoria = "marciais_corpo_a_corpo", custo = 150, dano = "1d8", tipo_dano = "Corte", peso = 1.0, tags = { "Versátil (1d10)" } },
	{ nome = "Foice com Corrente", subcategoria = "marciais_corpo_a_corpo", custo = 250, dano = "2d4", tipo_dano = "Corte", peso = 1.0, tags = { "Agarrar", "Alcance", "Duas Mãos", "Finta" } },
	{ nome = "Foice", subcategoria = "marciais_corpo_a_corpo", custo = 350, dano = "2d4", tipo_dano = "Corte", peso = 1.0, tags = { "Alcance", "Duas Mãos", "Mortal x3", "Pesada" } },
	{ nome = "Florete/Rapieira", subcategoria = "marciais_corpo_a_corpo", custo = 180, dano = "1d8", tipo_dano = "Perfuração", peso = 1.0, tags = { "Acuidade" } },
	{ nome = "Garra de Ferro", subcategoria = "marciais_corpo_a_corpo", custo = 180, dano = "1d6", tipo_dano = "Corte", peso = 1.0, tags = { "Acuidade", "Crítico" } },
	{ nome = "Glaive", subcategoria = "marciais_corpo_a_corpo", custo = 280, dano = "1d10", tipo_dano = "Corte", peso = 1.5, tags = { "Alcance", "Duas mãos", "Pesada" } },
	{ nome = "Jitte", subcategoria = "marciais_corpo_a_corpo", custo = 120, dano = "1d6", tipo_dano = "Perfuração", peso = 1.0, tags = { "Bloqueio", "Leve" } },
	{ nome = "Lança de Montaria", subcategoria = "marciais_corpo_a_corpo", custo = 500, dano = "1d12", tipo_dano = "Perfuração", peso = 1.5, tags = { "Alcance", "Especial (estocada)", "Duas Mãos", "Pesada" } },
	{ nome = "Linha de Batalha", subcategoria = "marciais_corpo_a_corpo", custo = 5, dano = "1d4", tipo_dano = "Corte", peso = 0.1, tags = { "Alcance", "Agarrar", "Tropeçar", "Duas Mãos" } },
	{ nome = "Maça Estrela", subcategoria = "marciais_corpo_a_corpo", custo = 250, dano = "1d8", tipo_dano = "Impacto", peso = 1.0, tags = { "Bloqueio", "Mortal x3" } },
	{ nome = "Machado", subcategoria = "marciais_corpo_a_corpo", custo = 150, dano = "1d8", tipo_dano = "Corte", peso = 1.0, tags = { "Versátil (1d10)" } },
	{ nome = "Machado Grande", subcategoria = "marciais_corpo_a_corpo", custo = 450, dano = "1d12", tipo_dano = "Corte", peso = 1.5, tags = { "Bloqueio", "Duas Mãos", "Pesada" } },
	{ nome = "Mangual", subcategoria = "marciais_corpo_a_corpo", custo = 220, dano = "1d8", tipo_dano = "Impacto", peso = 1.0, tags = { "Desarmar", "Duas Mãos", "Especial (+1 em ataque)" } },
	{ nome = "Manopla de Combate", subcategoria = "marciais_corpo_a_corpo", custo = 350, dano = "+1 ataque Desarmado", tipo_dano = "Impacto", peso = 1.0, tags = { "Bloqueio", "Leve" } },
	{ nome = "Marreta", subcategoria = "marciais_corpo_a_corpo", custo = 450, dano = "2d6", tipo_dano = "Impacto", peso = 1.5, tags = { "Bloqueio", "Duas Mãos", "Pesada" } },
	{ nome = "Martelo de Guerra", subcategoria = "marciais_corpo_a_corpo", custo = 150, dano = "1d8", tipo_dano = "Impacto", peso = 1.0, tags = { "Versátil (1d10)" } },
	{ nome = "Nunchaku", subcategoria = "marciais_corpo_a_corpo", custo = 120, dano = "1d6", tipo_dano = "Impacto", peso = 1.0, tags = { "Desarmar", "Leve" } },
	{ nome = "Picareta de Guerra", subcategoria = "marciais_corpo_a_corpo", custo = 150, dano = "1d8", tipo_dano = "Perfuração", peso = 1.0, tags = { "Duas Mãos" } },
	{ nome = "Soqueira com Lâminas", subcategoria = "marciais_corpo_a_corpo", custo = 120, dano = "1d6", tipo_dano = "Corte", peso = 0.5, tags = { "Acuidade", "Leve" } },
	{ nome = "Tonfá", subcategoria = "marciais_corpo_a_corpo", custo = 120, dano = "1d6", tipo_dano = "Impacto", peso = 1.0, tags = { "Bloqueio", "Leve" } },
	{ nome = "Tridente", subcategoria = "marciais_corpo_a_corpo", custo = 350, dano = "1d10", tipo_dano = "Perfuração", peso = 1.5, tags = { "Duas Mãos", "Pesada" } },
	-- ===== marciais_distancia =====
	{ nome = "Arco Longo", subcategoria = "marciais_distancia", custo = 250, dano = "1d8", tipo_dano = "Perfuração", peso = 1.0, tags = { "Duas Mãos", "Munição (32m/96m)" }, detalhe = "Arco de grande porte com longo alcance." },
	{ nome = "Besta de Mão", subcategoria = "marciais_distancia", custo = 200, dano = "1d6", tipo_dano = "Perfuração", peso = 1.0, tags = { "Munição (9m/18m)", "Recarregar" }, detalhe = "Compacta, pode ser usada com uma mão, mas exige recarga." },
	{ nome = "Besta Pesada", subcategoria = "marciais_distancia", custo = 250, dano = "1d10", tipo_dano = "Perfuração", peso = 1.0, tags = { "Munição (18m/32m)", "Duas Mãos" }, detalhe = "Disparo potente que exige ambas as mãos." },
	{ nome = "Fuma-Shuriken", subcategoria = "marciais_distancia", custo = 200, dano = "1d8", tipo_dano = "Corte", peso = 1.0, tags = { "Arremesso (6m/18m)", "Retorno", "Oculto" }, detalhe = "Shuriken gigante dobrável, difícil de detectar antes do uso." },
	{ nome = "Monster Chakram", subcategoria = "marciais_distancia", custo = 250, dano = "1d10", tipo_dano = "Corte", peso = 2.0, tags = { "Arremesso (6m/18m)", "Retorno", "Duas Mãos" }, detalhe = "Versão massiva do chakram para danos elevados." },
	-- ===== cientificas_simples =====
	{ nome = "Bola de gude explosiva (5)", subcategoria = "cientificas_simples", custo = 300, dano = "2d4 cada", tipo_dano = "Explosivo", peso = 0.5, tags = { "Arremesso (12m)", "Ataques Múltiplos", "Explosiva" }, detalhe = "Explode ao tocar em qualquer superfície depois de lançada." },
	{ nome = "Mosquete", subcategoria = "cientificas_simples", custo = 3000, dano = "1d12", tipo_dano = "Balístico", peso = 1.0, tags = { "Balística", "Duas Mãos", "Munição (32m/96m)", "Recarregar" }, detalhe = "Arma de fogo longa de cano liso. Requer munição de cartucho." },
	{ nome = "Motosserra", subcategoria = "cientificas_simples", custo = 5000, dano = "2d6", tipo_dano = "Corte", peso = 2.0, tags = { "Mortal x3", "Pesada" }, detalhe = "Ferramenta motorizada adaptada para combate. Requer combustível." },
	{ nome = "Pistola", subcategoria = "cientificas_simples", custo = 2000, dano = "1d10", tipo_dano = "Balístico", peso = 1.0, tags = { "Balística", "Munição (18m/32m)" }, detalhe = "Arma de fogo padrão para defesa pessoal." },
	{ nome = "Spray de pimenta (10)", subcategoria = "cientificas_simples", custo = 100, dano = "0", tipo_dano = "Químico", peso = 0.5, tags = { "Ataque Múltiplo", "Persistência" }, detalhe = "Item portátil com propriedade de dispersão que causa irritação severa aos olhos." },
	{ nome = "Tazer (3 Cargas)", subcategoria = "cientificas_simples", custo = 1000, dano = "0", tipo_dano = "Elétrico", peso = 0.5, tags = { "Ataque Múltiplo", "Persistência" }, detalhe = "Dispositivo de imobilização por choque elétrico." },
	-- ===== cientificas_complexas =====
	{ nome = "Dinamite (1 banana)", subcategoria = "cientificas_complexas", custo = 1000, dano = "2d8 + 8", tipo_dano = "Explosivo", peso = 1.0, tags = { "Arma de Cerco", "Explosivo", "Detonador" }, detalhe = "Dano dobrado em estruturas." },
	{ nome = "Espingarda", subcategoria = "cientificas_complexas", custo = 10000, dano = "4d6", tipo_dano = "Balístico", peso = 1.0, tags = { "Balística", "Duas Mãos", "Munição (6m/18m)", "Recarregar" }, detalhe = "Arma de cano longo com alto poder de parada." },
	{ nome = "Dispositivo de PEM (3 usos)", subcategoria = "cientificas_complexas", custo = 500, dano = "1d6", tipo_dano = "Eletromagnético", peso = 0.5, tags = { "Detonador" }, detalhe = "Pulso Eletromagnético para desfazer equipamentos eletrônicos." },
	{ nome = "Fuzil de Assalto", subcategoria = "cientificas_complexas", custo = 185000, dano = "2d10", tipo_dano = "Balístico", peso = 1.0, tags = { "Balística", "Crítico", "Duas Mãos", "Rajada: 10", "Munição" }, detalhe = "Permite disparos em área gastando 10 unidades de munição." },
	{ nome = "Granada Comum", subcategoria = "cientificas_complexas", custo = 500, dano = "2d6 + 5", tipo_dano = "Explosivo", peso = 0.5, tags = { "Arremesso (12m)", "Explosivo" }, detalhe = "Explode ao tocar em superfícies." },
	{ nome = "Granada Gás Lacrimogêneo", subcategoria = "cientificas_complexas", custo = 400, dano = "1d4", tipo_dano = "Químico", peso = 0.5, tags = { "Arremesso (12m)", "Dispersão", "Leve" }, detalhe = "Cria nuvem de gás que persiste." },
	{ nome = "Granada de Fumaça", subcategoria = "cientificas_complexas", custo = 150, dano = "0", tipo_dano = "-", peso = 0.5, tags = { "Arremesso (9m/18m)", "Cobertura", "Leve" }, detalhe = "Gera cobertura pesada." },
	{ nome = "Granada de Luz/Som", subcategoria = "cientificas_complexas", custo = 200, dano = "0", tipo_dano = "Sensorial", peso = 0.5, tags = { "Arremesso (9m/18m)", "Persistência" }, detalhe = "Atordoante." },
	{ nome = "Lança Chamas", subcategoria = "cientificas_complexas", custo = 20000, dano = "3d6", tipo_dano = "Fogo", peso = 2.0, tags = { "Duas Mãos", "Dispersão", "Munição", "Pesada" }, detalhe = "Projeta fogo em cone." },
	{ nome = "Molotov", subcategoria = "cientificas_complexas", custo = 100, dano = "1d6", tipo_dano = "Fogo", peso = 0.2, tags = { "Arremesso (18m)" }, detalhe = "Artefato incendiário simples." },
	-- ===== cientificas_especiais =====
	{ nome = "Bazuca (6 munições)", subcategoria = "cientificas_especiais", custo = 250000, dano = "2d10 + 15", tipo_dano = "Explosivo", peso = 4.0, tags = { "Arma de Cerco", "Duas Mãos", "Explosivo", "Munição", "Pesada", "Recarregar" }, detalhe = "Armamento pesado capaz de destruir estruturas." },
	{ nome = "Fuzil de Precisão", subcategoria = "cientificas_especiais", custo = 200000, dano = "2d10", tipo_dano = "Balístico", peso = 1.0, tags = { "Balística", "Crítico", "Distância Mínima 15m", "Duas Mãos", "Mortal x4", "Munição", "Recarregar" }, detalhe = "Arma de altíssimo alcance e precisão para snipers." },
	{ nome = "Metralhadora", subcategoria = "cientificas_especiais", custo = 200000, dano = "2d12", tipo_dano = "Balístico", peso = 1.0, tags = { "Balística", "Duas Mãos", "Especial (Rajada: 15)", "Mortal x3", "Munição" }, detalhe = "Arma de disparo rápido." },
	-- ===== cerco =====
	{ nome = "Balestra Fixa", subcategoria = "cerco", tipo = "Objeto Grande", custo = 2500, ca = 15, pv = 30, peso = 5.0, tags = { "Arma de Cerco", "Projétil", "Recarregar" }, detalhe = "Balestra maciça que dispara setas pesadas." },
	{ nome = "Canhão", subcategoria = "cerco", tipo = "Objeto Grande", custo = 12000, ca = 15, pv = 75, peso = 15.0, tags = { "Arma de Cerco", "Explosivo", "Recarregar", "Pesada" }, detalhe = "Usa pólvora para impulsionar bolas de ferro." },
	{ nome = "Torreta", subcategoria = "cerco", tipo = "Objeto Grande", custo = 34000, ca = 15, pv = 75, peso = 12.0, tags = { "Arma de Cerco", "Balística", "Rajada", "Fixa" }, detalhe = "Metralhadora de veículo." },
	{ nome = "Tanque de Guerra", subcategoria = "cerco", tipo = "Veículo Grande", custo = 7000000, ca = 12, pv = 500, peso = 12000.0, tags = { "Arma de Cerco", "Blindado", "Móvel", "Complexo" }, detalhe = "Veículo de combate completo." },
}

ItemsDB.armaduras = {
	{ nome = "Casaco Reforçado", custo = 130, ca = "11 + DES", peso = 0 },
	{ nome = "Jaqueta de Couro", custo = 300, ca = "11 + DES", peso = 0 },
	{ nome = "Camisa Embutida", custo = 50, ca = "11 + DES", peso = 0 },
	{ nome = "Colete Fino de Kevlar", custo = 350, ca = "12 + DES", peso = 0.3 },
	{ nome = "Colete Oculto", custo = 500, ca = "12 + DES", peso = 0.5 },
	{ nome = "Escudo Comum", custo = 60, ca = "+1", peso = 1.0 },
	{ nome = "Colete Oculto Maior", custo = 560, ca = "13 + DES (max. 2)", peso = 1.0 },
	{ nome = "Colete Padrão Kevlar", custo = 1200, ca = "14 + DES (max. 3)", peso = 0 },
	{ nome = "Peitoral Adamantina", custo = 180000, ca = "14 + DES (max. 3)", peso = 0 },
	{ nome = "Colete Tático", custo = 1500, ca = "15 + DES (max. 2)", peso = 0 },
	{ nome = "Escudo Tático", custo = 300, ca = "+3", peso = 1.5 },
	{ nome = "Colete Resposta Rápida", custo = 1000, ca = "16", peso = 1.0, requisito = "FOR 14" },
	{ nome = "Farda de Combate", custo = 2000, ca = "17", peso = 1.0, requisito = "FOR 14" },
	{ nome = "Farda Op. Especiais", custo = 3500, ca = "18", peso = 1.5, requisito = "FOR 14" },
	{ nome = "Armadura Adamantina", custo = 200000, ca = "17", peso = 1.0, requisito = "FOR 16" },
	{ nome = "Escudo Torre Tático", custo = 580, ca = "+5", peso = 3.0, requisito = "FOR 14" },
}

ItemsDB.municoes = {
	{ nome = "Flecha (20)", custo = 50, peso = 1.0 },
	{ nome = "Projétil Bazuca", custo = 1500, peso = 0.5 },
	{ nome = "Cartucho Grosso (4)", custo = 50, peso = 0.5 },
	{ nome = "Cartucho Fuzil (30)", custo = 200, peso = 1.0 },
	{ nome = "Cartucho Precisão (6)", custo = 100, peso = 1.0 },
	{ nome = "Cartucho Metralhadora (45)", custo = 300, peso = 1.5 },
	{ nome = "Cartucho Pistola (12)", custo = 100, peso = 0.5 },
	{ nome = "Combustível", custo = 50, peso = 1.0 },
}

ItemsDB.itens_medicos = {
	{ nome = "Kit Antídoto", custo = 50, peso = 0.5, usos = 3 },
	{ nome = "Kit Médico", custo = 500, peso = 0.8, usos = 5 },
	{ nome = "Máscara de Gás", custo = 350, peso = 0.5, usos = 15 },
	{ nome = "Pílula Hemoglobina", custo = 5, peso = 0, efeito = "Cura 2d4 + CON PV" },
	{ nome = "Pílula Paracetamol", custo = 10, peso = 0, efeito = "Cura 2d6 + CON PV" },
	{ nome = "Pílula Morfina", custo = 100, peso = 0, efeito = "Cura 2d8 + CON PV" },
	{ nome = "Respirador Aquático", custo = 350, peso = 2.0 },
}

ItemsDB.kits = {
	{ nome = "Kit de Armas", custo = 120, peso = 1.5, usos = 5 },
	{ nome = "Kit de Caça e Rastreio", custo = 150, peso = 1.5, usos = 5 },
	{ nome = "Kit de Cozinha", custo = 80, peso = 1.0, usos = 5 },
	{ nome = "Kit de Disfarce", custo = 50, peso = 0.5, usos = 10 },
	{ nome = "Kit de Falsificação", custo = 30, peso = 0.5, usos = 10 },
	{ nome = "Kit Forense", custo = 500, peso = 1.0, usos = 5 },
	{ nome = "Kit de Hacker", custo = 800, peso = 1.5, usos = 10 },
	{ nome = "Kit Ferramentas Ofício", custo = 50, peso = 1.5, usos = 3 },
}

ItemsDB.equipamentos_gerais = {
	-- Item especial: a compra dela e uma das 2 formas de virar Hunter
	-- licenciado (a outra e passar no Exame Hunter, ainda nao
	-- implementado -- ver OrganizationService.lua). No anime, quem
	-- vende a propria licenca "pode viver 4 vidas sem preocupacoes".
	{ nome = "Licença Hunter", custo = 3000000000, peso = 0 },
	{ nome = "Ponto de Rádio", custo = 150, peso = 0 },
	{ nome = "Celular", custo = 1500, peso = 0.1 },
	{ nome = "Pen-Drive", custo = 60, peso = 0 },
	{ nome = "Câmera", custo = 600, peso = 0.5 },
	{ nome = "Computador", custo = 3000, peso = 1.0 },
	{ nome = "Relógio Bússola", custo = 50, peso = 0.1 },
	{ nome = "Corda (10m)", custo = 25, peso = 0.5 },
	{ nome = "Haste Luminosa (par)", custo = 35, peso = 0.2 },
	{ nome = "Gancho Escalada (par)", custo = 50, peso = 0.5 },
	{ nome = "Gerador Calor", custo = 200, peso = 1.0 },
	{ nome = "Binóculos", custo = 45, peso = 0.5 },
	{ nome = "Espelho de mão", custo = 10, peso = 0.1 },
	{ nome = "Barraca (2 pessoas)", custo = 500, peso = 2.0 },
	{ nome = "Algema", custo = 100, peso = 0.5 },
	{ nome = "Mochila", custo = 120, espaco_gerado = 1.5 },
	{ nome = "Mala de Roupas", custo = 120, espaco_gerado = 2.0 },
	{ nome = "Mala de Viagem", custo = 120, espaco_gerado = 2.5 },
	{ nome = "Bracelete acoplar", custo = 120, espaco_gerado = 1.0 },
	{ nome = "Pochete", custo = 120, espaco_gerado = 0.7 },
	{ nome = "Cartucheira", custo = 120, espaco_gerado = 0.7 },
	{ nome = "Garrafa Térmica", custo = 120, peso = 0.5 },
}

-- Junta tudo numa lista so, indexada por nome (case-sensitive, igual ao webapp)
local todosItens = {}
local porNome = {}
for _, lista in pairs({ ItemsDB.armas, ItemsDB.armaduras, ItemsDB.municoes, ItemsDB.itens_medicos, ItemsDB.kits, ItemsDB.equipamentos_gerais }) do
	for _, item in ipairs(lista) do
		table.insert(todosItens, item)
		porNome[item.nome] = item
	end
end
ItemsDB.Todos = todosItens

function ItemsDB.FindItem(nome)
	return porNome[nome]
end

return ItemsDB
