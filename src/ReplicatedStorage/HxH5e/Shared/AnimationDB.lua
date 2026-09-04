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
-- Chaves que o JOGO JA USA de verdade (ActionBarClient.lua /
-- CombatService.lua chamam AnimationDB.FindByChave com esses nomes
-- exatos) -- NAO RENOMEAR sem atualizar o codigo tambem: Parado,
-- Correndo, AtaqueCaC, Bloquear.
--
-- Segunda leva de animacoes (Lucas, sessao de combos/hitbox/reacoes):
-- varias categorias novas -- Combos (sequencias de Karate + a de 3
-- golpes+disparo), Reacoes bem mais especificas que so "TomarDano"
-- generico (cabeca, bloqueio cruzado/box, quedas de varios tipos,
-- levantar, ficar caido), Dashes/Impulsos direcionais (WASD),
-- Interacoes (pegar item), e Armas (pendente pro dia que os
-- equipamentos via Tool forem implementados -- Knife Idle, corrida
-- com arma de uma mao).

local AnimationDB = {}

AnimationDB.Categorias = {
	{
		nome = "Movimento",
		animacoes = {
			{ chave = "Parado", nome = "Parado (Idle)", id = "rbxassetid://93718063117068", descricao = "Loop enquanto o personagem nao esta se movendo nem fazendo nada. Vem do Combat Idle_1 no rig Combat Animations." },
			{ chave = "IdleRespirando", nome = "Parado - Respirando", id = "rbxassetid://78729111122343", descricao = "Variante de idle com respiracao mais visivel." },
			{ chave = "Andando", nome = "Andando (sem pressa)", id = "rbxassetid://126534037944470", descricao = "Loop de caminhada normal. Vem de Walk Animation V3." },
			{ chave = "AndandoRapido", nome = "Andando Rapido", id = "rbxassetid://83605435480169", descricao = "Caminhada apressada, mais natural. Vem de Walk Animation_More Natural rapido." },
			{ chave = "Correndo", nome = "Correndo", id = "rbxassetid://94089159360233", descricao = "Loop de corrida (velocidade maior que andar). Vem do Fist Sprint_1 no rig Combat Animations -- corrida com bracos dobrados, como se segurasse um bastao." },
			{ chave = "CorridaNormal", nome = "Corrida Normal", id = "rbxassetid://134955425743316", descricao = "Variante de corrida sem pose de combate." },
			{ chave = "SprintAnim", nome = "Sprint", id = "rbxassetid://128842168202426", descricao = "Variante de sprint (nome generico dado pelo Lucas, distinta do Fist Sprint que ja preenche Correndo)." },
			{ chave = "CorrendoManeiro", nome = "Correndo (estilo)", id = "rbxassetid://128732650065856", descricao = "Corrida com estilo/atitude. Vem de Running_Animation1." },
			{ chave = "Pulando", nome = "Pulando", id = "", descricao = "Tocada no instante do salto." },
			{ chave = "Caindo", nome = "Caindo", id = "", descricao = "Loop enquanto o personagem esta no ar, caindo." },
			{ chave = "CairComEstilo", nome = "Cair com Estilo", id = "rbxassetid://114074566281374", descricao = "Queda/aterrissagem com pose estilizada (ex: apos pulo alto ou dash aereo)." },
			{ chave = "PegarItem", nome = "Pegar Item", id = "rbxassetid://117105454321707", descricao = "Interacao de abaixar e pegar um item do chao." },
		},
	},
	{
		nome = "Armas (pendente Tools)",
		-- So faz sentido usar de verdade quando o sistema de equipamentos
		-- via Tool for implementado (Lucas confirmou: "usar tools
		-- futuramente quando implementarmos os equipamentos"). Guardado
		-- aqui desde ja pra nao perder os IDs.
		animacoes = {
			{ chave = "KnifeIdle", nome = "Parado com Faca na Mao", id = "rbxassetid://101853116494608", descricao = "Idle especifico pra quando uma faca/adaga estiver equipada (Tool, pendente)." },
			{ chave = "CorridaComArmaUmaMao", nome = "Corrida com Arma em Uma Mao", id = "rbxassetid://114497172177446", descricao = "Corrida segurando uma arma de uma mao (Tool, pendente)." },
			{ chave = "SwordAnim", nome = "Ataque de Espada", id = "", descricao = "Ainda sem ID -- pendente publicacao." },
		},
	},
	{
		nome = "Combate",
		animacoes = {
			{ chave = "AtaqueCaC", nome = "Ataque Corpo a Corpo", id = "rbxassetid://72742539324008", descricao = "Golpe basico -- tecla F / botao Ataque-C-a-C (BasicAttack). Vem do Left Punch_Fast no rig Combat Animations -- soco rapido de esquerda." },
			{ chave = "Bloquear", nome = "Bloquear", id = "rbxassetid://122295932363436", descricao = "Reacao de bloqueio -- tecla Q / botao Bloquear (AttemptReaction 'block'). Vem do Block Instance no rig Combat Animations -- bloqueio/guarda alta." },
			{ chave = "BloqueioDuasMaos", nome = "Bloqueio de Duas Maos", id = "rbxassetid://130736150748526", descricao = "Variante de bloqueio usando as duas maos." },
			{ chave = "InstanciaBloqueio2", nome = "Bloqueio (variante 2)", id = "rbxassetid://91914703485115", descricao = "Segunda variante de pose de bloqueio." },
			{ chave = "Esquivar", nome = "Esquivar", id = "", descricao = "Reacao de esquiva -- tecla E / botao Esquivar (AttemptReaction 'dodge')." },
			{ chave = "ChuteGiratorio", nome = "Chute Giratorio", id = "rbxassetid://113509564879928", descricao = "Ataque especial em area, chute giratorio." },
			{ chave = "DefendendoArea", nome = "Defendendo Area / Controlando", id = "rbxassetid://97996134686597", descricao = "Pose de controle de area ou postura defensiva ampla." },
			{ chave = "DisparoDeAura", nome = "Disparo de Aura", id = "rbxassetid://95062565449753", descricao = "Ataque a distancia com aura (possivel uso em Hatsu de Emissao)." },
		},
	},
	{
		nome = "Combos",
		-- Sequencia de golpes encadeados -- apertar F repetidas vezes
		-- dentro de uma janela curta avanca pro proximo estagio
		-- (Karate1 -> Karate2 -> ... -> Karate5), resetando se passar
		-- do tempo. Ainda sem logica de jogo conectada -- so o catalogo.
		animacoes = {
			{ chave = "Karate1", nome = "Sequencia de Karate 1", id = "rbxassetid://76020269326811", descricao = "Primeiro golpe do combo." },
			{ chave = "Karate2", nome = "Sequencia de Karate 2", id = "rbxassetid://100696579219134", descricao = "Segundo golpe do combo." },
			{ chave = "Karate3", nome = "Sequencia de Karate 3", id = "rbxassetid://138180294346149", descricao = "Terceiro golpe do combo." },
			{ chave = "Karate4", nome = "Sequencia de Karate 4", id = "rbxassetid://122780690357832", descricao = "Quarto golpe do combo." },
			{ chave = "Karate5", nome = "Sequencia de Karate 5", id = "rbxassetid://122802603763506", descricao = "Quinto e ultimo golpe do combo." },
			{ chave = "Combo3GolpesDisparo", nome = "Combo: 3 Golpes + Disparo/Apontar", id = "rbxassetid://96417204696725", descricao = "Sequencia alternativa de combo terminando em disparo ou mira." },
		},
	},
	{
		nome = "Principios de Nen",
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
		animacoes = {
			{ chave = "TomarDano", nome = "Tomar Dano (generico)", id = "", descricao = "Reacao curta padrao ao sofrer um golpe, quando nao houver uma especifica." },
			{ chave = "TomarDanoCabeca", nome = "Golpeado na Cabeca", id = "rbxassetid://90897183860365", descricao = "Reacao a golpe mirado na cabeca." },
			{ chave = "TomarDanoBloqueioCruzado", nome = "Golpeado (Bloqueio Cruzado)", id = "rbxassetid://73041841615240", descricao = "Reacao ao ser atingido durante bloqueio com bracos cruzados." },
			{ chave = "TomarDanoBloqueioBox", nome = "Golpeado (Bloqueio de Boxe)", id = "rbxassetid://131761679804991", descricao = "Reacao ao ser atingido durante guarda de boxe." },
			{ chave = "QuedaFrente", nome = "Queda de Frente", id = "rbxassetid://81908766114150", descricao = "Cai de frente apos ser atingido." },
			{ chave = "QuedaLadoExplosao", nome = "Queda de Lado (Explosao)", id = "rbxassetid://73084705414899", descricao = "Cai de lado, efeito de impacto forte/explosivo." },
			{ chave = "DerrubadoCaindo", nome = "Derrubado e Caindo", id = "rbxassetid://121419699225981", descricao = "IMPORTANTE (nota do Lucas): sempre deve tocar ANTES de 'QuedaAlturaCostas' -- e a transicao de ser derrubado ate cair de fato." },
			{ chave = "QuedaAlturaCostas", nome = "Queda de Altura (Costas)", id = "rbxassetid://112158038218269", descricao = "Impacto forte de costas apos queda de altura -- toca DEPOIS de DerrubadoCaindo." },
			{ chave = "QuedaCurtaCostas", nome = "Queda Curta (Costas)", id = "rbxassetid://113513901830404", descricao = "Queda mais leve de costas, sem a fase de derrubado." },
			{ chave = "Caido", nome = "Caido (loop no chao)", id = "rbxassetid://137599322132173", descricao = "Pose/loop de personagem caido no chao, antes de levantar." },
			{ chave = "Levantando", nome = "Levantando do Chao", id = "rbxassetid://83035508314134", descricao = "Transicao de caido para em pe." },
			{ chave = "Nocauteado", nome = "Nocauteado / Derrotado", id = "", descricao = "Quando o PV chega a 0." },
		},
	},
	{
		nome = "Dashes / Impulsos",
		-- Impulsos direcionais (WASD) -- possivelmente pra um dash/dodge
		-- direcional futuro, distinto da Esquivar de reacao.
		animacoes = {
			{ chave = "ImpulsoFrente", nome = "Impulso para Frente (W)", id = "rbxassetid://103560668750101", descricao = "Dash pra frente." },
			{ chave = "ImpulsoTras", nome = "Impulso para Tras (S)", id = "rbxassetid://90057051047677", descricao = "Dash pra tras." },
			{ chave = "ImpulsoEsquerda", nome = "Impulso para Esquerda (A)", id = "rbxassetid://112378394199973", descricao = "Dash lateral esquerdo." },
			{ chave = "ImpulsoDireita", nome = "Impulso para Direita (D)", id = "rbxassetid://73547719865360", descricao = "Dash lateral direito." },
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
