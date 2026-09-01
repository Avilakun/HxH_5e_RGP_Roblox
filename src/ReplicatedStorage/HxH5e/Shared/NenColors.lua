--[[
    HxH5e NenColors (Shared) — cores de tema por categoria de Nen.
    Extraidas do webapp real (js/data/config.js, SYSTEM_DB.classes).
    Usadas pra colorir a borda/tema da ficha dinamicamente conforme a
    categoria do personagem (pedido do Lucas).
]]

local NenColors = {}

NenColors.PorCategoria = {
	["INTENSIFICAÇÃO"] = Color3.fromHex("00ff9d"),
	["TRANSMUTAÇÃO"] = Color3.fromHex("d946ef"),
	["MATERIALIZAÇÃO"] = Color3.fromHex("ff0055"),
	["ESPECIALIZAÇÃO"] = Color3.fromHex("00f0ff"),
	["MANIPULAÇÃO"] = Color3.fromHex("9ca3af"),
	["EMISSÃO"] = Color3.fromHex("ffe600"),
}

NenColors.Padrao = Color3.fromHex("00ff9d") -- personagem sem Nen desperto ainda (nivel 0)

function NenColors.Get(categoria)
	return NenColors.PorCategoria[categoria] or NenColors.Padrao
end

return NenColors
