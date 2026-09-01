--[[
    HxH5e AchievementsDB (Shared) — catalogo de conquistas.
    Cada uma tem: id, nome, descricao, tipo (contador/checagem/evento/
    manual/combate). A LOGICA de quando desbloquear cada uma fica em
    AchievementService.lua (server) -- este arquivo e so o catalogo
    pra exibicao e pra achar meta/campo de contador.
]]

local AchievementsDB = {}

AchievementsDB.Conquistas = {
	{ id = "primeira_cacada", nome = "Primeira Caçada", descricao = "Derrote um inimigo que se move.", tipo = "combate" },
	{ id = "critico_nat20", nome = "Isso Aqui é RPG!", descricao = "Tire seu primeiro crítico natural (d20 = 20) numa rolagem de Hatsu.", tipo = "evento" },
	{ id = "critico_nat1", nome = "Chorar é Ação Livre", descricao = "Tire seu primeiro crítico negativo (d20 = 1) numa rolagem de Hatsu.", tipo = "evento" },
	{ id = "ten_20x", nome = "Melhor Prevenir", descricao = "Ative TEN 20 vezes.", tipo = "contador", contador = "TenAtivacoes", meta = 20 },
	{ id = "ren_20x", nome = "Prática Leva à Perfeição", descricao = "Ative REN 20 vezes.", tipo = "contador", contador = "RenAtivacoes", meta = 20 },
	{ id = "zetsu_10x", nome = "Blindspot", descricao = "Ative ZETSU 10 vezes.", tipo = "contador", contador = "ZetsuAtivacoes", meta = 10 },
	{ id = "nivel_1", nome = "Nascido pra Isso", descricao = "Chegue ao Nível 1 (Batismo e Despertar).", tipo = "checagem" },
	{ id = "maestria_1", nome = "Levando isso a sério", descricao = "Alcance maestria (nível 3) em 1 princípio fundamental (Ten, Ren ou Zetsu).", tipo = "checagem" },
	{ id = "maestria_2", nome = "Um é pouco, dois é bom...", descricao = "Alcance maestria em 2 princípios fundamentais ao mesmo tempo.", tipo = "checagem" },
	{ id = "maestria_3", nome = "Hat-Trick Hunter", descricao = "Alcance maestria nos 3 princípios fundamentais (Ten, Ren e Zetsu) ao mesmo tempo.", tipo = "checagem" },
	{ id = "principio_avancado_1", nome = "Feijão com arroz bem feitinho", descricao = "Aprenda seu primeiro Princípio Avançado (En, In, Gyo ou Shu).", tipo = "checagem" },
	{ id = "primeiro_hatsu", nome = "Primeira Manifestação", descricao = "Crie seu primeiro Hatsu.", tipo = "checagem" },
	{ id = "pv_baixo", nome = "À Beira do Abismo", descricao = "Sobreviva com 10% ou menos do seu PV máximo.", tipo = "evento" },
	{ id = "primeira_organizacao", nome = "União Faz Açúcar", descricao = "Entre em sua primeira organização.", tipo = "manual" },
}

local byId = {}
for _, c in ipairs(AchievementsDB.Conquistas) do
	byId[c.id] = c
end
AchievementsDB.ById = byId

function AchievementsDB.Get(id)
	return byId[id]
end

return AchievementsDB
