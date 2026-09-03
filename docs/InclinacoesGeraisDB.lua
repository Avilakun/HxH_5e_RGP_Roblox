-- InclinacoesGeraisDB.lua -- gerado automaticamente a partir de
-- config.js (chave "inclinacoes") do webapp (github.com/Criadores-
-- HxH-5e/Ficha_HxH5e).
--
-- ⚠️ NOMENCLATURA CORRIGIDA (o Lucas apontou que eu tinha misturado
-- os termos na primeira versao deste arquivo): "Vantagem/Desvantagem"
-- no HxH5e e uma MECANICA DE ROLAGEM (aplica +1 dado de beneficio ou
-- prejuizo numa jogada) -- NAO E ISSO que este arquivo contem. O nome
-- correto pra essas listas e "Inclinacoes" (positivas e negativas):
-- tracos de personagem comprados com pontos na criacao, sem nenhuma
-- relacao com a mecanica de rolagem de dado extra.
--
-- NAO CONFUNDIR com CombatInclinationsDB.lua (que ja existe, veio de
-- um arquivo JS separado, combat-inclinations-db.js) -- aquele e um
-- sistema diferente, de trilhas de combate com 3 tiers cada. Este
-- aqui e o outro tipo de "inclinacao": tracos gerais de personagem
-- (nao especificos de combate), com efeito unico cada uma.
--
-- .positivas (27): cada uma com um "custo" em pontos pra comprar.
-- .negativas (42): cada uma com um "valor" em pontos que o jogador
--   GANHA de volta pra gastar nas positivas (convencao inversa --
--   valor alto = inclinacao negativa mais grave).
--
-- hasOptions=true + options={...}: a inclinacao tem variantes
-- escolhiveis (cada uma com seu proprio label/custo-valor/desc), em
-- vez de um efeito unico fixo.
local InclinacoesGeraisDB = {
	positivas = {
		{
			nome = "Aliado",
			custo = 1,
			desc = "O personagem possui um velho amigo que pode lhe oferecer ajuda, informações e abrigo caso esteja próximo de sua residência.",
		},
		{
			nome = "Contatos",
			custo = 1,
			desc = "Você tem um associado que lhe fornece informações úteis ou faz pequenos favores.",
			hasOptions = true,
			options = {
				{
					label = "Informação rápida",
					custo = 1,
					desc = "Recebe uma informação sobre a dúvida em até 24 horas por $500.",
				},
				{
					label = "Informação de confiança",
					custo = 2,
					desc = "Recebe todas as informações disponíveis, explicando quais se podem confiar ($2000).",
				},
				{
					label = "Informação barata",
					custo = 1,
					desc = "Diminui o custo da informação rápida de $500 para até $100.",
				},
			},
		},
		{
			nome = "Corpo de Gigante",
			custo = 5,
			desc = "Você é enorme e por isso tem um nível a mais de vitalidade. +5 HP inicial e +3 por nível. O usuário tem que ficar com altura acima de 2,10m e não consegue utilizar armas leves e pequenas sem depender de uma técnica.",
		},
		{
			nome = "Empatia com Animais",
			custo = 1,
			desc = "Você é talentoso em entender o comportamento dos animais. Superando um teste de INT = 10 você compreende o estado emocional do animal - amigável, assustado, hostil, faminto, etc.",
		},
		{
			nome = "Fôlego",
			custo = 2,
			desc = "Dificilmente alguém terá sucesso te asfixiando ou afogando. Você consegue prender a respiração por 5-7 minutos fazendo esforço e 10-15 apenas nadando de forma despretensiosa ou se concentrando.",
		},
		{
			nome = "Inventor",
			custo = 1,
			desc = "Modifica equipamentos ou cria novos. Selecione os benefícios:",
			hasOptions = true,
			options = {
				{
					label = "Propriedade de Dano",
					custo = 1,
					desc = "Dão até 1d8 de dano natural de qualquer propriedade (max. 3 propriedades).",
				},
				{
					label = "Alcance/Alvos",
					custo = 1,
					desc = "Atingem até 2 alvos.",
				},
				{
					label = "Compacto",
					custo = 1,
					desc = "Diminuem até 4 de espaço/peso.",
				},
				{
					label = "Defensivo",
					custo = 1,
					desc = "Aumentam até 2 de CA.",
				},
			},
		},
		{
			nome = "Ligação com a Máfia",
			custo = 3,
			desc = "O personagem tem certa influência com alguma família mafiosa e poderá pedir alguns favores, mas cuidado, é bom não exagerar, pois eles normalmente pedem favores em troca.",
		},
		{
			nome = "Sentidos Aguçados",
			custo = 1,
			desc = "Seus sentidos são mais desenvolvidos (+2 em testes específicos).",
			hasOptions = true,
			options = {
				{
					label = "Audição Aguçada",
					custo = 1,
					desc = "+2 para escutar ou reparar sons incomuns (ex: engatilhar arma no escuro).",
				},
				{
					label = "Paladar e Olfato",
					custo = 1,
					desc = "+2 para reparar gosto/cheiro. Bônus passivo antes de ingerir (evita veneno).",
				},
				{
					label = "Tato Aguçado",
					custo = 1,
					desc = "+2 em detectar pelo toque ou Prestidigitação (ex: revistar suspeito).",
				},
				{
					label = "Visão Aguçada",
					custo = 1,
					desc = "+2 em localizar visualmente, procurar armadilhas ou pegadas.",
				},
			},
		},
		{
			nome = "Sorte Grande",
			custo = 3,
			desc = "Você pode re-rolar 1 dado por sessão ficando com o maior resultado.",
		},
		{
			nome = "Tempo de Vida Estendido (Anomalia)",
			custo = 3,
			desc = "Independente de que raça pertença, você é uma anomalia. Seu ciclo de vida se estende em uma margem de 20 anos a mais em todos os períodos de desenvolvimento após a infância.",
		},
		{
			nome = "Visão no Escuro",
			custo = 2,
			desc = "Você pode ver 9m no escuro como se fosse dia e não sofre penalidades de escuridão que não conte como bloqueio ou aplique cegueira.",
		},
		{
			nome = "Ambidestria",
			custo = 2,
			desc = "Você luta com ambas as mãos com a mesma precisão e potência. Escolha um dos benefícios:",
			hasOptions = true,
			options = {
				{
					label = "Habilidoso em Combate Ágil",
					custo = 3,
					desc = "Ao empunhar armas leves em ambas as mãos, realize um ataque com Ação Bônus somando seu modificador no dano de ambos os ataques.",
				},
				{
					label = "Habilidoso em Combate Bruto",
					custo = 3,
					desc = "Pode usar qualquer arma sem a propriedade 'Duas Mãos' uma em cada mão como se fosse leve (só ataca com as duas no mesmo turno com Atributo Evoluído ou ataque extra).",
				},
				{
					label = "Habilidoso em Inventário",
					custo = 2,
					desc = "Pega e usa um item, ou troca de equipamento, usando a Ação Bônus.",
				},
				{
					label = "Cirurgião/Malabarista",
					custo = 2,
					desc = "+4 em Prestidigitação ou testes de precisão manual que não sejam ataques.",
				},
			},
		},
		{
			nome = "Apropriação Natural/Elemental",
			custo = 3,
			desc = "Pré-requisito: Categoria de Transmutação. Escolha um tipo de dano da tabela de forças da natureza igual ao elemento do seu Hatsu. Fica imune a esse tipo de dano e pode tratar 1 dado de dano como valor máximo ao rolar uma habilidade de transmutação elemental com esse elemento.",
		},
		{
			nome = "Aura Gigantesca",
			custo = 6,
			desc = "Dotado de um dom invejável, você possui muito mais aura que pessoas comuns. +30% de Aura máxima.",
		},
		{
			nome = "Boa Forma",
			custo = 2,
			desc = "Seu sistema ósseo e muscular é melhor que o normal. Pode ser escolhida de novo no futuro (quando não repetir a mesma opção).",
			hasOptions = true,
			options = {
				{
					label = "Boa Flexibilidade",
					custo = 2,
					desc = "+2 em testes de Escalada, testes de Fuga para se livrar de amarras e em tentativas de se libertar em combate corpo a corpo.",
				},
				{
					label = "Ultra Flexibilidade",
					custo = 4,
					desc = "Boa Flexibilidade aprimorada — o bônus passa a ser +4.",
				},
			},
		},
		{
			nome = "Destemido",
			custo = 2,
			desc = "Difícil de assustar ou intimidar. Vantagem em testes contra Intimidação (CAR ou FOR). Quando é mesmo assustado, sofre 2 de Estresse (dano psíquico) na Sanidade.",
		},
		{
			nome = "Disparo de Aura",
			custo = 3,
			desc = "Passivo para Emissores. Pré-requisito: 80% de assimilação com Emissão (Reforço ou Manipulação). Pode desprender aura pura do corpo em formato de ataque aplicando REN sem precisar de uma arma (5% de aura = 1d6), e atacar à distância com aura ignorando meia ou três-quartos de cobertura.",
		},
		{
			nome = "Especialista",
			custo = 2,
			desc = "Escolha até 2 assuntos (nichados) — dobra a proficiência em testes relacionados a eles.",
		},
		{
			nome = "Explorador",
			custo = 2,
			desc = "Vantagem em testes de Sabedoria (Percepção) e Inteligência (Investigação) para detectar passagens/mecanismos secretos, e vantagem em TRs para evitar ou resistir a armadilhas ao explorar.",
		},
		{
			nome = "Habitat Natural",
			custo = 1,
			desc = "Informe ao mestre um tipo de terreno e condição climática — sempre que estiver nesse ambiente, recebe um bônus em testes correspondente (ex: Ártico = +5 de resistência contra frio).",
		},
		{
			nome = "Imponência Assustadora",
			custo = 3,
			desc = "Aparência e postura ameaçadoras concedem +3 em iniciativa e em testes de Intimidação.",
		},
		{
			nome = "Memória Excepcional",
			custo = 1,
			desc = "Você se recorda com detalhes de situações e informações. Escolha uma alternativa:",
			hasOptions = true,
			options = {
				{
					label = "Memória Excepcional",
					custo = 1,
					desc = "Lembra automaticamente de tudo que concentrar atenção; recorda detalhes específicos com teste de INT = 10.",
				},
				{
					label = "Memória Fotográfica",
					custo = 3,
					desc = "Como acima, mas também recorda detalhes específicos sempre — o mestre/jogadores devem lembrá-lo como se estivesse tudo anotado ou gravado.",
				},
			},
		},
		{
			nome = "Noção do Perigo",
			custo = 4,
			desc = "O mestre faz, em segredo, um teste contra sua Percepção Passiva sempre que houver emboscada, armadilha ou perigo iminente; um sucesso avisa você a tempo de agir. Além disso, Percepção Passiva e Reações aumentam em 3.",
		},
		{
			nome = "Palpite de Instinto",
			custo = 3,
			desc = "Percebe as intenções de quem conversa com você — se é boa/má ou fala verdade. +5 em testes de Intuição ou de CAR contra ser Enganado.",
		},
		{
			nome = "Pulo do Gato",
			custo = 3,
			desc = "Subtrai automaticamente 5m de uma queda (trata como sucesso automático em Acrobacia para quedas simples) e reduz à metade o dano de quedas, desde que não esteja Agarrado/Preso, Atordoado/Incapacitado, Cego, Impedido, Inconsciente ou Paralisado.",
		},
		{
			nome = "Resistência a Venenos",
			custo = 2,
			desc = "Anticorpos poderosos contra qualquer veneno não produzido por aura — +10 em testes de CON contra venenos.",
		},
		{
			nome = "Tempo de Vida Estendido por Zetsu",
			custo = 3,
			desc = "Requisito: Zetsu Intermediário. Seu ciclo de vida se estende em 50 anos a mais em todos os períodos após a infância (70 anos se combinada com Tempo de Vida Estendido por Anomalia).",
		},
	},
	negativas = {
		{
			nome = "Avareza",
			valor = 2,
			desc = "Você fica preocupado demais em conservar sua riqueza. Você deverá procurar sempre o melhor negócio. Faça um teste de autocontrole (SAB/INT ou CAR) toda vez que tiver que gastar algum dinheiro.",
		},
		{
			nome = "Azar Grande",
			valor = 3,
			desc = "Você DEVE re-rolar seu primeiro acerto crítico no d20 da sessão.",
		},
		{
			nome = "Desatencioso",
			valor = 1,
			desc = "Você consegue entender as emoções dos outros, mas não as suas intenções. Isto faz de você desajeitado em situações envolvendo manipulação social. Você é o clássico 'nerd' e sofre -1 para usar ou resistir a Testes de Influência.",
		},
		{
			nome = "Dívida",
			valor = 3,
			desc = "Você deve um favor a alguém que te ajudou em um momento de dificuldade. Essa pessoa poderá te cobrar esse favor a qualquer momento e poderá ser qualquer coisa.",
		},
		{
			nome = "Esquecido",
			valor = 1,
			desc = "Você tem dificuldade de se recordar de nomes, lugares, aparências e informações. É bem comum causar confusão por isso.",
		},
		{
			nome = "Honestidade",
			valor = 2,
			desc = "Você precisa obedecer a lei sempre e dar o melhor de si para que os outros também o façam. Você assumirá também que os outros são honestos até saber o contrário.",
		},
		{
			nome = "Indeciso",
			valor = 5,
			desc = "Você tem muita dificuldade para se decidir, recebendo -3 em rolagens de iniciativa. Além disso, sempre que se deparar com uma escolha, faça um teste simples de INT ou CAR CD 15.",
		},
		{
			nome = "Inimigo",
			valor = 1,
			desc = "Alguém ou algo que ativamente tenta te prejudicar.",
			hasOptions = true,
			options = {
				{
					label = "Fraco",
					valor = 1,
					desc = "Inimigo chato, objetivos estúpidos, aparece para atrapalhar (Ex: Equipe Rocket).",
				},
				{
					label = "Rival",
					valor = 2,
					desc = "Inimigo mediano, mesmos objetivos que você, fará de tudo para atrapalhar inclusive lutar.",
				},
				{
					label = "Poderoso",
					valor = 5,
					desc = "Chefão maligno. Te caça para recrutar ou matar sem piedade.",
				},
			},
		},
		{
			nome = "Inveja",
			valor = 1,
			desc = "Você tem uma reação muito ruim frente a qualquer um que pareça mais inteligente, mais atraente, poderoso ou em melhor situação do que a sua!",
		},
		{
			nome = "Perda Auditiva",
			valor = 1,
			desc = "Você não é surdo, mas perdeu uma parte da audição e sofrerá um redutor de -3 em qualquer teste de Audição.",
		},
		{
			nome = "Veracidade",
			valor = 2,
			desc = "Você odeia dizer uma mentira ou o faz muito mal. Ter que mentir pode fazer literalmente você ficar enjoado ou com peso na consciência (Condição Envenenado ou -5 Sanidade).",
		},
		{
			nome = "Aleijado",
			valor = 3,
			desc = "Perna ruim ou ausente. -2 em qualquer perícia que exija o uso das pernas (incluindo Armas de Mão e combate desarmado, exceto combate à distância). Deslocamento Básico reduzido à metade.",
		},
		{
			nome = "Anosmia/Ageusia",
			valor = 1,
			desc = "Não sente cheiro nem sabor de nada — não detecta certos perigos que outros perceberiam, e falha automaticamente em detectar gases nocivos (mas nunca é afetado por mau odor, e não tem problema em comer qualquer coisa — o que não te dá imunidade a venenos).",
		},
		{
			nome = "Azar Perseguidor",
			valor = 6,
			desc = "Você é simplesmente azarado. Uma vez por sessão, o mestre usa uma 'Ação Protagonista' (1 d20 extra ou 3d6) para fazer algo dar errado com você — nunca o suficiente para matá-lo de imediato.",
		},
		{
			nome = "Baixa Destreza Manual ou Consciência Corporal",
			valor = 1,
			desc = "Coordenação motora ruim: -2 em qualquer teste baseado em DES (aplicado no resultado final, não causa Atributo Penalizado).",
		},
		{
			nome = "Caolho ou Estrábico",
			valor = 2,
			desc = "Tem apenas um olho, ou os dois não são confiáveis. -2 em armas de acuidade/à distância e em testes de percepção ou investigação baseados em visão.",
		},
		{
			nome = "Cegueira",
			valor = 3,
			desc = "Perdeu a visão em algum acidente ou nasceu sem ela. Escolha um nível:",
			hasOptions = true,
			options = {
				{
					label = "Miopia/Astigmatismo",
					valor = 3,
					desc = "50% de perda de visão — reconhece pessoas a 1,5m; ataques à distância com desvantagem.",
				},
				{
					label = "Glaucoma",
					valor = 4,
					desc = "80% de perda de visão — vê apenas vultos e localização, sem distinguir o que é cada um.",
				},
				{
					label = "Condição Cego",
					valor = 5,
					desc = "Cegueira total — aplica a condição Cego permanentemente.",
				},
			},
		},
		{
			nome = "Covardia",
			valor = 3,
			desc = "(Loucura Permanente) Requisito: CAR menor que 15. Diante de perigo, tenta fugir a menos que passe em um teste de coragem/vontade (INT/SAB/CAR, a critério do mestre). -3 em testes para resistir Intimidação.",
		},
		{
			nome = "Código de Honra",
			valor = 1,
			desc = "Segue um conjunto de princípios 'honrosos' o tempo todo, mesmo sob risco de morte. Quebrar o código escolhido causa 5 de Estresse (dano psíquico) na Sanidade. Escolha um:",
			hasOptions = true,
			options = {
				{
					label = "Simples",
					valor = 1,
					desc = "Sempre se vingar de um insulto; o inimigo de um companheiro é seu inimigo; nunca atacar um companheiro fora de um duelo justo.",
				},
				{
					label = "Cavalheiro",
					valor = 2,
					desc = "Nunca faltar com a palavra ou ignorar um insulto a você/sua fé/seus amados; nunca tirar vantagem desleal de um oponente.",
				},
				{
					label = "Soldado",
					valor = 3,
					desc = "Lutar e morrer pela honra da tropa; seguir ordens e regras de guerra; tratar inimigos honrosos com respeito.",
				},
			},
		},
		{
			nome = "Cleptomania",
			valor = 2,
			desc = "(Loucura Permanente) Compelido a roubar qualquer coisa que possa levar. Ao ter a chance, teste de autocontrole (CAR CD 15) — se falhar, deve roubar; se o furto falhar, sofre 5 de Estresse na Sanidade (recupera 2 ao furtar com sucesso depois).",
		},
		{
			nome = "Desinteresse",
			valor = 2,
			desc = "(Loucura Permanente) Requisito: INT menor que 15. Dificilmente dá atenção a coisas fora do seu interesse. Teste de autocontrole (INT CD 15) diante de algo estranho/novo — se falhar, simplesmente ignora.",
		},
		{
			nome = "Desvio de Atenção",
			valor = 3,
			desc = "(Loucura Permanente) Requisito: SAB menor que 15. Dificuldade de concentração prolongada — não pode repetir o mesmo teste mais de 3 vezes no mesmo dia sobre a mesma tarefa, e falha automaticamente em testes de provocação ao ser distraído.",
		},
		{
			nome = "Dupla Personalidade",
			valor = 4,
			desc = "Você tem outra personalidade com os mesmos Dado de Vida e Raça, mas atributos/características distintos, que surge ao tirar 1 num dado. Você não controla quando ocorre a mudança, e uma personalidade não lembra o que a outra fez.",
		},
		{
			nome = "Espírito de Lutador",
			valor = 3,
			desc = "Jamais desperdiça a chance de enfrentar alguém mais forte para provar que é o melhor — mesmo já tendo perdido várias vezes por esse impulso.",
		},
		{
			nome = "Excesso de Confiança",
			valor = 3,
			desc = "Requisito: um atributo maior que 18. Acredita ser mais poderoso, inteligente ou competente do que realmente é, e precisa representar isso mesmo quando é perigoso.",
		},
		{
			nome = "Fantasia",
			valor = 1,
			desc = "Crê fielmente em algo que só você acredita (uma 'verdade' criada por você mesmo). -3 em Intimidação e Persuasão contra quem já foi exposto à sua fantasia; deve interpretá-la ao menos 1x a cada 2 sessões.",
		},
		{
			nome = "Impulsividade",
			valor = 3,
			desc = "(Loucura Permanente) Requisito: INT ou SAB menor que 15. Age primeiro e pensa depois. Teste de autocontrole (INT ou SAB CD 15) quando seria melhor esperar — se falhar, age; se impedido de agir, sofre Estresse na Sanidade por rodada.",
		},
		{
			nome = "Instinto Assassino",
			valor = 4,
			desc = "(Loucura Permanente) Precisa matar alguém/algum animal a cada dois dias, ou entra em abstinência com -2 em tudo (dobra por dia adicional sem matar). Pode pegar Código de Honra de graça para simular ser um bom cidadão.",
		},
		{
			nome = "Legião de Inimigos",
			valor = 6,
			desc = "Um grupo, facção ou corporação caça você por motivos diversos (ex: uma máfia por ter matado o filho de um chefe de família).",
		},
		{
			nome = "Maneta (Braço)",
			valor = 4,
			desc = "Só tem um braço — não pode usar armas de duas mãos nem empunhar duas armas/escudo. -4 em tarefas normalmente feitas com dois braços (ex: Escalada, Luta Livre); sem redutor em tarefas de uma mão só.",
		},
		{
			nome = "Megalomania",
			valor = 5,
			desc = "(Loucura Permanente) Crê ser destinado a grandes coisas. Escolha um objetivo grandioso — enquanto não o concluir, tem apenas metade dos pontos de Sanidade totais.",
		},
		{
			nome = "Mente de Criança",
			valor = 2,
			desc = "(Loucura Permanente) Requisito: não ter antecedente Cientista/Especialista, Criminoso, Líder, Mentalista ou Negociante; não iniciar com tendência Maligna. Ainda tem inocência de criança e é mais facilmente enganado — -5 em testes de Intuição.",
		},
		{
			nome = "Mudez/Surdez",
			valor = 4,
			desc = "Não pode falar ou ouvir. -3 em testes de Carisma; precisa de Prestidigitação (Libras) para passar mensagens a quem não conhece a linguagem de sinais.",
		},
		{
			nome = "Nanismo",
			valor = 2,
			desc = "Não se beneficia do movimento concedido por Atletismo e recebe -1 em iniciativa.",
		},
		{
			nome = "No Limite/Borderliner",
			valor = 3,
			desc = "(Loucura Permanente) Corre riscos absurdamente irracionais diante de perigo mortal e não pode fugir do desafio, ainda que pareça loucura para quem observa.",
		},
		{
			nome = "Paranoia",
			valor = 5,
			desc = "(Loucura Permanente) Perdeu contato com a realidade — acredita que todos conspiram contra você e nunca confia em ninguém (nem em velhos amigos). Por não conseguir aquietar a mente, Zetsu recupera 5% menos aura em qualquer nível.",
		},
		{
			nome = "Paraplégico",
			valor = 6,
			desc = "Não se beneficia do movimento de Atletismo e recebe -5 em iniciativa. Falha automaticamente em TRs de esquiva contra impacto no chão/pernas, é considerado caído em combate, e o movimento total é reduzido a 3m.",
		},
		{
			nome = "Pesadelos",
			valor = 3,
			desc = "(Loucura Permanente) Atormentado todas as noites — o descanso longo recupera apenas metade dos recursos, e a eficiência de aura funciona de forma intermitente (a cada 2 usos).",
		},
		{
			nome = "Procurado",
			valor = 3,
			desc = "Requisito: não começar com tendência Heróico. Caçado por seus atos por mercenários; a recompensa cresce com sua fama/renome. Valor sugerido de 1 a 8 pontos — negocie com o mestre conforme o momento da escolha.",
		},
		{
			nome = "Teimosia",
			valor = 1,
			desc = "Sempre quer fazer as coisas do seu jeito — seus aliados podem precisar de vários testes de Persuasão para te convencer até de planos razoáveis.",
		},
		{
			nome = "Trapaceiro",
			valor = 3,
			desc = "Requisito: tendência Caótico ou Maligno, e INT ou DES maior que 15. Sente prazer em enganar pessoas perigosas (nunca as inofensivas). Falhar duas vezes com a mesma pessoa, ou perder uma boa chance de trapacear, causa -3 de Estresse na Sanidade.",
		},
		{
			nome = "Visões de Morte",
			valor = 5,
			desc = "(Loucura Permanente) Já esteve perto da morte — sempre que entra em combate, tem uma visão do oponente te matando. -10 em iniciativa; deve descrever essa visão em pensamento ou fala.",
		},
	},
}

-- Indice por nome (busca em ambas as listas), pra busca rapida
-- (mesmo padrao dos outros bancos de dados)
local porNome = {}
for _, v in ipairs(InclinacoesGeraisDB.positivas) do
	porNome[v.nome] = v
end
for _, v in ipairs(InclinacoesGeraisDB.negativas) do
	porNome[v.nome] = v
end

function InclinacoesGeraisDB.FindByNome(nome)
	return porNome[nome]
end

return InclinacoesGeraisDB
