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
		History = {},
		ImageUrl = nil,
		LastMod = nil,
		CreatedAt = nil,
		UpdatedAt = nil,
	},
}