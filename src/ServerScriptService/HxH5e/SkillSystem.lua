--[[
    HxH5e SkillSystem (server) — nucleo do sistema de Pericias.

    Regra de ouro combinada com o Lucas: interacao com o MUNDO
    (pular, correr, coletar) = efeito passivo, sentido no movimento,
    sem rolagem nenhuma. Interacao com OUTRO PERSONAGEM (se esconder,
    intimidar, blefar) = d20 silencioso no servidor.

    ⚠️ DECISAO PENDENTE DE CONFIRMACAO: o Lucas disse "proficiencia
    nao deve passar de +3" mas nao deu a escala exata de como chegar
    la. Implementei de forma conservadora: +2 se treinado (normal),
    +3 se especializado (Expertise, ver character.Expertise) -- NAO
    dobra o +2 (que daria +4 e estouraria o teto). Precisa confirmar
    com o Lucas se essa e a intencao certa.

    Fontes de bonus (todas somadas):
    - Modificador do atributo principal da pericia (ver SKILL_ATTR,
      derivado de SystemDB.skillMap).
    - Bonus de Proficiencia (+2 treinado / +3 especializado), so se a
      pericia estiver em character.Skills (treinada) -- sem treino,
      SO o atributo puro conta (efeito passivo ainda existe, so mais
      fraco).
    - Bonus de Furtividade do Zetsu treinado (NenService.CalcZetsuBonus
      .furtividade), SOMENTE pra pericia "Furtividade" e SOMENTE
      enquanto character.EmZetsu == true.
]]

local SkillSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SystemDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("SystemDB"))
local DiceUtils = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("DiceUtils"))
local NenService = require(script.Parent:WaitForChild("NenService"))
local CharacterService = nil -- setado via SkillSystem.Setup, evita ciclo de require

function SkillSystem.Setup(charService)
	CharacterService = charService
end

-- Inverte SystemDB.skillMap (atributo -> lista de pericias) numa
-- tabela pericia -> atributo, pra lookup direto.
local SKILL_ATTR = {}
for attr, lista in pairs(SystemDB.skillMap) do
	for _, skill in ipairs(lista) do
		SKILL_ATTR[skill] = attr
	end
end

local PROFICIENCY_BONUS = 2
local EXPERTISE_BONUS = 3 -- teto pedido pelo Lucas (nao dobra o PROFICIENCY_BONUS)

local function attrMod(value)
	return math.floor(((value or 10) - 10) / 2)
end

local function isTrained(character, skillName)
	for _, s in ipairs(character.Skills or {}) do
		if s == skillName then return true end
	end
	return false
end

local function isExpert(character, skillName)
	for _, s in ipairs(character.Expertise or {}) do
		if s == skillName then return true end
	end
	return false
end

-- Retorna o bonus TOTAL de uma pericia (pra aplicar em efeito passivo
-- OU como modificador de uma rolagem).
function SkillSystem.GetSkillBonus(character, skillName)
	local attr = SKILL_ATTR[skillName]
	if not attr then
		return 0
	end
	local mod = attrMod(character.Attributes and character.Attributes[attr] and character.Attributes[attr].value)

	local profBonus = 0
	if isExpert(character, skillName) then
		profBonus = EXPERTISE_BONUS
	elseif isTrained(character, skillName) then
		profBonus = PROFICIENCY_BONUS
	end

	local zetsuBonus = 0
	if skillName == "Furtividade" and character.EmZetsu then
		local z = NenService.CalcZetsuBonus(character)
		zetsuBonus = z.furtividade or 0
	end

	return mod + profBonus + zetsuBonus
end

-- Rolagem silenciosa (d20 + bonus), usada SO quando ha conflito com
-- outro personagem (ver regra de ouro no topo do arquivo). mode:
-- "NORMAL" (padrao) / "VANTAGEM" / "DESVANTAGEM" / "ÊNFASE".
function SkillSystem.RollSkill(character, skillName, mode)
	local bonus = SkillSystem.GetSkillBonus(character, skillName)
	-- Exaustao Nivel 1+ da desvantagem em Testes de Habilidade. Combina
	-- com o modo ja pedido seguindo a regra padrao: vantagem+desvantagem
	-- juntas se cancelam (vira NORMAL); sem vantagem, desvantagem
	-- prevalece.
	if CharacterService then
		local mods = CharacterService.GetConditionModifiers(character)
		if mods.desvantagemHabilidade then
			if mode == "VANTAGEM" then
				mode = "NORMAL"
			else
				mode = "DESVANTAGEM"
			end
		end
	end
	local roll = DiceUtils.RollD20(mode)
	-- roll.total ja e o resultado do d20 (0-20) apos aplicar o modo
	-- (vantagem/desvantagem/enfase), ANTES do bonus de pericia -- entao
	-- checar critico/falha e so comparar roll.total direto, sem precisar
	-- reconferir os dados brutos de novo.
	return {
		total = roll.total + bonus,
		bonus = bonus,
		dice = roll.dice,
		label = roll.label,
		isCritical = roll.total == 20,
		isFumble = roll.total == 1,
	}
end

return SkillSystem
