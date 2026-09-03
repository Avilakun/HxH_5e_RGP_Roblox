-- AnimationDB.lua -- catalogo central de animacoes do rig de
-- referencia, organizado por nome (nao so IDs), pra saber o que
-- gravar/copiar sem precisar abrir o Animation Editor pra conferir.
--
-- Como preencher: depois de gravar e publicar uma animacao no rig de
-- referencia, cole o ID (ex: "rbxassetid://123456789") no campo `id`
-- da entrada correspondente. Ate la, fica como string vazia -- os
-- campos abaixo ja tem o NOME e quando cada animacao toca, so falta
-- o ID.
--
-- Os nomes batem com as acoes que ja existem de verdade no jogo
-- (ActionBarClient.lua): Ataque C-a-C, Bloquear, Esquivar, e os 8
-- principios de Nen (Ten/Ren/Gyo/Shu/Ken/Ko/Ryu/In). Adicionei tambem
-- Movimento e Reacoes, que ainda nao tem gancho no codigo mas
-- qualquer rig de combate vai precisar.
--
-- Todas as criaturas que usarem o MESMO tipo de esqueleto (rig
-- padrao humanoide, por exemplo) podem reaproveitar os mesmos IDs
-- daqui -- nao precisa gravar de novo pra cada monstro.

local AnimationDB = {}

AnimationDB.Categorias = {
	{
		nome = "Movimento",
		animacoes = {
			{ chave = "Parado", nome = "Parado (Idle)", id = "rbxassetid://93718063117068", descricao = "Loop enquanto o personagem nao esta se movendo nem fazendo nada. Vem do Combat Idle_1 no rig Combat Animations." },
			{ chave = "Andando", nome = "Andando", id = "", descricao = "Loop de caminhada normal." },
			{ chave = "Correndo", nome = "Correndo", id = "rbxassetid://94089159360233", descricao = "Loop de corrida (velocidade maior que andar). Vem do Fist Sprint_1 no rig Combat Animations -- corrida com bracos dobrados, como se segurasse um bastao." },
			{ chave = "Pulando", nome = "Pulando", id = "", descricao = "Tocada no instante do salto." },
			{ chave = "Caindo", nome = "Caindo", id = "", descricao = "Loop enquanto o personagem esta no ar, caindo." },
		},
	},
	{
		nome = "Combate",
		animacoes = {
			{ chave = "AtaqueCaC", nome = "Ataque Corpo a Corpo", id = "rbxassetid://72742539324008", descricao = "Golpe basico -- tecla F / botao Ataque-C-a-C (BasicAttack). Vem do Left Punch_Fast no rig Combat Animations -- soco rapido de esquerda." },
			{ chave = "Bloquear", nome = "Bloquear", id = "rbxassetid://122295932363436", descricao = "Reacao de bloqueio -- tecla Q / botao Bloquear (AttemptReaction 'block'). Vem do Block Instance no rig Combat Animations -- bloqueio/guarda alta." },
			{ chave = "Esquivar", nome = "Esquivar", id = "", descricao = "Reacao de esquiva -- tecla E / botao Esquivar (AttemptReaction 'dodge')." },
		},
	},
	{
		nome = "Principios de Nen",
		-- Ativacao de cada principio -- mesma lista de 8 que existe no
		-- radial hoje (PRINCIPIOS em ActionBarClient.lua). EN e ZETSU
		-- ficam de fora por enquanto, mesmo combinado que ja vale pros
		-- icones do HUD.
		animacoes = {
			{ chave = "Ten", nome = "Ten (ativacao)", id = "", descricao = "Tecla T / slot da hotbar." },
			{ chave = "Ren", nome = "Ren (ativacao)", id = "", descricao = "Tecla R / slot da hotbar." },
			{ chave = "Gyo", nome = "Gyo (ativacao)", id = "", descricao = "Slot da hotbar." },
			{ chave = "Shu", nome = "Shu (ativacao)", id = "", descricao = "Slot da hotbar." },
			{ chave = "Ken", nome = "Ken (ativacao)", id = "", descricao = "Slot da hotbar." },
			{ chave = "Ko", nome = "Ko (ativacao)", id = "", descricao = "Slot da hotbar." },
			{ chave = "Ryu", nome = "Ryu (ativacao)", id = "", descricao = "Slot da hotbar." },
			{ chave = "In", nome = "In (ativacao)", id = "", descricao = "Slot da hotbar (chave interna do jogo e 'Inp')." },
		},
	},
	{
		nome = "Reacoes",
		-- Ainda sem gancho no codigo (o jogo ainda nao troca animacao
		-- ao tomar dano/morrer) -- mas todo rig de combate vai
		-- precisar, entao ja deixei os slots reservados.
		animacoes = {
			{ chave = "TomarDano", nome = "Tomar Dano", id = "", descricao = "Reacao curta ao sofrer um golpe." },
			{ chave = "Nocauteado", nome = "Nocauteado / Derrotado", id = "", descricao = "Quando o PV chega a 0." },
		},
	},
}

-- Indice por chave, pra busca rapida (mesmo padrao do MonsterDB/
-- CombatInclinationsDB) -- ex: AnimationDB.FindByChave("AtaqueCaC").id
local porChave = {}
for _, categoria in ipairs(AnimationDB.Categorias) do
	for _, anim in ipairs(categoria.animacoes) do
		porChave[anim.chave] = anim
	end
end

function AnimationDB.FindByChave(chave)
	return porChave[chave]
end

return AnimationDB
