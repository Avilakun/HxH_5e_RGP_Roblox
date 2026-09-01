-- HxH5e SystemDB (Shared)
-- Portado de js/data/config.js (SYSTEM_DB) do repo Criadores-HxH-5e/Ficha_HxH5e
-- via HTTP + parser JS->Lua rodado dentro do Studio.
-- v3: adicionadas inclinacoes (positivas/negativas).
-- Gerado automaticamente em 2026-08-28.

return {
	antecedentes = {
		{
			caracteristicas = {
				{
					efeito = "Animais e Feras (inclusive hostis) normalmente o consideram outra criatura não hostil. Seus companheiros são tratados como membros aliados do seu bando, desde que não atuem de forma hostil.",
					nome = "Habitat Natural",
				},
				{
					efeito = "De alguma forma você se acostumou com a linguagem de animais e feras. Ao passar um minuto interagindo com uma criatura não hostil você pode identificar alguma informação que ela já tenha conhecimento sobre o ambiente ou uma outra criatura.",
					nome = "Tarzan/Jane",
				},
				{
					efeito = "Você tem um companheiro que te concede a Ação 'Ajuda' no turno dele. Ele te entende e obedece comandos simples.",
					nome = "Companheiro Inabalável",
				},
			},
			descricao = "Pessoas que se importam com o equilíbrio da natureza, mas que também adoram um desafio, andam pelas florestas e pântanos buscando encontrar criaturas fantásticas e desconhecidas. Por outro lado, muitos amigos dos animais são simplesmente amados pela natureza como se fizessem parte dela.",
			equipamento = {
				"Qualquer arma simples",
				"Qualquer arma simples",
				"Kit de Caça e Rastreio de Criaturas ou Kit Médico",
			},
			nome = "Amigo dos Animais",
			proficiencias = "Escolha um Kit dentre os recebidos e Lidar com Animais e Natureza",
		},
		{
			caracteristicas = {
				{
					efeito = "Você é bem-vindo na alta sociedade e as pessoas assumem que você tem o direito de estar onde está. As pessoas comuns fazem todos os esforços para acomodá-lo e evitar seu desprazer.",
					nome = "Posição Privilegiada",
				},
				{
					efeito = "Você recebe toda semana uma quantia correspondente aos recursos financeiros de sua família de acordo com a tabela ao rolar 1d4.",
					nome = "Mauricinho / Patricinha",
				},
			},
			descricao = "Pessoas que entendem de riqueza, poder e privilégios. Mas não só entendem, elas desfrutam e estão acostumadas a isso. Através de algum título de nobreza, sua família exerce algum tipo de influência política significativa.",
			equipamento = {
				"Celular ou Câmera",
				"Computador",
				"Mochila 3 (Mala)",
				"Qualquer arma simples",
			},
			nome = "Aristocrata",
			proficiencias = "História e Religião",
		},
		{
			caracteristicas = {
				{
					efeito = "Comerciantes que negociam com você reconhecem seu trabalho como artista, você tem chance (50%) de pagar suas compras com merchandising.",
					nome = "Tudo no @",
				},
				{
					efeito = "Apresentar sua arte às pessoas antes de conversar ou negociar, faz com que fiquem fascinadas por você e tenham uma inclinação a concordar com sua opinião. Vantagem em testes de Carisma.",
					nome = "Virando a Cadeira",
				},
			},
			descricao = "Pessoas com as mais variadas capacidades de entretenimento se aventuram no mundo artístico para realizar seus sonhos vivendo daquilo que amam ou buscando alcançar fama e dinheiro.",
			equipamento = {
				"Mala de Roupas ou Mochila Comum/Maleta",
				"Câmera ou Celular",
				"Kit de Ferramentas de Ofício",
			},
			nome = "Artista",
			proficiencias = "Kit de Ferramenta de Ofício e escolha 3 dentre: Acrobacia, Atuação, Intuição ou Prestidigitação",
		},
		{
			caracteristicas = {
				{
					efeito = "Se concentrar em seu turno completo projeta um padrão hipnótico, fazendo com que todas as criaturas hostis tenham desvantagem em jogadas de ataque direcionadas a você.",
					nome = "Eco do Ritmo",
				},
				{
					efeito = "Vantagem em todos os testes de furtividade de qualquer natureza e não é descoberto ao realizar um ataque enquanto se está furtivo.",
					nome = "Sumidão",
				},
				{
					efeito = "Dano dobrado (nos dados) em ataques realizados enquanto se está oculto/furtivo.",
					nome = "Máquina de Matar",
				},
			},
			descricao = "Assassinos famosos como a família Zoldyck e ainda outros, desenvolvem habilidades próprias para sua profissão e, com isso, se tornam peritos naquilo que fazem. A arte de matar de forma rápida.",
			equipamento = {
				"Adaga/Faca",
				"Veneno Variante: 1 frasco",
				"Pochete de Perna",
				"Kit de disfarce ou Kit de Falsificação",
			},
			nome = "Assassino",
			proficiencias = "Escolha um Kit dentre os recebidos e Acrobacia e Furtividade",
		},
		{
			caracteristicas = {
				{
					efeito = "Vantagem em todos os testes relacionados a rastrear feras naturais e bestas mágicas (inclusive bestas de NEN).",
					nome = "Temos que Pegar!",
				},
				{
					efeito = "Você recebe +2 em sobrevivência e anula qualquer penalidade de sobrevivência não causadas por Hatsus.",
					nome = "Desbravador",
				},
			},
			descricao = "Nesse mundo existem diversas criaturas desconhecidas e hostis que se reproduzem nas sombras enquanto sobrepujam habitat naturais de outras criaturas.",
			equipamento = {
				"Espingarda Carregada ou Tazer",
				"Kit de Caça e Rastreio de Criaturas ou Kit Antídoto",
				"Qualquer arma simples ou Marcial e Rede",
			},
			nome = "Caçador de Feras",
			proficiencias = "Escolha um Kit dentre os recebidos e Natureza e Sobrevivência",
		},
		{
			caracteristicas = {
				{
					efeito = "O personagem pode utilizar sua ação principal para analisar o oponente ou situação tendo vantagem no próximo ataque contra um inimigo ou teste baseado em inteligência.",
					nome = "Explorar Fraqueza",
				},
				{
					efeito = "Ao utilizar um item / kit escolhido no antecedente, você ganha um 1d6 para rolar em qualquer jogada ou teste cabível 3 vezes por dia.",
					nome = "Mestre do Planejamento",
				},
			},
			descricao = "Após muito estudo e dedicação, começam a arriscar a vida também no campo experimental para comprovar suas teorias e hipóteses.",
			equipamento = {
				"Qualquer arma simples",
				"1 Mochila Comum/Maleta",
				"Kit Antídoto ou Kit Médico",
				"Kit de Armas ou Kit Forense ou Kit de Hacker",
			},
			nome = "Cientista",
			proficiencias = "Escolha 2 perícias com Kits e 3 dentre: História, Investigação, Medicina, Natureza, Prestidigitação, Religião ou Sobrevivência.",
		},
		{
			caracteristicas = {
				{
					efeito = "Inicia com celular roubado e kit de ferramentas de ofício.",
					nome = "Cleptomaníaco",
				},
				{
					efeito = "Acesso a kits de falsificação ou disfarce para golpes.",
					nome = "Estelionatário",
				},
				{
					efeito = "Possui informações privilegiadas (Pen-Drive) para manipular poder e influência.",
					nome = "Político Corrupto",
				},
				{
					efeito = "Inicia com recursos financeiros de vendas ilícitas e contatos de fornecedores.",
					nome = "Traficante",
				},
			},
			descricao = "Essas pessoas normalmente vivem à margem da lei, desprezando e quebrando os regulamentos da sociedade.",
			equipamento = {
				"Qualquer arma simples ou Marcial",
				"1 Pochete",
				"Item do Tipo de Criminoso (Cleptomaníaco, Estelionatário, etc)",
			},
			nome = "Criminoso",
			proficiencias = "Escolha um Kit dentre os recebidos e Enganação e Furtividade",
		},
		{
			caracteristicas = {
				{
					efeito = "Você consegue acessar alguns lugares ou pessoas e informações a partir da fama do seu mestre e da credibilidade que o nome lhe confere.",
					nome = "Abre-te Sésamo",
				},
				{
					efeito = "Seu mestre supostamente morreu ou desapareceu, porém ele lhe concedeu um ensinamento, poder, item, equipamento ou marca que te permite continuar sua história.",
					nome = "Mateus 28.18-20",
				},
			},
			descricao = "Uma pessoa que é orientada por um mestre e normalmente continua seguindo suas orientações. Dependendo do mestre o discípulo pode se desenvolver em áreas diferentes a partir de suas aptidões.",
			equipamento = {
				"Celular com contato ou anotações de seu mestre",
				"Qualquer arma simples ou Marcial",
				"Kit de Ferramentas de Ofício",
			},
			nome = "Discípulo",
			proficiencias = "Kit de Ferramenta de Ofício e Escolha 3 perícias quaisquer",
		},
		{
			caracteristicas = {
				{
					efeito = "Você treinou técnicas e desenvolveu seu corpo ao máximo para o combate corpo-a-corpo. Seus golpes desarmados causam 1d6 no lugar de 1d4.",
					nome = "Artista Marcial",
				},
				{
					efeito = "Você consegue escolher uma pessoa para manter sua atenção de forma constante. Você tem vantagem e +2 em jogadas de percepção para encontrar essa pessoa.",
					nome = "Horário de Trabalho",
				},
			},
			descricao = "Arduamente treinados para trabalhos físicos, guarda-costas podem ser pessoas dispostas a fazer um trabalho perigoso por dinheiro.",
			equipamento = {
				"Pistola",
				"Qualquer arma simples ou Marcial",
			},
			nome = "Guarda Costas",
			proficiencias = "Atletismo e Intimidação",
		},
		{
			caracteristicas = {
				{
					efeito = "Sua presença notável e inspiradora concede 1d4 (grau básico) que pode ser utilizado em qualquer jogada de seus aliados (cada um) até o fim do dia.",
					nome = "Presença de Liderança",
				},
			},
			descricao = "Você é uma pessoa que procura mudar a sociedade ao seu redor jogando na arena da política, pessoas e personalidades.",
			equipamento = {
				"1 pílula de Hemoglobina",
				"1 pílula de Hemoglobina variante",
				"Qualquer arma simples",
				"Qualquer outro Kit",
			},
			nome = "Líder",
			proficiencias = "Escolha três entre Enganação, História, Investigação ou Persuasão",
		},
		{
			caracteristicas = {
				{
					efeito = "Você não gasta passagem em navios, jatos, aviões e dirigíveis. Possui Documento de patente e Experiência de Convés.",
					nome = "Grande Herói da Marinha",
				},
				{
					efeito = "Buscando mais poder você ouviu falar de NEN. Possui Experiência de Convés, Pistola ou Mosquete, Arma simples ou Marcial e Relógio à prova d'água.",
					nome = "Imperador do Mar",
				},
			},
			descricao = "Você navegou em um navio pelo mar durante anos, enfrentando poderosas tormentas e monstros abissais.",
			equipamento = {
				"Corrente Pesada ou Rede",
				"Qualquer arma simples ou Marcial",
			},
			nome = "Marinheiro",
			proficiencias = "Atletismo e Percepção",
		},
		{
			caracteristicas = {
				{
					efeito = "+2 em testes de Percepção.",
					nome = "Perceptivo",
				},
				{
					efeito = "Possui vantagem em todos os testes de Carisma contra humanoides com inteligência igual ou superior a Modificador 0.",
					nome = "Referência Bibliográfica",
				},
			},
			descricao = "Conhecedores do funcionamento da mente, mentalistas são profissionais que trabalham com a realidade do pensamento ou com a ilusão.",
			equipamento = {
				"Qualquer arma simples",
				"Kit de Falsificação ou Kit de Ferramenta de Ofício",
			},
			nome = "Mentalista",
			proficiencias = "Escolha um Kit dentre os recebidos e Enganação ou Persuasão e Intuição",
		},
		{
			caracteristicas = {
				{
					efeito = "Quando vender qualquer item seu usado, você consegue vendê-lo com o custo oficial, desde que esteja funcional.",
					nome = "Camelô",
				},
				{
					efeito = "Você consegue comprar qualquer item com desconto de 30% do valor de mercado (exceto armas de fogo e itens místicos).",
					nome = "Pechincheiro",
				},
			},
			descricao = "Indivíduos acostumados a lidar com o público e, por isso, possuem facilidade na oratória e na persuasão.",
			equipamento = {
				"Qualquer equipamento dentro do orçamento de 2.000 $",
				"1 Mala de Roupas",
			},
			nome = "Negociante",
			proficiencias = "Atuação, Persuasão e Prestidigitação",
		},
		{
			caracteristicas = {
				{
					efeito = "Vantagem em testes de furtividade de qualquer natureza.",
					nome = "Furtividade Superior",
				},
				{
					efeito = "Cria um clone sólido. 5/5 PV, mesmas características sem NEN. Pode usar ação bônus para comandar clones.",
					nome = "Jutsu: Clone das Sombras",
				},
				{
					efeito = "Reação para fuga rápida com CA +5 e chance de aparecer em até 3m de onde estava.",
					nome = "Jutsu: Substituição",
				},
			},
			descricao = "Esgueirando-se na noite ou no meio da multidão, submetendo seus corpos à torturas para acostumarem-se com a dor e aplicando técnicas nunca antes vistas.",
			equipamento = {
				"Armas Ninja Variadas",
				"Kit de disfarce ou Kit de Falsificação",
				"Explosivos Ninja",
				"Qualquer arma simples ou Marcial",
			},
			nome = "Ninja",
			proficiencias = "Escolha um Kit dentre os recebidos e Acrobacia ou Atletismo e Furtividade",
		},
		{
			caracteristicas = {
				{
					efeito = "Você conhece os padrões secretos e o fluxo das cidades. Quando não em combate, você e companheiros podem viajar com o dobro da velocidade.",
					nome = "Segredos da Cidade",
				},
				{
					efeito = "Vantagem em todos os testes de Carisma quando se tratam de assuntos, pessoas e temas relacionados à máfia e ao conhecimento do submundo.",
					nome = "Zé-Pequeno",
				},
				{
					efeito = "Os inimigos tendem a te ignorar se você não fizer nada que os ameace e nem for o foco inicial de um conflito.",
					nome = "Insignificante",
				},
			},
			descricao = "Você cresceu nas ruas, sozinho, órfão e pobre. Você não tinha ninguém para cuidar de você ou te alimentar, então, aprendeu a se virar sozinho.",
			equipamento = {
				"Kit de Disfarce",
				"Kit de Ferramentas de Ofício ou Kit de Armas",
				"Qualquer arma simples",
			},
			nome = "Órfão",
			proficiencias = "Escolha 2 perícias com Kits recebidos. Recebe ainda Furtividade e Intuição ou Prestidigitação",
		},
		{
			caracteristicas = {
				{
					efeito = "Vantagem em qualquer teste de constituição. Treinou técnicas corporais para o combate desarmado. Seus golpes desarmados causam 1d6 no lugar de 1d4.",
					nome = "Monge",
				},
				{
					efeito = "Resistente a intimidação com ou sem aura. Pessoas com posição de autoridade alheias a você tem desvantagem em qualquer teste de carisma que não lhe beneficie.",
					nome = "Escravo",
				},
			},
			descricao = "Você viveu em reclusão – ou em uma comunidade isolada como um monastério ou completamente sozinho – por um período importante da sua vida.",
			equipamento = {
				"Qualquer arma simples ou Marcial",
				"Kit de Armas ou Kit de Caça e Rastreio de Criaturas",
			},
			nome = "Recluso",
			proficiencias = "Escolha 1 perícia com Kit recebido e Intuição, Medicina e Religião",
		},
		{
			caracteristicas = {
				{
					efeito = "Acostumado a abrir caminho para investigar planos do inimigo (Vantagem em Investigação e Furtividade quando estiver sozinho ou 20 metros separado do grupo).",
					nome = "Batedor",
				},
				{
					efeito = "Conhece procedimento que impede malefícios das pílulas de hemoglobina e suas variações e consegue aplicar em uma pessoa por dia.",
					nome = "Médico de Combate",
				},
				{
					efeito = "Atacar alvos além da distância normal não impõe desvantagem. Ataques ignoram meia cobertura e três-quartos.",
					nome = "Atirador de Elite",
				},
			},
			descricao = "A guerra sempre esteve na vida de soldados. Treinando desde jovem, estudando o uso das armas e armaduras, aprendendo técnicas básicas de sobrevivência.",
			equipamento = {
				"Qualquer arma simples ou Marcial",
				"Kit de Armas ou Kit de Caça e Rastreio de Criaturas",
				"1 Mala de Roupas ou Mochila Comum/Maleta",
			},
			nome = "Soldado",
			proficiencias = "Escolha 1 perícia com Kit recebido e Atletismo e Intimidação ou Sobrevivência",
		},
		{
			caracteristicas = {
				{
					efeito = "Sempre que cura um personagem, você adiciona seu INTx2 no total de PV curados.",
					nome = "Técnica Medicinal",
				},
				{
					efeito = "+3 em testes para estabilizar outros personagens. Aumenta o proveito do Kit de primeiros socorros.",
					nome = "Primeiros Socorros",
				},
				{
					efeito = "Pode fazer qualquer antídoto com kit de primeiros socorros e algum item da natureza ao redor.",
					nome = "Médico Experimental",
				},
			},
			descricao = "Um amor pela saúde dos outros, ou ainda um compromisso com a vida (seja por promessa ou dinheiro) domina todos dessa origem.",
			equipamento = {
				"Qualquer arma simples",
				"Kit Médico",
				"Kit Antídoto ou 3 pílulas de Hemoglobina variante",
			},
			nome = "Agente de Saúde",
			proficiencias = "Kit Médico ou Antídoto e Medicina e Percepção",
		},
		{
			caracteristicas = {
				{
					efeito = "Seu físico primoroso lhe permite fazer uma ação de movimento extra ou saltar em distância metade de seu deslocamento.",
					nome = "Bolt",
				},
				{
					efeito = "Se falhar em um teste de resistência, você pode rolar novamente para o teste, mas é obrigado a manter o novo resultado.",
					nome = "Implacável",
				},
			},
			descricao = "Você tem um físico primoroso e bem trabalhado, você competia/compete em algum tipo de esporte, individual ou coletivo.",
			equipamento = {
				"Qualquer arma simples",
				"1 pílula de Hemoglobina variante: (Morfina)",
			},
			nome = "Atleta",
			proficiencias = "Atletismo e Acrobacia ou Intuição ou Percepção",
		},
		{
			caracteristicas = {
				{
					efeito = "Com os ingredientes você pode fazer qualquer um dos tipos de pratos, além de você ter um bônus de 1d6 em testes de CAR 'contra' pessoas que comeram sua comida.",
					nome = "Sabor Único",
				},
				{
					efeito = "Com os ingredientes certos, você pode fazer uma comida que vale por um descanso curto.",
					nome = "Sabor de Casa",
				},
			},
			descricao = "Um ótimo cozinheiro, com habilidades de impressionar qualquer um.",
			equipamento = {
				"Qualquer arma simples",
				"Kit de Cozinha",
				"Kit de Caça e Rastreio de Criaturas",
			},
			nome = "Chef",
			proficiencias = "Com todos os kits recebidos e Sobrevivência, Percepção e História",
		},
		{
			caracteristicas = {
				{
					efeito = "Você tem +5 em acrobacia ou prestidigitação para seus números.",
					nome = "Performance",
				},
				{
					efeito = "Você consegue imitar sons que já tenha escutado, incluindo vozes.",
					nome = "Mimetismo",
				},
			},
			descricao = "Você sobrevivia com base em seu corpo e suas performances, fazendo malabares, piruetas e o que mais estivesse em seu arsenal.",
			equipamento = {
				"Qualquer arma simples",
				"Kit de Disfarce",
				"Roupa Chique",
			},
			nome = "Circense",
			proficiencias = "Kit de Disfarce, Acrobacia, Atuação e Persuasão ou Enganação",
		},
		{
			caracteristicas = {
				{
					efeito = "Ao invés de descansar, algumas latas de enérgico te fazem passar por um descanso normal, porém da próxima vez você precisará descansar.",
					nome = "Dormir não dá XP",
				},
				{
					efeito = "Você é acostumado a deixar tudo para a última hora, você consegue fazer tudo na metade do tempo, mas nem sempre ficará bom.",
					nome = "Procrastinador",
				},
			},
			descricao = "Alguém que vivia em casa jogando os mais diversos jogos, talvez um famoso pro-player, talvez apenas alguém que fugia da realidade nos games.",
			equipamento = {
				"Qualquer arma simples",
				"Dispositivo de PEM",
				"Computador, Celular e Pen Drive",
				"Kit de Hacker",
			},
			nome = "Gamer",
			proficiencias = "Kit de Hacker, História e Intuição",
		},
		{
			caracteristicas = {
				{
					efeito = "O mestre sempre irá te falar uma coisa extra, sem precisar jogar investigação em toda cena de investigação.",
					nome = "Detetive",
				},
				{
					efeito = "Graças à influência da sua agência, você pode obter cinco informações por campanha sem custo.",
					nome = "Rede de Contatos",
				},
			},
			descricao = "Um detetive, de renome ou não, trabalhando em busca de saber os mistérios do mundo, de casos policiais, ou daquilo que pegar mais.",
			equipamento = {
				"Pistola",
				"Kit Forense",
				"Ponto de rádio",
			},
			nome = "Investigador",
			proficiencias = "Kit Forense, Investigação e Atuação ou Intuição ou Percepção ou Enganação",
		},
		{
			caracteristicas = {
				{
					efeito = "Com uma ação bônus, e desde que esteja dentro de um veículo, o jogador desvia de qualquer coisa menor que seu veículo automaticamente.",
					nome = "Manobras Maníacas",
				},
				{
					efeito = "Com uma ação normal você pressiona o acelerador como nunca, dobrando sua velocidade atual enquanto em um veículo.",
					nome = "Piloto de Fuga",
				},
				{
					efeito = "Você recebe +3 em testes para pilotar.",
					nome = "Experiência no Volante",
				},
			},
			descricao = "Alguém que manda muito bem no volante, um piloto de fuga, um corredor de Fórmula 1. Pra que frear se eu posso acelerar e dar um drift?",
			equipamento = {
				"Qualquer arma simples",
				"Moto (pode pagar a diferença para ter um carro)",
			},
			nome = "Piloto",
			proficiencias = "Percepção, Intuição e Prestidigitação (Pilotar)",
		},
		{
			caracteristicas = {
				{
					efeito = "Você recebe +3 em teste de Religião para acalmar. E quando acalmar alguém, a pessoa acalmada receberá uma ação protagonista para gastar no próximo turno.",
					nome = "Pregar",
				},
				{
					efeito = "Sempre que realizar um teste de Carisma (Persuasão) enquanto estiver falando para um grupo grande de pessoas, você adiciona o dobro do seu bônus de proficiência.",
					nome = "Orador Público",
				},
				{
					efeito = "Após fazer uma oração a seu deus você se sente momentaneamente motivado e revigorado (seu modificador de SAB sobe um ponto).",
					nome = "Benção Divina",
				},
			},
			descricao = "Talvez um padre, um pastor, talvez um fanático de uma religião pouco conhecida. Mas com certeza alguém a procura de mais pessoas para o seu 'culto'.",
			equipamento = {
				"Qualquer arma simples",
				"Bíblia, ou qualquer outro livro sagrado",
			},
			nome = "Religioso",
			proficiencias = "Religião e História",
		},
		{
			caracteristicas = {
				{
					efeito = "Seus jogadores já botaram você em tanta enrascada que nada mais te surpreende, você se torna imune a condição 'surpreso' e tem vantagem em testes de carisma para convencer alguém de algo que você acabou de pensar.",
					nome = "Mestre do Improviso",
				},
				{
					efeito = "Uma vez por missão casualmente seu personagem diz algo que vai virar verdade, você não escolhe o que será isso, tudo que seu personagem falar poderá ser escolhido pelo mestre.",
					nome = "Sombra do Verdadeiro Mestre",
				},
			},
			descricao = "Você viveu sua vida narrando feitos incríveis, mas cansou de contar a história dos outros e resolveu começar sua própria aventura épica.",
			equipamento = {
				"Celular e Um kit de dados",
				"Computador",
				"Casaco reforçado",
			},
			nome = "Mestre de RPG",
			proficiencias = "Atuação, História e Enganação",
		},
	},
	classes = {
		{
			angle = 270,
			color = "#00ff9d",
			desc = "Aura expressa maior poder, cura e resistência",
			id = "INTENSIFICAÇÃO",
			label = "INTENSIFICAÇÃO",
		},
		{
			angle = 330,
			color = "#d946ef",
			desc = "Aura assume outra(s) propriedades(s)",
			id = "TRANSMUTAÇÃO",
			label = "TRANSMUTAÇÃO",
		},
		{
			angle = 30,
			color = "#ff0055",
			desc = "Aura cria e altera matéria física",
			id = "MATERIALIZAÇÃO",
			label = "MATERIALIZAÇÃO",
		},
		{
			angle = 90,
			color = "#00f0ff",
			desc = "Aura se apresenta de maneira inovadora",
			id = "ESPECIALIZAÇÃO",
			label = "ESPECIALIZAÇÃO",
		},
		{
			angle = 150,
			color = "#9ca3af",
			desc = "Aura manipula objetos, matéria ou seres vivos",
			id = "MANIPULAÇÃO",
			label = "MANIPULAÇÃO",
		},
		{
			angle = 210,
			color = "#ffe600",
			desc = "Aura se mantém forte fora do corpo e em longas distâncias",
			id = "EMISSÃO",
			label = "EMISSÃO",
		},
	},
	esforcoRacas = {
		["Anão"] = {
			bonus = "+2 CON (bônus NÃO concedido ao Humano — só a característica)",
			opcoes = {
				{
					efeito = "Vantagem em testes de resistência contra toxinas e venenos, e resistência contra efeitos de fadiga ou envenenamento por aura.",
					nome = "Resiliência Anã",
				},
				{
					efeito = "Redução de 10% no custo para manter técnicas passivas (Ten constante, Gyo prolongado — gasto mínimo de 5%).",
					nome = "Estabilidade de Aura",
				},
				{
					efeito = "+2 em testes relacionados à criação, manutenção ou modificação de equipamentos (mesmo por meio de Hatsu). Identifica o equilíbrio de aura em objetos sem precisar de Gyo.",
					nome = "Instinto de Forja",
				},
			},
		},
		Elfo = {
			bonus = "+2 INT ou SAB e +1 DES (bônus NÃO concedido ao Humano — só a característica)",
			opcoes = {
				{
					efeito = "Durante descansos ou meditações em ambientes naturais, recupera +1 ponto adicional de exaustão e reduz pela metade os efeitos de exaustão por clima, fome ou sede. Uma vez por combate, ganha +1 em qualquer teste de Resistência ou Reflexo até o final do turno.",
					nome = "Pulsar Verde",
				},
				{
					efeito = "Vantagem em testes de Percepção, Furtividade e Sobrevivência em ambientes naturais. Pode neutralizar/acalmar criaturas agressivas (teste de Carisma vs Sabedoria da criatura, 1x/missão).",
					nome = "Fluxo Harmônico",
				},
				{
					efeito = "Vantagem em testes de resistência física contra venenos, toxinas e doenças.",
					nome = "Expiração Vital",
				},
			},
		},
		Fanalis = {
			bonus = "+4 FOR ou CON e -2 nos demais atributos (bônus NÃO concedido ao Humano — só a característica)",
			opcoes = {
				{
					efeito = "Quando um inimigo o atinge com um ataque corpo a corpo, você pode usar sua reação para atacar desarmado ou com arma leve corpo a corpo imediatamente contra o agressor, com os benefícios de um contra-ataque (mas não os malefícios). 1x/dia; ao final da rodada, ganha 1 de exaustão. Não funciona se o oponente estiver furtivo.",
					nome = "Instinto Predatório",
				},
				{
					efeito = "Quando seu PV cai abaixo de 20%, entra em vigor explosivo por 1 minuto: +2 em jogadas de ataque corpo a corpo e +1d6 de dano adicional em ataques físicos. Após o efeito, ganha 1 nível de exaustão.",
					nome = "Fúria Muscular",
				},
				{
					efeito = "Uma vez por dia, como reação, reduz à metade o dano de um ataque corpo a corpo que o acertaria.",
					nome = "Pele de Ferro",
				},
			},
		},
		Gnomo = {
			bonus = "+2 DES ou INT (bônus NÃO concedido ao Humano — só a característica)",
			opcoes = {
				{
					efeito = "Vantagem em testes de Percepção e Análise de Aura.",
					nome = "Percepção Pequenina",
				},
				{
					efeito = "Vantagem em todos os testes de resistência de Inteligência, Sabedoria e Carisma contra Hatsu.",
					nome = "Esperteza Gnômica",
				},
				{
					efeito = "+2 em testes de Esquiva; -1 em testes de Força física pura (empurrar, puxar ou levantar algo pesado).",
					nome = "Tamanho ao Meu Favor",
				},
			},
		},
		Golias = {
			bonus = "+2 FOR ou CON (bônus NÃO concedido ao Humano — só a característica)",
			opcoes = {
				{
					efeito = "Após receber um dano, reduz à metade o dano de impacto, perfurante ou cortante recebido — um número de vezes por dia igual à sua proficiência.",
					nome = "Resistência de Pedra",
				},
				{
					efeito = "Usa FOR em vez de DES para calcular a precisão em ataques de arremesso manual com armas.",
					nome = "Alvo Destroçado",
				},
				{
					efeito = "Vantagem em testes de resistência contra fadiga, frio e calor.",
					nome = "Corpo de Pedra",
				},
			},
		},
		Imuchackk = {
			bonus = "+2 FOR, +1 CON e -2 INT (bônus NÃO concedido ao Humano — só a característica)",
			opcoes = {
				{
					efeito = "Reduz todo o dano de frio ou gelo em 50% (inclusive dano de aura elemental). Nenhum teste de Resistência Física sofre penalidade por frio. Pode manter Ten ativo por +2 turnos adicionais em ambientes gelados naturais.",
					nome = "Resistência Glacial",
				},
				{
					efeito = "Nada sem penalidade de movimento dentro d'água e prende a respiração por Minutos = 1 + (CON × 2).",
					nome = "Caça Aquática",
				},
				{
					efeito = "+1 ponto permanente em FOR ou CON.",
					nome = "Ritual de Maturidade",
				},
			},
		},
	},
	fqPresets = {
		["Aquático"] = {
			{
				desloc = "9m (Nado) / 9m Terrestre",
				deslocamentoTipo = "aquatico",
				deslocamentoValor = 9,
				nome = "Baleia",
				tracosSugeridos = {
					{
						nome = "Tração Animal",
					},
				},
			},
			{
				desloc = "9m (Nado) / 9m Terrestre",
				deslocamentoTipo = "aquatico",
				deslocamentoValor = 9,
				nome = "Lagosta",
				tracosSugeridos = {
					{
						nome = "Escudo Natural/Carapaça",
						opcao = "Resistência a Corte",
					},
				},
			},
			{
				desloc = "9m (Nado) / 9m Terrestre + Escalada sem teste",
				deslocamentoTipo = "aquatico",
				deslocamentoValor = 9,
				nome = "Polvo",
				tracosSugeridos = {
					{
						nome = "Arma natural",
						opcao = "Tentáculos/Cipós",
					},
				},
			},
			{
				desloc = "12m (Nado) / 9m Terrestre",
				deslocamentoTipo = "aquatico",
				deslocamentoValor = 12,
				nome = "Tubarão",
				tracosSugeridos = {
					{
						nome = "Arma natural",
						opcao = "Presas (Mordida)",
					},
				},
			},
		},
		Ave = {
			{
				desloc = "10,5m (Voo) / 9m Terrestre",
				deslocamentoTipo = "voo",
				deslocamentoValor = 10.5,
				nome = "Águia",
				tracosSugeridos = {
					{
						nome = "Arma natural",
						opcao = "Bico",
					},
					{
						nome = "Rasante",
					},
				},
			},
			{
				desloc = "7,5m (Voo) / 3m Terrestre",
				deslocamentoTipo = "voo",
				deslocamentoValor = 7.5,
				nome = "Beija-flor",
				tracosSugeridos = {
					{
						nome = "Evasão",
						opcao = "Aérea",
					},
				},
			},
			{
				desloc = "12m (Voo) / 9m Terrestre",
				deslocamentoTipo = "voo",
				deslocamentoValor = 12,
				nome = "Condor/Urubu",
				tracosSugeridos = {
					{
						nome = "Evasão",
						opcao = "Aérea",
					},
				},
			},
		},
		["Bestas Mágicas"] = {},
		["Inseto/Insectóide"] = {
			{
				desloc = "9m (Escalada) / 9m Terrestre",
				deslocamentoTipo = "escalada",
				deslocamentoValor = 9,
				nome = "Aranha",
				tracosSugeridos = {
					{
						nome = "Arma natural",
						opcao = "Tentáculos/Cipós",
					},
				},
			},
			{
				desloc = "9m Terrestre / 3m (Voo)",
				deslocamentoTipo = "voo",
				deslocamentoValor = 3,
				nome = "Besouro Bombardeiro",
				tracosSugeridos = {
					{
						nome = "Escudo Natural/Carapaça",
						opcao = "Resistência a Impacto",
					},
				},
			},
			{
				desloc = "9m Terrestre",
				deslocamentoTipo = "terrestre",
				deslocamentoValor = 9,
				nome = "Escorpião",
				tracosSugeridos = {
					{
						nome = "Veneno/Peçonha",
					},
					{
						nome = "Escudo Natural/Carapaça",
						opcao = "Resistência a Perfuração",
					},
				},
			},
			{
				desloc = "9m Terrestre / 6m (Voo)",
				deslocamentoTipo = "voo",
				deslocamentoValor = 6,
				nome = "Mosquito",
				tracosSugeridos = {
					{
						nome = "Evasão",
						opcao = "Aérea",
					},
					{
						nome = "Arma natural",
						opcao = "Ferrão (Picada)",
					},
				},
			},
		},
		["Mamífero"] = {
			{
				desloc = "10,5m Terrestre",
				deslocamentoTipo = "terrestre",
				deslocamentoValor = 10.5,
				nome = "Coelho",
				tracosSugeridos = {
					{
						nome = "Destreza animal",
					},
				},
			},
			{
				desloc = "7,5m Terrestre",
				deslocamentoTipo = "terrestre",
				deslocamentoValor = 7.5,
				nome = "Elefante",
				tracosSugeridos = {
					{
						nome = "Tração Animal",
					},
					{
						nome = "Escudo Natural/Carapaça",
						opcao = "Resistência a Impacto",
					},
				},
			},
			{
				desloc = "12m Terrestre",
				deslocamentoTipo = "terrestre",
				deslocamentoValor = 12,
				nome = "Guepardo",
				tracosSugeridos = {
					{
						nome = "Destreza animal",
					},
				},
			},
			{
				desloc = "9m Terrestre",
				deslocamentoTipo = "terrestre",
				deslocamentoValor = 9,
				nome = "Leão",
				tracosSugeridos = {
					{
						nome = "Arma natural",
						opcao = "Presas (Mordida)",
					},
					{
						nome = "Escudo Natural/Carapaça",
						opcao = "Resistência a Corte",
					},
				},
			},
			{
				desloc = "9m Terrestre",
				deslocamentoTipo = "terrestre",
				deslocamentoValor = 9,
				nome = "Lobo",
				tracosSugeridos = {
					{
						nome = "Arma natural",
						opcao = "Presas (Mordida)",
					},
				},
			},
			{
				desloc = "9m (Escalada)",
				deslocamentoTipo = "escalada",
				deslocamentoValor = 9,
				nome = "Macaco",
				tracosSugeridos = {
					{
						nome = "Destreza animal",
					},
					{
						nome = "Corpo Adaptável",
						opcao = "Corpo Mole (Resistência Impacto)",
					},
				},
			},
			{
				desloc = "9m Terrestre",
				deslocamentoTipo = "terrestre",
				deslocamentoValor = 9,
				nome = "Rinoceronte",
				tracosSugeridos = {
					{
						nome = "Investida",
					},
					{
						nome = "Tração Animal",
					},
				},
			},
			{
				desloc = "7,5m Terrestre (+9m Subterrâneo)",
				deslocamentoTipo = "terrestre",
				deslocamentoValor = 7.5,
				nome = "Tatu",
				tracosSugeridos = {
					{
						nome = "Escudo Natural/Carapaça",
						opcao = "Resistência a Impacto",
					},
					{
						nome = "Investida",
					},
				},
			},
		},
		["Réptil/Anfíbio"] = {
			{
				desloc = "9m Terrestre",
				deslocamentoTipo = "terrestre",
				deslocamentoValor = 9,
				nome = "Camaleão",
				tracosSugeridos = {
					{
						nome = "Regeneração",
					},
				},
			},
			{
				desloc = "9m Terrestre",
				deslocamentoTipo = "terrestre",
				deslocamentoValor = 9,
				nome = "Cobra",
				tracosSugeridos = {
					{
						nome = "Escudo Natural/Carapaça",
						opcao = "Resistência a Corte",
					},
				},
			},
			{
				desloc = "9m Terrestre",
				deslocamentoTipo = "terrestre",
				deslocamentoValor = 9,
				nome = "Sapo",
				tracosSugeridos = {
					{
						nome = "Corpo Adaptável",
						opcao = "Constituição Respiratória (Aquático)",
					},
					{
						nome = "Veneno/Peçonha",
					},
				},
			},
			{
				desloc = "6m (Nado)",
				deslocamentoTipo = "aquatico",
				deslocamentoValor = 6,
				nome = "Tartaruga",
				tracosSugeridos = {
					{
						nome = "Escudo Natural/Carapaça",
						opcao = "Resistência a Impacto",
					},
				},
			},
		},
	},
	inclinacoes = {
		negativas = {
			{
				desc = "Você fica preocupado demais em conservar sua riqueza. Você deverá procurar sempre o melhor negócio. Faça um teste de autocontrole (SAB/INT ou CAR) toda vez que tiver que gastar algum dinheiro.",
				nome = "Avareza",
				valor = 2,
			},
			{
				desc = "Você DEVE re-rolar seu primeiro acerto crítico no d20 da sessão.",
				nome = "Azar Grande",
				valor = 3,
			},
			{
				desc = "Você consegue entender as emoções dos outros, mas não as suas intenções. Isto faz de você desajeitado em situações envolvendo manipulação social. Você é o clássico 'nerd' e sofre -1 para usar ou resistir a Testes de Influência.",
				nome = "Desatencioso",
				valor = 1,
			},
			{
				desc = "Você deve um favor a alguém que te ajudou em um momento de dificuldade. Essa pessoa poderá te cobrar esse favor a qualquer momento e poderá ser qualquer coisa.",
				nome = "Dívida",
				valor = 3,
			},
			{
				desc = "Você tem dificuldade de se recordar de nomes, lugares, aparências e informações. É bem comum causar confusão por isso.",
				nome = "Esquecido",
				valor = 1,
			},
			{
				desc = "Você precisa obedecer a lei sempre e dar o melhor de si para que os outros também o façam. Você assumirá também que os outros são honestos até saber o contrário.",
				nome = "Honestidade",
				valor = 2,
			},
			{
				desc = "Você tem muita dificuldade para se decidir, recebendo -3 em rolagens de iniciativa. Além disso, sempre que se deparar com uma escolha, faça um teste simples de INT ou CAR CD 15.",
				nome = "Indeciso",
				valor = 5,
			},
			{
				desc = "Alguém ou algo que ativamente tenta te prejudicar.",
				hasOptions = true,
				nome = "Inimigo",
				options = {
					{
						desc = "Inimigo chato, objetivos estúpidos, aparece para atrapalhar (Ex: Equipe Rocket).",
						label = "Fraco",
						valor = 1,
					},
					{
						desc = "Inimigo mediano, mesmos objetivos que você, fará de tudo para atrapalhar inclusive lutar.",
						label = "Rival",
						valor = 2,
					},
					{
						desc = "Chefão maligno. Te caça para recrutar ou matar sem piedade.",
						label = "Poderoso",
						valor = 5,
					},
				},
				valor = 1,
			},
			{
				desc = "Você tem uma reação muito ruim frente a qualquer um que pareça mais inteligente, mais atraente, poderoso ou em melhor situação do que a sua!",
				nome = "Inveja",
				valor = 1,
			},
			{
				desc = "Você não é surdo, mas perdeu uma parte da audição e sofrerá um redutor de -3 em qualquer teste de Audição.",
				nome = "Perda Auditiva",
				valor = 1,
			},
			{
				desc = "Você odeia dizer uma mentira ou o faz muito mal. Ter que mentir pode fazer literalmente você ficar enjoado ou com peso na consciência (Condição Envenenado ou -5 Sanidade).",
				nome = "Veracidade",
				valor = 2,
			},
			{
				desc = "Perna ruim ou ausente. -2 em qualquer perícia que exija o uso das pernas (incluindo Armas de Mão e combate desarmado, exceto combate à distância). Deslocamento Básico reduzido à metade.",
				nome = "Aleijado",
				valor = 3,
			},
			{
				desc = "Não sente cheiro nem sabor de nada — não detecta certos perigos que outros perceberiam, e falha automaticamente em detectar gases nocivos (mas nunca é afetado por mau odor, e não tem problema em comer qualquer coisa — o que não te dá imunidade a venenos).",
				nome = "Anosmia/Ageusia",
				valor = 1,
			},
			{
				desc = "Você é simplesmente azarado. Uma vez por sessão, o mestre usa uma 'Ação Protagonista' (1 d20 extra ou 3d6) para fazer algo dar errado com você — nunca o suficiente para matá-lo de imediato.",
				nome = "Azar Perseguidor",
				valor = 6,
			},
			{
				desc = "Coordenação motora ruim: -2 em qualquer teste baseado em DES (aplicado no resultado final, não causa Atributo Penalizado).",
				nome = "Baixa Destreza Manual ou Consciência Corporal",
				valor = 1,
			},
			{
				desc = "Tem apenas um olho, ou os dois não são confiáveis. -2 em armas de acuidade/à distância e em testes de percepção ou investigação baseados em visão.",
				nome = "Caolho ou Estrábico",
				valor = 2,
			},
			{
				desc = "Perdeu a visão em algum acidente ou nasceu sem ela. Escolha um nível:",
				hasOptions = true,
				nome = "Cegueira",
				options = {
					{
						desc = "50% de perda de visão — reconhece pessoas a 1,5m; ataques à distância com desvantagem.",
						label = "Miopia/Astigmatismo",
						valor = 3,
					},
					{
						desc = "80% de perda de visão — vê apenas vultos e localização, sem distinguir o que é cada um.",
						label = "Glaucoma",
						valor = 4,
					},
					{
						desc = "Cegueira total — aplica a condição Cego permanentemente.",
						label = "Condição Cego",
						valor = 5,
					},
				},
				valor = 3,
			},
			{
				desc = "(Loucura Permanente) Requisito: CAR menor que 15. Diante de perigo, tenta fugir a menos que passe em um teste de coragem/vontade (INT/SAB/CAR, a critério do mestre). -3 em testes para resistir Intimidação.",
				nome = "Covardia",
				valor = 3,
			},
			{
				desc = "Segue um conjunto de princípios 'honrosos' o tempo todo, mesmo sob risco de morte. Quebrar o código escolhido causa 5 de Estresse (dano psíquico) na Sanidade. Escolha um:",
				hasOptions = true,
				nome = "Código de Honra",
				options = {
					{
						desc = "Sempre se vingar de um insulto; o inimigo de um companheiro é seu inimigo; nunca atacar um companheiro fora de um duelo justo.",
						label = "Simples",
						valor = 1,
					},
					{
						desc = "Nunca faltar com a palavra ou ignorar um insulto a você/sua fé/seus amados; nunca tirar vantagem desleal de um oponente.",
						label = "Cavalheiro",
						valor = 2,
					},
					{
						desc = "Lutar e morrer pela honra da tropa; seguir ordens e regras de guerra; tratar inimigos honrosos com respeito.",
						label = "Soldado",
						valor = 3,
					},
				},
				valor = 1,
			},
			{
				desc = "(Loucura Permanente) Compelido a roubar qualquer coisa que possa levar. Ao ter a chance, teste de autocontrole (CAR CD 15) — se falhar, deve roubar; se o furto falhar, sofre 5 de Estresse na Sanidade (recupera 2 ao furtar com sucesso depois).",
				nome = "Cleptomania",
				valor = 2,
			},
			{
				desc = "(Loucura Permanente) Requisito: INT menor que 15. Dificilmente dá atenção a coisas fora do seu interesse. Teste de autocontrole (INT CD 15) diante de algo estranho/novo — se falhar, simplesmente ignora.",
				nome = "Desinteresse",
				valor = 2,
			},
			{
				desc = "(Loucura Permanente) Requisito: SAB menor que 15. Dificuldade de concentração prolongada — não pode repetir o mesmo teste mais de 3 vezes no mesmo dia sobre a mesma tarefa, e falha automaticamente em testes de provocação ao ser distraído.",
				nome = "Desvio de Atenção",
				valor = 3,
			},
			{
				desc = "Você tem outra personalidade com os mesmos Dado de Vida e Raça, mas atributos/características distintos, que surge ao tirar 1 num dado. Você não controla quando ocorre a mudança, e uma personalidade não lembra o que a outra fez.",
				nome = "Dupla Personalidade",
				valor = 4,
			},
			{
				desc = "Jamais desperdiça a chance de enfrentar alguém mais forte para provar que é o melhor — mesmo já tendo perdido várias vezes por esse impulso.",
				nome = "Espírito de Lutador",
				valor = 3,
			},
			{
				desc = "Requisito: um atributo maior que 18. Acredita ser mais poderoso, inteligente ou competente do que realmente é, e precisa representar isso mesmo quando é perigoso.",
				nome = "Excesso de Confiança",
				valor = 3,
			},
			{
				desc = "Crê fielmente em algo que só você acredita (uma 'verdade' criada por você mesmo). -3 em Intimidação e Persuasão contra quem já foi exposto à sua fantasia; deve interpretá-la ao menos 1x a cada 2 sessões.",
				nome = "Fantasia",
				valor = 1,
			},
			{
				desc = "(Loucura Permanente) Requisito: INT ou SAB menor que 15. Age primeiro e pensa depois. Teste de autocontrole (INT ou SAB CD 15) quando seria melhor esperar — se falhar, age; se impedido de agir, sofre Estresse na Sanidade por rodada.",
				nome = "Impulsividade",
				valor = 3,
			},
			{
				desc = "(Loucura Permanente) Precisa matar alguém/algum animal a cada dois dias, ou entra em abstinência com -2 em tudo (dobra por dia adicional sem matar). Pode pegar Código de Honra de graça para simular ser um bom cidadão.",
				nome = "Instinto Assassino",
				valor = 4,
			},
			{
				desc = "Um grupo, facção ou corporação caça você por motivos diversos (ex: uma máfia por ter matado o filho de um chefe de família).",
				nome = "Legião de Inimigos",
				valor = 6,
			},
			{
				desc = "Só tem um braço — não pode usar armas de duas mãos nem empunhar duas armas/escudo. -4 em tarefas normalmente feitas com dois braços (ex: Escalada, Luta Livre); sem redutor em tarefas de uma mão só.",
				nome = "Maneta (Braço)",
				valor = 4,
			},
			{
				desc = "(Loucura Permanente) Crê ser destinado a grandes coisas. Escolha um objetivo grandioso — enquanto não o concluir, tem apenas metade dos pontos de Sanidade totais.",
				nome = "Megalomania",
				valor = 5,
			},
			{
				desc = "(Loucura Permanente) Requisito: não ter antecedente Cientista/Especialista, Criminoso, Líder, Mentalista ou Negociante; não iniciar com tendência Maligna. Ainda tem inocência de criança e é mais facilmente enganado — -5 em testes de Intuição.",
				nome = "Mente de Criança",
				valor = 2,
			},
			{
				desc = "Não pode falar ou ouvir. -3 em testes de Carisma; precisa de Prestidigitação (Libras) para passar mensagens a quem não conhece a linguagem de sinais.",
				nome = "Mudez/Surdez",
				valor = 4,
			},
			{
				desc = "Não se beneficia do movimento concedido por Atletismo e recebe -1 em iniciativa.",
				nome = "Nanismo",
				valor = 2,
			},
			{
				desc = "(Loucura Permanente) Corre riscos absurdamente irracionais diante de perigo mortal e não pode fugir do desafio, ainda que pareça loucura para quem observa.",
				nome = "No Limite/Borderliner",
				valor = 3,
			},
			{
				desc = "(Loucura Permanente) Perdeu contato com a realidade — acredita que todos conspiram contra você e nunca confia em ninguém (nem em velhos amigos). Por não conseguir aquietar a mente, Zetsu recupera 5% menos aura em qualquer nível.",
				nome = "Paranoia",
				valor = 5,
			},
			{
				desc = "Não se beneficia do movimento de Atletismo e recebe -5 em iniciativa. Falha automaticamente em TRs de esquiva contra impacto no chão/pernas, é considerado caído em combate, e o movimento total é reduzido a 3m.",
				nome = "Paraplégico",
				valor = 6,
			},
			{
				desc = "(Loucura Permanente) Atormentado todas as noites — o descanso longo recupera apenas metade dos recursos, e a eficiência de aura funciona de forma intermitente (a cada 2 usos).",
				nome = "Pesadelos",
				valor = 3,
			},
			{
				desc = "Requisito: não começar com tendência Heróico. Caçado por seus atos por mercenários; a recompensa cresce com sua fama/renome. Valor sugerido de 1 a 8 pontos — negocie com o mestre conforme o momento da escolha.",
				nome = "Procurado",
				valor = 3,
			},
			{
				desc = "Sempre quer fazer as coisas do seu jeito — seus aliados podem precisar de vários testes de Persuasão para te convencer até de planos razoáveis.",
				nome = "Teimosia",
				valor = 1,
			},
			{
				desc = "Requisito: tendência Caótico ou Maligno, e INT ou DES maior que 15. Sente prazer em enganar pessoas perigosas (nunca as inofensivas). Falhar duas vezes com a mesma pessoa, ou perder uma boa chance de trapacear, causa -3 de Estresse na Sanidade.",
				nome = "Trapaceiro",
				valor = 3,
			},
			{
				desc = "(Loucura Permanente) Já esteve perto da morte — sempre que entra em combate, tem uma visão do oponente te matando. -10 em iniciativa; deve descrever essa visão em pensamento ou fala.",
				nome = "Visões de Morte",
				valor = 5,
			},
		},
		positivas = {
			{
				custo = 1,
				desc = "O personagem possui um velho amigo que pode lhe oferecer ajuda, informações e abrigo caso esteja próximo de sua residência.",
				nome = "Aliado",
			},
			{
				custo = 1,
				desc = "Você tem um associado que lhe fornece informações úteis ou faz pequenos favores.",
				hasOptions = true,
				nome = "Contatos",
				options = {
					{
						custo = 1,
						desc = "Recebe uma informação sobre a dúvida em até 24 horas por $500.",
						label = "Informação rápida",
					},
					{
						custo = 2,
						desc = "Recebe todas as informações disponíveis, explicando quais se podem confiar ($2000).",
						label = "Informação de confiança",
					},
					{
						custo = 1,
						desc = "Diminui o custo da informação rápida de $500 para até $100.",
						label = "Informação barata",
					},
				},
			},
			{
				custo = 5,
				desc = "Você é enorme e por isso tem um nível a mais de vitalidade. +5 HP inicial e +3 por nível. O usuário tem que ficar com altura acima de 2,10m e não consegue utilizar armas leves e pequenas sem depender de uma técnica.",
				nome = "Corpo de Gigante",
			},
			{
				custo = 1,
				desc = "Você é talentoso em entender o comportamento dos animais. Superando um teste de INT = 10 você compreende o estado emocional do animal - amigável, assustado, hostil, faminto, etc.",
				nome = "Empatia com Animais",
			},
			{
				custo = 2,
				desc = "Dificilmente alguém terá sucesso te asfixiando ou afogando. Você consegue prender a respiração por 5-7 minutos fazendo esforço e 10-15 apenas nadando de forma despretensiosa ou se concentrando.",
				nome = "Fôlego",
			},
			{
				custo = 1,
				desc = "Modifica equipamentos ou cria novos. Selecione os benefícios:",
				hasOptions = true,
				nome = "Inventor",
				options = {
					{
						custo = 1,
						desc = "Dão até 1d8 de dano natural de qualquer propriedade (max. 3 propriedades).",
						label = "Propriedade de Dano",
					},
					{
						custo = 1,
						desc = "Atingem até 2 alvos.",
						label = "Alcance/Alvos",
					},
					{
						custo = 1,
						desc = "Diminuem até 4 de espaço/peso.",
						label = "Compacto",
					},
					{
						custo = 1,
						desc = "Aumentam até 2 de CA.",
						label = "Defensivo",
					},
				},
			},
			{
				custo = 3,
				desc = "O personagem tem certa influência com alguma família mafiosa e poderá pedir alguns favores, mas cuidado, é bom não exagerar, pois eles normalmente pedem favores em troca.",
				nome = "Ligação com a Máfia",
			},
			{
				custo = 1,
				desc = "Seus sentidos são mais desenvolvidos (+2 em testes específicos).",
				hasOptions = true,
				nome = "Sentidos Aguçados",
				options = {
					{
						custo = 1,
						desc = "+2 para escutar ou reparar sons incomuns (ex: engatilhar arma no escuro).",
						label = "Audição Aguçada",
					},
					{
						custo = 1,
						desc = "+2 para reparar gosto/cheiro. Bônus passivo antes de ingerir (evita veneno).",
						label = "Paladar e Olfato",
					},
					{
						custo = 1,
						desc = "+2 em detectar pelo toque ou Prestidigitação (ex: revistar suspeito).",
						label = "Tato Aguçado",
					},
					{
						custo = 1,
						desc = "+2 em localizar visualmente, procurar armadilhas ou pegadas.",
						label = "Visão Aguçada",
					},
				},
			},
			{
				custo = 3,
				desc = "Você pode re-rolar 1 dado por sessão ficando com o maior resultado.",
				nome = "Sorte Grande",
			},
			{
				custo = 3,
				desc = "Independente de que raça pertença, você é uma anomalia. Seu ciclo de vida se estende em uma margem de 20 anos a mais em todos os períodos de desenvolvimento após a infância.",
				nome = "Tempo de Vida Estendido (Anomalia)",
			},
			{
				custo = 2,
				desc = "Você pode ver 9m no escuro como se fosse dia e não sofre penalidades de escuridão que não conte como bloqueio ou aplique cegueira.",
				nome = "Visão no Escuro",
			},
			{
				custo = 2,
				desc = "Você luta com ambas as mãos com a mesma precisão e potência. Escolha um dos benefícios:",
				hasOptions = true,
				nome = "Ambidestria",
				options = {
					{
						custo = 3,
						desc = "Ao empunhar armas leves em ambas as mãos, realize um ataque com Ação Bônus somando seu modificador no dano de ambos os ataques.",
						label = "Habilidoso em Combate Ágil",
					},
					{
						custo = 3,
						desc = "Pode usar qualquer arma sem a propriedade 'Duas Mãos' uma em cada mão como se fosse leve (só ataca com as duas no mesmo turno com Atributo Evoluído ou ataque extra).",
						label = "Habilidoso em Combate Bruto",
					},
					{
						custo = 2,
						desc = "Pega e usa um item, ou troca de equipamento, usando a Ação Bônus.",
						label = "Habilidoso em Inventário",
					},
					{
						custo = 2,
						desc = "+4 em Prestidigitação ou testes de precisão manual que não sejam ataques.",
						label = "Cirurgião/Malabarista",
					},
				},
			},
			{
				custo = 3,
				desc = "Pré-requisito: Categoria de Transmutação. Escolha um tipo de dano da tabela de forças da natureza igual ao elemento do seu Hatsu. Fica imune a esse tipo de dano e pode tratar 1 dado de dano como valor máximo ao rolar uma habilidade de transmutação elemental com esse elemento.",
				nome = "Apropriação Natural/Elemental",
			},
			{
				custo = 6,
				desc = "Dotado de um dom invejável, você possui muito mais aura que pessoas comuns. +30% de Aura máxima.",
				nome = "Aura Gigantesca",
			},
			{
				custo = 2,
				desc = "Seu sistema ósseo e muscular é melhor que o normal. Pode ser escolhida de novo no futuro (quando não repetir a mesma opção).",
				hasOptions = true,
				nome = "Boa Forma",
				options = {
					{
						custo = 2,
						desc = "+2 em testes de Escalada, testes de Fuga para se livrar de amarras e em tentativas de se libertar em combate corpo a corpo.",
						label = "Boa Flexibilidade",
					},
					{
						custo = 4,
						desc = "Boa Flexibilidade aprimorada — o bônus passa a ser +4.",
						label = "Ultra Flexibilidade",
					},
				},
			},
			{
				custo = 2,
				desc = "Difícil de assustar ou intimidar. Vantagem em testes contra Intimidação (CAR ou FOR). Quando é mesmo assustado, sofre 2 de Estresse (dano psíquico) na Sanidade.",
				nome = "Destemido",
			},
			{
				custo = 3,
				desc = "Passivo para Emissores. Pré-requisito: 80% de assimilação com Emissão (Reforço ou Manipulação). Pode desprender aura pura do corpo em formato de ataque aplicando REN sem precisar de uma arma (5% de aura = 1d6), e atacar à distância com aura ignorando meia ou três-quartos de cobertura.",
				nome = "Disparo de Aura",
			},
			{
				custo = 2,
				desc = "Escolha até 2 assuntos (nichados) — dobra a proficiência em testes relacionados a eles.",
				nome = "Especialista",
			},
			{
				custo = 2,
				desc = "Vantagem em testes de Sabedoria (Percepção) e Inteligência (Investigação) para detectar passagens/mecanismos secretos, e vantagem em TRs para evitar ou resistir a armadilhas ao explorar.",
				nome = "Explorador",
			},
			{
				custo = 1,
				desc = "Informe ao mestre um tipo de terreno e condição climática — sempre que estiver nesse ambiente, recebe um bônus em testes correspondente (ex: Ártico = +5 de resistência contra frio).",
				nome = "Habitat Natural",
			},
			{
				custo = 3,
				desc = "Aparência e postura ameaçadoras concedem +3 em iniciativa e em testes de Intimidação.",
				nome = "Imponência Assustadora",
			},
			{
				custo = 1,
				desc = "Você se recorda com detalhes de situações e informações. Escolha uma alternativa:",
				hasOptions = true,
				nome = "Memória Excepcional",
				options = {
					{
						custo = 1,
						desc = "Lembra automaticamente de tudo que concentrar atenção; recorda detalhes específicos com teste de INT = 10.",
						label = "Memória Excepcional",
					},
					{
						custo = 3,
						desc = "Como acima, mas também recorda detalhes específicos sempre — o mestre/jogadores devem lembrá-lo como se estivesse tudo anotado ou gravado.",
						label = "Memória Fotográfica",
					},
				},
			},
			{
				custo = 4,
				desc = "O mestre faz, em segredo, um teste contra sua Percepção Passiva sempre que houver emboscada, armadilha ou perigo iminente; um sucesso avisa você a tempo de agir. Além disso, Percepção Passiva e Reações aumentam em 3.",
				nome = "Noção do Perigo",
			},
			{
				custo = 3,
				desc = "Percebe as intenções de quem conversa com você — se é boa/má ou fala verdade. +5 em testes de Intuição ou de CAR contra ser Enganado.",
				nome = "Palpite de Instinto",
			},
			{
				custo = 3,
				desc = "Subtrai automaticamente 5m de uma queda (trata como sucesso automático em Acrobacia para quedas simples) e reduz à metade o dano de quedas, desde que não esteja Agarrado/Preso, Atordoado/Incapacitado, Cego, Impedido, Inconsciente ou Paralisado.",
				nome = "Pulo do Gato",
			},
			{
				custo = 2,
				desc = "Anticorpos poderosos contra qualquer veneno não produzido por aura — +10 em testes de CON contra venenos.",
				nome = "Resistência a Venenos",
			},
			{
				custo = 3,
				desc = "Requisito: Zetsu Intermediário. Seu ciclo de vida se estende em 50 anos a mais em todos os períodos após a infância (70 anos se combinada com Tempo de Vida Estendido por Anomalia).",
				nome = "Tempo de Vida Estendido por Zetsu",
			},
		},
	},
	otherSkills = {
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
	},
	pointBuyCosts = {
		-20,
		-17,
		-14,
		-11,
		-8,
		-6,
		-4,
		-2,
		-1,
		0,
		1,
		2,
		3,
		4,
		6,
		8,
		11,
		14,
		17,
		20,
		23,
		26,
		29,
		32,
		35,
		38,
		41,
		44,
		47,
		50,
	},
	racas = {
		{
			aumento_atributo = {
				CON = 1,
				DES = 1,
				FOR = 1,
				INT = 1,
				PRE = 1,
				SAB = 1,
			},
			categoria = "Humanos e Tribos",
			descricao = "Raça mais comum no mundo.",
			fonte = "[3, 4]",
			nome = "Humano Comum",
		},
		{
			aumento_atributo = {
				CON = 2,
				DES = -2,
				FOR = 4,
				INT = -2,
				PRE = -2,
				SAB = -2,
			},
			categoria = "Humanos e Tribos",
			descricao = "Composição física descomunal.",
			fonte = "[3, 4]",
			nome = "Fanalis",
			opcoes_caracteristica = {
				{
					efeito = "Quando um inimigo o atinge com um ataque corpo a corpo, você pode usar sua reação para atacar desarmado ou com arma leve corpo a corpo imediatamente contra o agressor, com os benefícios de um contra-ataque (mas não os malefícios). 1x/dia; ao final da rodada, ganha 1 de exaustão. Não funciona se o oponente estiver furtivo.",
					nome = "Instinto Predatório",
				},
				{
					efeito = "Quando seu PV cai abaixo de 20%, entra em vigor explosivo por 1 minuto: +2 em jogadas de ataque corpo a corpo e +1d6 de dano adicional em ataques físicos. Após o efeito, ganha 1 nível de exaustão.",
					nome = "Fúria Muscular",
				},
				{
					efeito = "Uma vez por dia, como reação, reduz à metade o dano de um ataque corpo a corpo que o acertaria.",
					nome = "Pele de Ferro",
				},
			},
		},
		{
			aumento_atributo = "Distribua 3 pontos em qualquer atributo",
			categoria = "Humanos e Tribos",
			descricao = "Homens Flauta.",
			fonte = "[3, 4]",
			nome = "Gyudondond",
			opcoes_caracteristica = {
				{
					efeito = "Membros da Tribo Gyudondond podem utilizar Intimidação como ação de movimento ao performar uma dança, desde que sua aura esteja ativa (qualquer Princípio ou Técnica de NEN, exceto Zetsu). Efeito adicional: se falhar a Intimidação, o alvo ainda sofre -1 em seu próximo teste de concentração, percepção ou intuição (por distração sonora). Limite: 1 vez por turno.",
					nome = "Alarido de Guerra",
				},
				{
					efeito = "Ação de movimento. A vibração sonora dos tubos corporais ajuda o fluxo da aura. Enquanto o Gyudondond estiver emitindo sons ritmados (passivamente ou propositalmente), recebe +1 em testes de concentração em seus Hatsus. Perde o bônus se estiver em silêncio absoluto, surdo ou impedido de se mover.",
					nome = "Harmonia de Aura",
				},
				{
					efeito = "Possui sensibilidade especial a sons e vibrações: detecta movimentações próximas (até 5m) mesmo sem visão, ao sentir vibrações no ar ou no solo. Testes de Percepção baseados em audição e toque recebem +2. Em contrapartida, ataques sonoros (ou ruídos intensos) causam +2 de dano contra ele, por hipersensibilidade auditiva.",
					nome = "Sonoridade Instintiva",
				},
			},
		},
		{
			aumento_atributo = {
				CON = 1,
				FOR = 2,
				INT = -2,
			},
			categoria = "Humanos e Tribos",
			descricao = "Guerreiros gélidos.",
			fonte = "[3, 4]",
			nome = "Imuchack",
			opcoes_caracteristica = {
				{
					efeito = "Reduz todo o dano de frio ou gelo em 50% (inclusive dano de aura elemental). Nenhum teste de Resistência Física sofre penalidade por frio. Pode manter Ten ativo por +2 turnos adicionais em ambientes gelados naturais.",
					nome = "Resistência Glacial",
				},
				{
					efeito = "Nada sem penalidade de movimento dentro d'água e prende a respiração por Minutos = 1 + (CON × 2).",
					nome = "Caça Aquática",
				},
				{
					efeito = "+1 ponto permanente em FOR ou CON.",
					nome = "Ritual de Maturidade",
				},
			},
		},
		{
			aumento_atributo = {
				INT_ou_SAB = 2,
			},
			caracteristicas = {
				{
					efeito = "+1 em todos os atributos enquanto os olhos estiverem vermelhos. Testes de Intimidação, Intuição e Concentração têm vantagem. Ao conhecer NEN, ativa consumindo 10% de aura. Duração: rodadas iguais ao bônus de Sabedoria (mín. 1). Pode ser usado um número de vezes por dia igual à proficiência. Após a ativação, sofre 1 nível de Exaustão pelo esforço físico e mental.",
					nome = "Mudança Escarlate",
				},
				{
					efeito = "Você pode ser procurado e caçado, caso descubram seus olhos e sua origem.",
					nome = "Caça Fascinante",
				},
				{
					efeito = "Seus olhos se tornam escarlates após um estresse mental extenuante: estar com menos de 20% de vida; sofrer dano psíquico além da metade da vida; estar Amedrontado/Assustado/Aterrorizado por quem já lhe causou +25% de dano; ou ver amigos próximos morrendo.",
					nome = "Sofrimento Profundo",
				},
			},
			categoria = "Clãs Especiais",
			descricao = "Olhos Escarlates.",
			fonte = "[5, 6]",
			nome = "Kurta",
		},
		{
			aumento_atributo = "Nenhum",
			caracteristicas = {
				{
					efeito = "Dano variado baseado na anatomia.",
					nome = "Arma natural",
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
					efeito = "Mudança corporal dramática ou adaptação ambiental.",
					nome = "Corpo Adaptável",
					opcoes = {
						"Metamorfose (Lagarta->Borboleta)",
						"Constituição Respiratória (Aéreo)",
						"Constituição Respiratória (Aquático)",
						"Corpo Mole (Resistência Impacto)",
					},
				},
				{
					efeito = "Dano crítico em construções e Constructos.",
					nome = "Criatura de Cerco",
				},
				{
					efeito = "Vantagem em testes de resistência de Destreza.",
					nome = "Destreza animal",
				},
				{
					efeito = "Resistência a tipos específicos de dano físico.",
					nome = "Escudo Natural/Carapaça",
					opcoes = {
						"Resistência a Corte",
						"Resistência a Perfuração",
						"Resistência a Impacto",
					},
				},
				{
					efeito = "Manobra de fuga que adiciona +2 na Reação de Esquiva.",
					nome = "Evasão",
					opcoes = {
						"Aérea",
						"Aquática",
						"Terrestre",
					},
				},
				{
					efeito = "Dano extra com movimento.",
					nome = "Investida",
				},
				{
					efeito = "Manobra de ataque aéreo sem receber AdO.",
					nome = "Rasante",
				},
				{
					efeito = "Recuperação gradual de Vida.",
					nome = "Regeneração",
				},
				{
					efeito = "Comunicação entre espécies.",
					nome = "Telepatia",
					opcoes = {
						"Ativa (Inferior)",
						"Passiva (Superior)",
					},
				},
				{
					efeito = "Capacidade de carga aumentada e/ou salto dobrado.",
					nome = "Tração Animal",
				},
				{
					efeito = "Aplica veneno. Imune ao próprio veneno.",
					nome = "Veneno/Peçonha",
				},
			},
			categoria = "Formigas Quimera",
			descricao = "Sem Antecedentes. Ver Regra.",
			fagogenese_options = {
				"Ave",
				"Mamífero",
				"Réptil/Anfíbio",
				"Aquático",
				"Inseto/Insectóide",
				"Bestas Mágicas",
			},
			fonte = "[1, 2]",
			nome = "Formiga Quimera",
		},
		{
			aumento_atributo = "Nenhum",
			caracteristicas = {
				{
					efeito = "Possui ecolocalização de 5m, não precisando depender dos sentidos de visão e audição quando submerso no solo.",
					nome = "Ecolocalização",
				},
				{
					efeito = "9m comum e 4,5m subterrâneo.",
					nome = "Deslocamento Subterrâneo",
				},
			},
			categoria = "Modificados e Fantasia",
			descricao = "Povo verme.",
			fonte = "[5, 6]",
			nome = "Wormorfos",
			opcoes_caracteristica = {
				{
					efeito = "Resistência a dano de impacto/concussão (corpo menos rígido, adapta-se e \"engloba\" o impacto). Em contrapartida, sofre 1/4 (25%, arredondado para cima) a mais de dano perfurante ou cortante, por ter estrutura mais vulnerável a penetrações.",
					nome = "Corpo Malemolente",
				},
				{
					efeito = "Além de se submergir, pode puxar inimigos para o solo: usa \"Agarrão/Puxão\" contra a CA do alvo no lugar de um Teste Contestado. Em caso de sucesso, pode gastar a Ação Bônus para submergir puxando o alvo para o solo, aplicando as condições \"Caído\" e \"Imóvel\".",
					nome = "Enterrada",
				},
			},
		},
		{
			aumento_atributo = "Escolha +2",
			caracteristicas = {
				{
					efeito = "Enxerga na penumbra a até 18m no escuro. Sua percepção capta o fluxo vital de plantas e animais, permitindo detectar seres vivos mesmo através de folhagens densas, desde que não estejam ocultos por Zetsu.",
					nome = "Visão na Penumbra",
				},
			},
			categoria = "Modificados e Fantasia",
			descricao = "Herança feérica.",
			fonte = "[5, 6]",
			nome = "Elfos e Meio-Elfos",
			opcoes_caracteristica = {
				{
					efeito = "Durante descansos ou meditações em ambientes naturais, recupera +1 ponto adicional de exaustão e reduz pela metade os efeitos de exaustão por clima, fome ou sede. Uma vez por combate, ganha +1 em qualquer teste de Resistência ou Reflexo até o final do turno.",
					nome = "Pulsar Verde",
				},
				{
					efeito = "Vantagem em testes de Percepção, Furtividade e Sobrevivência em ambientes naturais. Pode neutralizar/acalmar criaturas agressivas (teste de Carisma vs Sabedoria da criatura, 1x/missão).",
					nome = "Fluxo Harmônico",
				},
				{
					efeito = "Vantagem em testes de resistência física contra venenos, toxinas e doenças.",
					nome = "Expiração Vital",
				},
			},
		},
		{
			aumento_atributo = {
				CON = 1,
				FOR = 1,
			},
			caracteristicas = {
				{
					efeito = "Enxerga na penumbra a até 18m no escuro.",
					nome = "Visão na Penumbra",
				},
				{
					efeito = "Quando reduzido a 0 pontos de vida sem morrer completamente, pode voltar para 1 ponto de vida. Utilizável um número de vezes por dia igual à sua proficiência.",
					nome = "Resistência Implacável",
				},
			},
			categoria = "Modificados e Fantasia",
			descricao = "Guerreiros robustos.",
			fonte = "[5, 6]",
			nome = "Meio-Orcs",
		},
		{
			aumento_atributo = {
				CON = 2,
			},
			caracteristicas = {
				{
					efeito = "Enxerga na penumbra a até 18m no escuro.",
					nome = "Visão na Penumbra",
				},
				{
					efeito = "7,5m.",
					nome = "Deslocamento",
				},
			},
			categoria = "Modificados e Fantasia",
			descricao = "Robustos.",
			fonte = "[7]",
			nome = "Anões",
			opcoes_caracteristica = {
				{
					efeito = "Vantagem em testes de resistência contra toxinas e venenos, e resistência contra efeitos de fadiga ou envenenamento por aura.",
					nome = "Resiliência Anã",
				},
				{
					efeito = "Redução de 10% no custo para manter técnicas passivas (Ten constante, Gyo prolongado — gasto mínimo de 5%).",
					nome = "Estabilidade de Aura",
				},
				{
					efeito = "+2 em testes relacionados à criação, manutenção ou modificação de equipamentos (mesmo por meio de Hatsu). Identifica o equilíbrio de aura em objetos sem precisar de Gyo.",
					nome = "Instinto de Forja",
				},
			},
		},
		{
			aumento_atributo = "Escolha +2",
			caracteristicas = {
				{
					efeito = "Resistência ao elemento ligado à cor do seu ancestral dracônico (ver tabela do manual: Azul/Bronze/Cobre-Elétrico ou Ácido, Branco-Frio, Latão/Ouro/Vermelho-Fogo, Negro-Ácido, Prata-Elétrico, Verde-Veneno).",
					nome = "Resistência Ancestral",
				},
				{
					efeito = "Ação Principal: ataque em área, TR = 10 + CON + Proficiência. Dano 2d6 num fracasso (metade num sucesso); 3d6 no 6º nível; 4d6 no 11º nível. Formato e atributo do TR variam pela cor do ancestral (linha 1,5m/9m com TR de DES, ou cone de 4,5m com TR de DES/CON).",
					nome = "Arma de Sopro",
				},
			},
			categoria = "Modificados e Fantasia",
			descricao = "Herança dragão.",
			fonte = "[7]",
			nome = "Draconatos",
		},
		{
			aumento_atributo = {
				DES = 1,
				INT = 2,
			},
			caracteristicas = {
				{
					efeito = "Deslocamento de 7,5m.",
					nome = "Tamanho Pequeno",
				},
			},
			categoria = "Modificados e Fantasia",
			descricao = "Pequenos e sortudos.",
			fonte = "Extra",
			nome = "Halflings",
			opcoes_caracteristica = {
				{
					efeito = "Quando obtiver um 1 natural em uma jogada de ataque, teste de habilidade ou teste de resistência, pode rolar novamente e deve usar o novo resultado (1x por dia/sessão).",
					nome = "Sortudo",
				},
				{
					efeito = "Vantagem em testes de resistência contra ficar Amedrontado/Intimidado.",
					nome = "Bravura",
				},
				{
					efeito = "Pode mover-se através do espaço de qualquer criatura de tamanho maior que o seu.",
					nome = "Agilidade Halfling",
				},
			},
		},
		{
			aumento_atributo = "Escolha +2",
			caracteristicas = {
				{
					efeito = "Deslocamento de 7,5m.",
					nome = "Tamanho Pequeno",
				},
				{
					efeito = "Enxerga na penumbra a até 18m no escuro.",
					nome = "Visão na Penumbra",
				},
			},
			categoria = "Modificados e Fantasia",
			descricao = "Inventores.",
			fonte = "Extra",
			nome = "Gnomos",
			opcoes_caracteristica = {
				{
					efeito = "Vantagem em testes de Percepção e Análise de Aura.",
					nome = "Percepção Pequenina",
				},
				{
					efeito = "Vantagem em todos os testes de resistência de Inteligência, Sabedoria e Carisma contra Hatsu.",
					nome = "Esperteza Gnômica",
				},
				{
					efeito = "+2 em testes de Esquiva; -1 em testes de Força física pura (empurrar, puxar ou levantar algo pesado).",
					nome = "Tamanho ao Meu Favor",
				},
			},
		},
		{
			aumento_atributo = "Escolha +2",
			caracteristicas = {
				{
					efeito = "Deslocamento de 9m.",
					nome = "Tamanho Médio",
				},
			},
			categoria = "Modificados e Fantasia",
			descricao = "Gigantes de pedra.",
			fonte = "Extra",
			nome = "Golias",
			opcoes_caracteristica = {
				{
					efeito = "Após receber um dano, reduz à metade o dano de impacto, perfurante ou cortante recebido — um número de vezes por dia igual à sua proficiência.",
					nome = "Resistência de Pedra",
				},
				{
					efeito = "Usa FOR em vez de DES para calcular a precisão em ataques de arremesso manual com armas.",
					nome = "Alvo Destroçado",
				},
				{
					efeito = "Vantagem em testes de resistência contra fadiga, frio e calor.",
					nome = "Corpo de Pedra",
				},
			},
		},
		{
			aumento_atributo = "Varia",
			caracteristicas = {
				{
					efeito = "Tamanho de Miúdo até Grande. Deslocamento igual a 2 tipos diferentes de movimento, dependendo de sua \"programação\".",
					nome = "Tamanho e Deslocamento",
				},
				{
					efeito = "Pode alterar no início de cada dia os pontos de atributo que recebe, enquanto reavalia e limpa dados de seu \"núcleo-processador e disco rígido\" na medida que evolui.",
					nome = "Atualização de Disco Rígido",
				},
				{
					efeito = "Não fica exausto biologicamente, mas recebe a mesma condição ao entrar em curto-circuito por dano elétrico.",
					nome = "Curto Circuito",
				},
			},
			categoria = "Tecnológicos e Sobrenaturais",
			descricao = "Andróides.",
			fonte = "[8, 9]",
			nome = "Neans",
		},
		{
			aumento_atributo = {
				["Físico"] = 1,
				INT = 2,
			},
			caracteristicas = {
				{
					efeito = "Tamanho Médio. Deslocamento de 9m comum e 3m planar (aumenta em 3m para cada casta que sobe: Vampiro, Lorde Vampiro, Conde Vampiro, Imperador Vampiro).",
					nome = "Tamanho e Deslocamento",
				},
				{
					efeito = "Após um ataque de mordida bem-sucedido, pode gastar a Ação Bônus para o alvo rolar um TR de CON (CD = 10 + CON + Prof. do vampiro). Se falhar, o vampiro rouba 10% da aura dele, +10% para cada 5 pontos de diferença na falha.",
					nome = "Sugar Aura",
				},
				{
					efeito = "Após 2 rodadas sob a luz do sol, sofre -5 na CA até sair do contato com a luz. Aparições durante o dia em locais protegidos aplicam só -2 na CA.",
					nome = "Exposição Solar",
				},
			},
			categoria = "Tecnológicos e Sobrenaturais",
			descricao = "Seres noturnos.",
			fonte = "[8, 9]",
			nome = "Vampiros",
		},
		{
			aumento_atributo = "Escolha +2",
			caracteristicas = {
				{
					efeito = "Uma vez por dia/cena/missão/semana, usuários de NEN podem rolar um dado aleatório entre a quantidade de suas Restrições/Condições para ignorar a que for sorteada naquela ativação. Regra geral: a duração do Hatsu escolhido precisa ser \"Instantânea\"; para os demais critérios, consulte seu mestre após a definição completa do Hatsu.",
					nome = "Interpretação Travessa/Trapaceira",
				},
			},
			categoria = "Tecnológicos e Sobrenaturais",
			descricao = "Nen Post-Mortem.",
			fonte = "Extra",
			nome = "Djins",
		},
		{
			aumento_atributo = {
				DES = 1,
				FOR = 2,
			},
			caracteristicas = {
				{
					efeito = "Enxerga na penumbra a até 18m como se fosse luz plena, e no escuro como se fosse penumbra.",
					nome = "Visão no Escuro",
				},
			},
			categoria = "Raças Incomuns",
			descricao = "Brutais.",
			fonte = "Extra",
			nome = "Bugbears",
			opcoes_caracteristica = {
				{
					efeito = "Ao surpreender um alvo e acertá-lo no primeiro ataque do combate, causa 2d6 de dano extra e ataca com vantagem (por estar em furtividade). Só uma vez por alvo combatido.",
					nome = "Ataque Surpresa",
				},
				{
					efeito = "Após três rodadas lutando contra o mesmo oponente, ganha +1 de acerto contra aquele alvo específico.",
					nome = "Instinto Adaptativo",
				},
				{
					efeito = "Uma vez por combate, ao ser alvo de um ataque surpresa (ou de uma técnica oculta de Nen), pode reagir automaticamente gastando 2 reações em vez de precisar de 1 disponível normalmente.",
					nome = "Percepção Instintiva",
				},
				{
					efeito = "Ao ativar Ren, causa um efeito intimidador mesmo sem querer: teste contestado de Intimidação com vantagem para o Bugbear; se o alvo falhar, fica intimidado até o final da rodada (contra animais/iniciantes pode causar Amedrontado). Usável um número de vezes por dia igual à proficiência.",
					nome = "Pressão de Predador",
				},
			},
		},
		{
			aumento_atributo = {
				INT = -1,
				PRE = -1,
				SAB = 4,
			},
			caracteristicas = {
				{
					efeito = "Enxerga na penumbra a até 18m como se fosse luz plena, e no escuro como se fosse penumbra.",
					nome = "Visão no Escuro",
				},
			},
			categoria = "Raças Incomuns",
			descricao = "Meio-Dríades.",
			fonte = "Extra",
			nome = "Dahllans",
			opcoes_caracteristica = {
				{
					efeito = "Testes sociais de Persuasão e Intuição recebem +1 contra seres conscientes. Sente emoções superficiais de seres vivos tocados ou em interação direta, desde que não estejam em Zetsu total — uma forma primitiva de leitura emocional, sem invadir a mente.",
					nome = "Empatia Natural",
				},
				{
					efeito = "Capaz de entender e falar com animais, podendo conversar, pedir informações ou apenas irritá-los. Insetos, animais terrestres, marinhos e bestas mágicas se encaixam, desde que possuam INT acima de 0.",
					nome = "Dr. Dolittle",
				},
			},
		},
		{
			aumento_atributo = {
				FOR = 1,
				SAB = 2,
			},
			caracteristicas = {
				{
					efeito = "Em ambiente de natureza (florestas e afins), pode usar Ação Bônus + movimento para se \"transportar\" de uma árvore/arbusto a outra sem ser percebido, em até 12m. Usável por dia um número de vezes igual ao modificador de Sabedoria.",
					nome = "Passo Oculto",
				},
			},
			categoria = "Raças Incomuns",
			descricao = "Guardiões.",
			fonte = "Extra",
			nome = "Firbolgs",
		},
		{
			aumento_atributo = "Escolha +2",
			caracteristicas = {
				{
					efeito = "Enxerga na penumbra a até 9m como se fosse luz plena, e no escuro como se fosse penumbra.",
					nome = "Visão no Escuro",
				},
				{
					efeito = "Ao causar dano a uma criatura maior que você (ataque ou Hatsu), pode causar dano adicional igual à sua proficiência somada ao seu nível de personagem. Após usar, só pode usar de novo após terminar um descanso.",
					nome = "Fúria do Pequeno (Nanico)",
				},
			},
			categoria = "Raças Incomuns",
			descricao = "Maliciosos.",
			fonte = "Extra",
			nome = "Goblins",
		},
	},
	skillMap = {
		CON = {},
		DES = {
			"Acrobacia",
			"Furtividade",
			"Prestidigitação",
		},
		FOR = {
			"Atletismo",
		},
		INT = {
			"Arcanismo",
			"História",
			"Investigação",
			"Natureza",
			"Religião",
		},
		PRE = {
			"Atuação",
			"Enganação",
			"Intimidação",
			"Persuasão",
		},
		SAB = {
			"Lidar com Animais",
			"Intuição",
			"Medicina",
			"Percepção",
			"Sobrevivência",
		},
	},
	skills = {
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
	},
	xpTable = {
		50,
		150,
		350,
		500,
		800,
		1000,
		1500,
		2500,
		3200,
		4000,
		5000,
		6500,
	},
}
