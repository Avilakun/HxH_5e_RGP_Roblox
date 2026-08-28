--[[
    HxH5e BuffManager (M1.6)
    Controla buffs ativos por jogador e envia a contagem regressiva ao cliente.
    O remote BuffTick é criado pelo ServerBootstrap ANTES deste módulo carregar.
]]

local BuffManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HxH5e = ReplicatedStorage:WaitForChild("HxH5e")

local BuffTick = HxH5e:WaitForChild("BuffTick")

local buffs = {} -- [player] = { [nome] = horarioExpiracao }

local DURACAO_PADRAO = 6 -- segundos (mesmo valor usado no NenService)

function BuffManager.Start(player, nome, duracao)
	if not buffs[player] then
		buffs[player] = {}
	end
	buffs[player][nome] = os.clock() + (duracao or DURACAO_PADRAO)
end

function BuffManager.Has(player, nome)
	local tbl = buffs[player]
	if not tbl then
		return false
	end
	local expira = tbl[nome]
	return expira and (expira - os.clock()) > 0
end

function BuffManager.GetActive(player)
	local agora = os.clock()
	local lista = {}
	local tbl = buffs[player]
	if tbl then
		for nome, expira in pairs(tbl) do
			local restante = expira - agora
			if restante > 0 then
				table.insert(lista, { name = nome, remaining = restante })
			else
				tbl[nome] = nil
			end
		end
	end
	return lista
end

function BuffManager.Clear(player)
	buffs[player] = nil
end

-- Loop: envia ao jogador os buffs ativos a cada 0.5s
task.spawn(function()
	while true do
		task.wait(0.5)
		for player, _ in pairs(buffs) do
			if player.Parent then
				local lista = BuffManager.GetActive(player)
				pcall(function()
					BuffTick:FireClient(player, lista)
				end)
			end
		end
	end
end)

return BuffManager