-- HxH5e Character Schema v0.3 (M0.8 + Afinidade/Genialidade + M0.9 Nen Base)
-- Alinhado ao app (ficha-hx-h5e.vercel.app / GitHub Ficha_HxH5e).
-- Contrato evolutivo: NÃO congelar. Atualizações do app viram patches aqui.
return {
	SchemaVersion = "0.3",
	Defaults = {
		Id = nil,
		OwnerUserId = nil,
		Name = "",
		Race = nil,
		Background = nil,
		Class = nil,            -- categoria de Nen (mesma de Nen.Category)
		Level = 0,
		CharacterType = "PLAYER",
		ControlMode = "PLAYER",

		Attributes = {
			FOR = { value = 10, save = false },
			DES = { value = 10, save = false },
			CON = { value = 10, save = false },
			INT = { value = 10, save = false },
			SAB = { value = 10, save = false },
			PRE = { value = 10, save = false },
		},

		Vitals = {
			HP = { Current = 0, Max = 0 },
			Aura = { Current = 100, Max = 100 },
			Sanidade = { Current = 100, Max = 100 },
			RDM = 0,
			CA = 10,
			Reacoes = 7,
			Deslocamento = 9,
			DeslocamentoPlanar = 0, -- so Vampiros usam (ver VampiroCasta)
		},
		VampiroCasta = nil, -- "Vampiro"/"Lorde Vampiro"/"Conde Vampiro"/"Imperador Vampiro" (so raca Vampiros)

		-- ================= Level-up (ver LevelUpService.lua) =================
		PendingLevelUps = {}, -- fila de niveis ainda nao confirmados (ex: {3,4} se subiu 2 de uma vez)
		PendingAttrPoints = 0, -- pontos de atributo ganhos, ainda nao distribuidos
		PendingInclinationPoints = 0, -- pontos de inclinacao (P.I) ganhos, ainda nao escolhidos
		PendingProficiencyPoints = 0, -- pontos de proficiencia ganhos, ainda nao aplicados
		EmZetsu = false, -- ver NenService.ActivatePrinciple/HatsuService.ActivateHatsu
		Achievements = {}, -- lista de IDs de conquistas desbloqueadas (ver AchievementsDB.lua)
		AchievementCounters = {}, -- ex: { TenAtivacoes = 5, RenAtivacoes = 12 } (so pras conquistas tipo "contador")
		RaceCaracteristicaEscolhida = nil, -- nome da opcao escolhida (ex: raca Anao)
		Organizacoes = {}, -- lista de { orgId, nivel (1-5), reputacao, status }, ver OrganizationService.lua

		-- "Tendencia" (Heroico/Caotico/Neutro/Maligno) -- existe no
		-- webapp real (char.alignment) mas nunca tinha sido portada.
		-- Padrao "Neutro". Muda com um clique (ver FichaClient), sem
		-- remote proprio -- reaproveita SetCharacterField generico se
		-- ja existir, senao um remote dedicado sera criado.
		Alignment = "Neutro",

		-- Progressao de casta Vampiro (Sugar Aura): contadores usados
		-- pelos requisitos reais de promocao (ver CharacterService.lua).
		VampiroAuraTotalDrenada = 0,
		VampiroSeresDrenados = {},
		VampiroSobreviveuFerimentoFatal = false,

		-- Gostos/Desgostos (Sanidade): tags escolhidas pelo jogador na
		-- Bio, ver SanityTagsDB.lua/SanityTagService.lua.
		GostosEscolhidos = {},
		DesgostosEscolhidos = {},
		TagCooldowns = {}, -- [tagId] = hora de jogo do ultimo disparo
		SozinhoDesde = nil, -- hora de jogo (Desgosto "isolamento")

		-- Surto de Sanidade (4 niveis por limiar de %), ver
		-- SanitySurgeDB.lua/SanitySurgeService.lua.
		SurtosAtivos = { curta = nil, longa = nil, leve = nil, pesado = nil },
		SurtoJaTriggado = { curta = false, longa = false, leve = false, pesado = false },
		UltimaAcaoPrincipalHoras = nil,

		Nen = {
			Category = nil,   -- INTENSIFICAÇÃO | TRANSMUTAÇÃO | MATERIALIZAÇÃO | EMISSÃO | MANIPULAÇÃO | ESPECIALIZAÇÃO
			Affinity = {
				Roll = nil,   -- valor do 1d100
				Tier = nil,   -- Baixa | Media | Alta | Excepcional
			},
			Genius = {
				Roll = nil,   -- soma do 2d20 (2 a 40)
				Tier = nil,   -- Normal | Talentoso | Genio | Ultimate
			},
			Dominio = {
				-- Fundamentais (0-3): 1 P.N por nível
				Ten = 0, Ren = 0, Zetsu = 0,
				-- Aprimoramento após Maestria (até 7 P.N)
				Ten_pn = 0, Ren_pn = 0, Zetsu_pn = 0,
				-- Opção de aprimoramento (1 ou 2)
				Ren_opcao = 1, Zetsu_opcao = 1,
				-- Avançados: desbloqueio + Superior (_sup) + Aprimoramento (_pn até 8)
				En = false, En_sup = false, En_pn = 0,
				Inp = false, Inp_sup = false, Inp_pn = 0,  -- IN (inp p/ não conflitar)
				Gyo = false, Gyo_sup = false, Gyo_pn = 0,
				Shu = false, Shu_sup = false, Shu_pn = 0,
				Ken = false, Ken_sup = false, Ken_pn = 0,
				Ko = false, Ko_sup = false, Ko_pn = 0,
				Ryu = false, Ryu_sup = false, Ryu_pn = 0,
			},
			Principles = {},
		},

		Hatsus = {},
		Skills = {},
		Expertise = {},
		Inventory = {}, -- lista de { Name, Qty } (ver ItemsDB.lua pra detalhes de cada item)
		Money = 0, -- moeda pra comprar/vender na loja (ver ItemsDB.lua)
		Conditions = {},
		Inclinations = {
			Positive = {},
			Negative = {},
		},
		Bio = {
			Personality = "",
			Goals = "",
			Likes = "",
			Hates = "",
			Historia = "",
			Organizacoes = "",
			Inimigos = "",
			Aliados = "",
		},

		-- Foco de Caça e Ação Protagonista (livro: "Todo Hunter Precisa
		-- estar caçando algo"). O foco e o objetivo grandioso do
		-- personagem (tipo de Hunter que quer ser, ou inimigo especifico
		-- adquirido na aventura); permanece ate ser cumprido. A Ação
		-- Protagonista funciona como a Inspiracao do D&D -- 1x por
		-- sessao, só quando ligada ao Foco de Caça -- pra: (1) forcar o
		-- inimigo a rerolar com desvantagem, (2) o proprio jogador
		-- rerolar com vantagem, ou (3) aplicar 3d6 pra diminuir a
		-- rolagem do inimigo ou aumentar a rolagem anterior. O efeito em
		-- si e resolvido manualmente pelo mestre/jogador (nao ha um
		-- "replay" automatico da ultima rolagem no sistema) -- o remote
		-- so controla se o recurso esta disponivel.
		FocoDeCaca = "",
		AcaoProtagonistaDisponivel = true,

		-- Armadura equipada (torso) e escudo (mao secundaria).
		-- Quando ativa, a CA da armadura SOBREPOE 10+CON (nao soma);
		-- escudos SOMAM por cima disso, sao cumulativos. Durabilidade
		-- maxima = caBase do item (ver ItemsDB.armaduras), reduz 1 por
		-- golpe sofrido (2 se dano rajada/explosivo), exceto enquanto
		-- o personagem estiver com TEN/KEN/RYU ativo. Ao chegar em 0,
		-- a armadura quebra: volta pro CA base 10+CON ate ser trocada.
		ArmaduraEquipada = nil,
		EscudoEquipado = nil,

		-- Slots de hotkey configuraveis (menu radial): cada posicao
		-- guarda o nome de um principio de Nen ja desbloqueado, ou
		-- `false` se vazio -- NUNCA nil no meio do array (isso quebra
		-- o operador # do Lua e a serializacao do DataStore). Comeca
		-- com 4 slots -- o Lucas pode pedir mais depois.
		HotkeySlots = { false, false, false, false },
		-- Nen Post-Mortem: se o jogador USA a Ação Protagonista numa
		-- rodada e MESMO ASSIM falha causando/permitindo a propria
		-- morte, o Nen "desperta" postumamente com um voto/condicao
		-- narrativa. Puramente narrativo, sem mecanica numerica -- so
		-- registra que aconteceu e a descricao que o jogador deu.
		NenPostMortem = nil, -- { Voto = "texto descrito pelo jogador", Data = os.time() }

		History = {},
		ImageUrl = nil,
		LastMod = nil,
		CreatedAt = nil,
		UpdatedAt = nil,
	},
}