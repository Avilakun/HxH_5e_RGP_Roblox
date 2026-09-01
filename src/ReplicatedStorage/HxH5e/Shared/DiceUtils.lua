--[[
    HxH5e DiceUtils (Shared) — rolagem de d20 com Vantagem/Desvantagem
    Portado fielmente do webapp (sheet.js: getRollResult). SEMPRE deve
    ser chamado no SERVIDOR pra valer (o resultado decide coisas reais
    do jogo) -- esta em Shared so porque a logica em si e pura/sem
    estado, nao porque o cliente deva confiar no proprio resultado.

    4 modos (identico ao webapp -- o 4o nao e D&D padrao, e uma
    mecanica propria do sistema):
    - NORMAL: rola 1d20 puro.
    - VANTAGEM: rola 2d20, usa o MAIOR.
    - DESVANTAGEM: rola 2d20, usa o MENOR.
    - ÊNFASE: rola 2d20, usa o resultado mais LONGE de 10.5 (ou seja,
      o mais extremo -- pode ser o mais alto OU o mais baixo).
]]

local DiceUtils = {}

function DiceUtils.RollD20(mode)
	local r1 = math.random(1, 20)
	local r2 = math.random(1, 20)

	if mode == "VANTAGEM" then
		return { total = math.max(r1, r2), dice = { r1, r2 }, label = "Vantagem" }
	elseif mode == "DESVANTAGEM" then
		return { total = math.min(r1, r2), dice = { r1, r2 }, label = "Desvantagem" }
	elseif mode == "ÊNFASE" then
		local dist1 = math.abs(r1 - 10.5)
		local dist2 = math.abs(r2 - 10.5)
		local total = (dist1 > dist2) and r1 or r2
		return { total = total, dice = { r1, r2 }, label = "Ênfase" }
	end

	return { total = r1, dice = { r1 }, label = "Normal" }
end

return DiceUtils
