-- RacasDB.lua -- gerado automaticamente a partir de config.js (chave
-- "racas") do webapp (github.com/Criadores-HxH-5e/Ficha_HxH5e).
-- 21 racas jogaveis, cada uma com bonus de atributo, caracteristicas
-- fixas e/ou escolhas de caracteristica, fonte (referencia do manual)
-- e categoria (agrupamento tematico usado no seletor do webapp).
--
-- Fecha a pendencia documentada varias sessoes atras: "Racas: so 3
-- implementadas de ~23" -- essa fonte tem 21, bem proximo do numero
-- que ja tinha estimado.
--
-- aumento_atributo tem 2 formatos DIFERENTES na fonte original --
-- preservados como estavam, sem tentar unificar:
--   - tabela: { FOR = 1, CON = 1 } -- bonus fixo por atributo
--   - string: "Escolha +2" / "Nenhum" / "Varia" / "Distribua 3
--     pontos em qualquer atributo" -- regra textual, precisa de
--     interpretacao/UI na hora de criar o personagem (nao e so
--     somar automaticamente).
--
-- caracteristicas = tracos FIXOS que a raca sempre tem.
-- opcoes_caracteristica = tracos ESCOLHIVEIS (o jogador escolhe
--   1 ou mais na criacao, dependendo da raca).
-- fagogenese_options = so existe pra "Formiga Quimera" (as
--   categorias de fagogenese disponiveis pra escolher).

local RacasDB = {
	{
		nome = "Humano Comum",
		descricao = "Raça mais comum no mundo.",
		aumento_atributo = {
			FOR = 1,
			DES = 1,
			CON = 1,
			INT = 1,
			SAB = 1,
			PRE = 1,
		},
		fonte = "[3, 4]",
		categoria = "Humanos e Tribos",
	},
	{
		nome = "Fanalis",
		descricao = "Composição física descomunal.",
		aumento_atributo = {
			FOR = 4,
			CON = 2,
			DES = -2,
			INT = -2,
			SAB = -2,
			PRE = -2,
		},
		opcoes_caracteristica = {
			{
				nome = "Instinto Predatório",
				efeito = "Quando um inimigo o atinge com um ataque corpo a corpo, você pode usar sua reação para atacar desarmado ou com arma leve corpo a corpo imediatamente contra o agressor, com os benefícios de um contra-ataque (mas não os malefícios). 1x/dia; ao final da rodada, ganha 1 de exaustão. Não funciona se o oponente estiver furtivo.",
			},
			{
				nome = "Fúria Muscular",
				efeito = "Quando seu PV cai abaixo de 20%, entra em vigor explosivo por 1 minuto: +2 em jogadas de ataque corpo a corpo e +1d6 de dano adicional em ataques físicos. Após o efeito, ganha 1 nível de exaustão.",
			},
			{
				nome = "Pele de Ferro",
				efeito = "Uma vez por dia, como reação, reduz à metade o dano de um ataque corpo a corpo que o acertaria.",
			},
		},
		fonte = "[3, 4]",
		categoria = "Humanos e Tribos",
	},
	{
		nome = "Gyudondond",
		descricao = "Homens Flauta.",
		aumento_atributo = "Distribua 3 pontos em qualquer atributo",
		opcoes_caracteristica = {
			{
				nome = "Alarido de Guerra",
				efeito = "Membros da Tribo Gyudondond podem utilizar Intimidação como ação de movimento ao performar uma dança, desde que sua aura esteja ativa (qualquer Princípio ou Técnica de NEN, exceto Zetsu). Efeito adicional: se falhar a Intimidação, o alvo ainda sofre -1 em seu próximo teste de concentração, percepção ou intuição (por distração sonora). Limite: 1 vez por turno.",
			},
			{
				nome = "Harmonia de Aura",
				efeito = "Ação de movimento. A vibração sonora dos tubos corporais ajuda o fluxo da aura. Enquanto o Gyudondond estiver emitindo sons ritmados (passivamente ou propositalmente), recebe +1 em testes de concentração em seus Hatsus. Perde o bônus se estiver em silêncio absoluto, surdo ou impedido de se mover.",
			},
			{
				nome = "Sonoridade Instintiva",
				efeito = "Possui sensibilidade especial a sons e vibrações: detecta movimentações próximas (até 5m) mesmo sem visão, ao sentir vibrações no ar ou no solo. Testes de Percepção baseados em audição e toque recebem +2. Em contrapartida, ataques sonoros (ou ruídos intensos) causam +2 de dano contra ele, por hipersensibilidade auditiva.",
			},
		},
		fonte = "[3, 4]",
		categoria = "Humanos e Tribos",
	},
	{
		nome = "Imuchack",
		descricao = "Guerreiros gélidos.",
		aumento_atributo = {
			FOR = 2,
			CON = 1,
			INT = -2,
		},
		opcoes_caracteristica = {
			{
				nome = "Resistência Glacial",
				efeito = "Reduz todo o dano de frio ou gelo em 50% (inclusive dano de aura elemental). Nenhum teste de Resistência Física sofre penalidade por frio. Pode manter Ten ativo por +2 turnos adicionais em ambientes gelados naturais.",
			},
			{
				nome = "Caça Aquática",
				efeito = "Nada sem penalidade de movimento dentro d'água e prende a respiração por Minutos = 1 + (CON × 2).",
			},
			{
				nome = "Ritual de Maturidade",
				efeito = "+1 ponto permanente em FOR ou CON.",
			},
		},
		fonte = "[3, 4]",
		categoria = "Humanos e Tribos",
	},
	{
		nome = "Kurta",
		descricao = "Olhos Escarlates.",
		aumento_atributo = {
			INT_ou_SAB = 2,
		},
		caracteristicas = {
			{
				nome = "Mudança Escarlate",
				efeito = "+1 em todos os atributos enquanto os olhos estiverem vermelhos. Testes de Intimidação, Intuição e Concentração têm vantagem. Ao conhecer NEN, ativa consumindo 10% de aura. Duração: rodadas iguais ao bônus de Sabedoria (mín. 1). Pode ser usado um número de vezes por dia igual à proficiência. Após a ativação, sofre 1 nível de Exaustão pelo esforço físico e mental.",
			},
			{
				nome = "Caça Fascinante",
				efeito = "Você pode ser procurado e caçado, caso descubram seus olhos e sua origem.",
			},
			{
				nome = "Sofrimento Profundo",
				efeito = "Seus olhos se tornam escarlates após um estresse mental extenuante: estar com menos de 20% de vida; sofrer dano psíquico além da metade da vida; estar Amedrontado/Assustado/Aterrorizado por quem já lhe causou +25% de dano; ou ver amigos próximos morrendo.",
			},
		},
		fonte = "[5, 6]",
		categoria = "Clãs Especiais",
	},
	{
		nome = "Formiga Quimera",
		descricao = "Sem Antecedentes. Ver Regra.",
		aumento_atributo = "Nenhum",
		fagogenese_options = {
			"Ave",
			"Mamífero",
			"Réptil/Anfíbio",
			"Aquático",
			"Inseto/Insectóide",
			"Bestas Mágicas",
		},
		caracteristicas = {
			{
				nome = "Arma natural",
				efeito = "Dano variado baseado na anatomia.",
				opcoes = {
					"Bico",
					"Cauda",
					"Chifres",
					"Espinhos",
					"Garras",
					"Presas (Mordida)",
					"Ferrão (Picada)",
					"Tentáculos/Cipós",
				},
			},
			{
				nome = "Corpo Adaptável",
				efeito = "Mudança corporal dramática ou adaptação ambiental.",
				opcoes = {
					"Metamorfose (Lagarta->Borboleta)",
					"Constituição Respiratória (Aéreo)",
					"Constituição Respiratória (Aquático)",
					"Corpo Mole (Resistência Impacto)",
				},
			},
			{
				nome = "Criatura de Cerco",
				efeito = "Dano crítico em construções e Constructos.",
			},
			{
				nome = "Destreza animal",
				efeito = "Vantagem em testes de resistência de Destreza.",
			},
			{
				nome = "Escudo Natural/Carapaça",
				efeito = "Resistência a tipos específicos de dano físico.",
				opcoes = {
					"Resistência a Corte",
					"Resistência a Perfuração",
					"Resistência a Impacto",
				},
			},
			{
				nome = "Evasão",
				efeito = "Manobra de fuga que adiciona +2 na Reação de Esquiva.",
				opcoes = {
					"Aérea",
					"Aquática",
					"Terrestre",
				},
			},
			{
				nome = "Investida",
				efeito = "Dano extra com movimento.",
			},
			{
				nome = "Rasante",
				efeito = "Manobra de ataque aéreo sem receber AdO.",
			},
			{
				nome = "Regeneração",
				efeito = "Recuperação gradual de Vida.",
			},
			{
				nome = "Telepatia",
				efeito = "Comunicação entre espécies.",
				opcoes = {
					"Ativa (Inferior)",
					"Passiva (Superior)",
				},
			},
			{
				nome = "Tração Animal",
				efeito = "Capacidade de carga aumentada e/ou salto dobrado.",
			},
			{
				nome = "Veneno/Peçonha",
				efeito = "Aplica veneno. Imune ao próprio veneno.",
			},
		},
		fonte = "[1, 2]",
		categoria = "Formigas Quimera",
	},
	{
		nome = "Wormorfos",
		descricao = "Povo verme.",
		aumento_atributo = "Nenhum",
		caracteristicas = {
			{
				nome = "Ecolocalização",
				efeito = "Possui ecolocalização de 5m, não precisando depender dos sentidos de visão e audição quando submerso no solo.",
			},
			{
				nome = "Deslocamento Subterrâneo",
				efeito = "9m comum e 4,5m subterrâneo.",
			},
		},
		opcoes_caracteristica = {
			{
				nome = "Corpo Malemolente",
				efeito = "Resistência a dano de impacto/concussão (corpo menos rígido, adapta-se e \"engloba\" o impacto). Em contrapartida, sofre 1/4 (25%, arredondado para cima) a mais de dano perfurante ou cortante, por ter estrutura mais vulnerável a penetrações.",
			},
			{
				nome = "Enterrada",
				efeito = "Além de se submergir, pode puxar inimigos para o solo: usa \"Agarrão/Puxão\" contra a CA do alvo no lugar de um Teste Contestado. Em caso de sucesso, pode gastar a Ação Bônus para submergir puxando o alvo para o solo, aplicando as condições \"Caído\" e \"Imóvel\".",
			},
		},
		fonte = "[5, 6]",
		categoria = "Modificados e Fantasia",
	},
	{
		nome = "Elfos e Meio-Elfos",
		descricao = "Herança feérica.",
		aumento_atributo = "Escolha +2",
		caracteristicas = {
			{
				nome = "Visão na Penumbra",
				efeito = "Enxerga na penumbra a até 18m no escuro. Sua percepção capta o fluxo vital de plantas e animais, permitindo detectar seres vivos mesmo através de folhagens densas, desde que não estejam ocultos por Zetsu.",
			},
		},
		opcoes_caracteristica = {
			{
				nome = "Pulsar Verde",
				efeito = "Durante descansos ou meditações em ambientes naturais, recupera +1 ponto adicional de exaustão e reduz pela metade os efeitos de exaustão por clima, fome ou sede. Uma vez por combate, ganha +1 em qualquer teste de Resistência ou Reflexo até o final do turno.",
			},
			{
				nome = "Fluxo Harmônico",
				efeito = "Vantagem em testes de Percepção, Furtividade e Sobrevivência em ambientes naturais. Pode neutralizar/acalmar criaturas agressivas (teste de Carisma vs Sabedoria da criatura, 1x/missão).",
			},
			{
				nome = "Expiração Vital",
				efeito = "Vantagem em testes de resistência física contra venenos, toxinas e doenças.",
			},
		},
		fonte = "[5, 6]",
		categoria = "Modificados e Fantasia",
	},
	{
		nome = "Meio-Orcs",
		descricao = "Guerreiros robustos.",
		aumento_atributo = {
			FOR = 1,
			CON = 1,
		},
		caracteristicas = {
			{
				nome = "Visão na Penumbra",
				efeito = "Enxerga na penumbra a até 18m no escuro.",
			},
			{
				nome = "Resistência Implacável",
				efeito = "Quando reduzido a 0 pontos de vida sem morrer completamente, pode voltar para 1 ponto de vida. Utilizável um número de vezes por dia igual à sua proficiência.",
			},
		},
		fonte = "[5, 6]",
		categoria = "Modificados e Fantasia",
	},
	{
		nome = "Anões",
		descricao = "Robustos.",
		aumento_atributo = {
			CON = 2,
		},
		caracteristicas = {
			{
				nome = "Visão na Penumbra",
				efeito = "Enxerga na penumbra a até 18m no escuro.",
			},
			{
				nome = "Deslocamento",
				efeito = "7,5m.",
			},
		},
		opcoes_caracteristica = {
			{
				nome = "Resiliência Anã",
				efeito = "Vantagem em testes de resistência contra toxinas e venenos, e resistência contra efeitos de fadiga ou envenenamento por aura.",
			},
			{
				nome = "Estabilidade de Aura",
				efeito = "Redução de 10% no custo para manter técnicas passivas (Ten constante, Gyo prolongado — gasto mínimo de 5%).",
			},
			{
				nome = "Instinto de Forja",
				efeito = "+2 em testes relacionados à criação, manutenção ou modificação de equipamentos (mesmo por meio de Hatsu). Identifica o equilíbrio de aura em objetos sem precisar de Gyo.",
			},
		},
		fonte = "[7]",
		categoria = "Modificados e Fantasia",
	},
	{
		nome = "Draconatos",
		descricao = "Herança dragão.",
		aumento_atributo = "Escolha +2",
		caracteristicas = {
			{
				nome = "Resistência Ancestral",
				efeito = "Resistência ao elemento ligado à cor do seu ancestral dracônico (ver tabela do manual: Azul/Bronze/Cobre-Elétrico ou Ácido, Branco-Frio, Latão/Ouro/Vermelho-Fogo, Negro-Ácido, Prata-Elétrico, Verde-Veneno).",
			},
			{
				nome = "Arma de Sopro",
				efeito = "Ação Principal: ataque em área, TR = 10 + CON + Proficiência. Dano 2d6 num fracasso (metade num sucesso); 3d6 no 6º nível; 4d6 no 11º nível. Formato e atributo do TR variam pela cor do ancestral (linha 1,5m/9m com TR de DES, ou cone de 4,5m com TR de DES/CON).",
			},
		},
		fonte = "[7]",
		categoria = "Modificados e Fantasia",
	},
	{
		nome = "Halflings",
		descricao = "Pequenos e sortudos.",
		aumento_atributo = {
			DES = 1,
			INT = 2,
		},
		caracteristicas = {
			{
				nome = "Tamanho Pequeno",
				efeito = "Deslocamento de 7,5m.",
			},
		},
		opcoes_caracteristica = {
			{
				nome = "Sortudo",
				efeito = "Quando obtiver um 1 natural em uma jogada de ataque, teste de habilidade ou teste de resistência, pode rolar novamente e deve usar o novo resultado (1x por dia/sessão).",
			},
			{
				nome = "Bravura",
				efeito = "Vantagem em testes de resistência contra ficar Amedrontado/Intimidado.",
			},
			{
				nome = "Agilidade Halfling",
				efeito = "Pode mover-se através do espaço de qualquer criatura de tamanho maior que o seu.",
			},
		},
		fonte = "Extra",
		categoria = "Modificados e Fantasia",
	},
	{
		nome = "Gnomos",
		descricao = "Inventores.",
		aumento_atributo = "Escolha +2",
		caracteristicas = {
			{
				nome = "Tamanho Pequeno",
				efeito = "Deslocamento de 7,5m.",
			},
			{
				nome = "Visão na Penumbra",
				efeito = "Enxerga na penumbra a até 18m no escuro.",
			},
		},
		opcoes_caracteristica = {
			{
				nome = "Percepção Pequenina",
				efeito = "Vantagem em testes de Percepção e Análise de Aura.",
			},
			{
				nome = "Esperteza Gnômica",
				efeito = "Vantagem em todos os testes de resistência de Inteligência, Sabedoria e Carisma contra Hatsu.",
			},
			{
				nome = "Tamanho ao Meu Favor",
				efeito = "+2 em testes de Esquiva; -1 em testes de Força física pura (empurrar, puxar ou levantar algo pesado).",
			},
		},
		fonte = "Extra",
		categoria = "Modificados e Fantasia",
	},
	{
		nome = "Golias",
		descricao = "Gigantes de pedra.",
		aumento_atributo = "Escolha +2",
		caracteristicas = {
			{
				nome = "Tamanho Médio",
				efeito = "Deslocamento de 9m.",
			},
		},
		opcoes_caracteristica = {
			{
				nome = "Resistência de Pedra",
				efeito = "Após receber um dano, reduz à metade o dano de impacto, perfurante ou cortante recebido — um número de vezes por dia igual à sua proficiência.",
			},
			{
				nome = "Alvo Destroçado",
				efeito = "Usa FOR em vez de DES para calcular a precisão em ataques de arremesso manual com armas.",
			},
			{
				nome = "Corpo de Pedra",
				efeito = "Vantagem em testes de resistência contra fadiga, frio e calor.",
			},
		},
		fonte = "Extra",
		categoria = "Modificados e Fantasia",
	},
	{
		nome = "Neans",
		descricao = "Andróides.",
		aumento_atributo = "Varia",
		caracteristicas = {
			{
				nome = "Tamanho e Deslocamento",
				efeito = "Tamanho de Miúdo até Grande. Deslocamento igual a 2 tipos diferentes de movimento, dependendo de sua \"programação\".",
			},
			{
				nome = "Atualização de Disco Rígido",
				efeito = "Pode alterar no início de cada dia os pontos de atributo que recebe, enquanto reavalia e limpa dados de seu \"núcleo-processador e disco rígido\" na medida que evolui.",
			},
			{
				nome = "Curto Circuito",
				efeito = "Não fica exausto biologicamente, mas recebe a mesma condição ao entrar em curto-circuito por dano elétrico.",
			},
		},
		fonte = "[8, 9]",
		categoria = "Tecnológicos e Sobrenaturais",
	},
	{
		nome = "Vampiros",
		descricao = "Seres noturnos.",
		aumento_atributo = {
			INT = 2,
			["Físico"] = 1,
		},
		caracteristicas = {
			{
				nome = "Tamanho e Deslocamento",
				efeito = "Tamanho Médio. Deslocamento de 9m comum e 3m planar (aumenta em 3m para cada casta que sobe: Vampiro, Lorde Vampiro, Conde Vampiro, Imperador Vampiro).",
			},
			{
				nome = "Sugar Aura",
				efeito = "Após um ataque de mordida bem-sucedido, pode gastar a Ação Bônus para o alvo rolar um TR de CON (CD = 10 + CON + Prof. do vampiro). Se falhar, o vampiro rouba 10% da aura dele, +10% para cada 5 pontos de diferença na falha.",
			},
			{
				nome = "Exposição Solar",
				efeito = "Após 2 rodadas sob a luz do sol, sofre -5 na CA até sair do contato com a luz. Aparições durante o dia em locais protegidos aplicam só -2 na CA.",
			},
		},
		fonte = "[8, 9]",
		categoria = "Tecnológicos e Sobrenaturais",
	},
	{
		nome = "Djins",
		descricao = "Nen Post-Mortem.",
		aumento_atributo = "Escolha +2",
		caracteristicas = {
			{
				nome = "Interpretação Travessa/Trapaceira",
				efeito = "Uma vez por dia/cena/missão/semana, usuários de NEN podem rolar um dado aleatório entre a quantidade de suas Restrições/Condições para ignorar a que for sorteada naquela ativação. Regra geral: a duração do Hatsu escolhido precisa ser \"Instantânea\"; para os demais critérios, consulte seu mestre após a definição completa do Hatsu.",
			},
		},
		fonte = "Extra",
		categoria = "Tecnológicos e Sobrenaturais",
	},
	{
		nome = "Bugbears",
		descricao = "Brutais.",
		aumento_atributo = {
			FOR = 2,
			DES = 1,
		},
		caracteristicas = {
			{
				nome = "Visão no Escuro",
				efeito = "Enxerga na penumbra a até 18m como se fosse luz plena, e no escuro como se fosse penumbra.",
			},
		},
		opcoes_caracteristica = {
			{
				nome = "Ataque Surpresa",
				efeito = "Ao surpreender um alvo e acertá-lo no primeiro ataque do combate, causa 2d6 de dano extra e ataca com vantagem (por estar em furtividade). Só uma vez por alvo combatido.",
			},
			{
				nome = "Instinto Adaptativo",
				efeito = "Após três rodadas lutando contra o mesmo oponente, ganha +1 de acerto contra aquele alvo específico.",
			},
			{
				nome = "Percepção Instintiva",
				efeito = "Uma vez por combate, ao ser alvo de um ataque surpresa (ou de uma técnica oculta de Nen), pode reagir automaticamente gastando 2 reações em vez de precisar de 1 disponível normalmente.",
			},
			{
				nome = "Pressão de Predador",
				efeito = "Ao ativar Ren, causa um efeito intimidador mesmo sem querer: teste contestado de Intimidação com vantagem para o Bugbear; se o alvo falhar, fica intimidado até o final da rodada (contra animais/iniciantes pode causar Amedrontado). Usável um número de vezes por dia igual à proficiência.",
			},
		},
		fonte = "Extra",
		categoria = "Raças Incomuns",
	},
	{
		nome = "Dahllans",
		descricao = "Meio-Dríades.",
		aumento_atributo = {
			SAB = 4,
			INT = -1,
			PRE = -1,
		},
		caracteristicas = {
			{
				nome = "Visão no Escuro",
				efeito = "Enxerga na penumbra a até 18m como se fosse luz plena, e no escuro como se fosse penumbra.",
			},
		},
		opcoes_caracteristica = {
			{
				nome = "Empatia Natural",
				efeito = "Testes sociais de Persuasão e Intuição recebem +1 contra seres conscientes. Sente emoções superficiais de seres vivos tocados ou em interação direta, desde que não estejam em Zetsu total — uma forma primitiva de leitura emocional, sem invadir a mente.",
			},
			{
				nome = "Dr. Dolittle",
				efeito = "Capaz de entender e falar com animais, podendo conversar, pedir informações ou apenas irritá-los. Insetos, animais terrestres, marinhos e bestas mágicas se encaixam, desde que possuam INT acima de 0.",
			},
		},
		fonte = "Extra",
		categoria = "Raças Incomuns",
	},
	{
		nome = "Firbolgs",
		descricao = "Guardiões.",
		aumento_atributo = {
			SAB = 2,
			FOR = 1,
		},
		caracteristicas = {
			{
				nome = "Passo Oculto",
				efeito = "Em ambiente de natureza (florestas e afins), pode usar Ação Bônus + movimento para se \"transportar\" de uma árvore/arbusto a outra sem ser percebido, em até 12m. Usável por dia um número de vezes igual ao modificador de Sabedoria.",
			},
		},
		fonte = "Extra",
		categoria = "Raças Incomuns",
	},
	{
		nome = "Goblins",
		descricao = "Maliciosos.",
		aumento_atributo = "Escolha +2",
		caracteristicas = {
			{
				nome = "Visão no Escuro",
				efeito = "Enxerga na penumbra a até 9m como se fosse luz plena, e no escuro como se fosse penumbra.",
			},
			{
				nome = "Fúria do Pequeno (Nanico)",
				efeito = "Ao causar dano a uma criatura maior que você (ataque ou Hatsu), pode causar dano adicional igual à sua proficiência somada ao seu nível de personagem. Após usar, só pode usar de novo após terminar um descanso.",
			},
		},
		fonte = "Extra",
		categoria = "Raças Incomuns",
	},
}

-- Indice por nome, pra busca rapida (mesmo padrao do MonsterDB/
-- CombatInclinationsDB/ItemsDB.FindItem)
local porNome = {}
for _, r in ipairs(RacasDB) do
	porNome[r.nome] = r
end

local RacasDBModule = { Racas = RacasDB }

function RacasDBModule.FindByNome(nome)
	return porNome[nome]
end

return RacasDBModule
