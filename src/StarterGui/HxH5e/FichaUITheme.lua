--!strict
-- FichaUITheme — cor de tema derivada da categoria de Nen.
-- Todo elemento colorido se registra aqui; trocar a categoria recolore tudo de uma vez.
-- Ícones devem ser PNG BRANCOS com fundo transparente: a cor vem de ImageColor3.

local Theme = {}

Theme.Categories = {
	["Intensificação"]  = Color3.fromRGB(0, 255, 157),
	["Emissão"]         = Color3.fromRGB(0, 200, 255),
	["Transmutação"]    = Color3.fromRGB(180, 120, 255),
	["Materialização"]  = Color3.fromRGB(255, 196, 0),
	["Manipulação"]     = Color3.fromRGB(255, 95, 245),
	["Especialização"]  = Color3.fromRGB(255, 59, 59),
}

-- Vitais são imunes ao tema (têm cor própria e vivem fora da ficha)
Theme.Vitals = {
	PV       = Color3.fromRGB(255, 77, 77),
	Aura     = Color3.fromRGB(0, 200, 255),
	Sanidade = Color3.fromRGB(180, 120, 255),
	Reacoes  = Color3.fromRGB(255, 196, 0),
}

Theme.Bg        = Color3.fromRGB(7, 10, 12)
Theme.Panel     = Color3.fromRGB(5, 7, 10)
Theme.Popover   = Color3.fromRGB(10, 15, 13)
Theme.Label     = Color3.fromRGB(232, 245, 239) -- rótulos: neutro, nunca tema
Theme.Muted     = Color3.fromRGB(150, 160, 156)
Theme.Warn      = Color3.fromRGB(255, 215, 102) -- negativas, condições, excesso de peso

Theme.FontTitle = Enum.Font.GothamBold
Theme.FontBody  = Enum.Font.Gotham
Theme.FontMono  = Enum.Font.Code

Theme.Accent = Theme.Categories["Intensificação"]

local registry: { { inst: Instance, prop: string, alpha: number? } } = {}

-- Mistura a cor de tema com o fundo, imitando color-mix(... N%, transparent)
function Theme.mix(alpha: number, color: Color3?): Color3
	local c = color or Theme.Accent
	return Theme.Bg:Lerp(c, math.clamp(alpha, 0, 1))
end

-- prop: "TextColor3" | "BackgroundColor3" | "ImageColor3" | "Color" (UIStroke)
function Theme.register(inst: Instance, prop: string, alpha: number?)
	table.insert(registry, { inst = inst, prop = prop, alpha = alpha })
	local value = if alpha then Theme.mix(alpha) else Theme.Accent
	;(inst :: any)[prop] = value
end

function Theme.setCategory(name: string)
	Theme.Accent = Theme.Categories[name] or Theme.Accent
	for i = #registry, 1, -1 do
		local entry = registry[i]
		if entry.inst.Parent == nil and not entry.inst:IsA("UIStroke") then
			table.remove(registry, i)
		else
			local value = if entry.alpha then Theme.mix(entry.alpha) else Theme.Accent
			;(entry.inst :: any)[entry.prop] = value
		end
	end
end

return Theme
