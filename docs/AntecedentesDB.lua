-- AntecedentesDB.lua -- gerado automaticamente a partir de config.js
-- (chave "antecedentes") do webapp (github.com/Criadores-HxH-5e/
-- Ficha_HxH5e). 26 antecedentes (backgrounds) de criacao de
-- personagem, cada um com descricao, proficiencias, equipamento
-- inicial e caracteristicas (tracos fixos que o antecedente concede).
--
-- Mecanica que nunca tinha sido notada/documentada como pendencia
-- antes -- achada explorando o resto do config.js (mesmo arquivo de
-- onde saiu RacasDB.lua) atras de mais conteudo reaproveitavel.
local AntecedentesDB = {
	{
		nome = "Amigo dos Animais",
		descricao = "Pessoas que se importam com o equilíbrio da natureza, mas que também adoram um desafio, andam pelas florestas e pântanos buscando encontrar criaturas fantásticas e desconhecidas. Por outro lado, muitos amigos dos animais são simplesmente amados pela natureza como se fizessem parte dela.",
		proficiencias = "Escolha um Kit dentre os recebidos e Lidar com Animais e Natureza",
		equipamento = {
			"Qualquer arma simples",
			"Qualquer arma simples",
			"Kit de Caça e Rastreio de Criaturas ou Kit Médico",
		},
		caracteristicas = {
			{
				nome = "Habitat Natural",
				efeito = "Animais e Feras (inclusive hostis) normalmente o consideram outra criatura não hostil. Seus companheiros são tratados como membros aliados do seu bando, desde que não atuem de forma hostil.",
			},
			{
				nome = "Tarzan/Jane",
				efeito = "De alguma forma você se acostumou com a linguagem de animais e feras. Ao passar um minuto interagindo com uma criatura não hostil você pode identificar alguma informação que ela já tenha conhecimento sobre o ambiente ou uma outra criatura.",
			},
			{
				nome = "Companheiro Inabalável",
				efeito = "Você tem um companheiro que te concede a Ação 'Ajuda' no turno dele. Ele te entende e obedece comandos simples.",
			},
		},
	},
	{
		nome = "Aristocrata",
		descricao = "Pessoas que entendem de riqueza, poder e privilégios. Mas não só entendem, elas desfrutam e estão acostumadas a isso. Através de algum título de nobreza, sua família exerce algum tipo de influência política significativa.",
		proficiencias = "História e Religião",
		equipamento = {
			"Celular ou Câmera",
			"Computador",
			"Mochila 3 (Mala)",
			"Qualquer arma simples",
		},
		caracteristicas = {
			{
				nome = "Posição Privilegiada",
				efeito = "Você é bem-vindo na alta sociedade e as pessoas assumem que você tem o direito de estar onde está. As pessoas comuns fazem todos os esforços para acomodá-lo e evitar seu desprazer.",
			},
			{
				nome = "Mauricinho / Patricinha",
				efeito = "Você recebe toda semana uma quantia correspondente aos recursos financeiros de sua família de acordo com a tabela ao rolar 1d4.",
			},
		},
	},
	{
		nome = "Artista",
		descricao = "Pessoas com as mais variadas capacidades de entretenimento se aventuram no mundo artístico para realizar seus sonhos vivendo daquilo que amam ou buscando alcançar fama e dinheiro.",
		proficiencias = "Kit de Ferramenta de Ofício e escolha 3 dentre: Acrobacia, Atuação, Intuição ou Prestidigitação",
		equipamento = {
			"Mala de Roupas ou Mochila Comum/Maleta",
			"Câmera ou Celular",
			"Kit de Ferramentas de Ofício",
		},
		caracteristicas = {
			{
				nome = "Tudo no @",
				efeito = "Comerciantes que negociam com você reconhecem seu trabalho como artista, você tem chance (50%) de pagar suas compras com merchandising.",
			},
			{
				nome = "Virando a Cadeira",
				efeito = "Apresentar sua arte às pessoas antes de conversar ou negociar, faz com que fiquem fascinadas por você e tenham uma inclinação a concordar com sua opinião. Vantagem em testes de Carisma.",
			},
		},
	},
	{
		nome = "Assassino",
		descricao = "Assassinos famosos como a família Zoldyck e ainda outros, desenvolvem habilidades próprias para sua profissão e, com isso, se tornam peritos naquilo que fazem. A arte de matar de forma rápida.",
		proficiencias = "Escolha um Kit dentre os recebidos e Acrobacia e Furtividade",
		equipamento = {
			"Adaga/Faca",
			"Veneno Variante: 1 frasco",
			"Pochete de Perna",
			"Kit de disfarce ou Kit de Falsificação",
		},
		caracteristicas = {
			{
				nome = "Eco do Ritmo",
				efeito = "Se concentrar em seu turno completo projeta um padrão hipnótico, fazendo com que todas as criaturas hostis tenham desvantagem em jogadas de ataque direcionadas a você.",
			},
			{
				nome = "Sumidão",
				efeito = "Vantagem em todos os testes de furtividade de qualquer natureza e não é descoberto ao realizar um ataque enquanto se está furtivo.",
			},
			{
				nome = "Máquina de Matar",
				efeito = "Dano dobrado (nos dados) em ataques realizados enquanto se está oculto/furtivo.",
			},
		},
	},
	{
		nome = "Caçador de Feras",
		descricao = "Nesse mundo existem diversas criaturas desconhecidas e hostis que se reproduzem nas sombras enquanto sobrepujam habitat naturais de outras criaturas.",
		proficiencias = "Escolha um Kit dentre os recebidos e Natureza e Sobrevivência",
		equipamento = {
			"Espingarda Carregada ou Tazer",
			"Kit de Caça e Rastreio de Criaturas ou Kit Antídoto",
			"Qualquer arma simples ou Marcial e Rede",
		},
		caracteristicas = {
			{
				nome = "Temos que Pegar!",
				efeito = "Vantagem em todos os testes relacionados a rastrear feras naturais e bestas mágicas (inclusive bestas de NEN).",
			},
			{
				nome = "Desbravador",
				efeito = "Você recebe +2 em sobrevivência e anula qualquer penalidade de sobrevivência não causadas por Hatsus.",
			},
		},
	},
	{
		nome = "Cientista",
		descricao = "Após muito estudo e dedicação, começam a arriscar a vida também no campo experimental para comprovar suas teorias e hipóteses.",
		proficiencias = "Escolha 2 perícias com Kits e 3 dentre: História, Investigação, Medicina, Natureza, Prestidigitação, Religião ou Sobrevivência.",
		equipamento = {
			"Qualquer arma simples",
			"1 Mochila Comum/Maleta",
			"Kit Antídoto ou Kit Médico",
			"Kit de Armas ou Kit Forense ou Kit de Hacker",
		},
		caracteristicas = {
			{
				nome = "Explorar Fraqueza",
				efeito = "O personagem pode utilizar sua ação principal para analisar o oponente ou situação tendo vantagem no próximo ataque contra um inimigo ou teste baseado em inteligência.",
			},
			{
				nome = "Mestre do Planejamento",
				efeito = "Ao utilizar um item / kit escolhido no antecedente, você ganha um 1d6 para rolar em qualquer jogada ou teste cabível 3 vezes por dia.",
			},
		},
	},
	{
		nome = "Criminoso",
		descricao = "Essas pessoas normalmente vivem à margem da lei, desprezando e quebrando os regulamentos da sociedade.",
		proficiencias = "Escolha um Kit dentre os recebidos e Enganação e Furtividade",
		equipamento = {
			"Qualquer arma simples ou Marcial",
			"1 Pochete",
			"Item do Tipo de Criminoso (Cleptomaníaco, Estelionatário, etc)",
		},
		caracteristicas = {
			{
				nome = "Cleptomaníaco",
				efeito = "Inicia com celular roubado e kit de ferramentas de ofício.",
			},
			{
				nome = "Estelionatário",
				efeito = "Acesso a kits de falsificação ou disfarce para golpes.",
			},
			{
				nome = "Político Corrupto",
				efeito = "Possui informações privilegiadas (Pen-Drive) para manipular poder e influência.",
			},
			{
				nome = "Traficante",
				efeito = "Inicia com recursos financeiros de vendas ilícitas e contatos de fornecedores.",
			},
		},
	},
	{
		nome = "Discípulo",
		descricao = "Uma pessoa que é orientada por um mestre e normalmente continua seguindo suas orientações. Dependendo do mestre o discípulo pode se desenvolver em áreas diferentes a partir de suas aptidões.",
		proficiencias = "Kit de Ferramenta de Ofício e Escolha 3 perícias quaisquer",
		equipamento = {
			"Celular com contato ou anotações de seu mestre",
			"Qualquer arma simples ou Marcial",
			"Kit de Ferramentas de Ofício",
		},
		caracteristicas = {
			{
				nome = "Abre-te Sésamo",
				efeito = "Você consegue acessar alguns lugares ou pessoas e informações a partir da fama do seu mestre e da credibilidade que o nome lhe confere.",
			},
			{
				nome = "Mateus 28.18-20",
				efeito = "Seu mestre supostamente morreu ou desapareceu, porém ele lhe concedeu um ensinamento, poder, item, equipamento ou marca que te permite continuar sua história.",
			},
		},
	},
	{
		nome = "Guarda Costas",
		descricao = "Arduamente treinados para trabalhos físicos, guarda-costas podem ser pessoas dispostas a fazer um trabalho perigoso por dinheiro.",
		proficiencias = "Atletismo e Intimidação",
		equipamento = {
			"Pistola",
			"Qualquer arma simples ou Marcial",
		},
		caracteristicas = {
			{
				nome = "Artista Marcial",
				efeito = "Você treinou técnicas e desenvolveu seu corpo ao máximo para o combate corpo-a-corpo. Seus golpes desarmados causam 1d6 no lugar de 1d4.",
			},
			{
				nome = "Horário de Trabalho",
				efeito = "Você consegue escolher uma pessoa para manter sua atenção de forma constante. Você tem vantagem e +2 em jogadas de percepção para encontrar essa pessoa.",
			},
		},
	},
	{
		nome = "Líder",
		descricao = "Você é uma pessoa que procura mudar a sociedade ao seu redor jogando na arena da política, pessoas e personalidades.",
		proficiencias = "Escolha três entre Enganação, História, Investigação ou Persuasão",
		equipamento = {
			"1 pílula de Hemoglobina",
			"1 pílula de Hemoglobina variante",
			"Qualquer arma simples",
			"Qualquer outro Kit",
		},
		caracteristicas = {
			{
				nome = "Presença de Liderança",
				efeito = "Sua presença notável e inspiradora concede 1d4 (grau básico) que pode ser utilizado em qualquer jogada de seus aliados (cada um) até o fim do dia.",
			},
		},
	},
	{
		nome = "Marinheiro",
		descricao = "Você navegou em um navio pelo mar durante anos, enfrentando poderosas tormentas e monstros abissais.",
		proficiencias = "Atletismo e Percepção",
		equipamento = {
			"Corrente Pesada ou Rede",
			"Qualquer arma simples ou Marcial",
		},
		caracteristicas = {
			{
				nome = "Grande Herói da Marinha",
				efeito = "Você não gasta passagem em navios, jatos, aviões e dirigíveis. Possui Documento de patente e Experiência de Convés.",
			},
			{
				nome = "Imperador do Mar",
				efeito = "Buscando mais poder você ouviu falar de NEN. Possui Experiência de Convés, Pistola ou Mosquete, Arma simples ou Marcial e Relógio à prova d'água.",
			},
		},
	},
	{
		nome = "Mentalista",
		descricao = "Conhecedores do funcionamento da mente, mentalistas são profissionais que trabalham com a realidade do pensamento ou com a ilusão.",
		proficiencias = "Escolha um Kit dentre os recebidos e Enganação ou Persuasão e Intuição",
		equipamento = {
			"Qualquer arma simples",
			"Kit de Falsificação ou Kit de Ferramenta de Ofício",
		},
		caracteristicas = {
			{
				nome = "Perceptivo",
				efeito = "+2 em testes de Percepção.",
			},
			{
				nome = "Referência Bibliográfica",
				efeito = "Possui vantagem em todos os testes de Carisma contra humanoides com inteligência igual ou superior a Modificador 0.",
			},
		},
	},
	{
		nome = "Negociante",
		descricao = "Indivíduos acostumados a lidar com o público e, por isso, possuem facilidade na oratória e na persuasão.",
		proficiencias = "Atuação, Persuasão e Prestidigitação",
		equipamento = {
			"Qualquer equipamento dentro do orçamento de 2.000 $",
			"1 Mala de Roupas",
		},
		caracteristicas = {
			{
				nome = "Camelô",
				efeito = "Quando vender qualquer item seu usado, você consegue vendê-lo com o custo oficial, desde que esteja funcional.",
			},
			{
				nome = "Pechincheiro",
				efeito = "Você consegue comprar qualquer item com desconto de 30% do valor de mercado (exceto armas de fogo e itens místicos).",
			},
		},
	},
	{
		nome = "Ninja",
		descricao = "Esgueirando-se na noite ou no meio da multidão, submetendo seus corpos à torturas para acostumarem-se com a dor e aplicando técnicas nunca antes vistas.",
		proficiencias = "Escolha um Kit dentre os recebidos e Acrobacia ou Atletismo e Furtividade",
		equipamento = {
			"Armas Ninja Variadas",
			"Kit de disfarce ou Kit de Falsificação",
			"Explosivos Ninja",
			"Qualquer arma simples ou Marcial",
		},
		caracteristicas = {
			{
				nome = "Furtividade Superior",
				efeito = "Vantagem em testes de furtividade de qualquer natureza.",
			},
			{
				nome = "Jutsu: Clone das Sombras",
				efeito = "Cria um clone sólido. 5/5 PV, mesmas características sem NEN. Pode usar ação bônus para comandar clones.",
			},
			{
				nome = "Jutsu: Substituição",
				efeito = "Reação para fuga rápida com CA +5 e chance de aparecer em até 3m de onde estava.",
			},
		},
	},
	{
		nome = "Órfão",
		descricao = "Você cresceu nas ruas, sozinho, órfão e pobre. Você não tinha ninguém para cuidar de você ou te alimentar, então, aprendeu a se virar sozinho.",
		proficiencias = "Escolha 2 perícias com Kits recebidos. Recebe ainda Furtividade e Intuição ou Prestidigitação",
		equipamento = {
			"Kit de Disfarce",
			"Kit de Ferramentas de Ofício ou Kit de Armas",
			"Qualquer arma simples",
		},
		caracteristicas = {
			{
				nome = "Segredos da Cidade",
				efeito = "Você conhece os padrões secretos e o fluxo das cidades. Quando não em combate, você e companheiros podem viajar com o dobro da velocidade.",
			},
			{
				nome = "Zé-Pequeno",
				efeito = "Vantagem em todos os testes de Carisma quando se tratam de assuntos, pessoas e temas relacionados à máfia e ao conhecimento do submundo.",
			},
			{
				nome = "Insignificante",
				efeito = "Os inimigos tendem a te ignorar se você não fizer nada que os ameace e nem for o foco inicial de um conflito.",
			},
		},
	},
	{
		nome = "Recluso",
		descricao = "Você viveu em reclusão – ou em uma comunidade isolada como um monastério ou completamente sozinho – por um período importante da sua vida.",
		proficiencias = "Escolha 1 perícia com Kit recebido e Intuição, Medicina e Religião",
		equipamento = {
			"Qualquer arma simples ou Marcial",
			"Kit de Armas ou Kit de Caça e Rastreio de Criaturas",
		},
		caracteristicas = {
			{
				nome = "Monge",
				efeito = "Vantagem em qualquer teste de constituição. Treinou técnicas corporais para o combate desarmado. Seus golpes desarmados causam 1d6 no lugar de 1d4.",
			},
			{
				nome = "Escravo",
				efeito = "Resistente a intimidação com ou sem aura. Pessoas com posição de autoridade alheias a você tem desvantagem em qualquer teste de carisma que não lhe beneficie.",
			},
		},
	},
	{
		nome = "Soldado",
		descricao = "A guerra sempre esteve na vida de soldados. Treinando desde jovem, estudando o uso das armas e armaduras, aprendendo técnicas básicas de sobrevivência.",
		proficiencias = "Escolha 1 perícia com Kit recebido e Atletismo e Intimidação ou Sobrevivência",
		equipamento = {
			"Qualquer arma simples ou Marcial",
			"Kit de Armas ou Kit de Caça e Rastreio de Criaturas",
			"1 Mala de Roupas ou Mochila Comum/Maleta",
		},
		caracteristicas = {
			{
				nome = "Batedor",
				efeito = "Acostumado a abrir caminho para investigar planos do inimigo (Vantagem em Investigação e Furtividade quando estiver sozinho ou 20 metros separado do grupo).",
			},
			{
				nome = "Médico de Combate",
				efeito = "Conhece procedimento que impede malefícios das pílulas de hemoglobina e suas variações e consegue aplicar em uma pessoa por dia.",
			},
			{
				nome = "Atirador de Elite",
				efeito = "Atacar alvos além da distância normal não impõe desvantagem. Ataques ignoram meia cobertura e três-quartos.",
			},
		},
	},
	{
		nome = "Agente de Saúde",
		descricao = "Um amor pela saúde dos outros, ou ainda um compromisso com a vida (seja por promessa ou dinheiro) domina todos dessa origem.",
		proficiencias = "Kit Médico ou Antídoto e Medicina e Percepção",
		equipamento = {
			"Qualquer arma simples",
			"Kit Médico",
			"Kit Antídoto ou 3 pílulas de Hemoglobina variante",
		},
		caracteristicas = {
			{
				nome = "Técnica Medicinal",
				efeito = "Sempre que cura um personagem, você adiciona seu INTx2 no total de PV curados.",
			},
			{
				nome = "Primeiros Socorros",
				efeito = "+3 em testes para estabilizar outros personagens. Aumenta o proveito do Kit de primeiros socorros.",
			},
			{
				nome = "Médico Experimental",
				efeito = "Pode fazer qualquer antídoto com kit de primeiros socorros e algum item da natureza ao redor.",
			},
		},
	},
	{
		nome = "Atleta",
		descricao = "Você tem um físico primoroso e bem trabalhado, você competia/compete em algum tipo de esporte, individual ou coletivo.",
		proficiencias = "Atletismo e Acrobacia ou Intuição ou Percepção",
		equipamento = {
			"Qualquer arma simples",
			"1 pílula de Hemoglobina variante: (Morfina)",
		},
		caracteristicas = {
			{
				nome = "Bolt",
				efeito = "Seu físico primoroso lhe permite fazer uma ação de movimento extra ou saltar em distância metade de seu deslocamento.",
			},
			{
				nome = "Implacável",
				efeito = "Se falhar em um teste de resistência, você pode rolar novamente para o teste, mas é obrigado a manter o novo resultado.",
			},
		},
	},
	{
		nome = "Chef",
		descricao = "Um ótimo cozinheiro, com habilidades de impressionar qualquer um.",
		proficiencias = "Com todos os kits recebidos e Sobrevivência, Percepção e História",
		equipamento = {
			"Qualquer arma simples",
			"Kit de Cozinha",
			"Kit de Caça e Rastreio de Criaturas",
		},
		caracteristicas = {
			{
				nome = "Sabor Único",
				efeito = "Com os ingredientes você pode fazer qualquer um dos tipos de pratos, além de você ter um bônus de 1d6 em testes de CAR 'contra' pessoas que comeram sua comida.",
			},
			{
				nome = "Sabor de Casa",
				efeito = "Com os ingredientes certos, você pode fazer uma comida que vale por um descanso curto.",
			},
		},
	},
	{
		nome = "Circense",
		descricao = "Você sobrevivia com base em seu corpo e suas performances, fazendo malabares, piruetas e o que mais estivesse em seu arsenal.",
		proficiencias = "Kit de Disfarce, Acrobacia, Atuação e Persuasão ou Enganação",
		equipamento = {
			"Qualquer arma simples",
			"Kit de Disfarce",
			"Roupa Chique",
		},
		caracteristicas = {
			{
				nome = "Performance",
				efeito = "Você tem +5 em acrobacia ou prestidigitação para seus números.",
			},
			{
				nome = "Mimetismo",
				efeito = "Você consegue imitar sons que já tenha escutado, incluindo vozes.",
			},
		},
	},
	{
		nome = "Gamer",
		descricao = "Alguém que vivia em casa jogando os mais diversos jogos, talvez um famoso pro-player, talvez apenas alguém que fugia da realidade nos games.",
		proficiencias = "Kit de Hacker, História e Intuição",
		equipamento = {
			"Qualquer arma simples",
			"Dispositivo de PEM",
			"Computador, Celular e Pen Drive",
			"Kit de Hacker",
		},
		caracteristicas = {
			{
				nome = "Dormir não dá XP",
				efeito = "Ao invés de descansar, algumas latas de enérgico te fazem passar por um descanso normal, porém da próxima vez você precisará descansar.",
			},
			{
				nome = "Procrastinador",
				efeito = "Você é acostumado a deixar tudo para a última hora, você consegue fazer tudo na metade do tempo, mas nem sempre ficará bom.",
			},
		},
	},
	{
		nome = "Investigador",
		descricao = "Um detetive, de renome ou não, trabalhando em busca de saber os mistérios do mundo, de casos policiais, ou daquilo que pegar mais.",
		proficiencias = "Kit Forense, Investigação e Atuação ou Intuição ou Percepção ou Enganação",
		equipamento = {
			"Pistola",
			"Kit Forense",
			"Ponto de rádio",
		},
		caracteristicas = {
			{
				nome = "Detetive",
				efeito = "O mestre sempre irá te falar uma coisa extra, sem precisar jogar investigação em toda cena de investigação.",
			},
			{
				nome = "Rede de Contatos",
				efeito = "Graças à influência da sua agência, você pode obter cinco informações por campanha sem custo.",
			},
		},
	},
	{
		nome = "Piloto",
		descricao = "Alguém que manda muito bem no volante, um piloto de fuga, um corredor de Fórmula 1. Pra que frear se eu posso acelerar e dar um drift?",
		proficiencias = "Percepção, Intuição e Prestidigitação (Pilotar)",
		equipamento = {
			"Qualquer arma simples",
			"Moto (pode pagar a diferença para ter um carro)",
		},
		caracteristicas = {
			{
				nome = "Manobras Maníacas",
				efeito = "Com uma ação bônus, e desde que esteja dentro de um veículo, o jogador desvia de qualquer coisa menor que seu veículo automaticamente.",
			},
			{
				nome = "Piloto de Fuga",
				efeito = "Com uma ação normal você pressiona o acelerador como nunca, dobrando sua velocidade atual enquanto em um veículo.",
			},
			{
				nome = "Experiência no Volante",
				efeito = "Você recebe +3 em testes para pilotar.",
			},
		},
	},
	{
		nome = "Religioso",
		descricao = "Talvez um padre, um pastor, talvez um fanático de uma religião pouco conhecida. Mas com certeza alguém a procura de mais pessoas para o seu 'culto'.",
		proficiencias = "Religião e História",
		equipamento = {
			"Qualquer arma simples",
			"Bíblia, ou qualquer outro livro sagrado",
		},
		caracteristicas = {
			{
				nome = "Pregar",
				efeito = "Você recebe +3 em teste de Religião para acalmar. E quando acalmar alguém, a pessoa acalmada receberá uma ação protagonista para gastar no próximo turno.",
			},
			{
				nome = "Orador Público",
				efeito = "Sempre que realizar um teste de Carisma (Persuasão) enquanto estiver falando para um grupo grande de pessoas, você adiciona o dobro do seu bônus de proficiência.",
			},
			{
				nome = "Benção Divina",
				efeito = "Após fazer uma oração a seu deus você se sente momentaneamente motivado e revigorado (seu modificador de SAB sobe um ponto).",
			},
		},
	},
	{
		nome = "Mestre de RPG",
		descricao = "Você viveu sua vida narrando feitos incríveis, mas cansou de contar a história dos outros e resolveu começar sua própria aventura épica.",
		proficiencias = "Atuação, História e Enganação",
		equipamento = {
			"Celular e Um kit de dados",
			"Computador",
			"Casaco reforçado",
		},
		caracteristicas = {
			{
				nome = "Mestre do Improviso",
				efeito = "Seus jogadores já botaram você em tanta enrascada que nada mais te surpreende, você se torna imune a condição 'surpreso' e tem vantagem em testes de carisma para convencer alguém de algo que você acabou de pensar.",
			},
			{
				nome = "Sombra do Verdadeiro Mestre",
				efeito = "Uma vez por missão casualmente seu personagem diz algo que vai virar verdade, você não escolhe o que será isso, tudo que seu personagem falar poderá ser escolhido pelo mestre.",
			},
		},
	},
}

-- Indice por nome, pra busca rapida (mesmo padrao do RacasDB/
-- MonsterDB/CombatInclinationsDB)
local porNome = {}
for _, a in ipairs(AntecedentesDB) do
	porNome[a.nome] = a
end

local AntecedentesDBModule = { Antecedentes = AntecedentesDB }

function AntecedentesDBModule.FindByNome(nome)
	return porNome[nome]
end

return AntecedentesDBModule
