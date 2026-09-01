--[[
    HxH5e AchievementService (server) — motor de conquistas.
    3 formas de desbloquear (+ 2 tipos "adormecidos" pra depois):
    - Contador: incrementa um campo em character.AchievementCounters,
      desbloqueia quando bate a meta (Ten/Ren/Zetsu Nx).
    - Checagem simples: le um campo que ja existe no personagem (nivel,
      Dominio.Ten etc) direto, sem guardar nada extra -- roda de novo a
      cada acao relevante (treinar principio, subir nivel, criar Hatsu).
    - Evento: dispara uma vez quando algo especifico acontece (critico
      natural, PV baixo) -- nao precisa de contador, so verifica se ja
      esta desbloqueada antes de aplicar.
    - Manual (ex: entrar em organizacao) e Combate (ex: derrotar
      inimigo) ficam so cadastradas por enquanto -- sem sistema pra
      disparar ainda (organizacoes estruturadas e combate de verdade
      sao pendencias futuras).

    Toda conquista desbloqueada fica registrada em
    character.Achievements (persistente) e retorna os dados pra quem
    chamou poder notificar o jogador (badge de notificacao no cliente).
]]

local AchievementService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AchievementsDB = require(ReplicatedStorage:WaitForChild("HxH5e"):WaitForChild("Shared"):WaitForChild("AchievementsDB"))

-- Desbloqueia UMA conquista por id, se ainda nao estiver desbloqueada.
-- Retorna { success, isNew, achievement } -- isNew=false se ja tinha.
function AchievementService.Unlock(character, id)
	local def = AchievementsDB.Get(id)
	if not def then
		return { success = false, isNew = false, error = "Conquista desconhecida: " .. tostring(id) }
	end
	character.Achievements = character.Achievements or {}
	for _, jaTem in ipairs(character.Achievements) do
		if jaTem == id then
			return { success = true, isNew = false, achievement = def }
		end
	end
	table.insert(character.Achievements, id)
	return { success = true, isNew = true, achievement = def }
end

-- Incrementa um contador e desbloqueia a conquista associada se bater
-- a meta. Usado por Ten/Ren/Zetsu (ativacao, nao treino).
function AchievementService.IncrementCounter(character, counterField, achievementId)
	character.AchievementCounters = character.AchievementCounters or {}
	character.AchievementCounters[counterField] = (character.AchievementCounters[counterField] or 0) + 1
	local def = AchievementsDB.Get(achievementId)
	if def and def.meta and character.AchievementCounters[counterField] >= def.meta then
		return AchievementService.Unlock(character, achievementId)
	end
	return { success = true, isNew = false }
end

-- Reavalia todas as conquistas de "checagem simples" (leitura direta
-- do estado atual do personagem, idempotente -- seguro chamar toda
-- vez que algo relevante mudar). Retorna a lista das que desbloquearam
-- AGORA (pra notificar), ignorando as que ja estavam desbloqueadas.
function AchievementService.CheckAllLiveAchievements(character)
	local desbloqueadasAgora = {}
	local function tenta(id)
		local r = AchievementService.Unlock(character, id)
		if r.isNew then
			table.insert(desbloqueadasAgora, r.achievement)
		end
	end

	if (character.Level or 0) >= 1 then
		tenta("nivel_1")
	end

	local dominio = (character.Nen and character.Nen.Dominio) or {}
	local maestrias = 0
	if (dominio.Ten or 0) >= 3 then maestrias = maestrias + 1 end
	if (dominio.Ren or 0) >= 3 then maestrias = maestrias + 1 end
	if (dominio.Zetsu or 0) >= 3 then maestrias = maestrias + 1 end
	if maestrias >= 1 then tenta("maestria_1") end
	if maestrias >= 2 then tenta("maestria_2") end
	if maestrias >= 3 then tenta("maestria_3") end

	if dominio.En or dominio.Inp or dominio.Gyo or dominio.Shu then
		tenta("principio_avancado_1")
	end

	if character.Hatsus and #character.Hatsus >= 1 then
		tenta("primeiro_hatsu")
	end

	return desbloqueadasAgora
end

-- Eventos (disparo unico, verificado no momento exato que acontece).
function AchievementService.CheckCritico(character, rolagemNatural)
	if rolagemNatural == 20 then
		local r = AchievementService.Unlock(character, "critico_nat20")
		if r.isNew then return r.achievement end
	elseif rolagemNatural == 1 then
		local r = AchievementService.Unlock(character, "critico_nat1")
		if r.isNew then return r.achievement end
	end
	return nil
end

function AchievementService.CheckPVBaixo(character)
	local hp = character.Vitals and character.Vitals.HP
	if hp and hp.Max and hp.Max > 0 and hp.Current and hp.Current > 0 and (hp.Current / hp.Max) <= 0.10 then
		local r = AchievementService.Unlock(character, "pv_baixo")
		if r.isNew then return r.achievement end
	end
	return nil
end

function AchievementService.GetCatalog()
	return AchievementsDB.Conquistas
end

return AchievementService
