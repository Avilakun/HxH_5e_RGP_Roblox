--[[
    HxH5e ItemsDB (Shared) — catalogo de equipamentos/armas/itens (loja)
    Portado de js/data/config.js (ITEM_DB) do webapp.
    Simplificado pra economizar espaco: guardamos so nome/custo/dano/
    tipo_dano/ca/peso -- tags e "detalhe" (texto de flavor) foram
    cortados por ora. Se precisar deles depois, re-portar do webapp.
]]

local ItemsDB = {}

ItemsDB.armas = {
	{ nome = "Adaga", custo = 10, dano = "1d4", tipo_dano = "Corte", peso = 0.5 },
	{ nome = "Azagaia", custo = 25, dano = "1d6", tipo_dano = "Perfuração", peso = 1.0 },
	{ nome = "Cajado / Bastão", custo = 5, dano = "1d6", tipo_dano = "Impacto", peso = 1.0 },
	{ nome = "Clava Grande", custo = 150, dano = "1d8", tipo_dano = "Impacto", peso = 2.0 },
	{ nome = "Foice Curta", custo = 30, dano = "1d4", tipo_dano = "Corte", peso = 1.0 },
	{ nome = "Lança", custo = 120, dano = "1d6", tipo_dano = "Perfuração", peso = 1.0 },
	{ nome = "Maça", custo = 120, dano = "1d6", tipo_dano = "Impacto", peso = 1.0 },
	{ nome = "Machadinha", custo = 20, dano = "1d6", tipo_dano = "Corte", peso = 0.5 },
	{ nome = "Martelo Leve", custo = 10, dano = "1d4", tipo_dano = "Impacto", peso = 0.5 },
	{ nome = "Porrete Pogamoggan", custo = 80, dano = "1d4", tipo_dano = "Impacto", peso = 0.5 },
	{ nome = "Agulha Senbon (1)", custo = 30, dano = "1d4", tipo_dano = "Perfuração", peso = 0.1 },
	{ nome = "Arco Curto", custo = 60, dano = "1d6", tipo_dano = "Perfuração", peso = 1.0 },
	{ nome = "Corrente Pesada", custo = 60, dano = "1d8", tipo_dano = "Impacto", peso = 1.0 },
	{ nome = "Dardo / Zarabatana", custo = 20, dano = "1d4", tipo_dano = "Perfuração", peso = 0.5 },
	{ nome = "Funda / Estilingue", custo = 20, dano = "1d4", tipo_dano = "Impacto", peso = 0.3 },
	{ nome = "Rede", custo = 30, dano = "-", tipo_dano = "Sem dano", peso = 1.0 },
	{ nome = "Shuriken", custo = 30, dano = "1d4", tipo_dano = "Corte", peso = 0.1 },
	{ nome = "Alabarda", custo = 400, dano = "1d12", tipo_dano = "Corte", peso = 1.5 },
	{ nome = "Bastão de 3 partes", custo = 300, dano = "1d8", tipo_dano = "Impacto", peso = 1.0 },
	{ nome = "Bumerangue", custo = 150, dano = "1d6", tipo_dano = "Impacto", peso = 0.5 },
	{ nome = "Chakram", custo = 150, dano = "1d6", tipo_dano = "Corte", peso = 1.0 },
	{ nome = "Chicote", custo = 120, dano = "1d4", tipo_dano = "Corte", peso = 0.5 },
	{ nome = "Cimitarra", custo = 120, dano = "1d6", tipo_dano = "Corte", peso = 1.0 },
	{ nome = "Espada Curta", custo = 120, dano = "1d6", tipo_dano = "Corte", peso = 1.0 },
	{ nome = "Espada Exótica (Katana)", custo = 180, dano = "1d8", tipo_dano = "Corte", peso = 1.0 },
	{ nome = "Espada Grande", custo = 450, dano = "2d6", tipo_dano = "Corte", peso = 1.5 },
	{ nome = "Espada Longa", custo = 150, dano = "1d8", tipo_dano = "Corte", peso = 1.0 },
	{ nome = "Foice com Corrente", custo = 250, dano = "2d4", tipo_dano = "Corte", peso = 1.0 },
	{ nome = "Foice", custo = 350, dano = "2d4", tipo_dano = "Corte", peso = 1.0 },
	{ nome = "Florete/Rapieira", custo = 180, dano = "1d8", tipo_dano = "Perfuração", peso = 1.0 },
	{ nome = "Garra de Ferro", custo = 180, dano = "1d6", tipo_dano = "Corte", peso = 1.0 },
	{ nome = "Glaive", custo = 280, dano = "1d10", tipo_dano = "Corte", peso = 1.5 },
	{ nome = "Jitte", custo = 120, dano = "1d6", tipo_dano = "Perfuração", peso = 1.0 },
	{ nome = "Lança de Montaria", custo = 500, dano = "1d12", tipo_dano = "Perfuração", peso = 1.5 },
	{ nome = "Linha de Batalha", custo = 5, dano = "1d4", tipo_dano = "Corte", peso = 0.1 },
	{ nome = "Maça Estrela", custo = 250, dano = "1d8", tipo_dano = "Impacto", peso = 1.0 },
	{ nome = "Machado", custo = 150, dano = "1d8", tipo_dano = "Corte", peso = 1.0 },
	{ nome = "Machado Grande", custo = 450, dano = "1d12", tipo_dano = "Corte", peso = 1.5 },
	{ nome = "Mangual", custo = 220, dano = "1d8", tipo_dano = "Impacto", peso = 1.0 },
	{ nome = "Manopla de Combate", custo = 350, dano = "+1 ataque Desarmado", tipo_dano = "Impacto", peso = 1.0 },
	{ nome = "Marreta", custo = 450, dano = "2d6", tipo_dano = "Impacto", peso = 1.5 },
	{ nome = "Martelo de Guerra", custo = 150, dano = "1d8", tipo_dano = "Impacto", peso = 1.0 },
	{ nome = "Nunchaku", custo = 120, dano = "1d6", tipo_dano = "Impacto", peso = 1.0 },
	{ nome = "Picareta de Guerra", custo = 150, dano = "1d8", tipo_dano = "Perfuração", peso = 1.0 },
	{ nome = "Soqueira com Lâminas", custo = 120, dano = "1d6", tipo_dano = "Corte", peso = 0.5 },
	{ nome = "Tonfá", custo = 120, dano = "1d6", tipo_dano = "Impacto", peso = 1.0 },
	{ nome = "Tridente", custo = 350, dano = "1d10", tipo_dano = "Perfuração", peso = 1.5 },
	{ nome = "Arco Longo", custo = 250, dano = "1d8", tipo_dano = "Perfuração", peso = 1.0 },
	{ nome = "Besta de Mão", custo = 200, dano = "1d6", tipo_dano = "Perfuração", peso = 1.0 },
	{ nome = "Besta Pesada", custo = 250, dano = "1d10", tipo_dano = "Perfuração", peso = 1.0 },
	{ nome = "Fuma-Shuriken", custo = 200, dano = "1d8", tipo_dano = "Corte", peso = 1.0 },
	{ nome = "Monster Chakram", custo = 250, dano = "1d10", tipo_dano = "Corte", peso = 2.0 },
	{ nome = "Bola de gude explosiva (5)", custo = 300, dano = "2d4 cada", tipo_dano = "Explosivo", peso = 0.5 },
	{ nome = "Mosquete", custo = 3000, dano = "1d12", tipo_dano = "Balístico", peso = 1.0 },
	{ nome = "Motosserra", custo = 5000, dano = "2d6", tipo_dano = "Corte", peso = 2.0 },
	{ nome = "Pistola", custo = 2000, dano = "1d10", tipo_dano = "Balístico", peso = 1.0 },
	{ nome = "Spray de pimenta (10)", custo = 100, dano = "0", tipo_dano = "Químico", peso = 0.5 },
	{ nome = "Tazer (3 Cargas)", custo = 1000, dano = "0", tipo_dano = "Elétrico", peso = 0.5 },
	{ nome = "Dinamite (1 banana)", custo = 1000, dano = "2d8 + 8", tipo_dano = "Explosivo", peso = 1.0 },
	{ nome = "Espingarda", custo = 10000, dano = "4d6", tipo_dano = "Balístico", peso = 1.0 },
	{ nome = "Dispositivo de PEM (3 usos)", custo = 500, dano = "1d6", tipo_dano = "Eletromagnético", peso = 0.5 },
	{ nome = "Fuzil de Assalto", custo = 185000, dano = "2d10", tipo_dano = "Balístico", peso = 1.0 },
	{ nome = "Granada Comum", custo = 500, dano = "2d6 + 5", tipo_dano = "Explosivo", peso = 0.5 },
	{ nome = "Granada Gás Lacrimogêneo", custo = 400, dano = "1d4", tipo_dano = "Químico", peso = 0.5 },
	{ nome = "Granada de Fumaça", custo = 150, dano = "0", tipo_dano = "-", peso = 0.5 },
	{ nome = "Granada de Luz/Som", custo = 200, dano = "0", tipo_dano = "Sensorial", peso = 0.5 },
	{ nome = "Lança Chamas", custo = 20000, dano = "3d6", tipo_dano = "Fogo", peso = 2.0 },
	{ nome = "Molotov", custo = 100, dano = "1d6", tipo_dano = "Fogo", peso = 0.2 },
	{ nome = "Bazuca (6 munições)", custo = 250000, dano = "2d10 + 15", tipo_dano = "Explosivo", peso = 4.0 },
	{ nome = "Fuzil de Precisão", custo = 200000, dano = "2d10", tipo_dano = "Balístico", peso = 1.0 },
	{ nome = "Metralhadora", custo = 200000, dano = "2d12", tipo_dano = "Balístico", peso = 1.0 },
	{ nome = "Balestra Fixa", custo = 2500, ca = 15, pv = 30, peso = 5.0 },
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
