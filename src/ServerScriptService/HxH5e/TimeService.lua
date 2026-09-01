--[[
    HxH5e TimeService (server) — relogio de jogo (dia/noite) e
    contador acumulado de horas de jogo, usado pelo sistema de
    Exaustao/Descanso (pedido do Lucas: "1min real = 1h de jogo").

    Lighting.ClockTime mostra a HORA DO DIA (0-24, reseta a cada
    ciclo, so pro visual dia/noite). totalGameHours e um contador
    SEPARADO que so cresce (nunca reseta) -- usado pra medir duracao
    de descansos e requisitos de Exaustao Nivel 3 (dias/semanas).

    Taxa: 1 hora de jogo a cada 60 segundos reais (1 minuto real = 1
    hora de jogo, como o Lucas pediu pra testar). Um dia inteiro de
    jogo (24h) leva 24 minutos reais.
]]

local TimeService = {}

local Lighting = game:GetService("Lighting")

local HOURS_PER_REAL_SECOND = 1 / 60 -- 1 hora de jogo a cada 60s reais
local totalGameHours = 0
local started = false

function TimeService.Start()
	if started then return end
	started = true
	Lighting.ClockTime = 8 -- comeca de manha, so estetico
	task.spawn(function()
		while true do
			task.wait(1)
			totalGameHours = totalGameHours + HOURS_PER_REAL_SECOND
			Lighting.ClockTime = totalGameHours % 24
		end
	end)
end

-- Total de horas de jogo desde que o servidor iniciou (nunca reseta,
-- diferente do ClockTime visual). Usado pra medir duracao de
-- descansos e requisitos de tempo mais longos (Exaustao Nivel 3).
function TimeService.GetTotalGameHours()
	return totalGameHours
end

function TimeService.GetClockTime()
	return Lighting.ClockTime
end

return TimeService
