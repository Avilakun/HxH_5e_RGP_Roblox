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
		},

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
		Inventory = {},
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
		},
		History = {},
		ImageUrl = nil,
		LastMod = nil,
		CreatedAt = nil,
		UpdatedAt = nil,
	},
}