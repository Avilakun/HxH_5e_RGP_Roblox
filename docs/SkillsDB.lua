-- SkillsDB.lua -- gerado automaticamente a partir de config.js (chaves
-- "skills", "otherSkills", "pointBuyCosts") do webapp (github.com/
-- Criadores-HxH-5e/Ficha_HxH5e). Ultimos pedacos do config.js que
-- ainda faltavam converter (o resto -- armas, armaduras, racas,
-- antecedentes, inclinacoes -- ja tinha sido portado em sessoes
-- anteriores).
--
-- .skills (24): pericias "normais" -- os 6 Testes de Resistencia (TR)
--   de cada atributo, seguidos das 18 pericias baseadas em atributo
--   (Acrobacia, Atletismo, Percepcao etc).
-- .otherSkills (11): proficiencias "de equipamento" -- armas (simples/
--   marciais, corpo-a-corpo/distancia), armaduras, kits, linguas
--   antigas -- categoria separada de skills porque nao usa um
--   atributo fixo do mesmo jeito.
-- .pointBuyCosts: tabela de custo em pontos pra COMPRAR um valor de
--   atributo na criacao do personagem (sistema point-buy, D&D-like).
--   Indexada pelo valor final do atributo (1 a 30) -- ex:
--   PointBuyCosts[16] = 8 (custa 8 pontos deixar um atributo em 16).
--   Valores negativos (ex: PointBuyCosts[9] = -1) devolvem pontos --
--   abaixar um atributo abaixo de 10 da pontos de volta pra gastar
--   em outros atributos.

local SkillsDB = {}

SkillsDB.Skills = {
	"TR de FOR",
	"TR de DES",
	"TR de CON",
	"TR de INT",
	"TR de SAB",
	"TR de PRE",
	"Acrobacia",
	"Arcanismo",
	"Atletismo",
	"Atuação",
	"Enganação",
	"Furtividade",
	"História",
	"Intimidação",
	"Intuição",
	"Investigação",
	"Lidar com Animais",
	"Medicina",
	"Natureza",
	"Percepção",
	"Persuasão",
	"Prestidigitação",
	"Religião",
	"Sobrevivência",
}

SkillsDB.OtherSkills = {
	"Armas Marciais corpo-a-corpo",
	"Armas Marciais à distância",
	"Armas Simples corpo-a-corpo",
	"Armas Simples à distância",
	"Equipamentos de Proteção e Armaduras Médias",
	"Equipamentos de Proteção e Armaduras Pesadas",
	"Equipamentos Improvisados/Manufaturados (Bugigangas e Armas de Hatsus criativos)",
	"Científicas/Explosivas",
	"Linguas Antigas e Culturas",
	"Armas de Cerco",
	"Kits",
}

SkillsDB.PointBuyCosts = {
	[1] = -20,
	[2] = -17,
	[3] = -14,
	[4] = -11,
	[5] = -8,
	[6] = -6,
	[7] = -4,
	[8] = -2,
	[9] = -1,
	[10] = 0,
	[11] = 1,
	[12] = 2,
	[13] = 3,
	[14] = 4,
	[15] = 6,
	[16] = 8,
	[17] = 11,
	[18] = 14,
	[19] = 17,
	[20] = 20,
	[21] = 23,
	[22] = 26,
	[23] = 29,
	[24] = 32,
	[25] = 35,
	[26] = 38,
	[27] = 41,
	[28] = 44,
	[29] = 47,
	[30] = 50,
}

return SkillsDB
