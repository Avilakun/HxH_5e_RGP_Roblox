--!strict
-- FichaUIWidgets — construtores enxutos. Sem box-shadow no Roblox: o glow
-- neon vira UIStroke + tint de fundo, que é a aproximação mais próxima.

local Theme = require(script.Parent.FichaUITheme)
local Icons = require(script.Parent.FichaUIIcons)

local W = {}

function W.corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

function W.stroke(parent: Instance, alpha: number, themed: boolean?)
	local s = Instance.new("UIStroke")
	s.Thickness = 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	if themed ~= false then
		Theme.register(s, "Color")
		s.Transparency = 1 - alpha
	else
		s.Color = Color3.fromRGB(255, 255, 255)
		s.Transparency = 1 - alpha
	end
	return s
end

function W.pad(parent: Instance, all: number, extra: {top: number?, bottom: number?, left: number?, right: number?}?)
	local p = Instance.new("UIPadding")
	local e = extra or {}
	p.PaddingTop = UDim.new(0, e.top or all)
	p.PaddingBottom = UDim.new(0, e.bottom or all)
	p.PaddingLeft = UDim.new(0, e.left or all)
	p.PaddingRight = UDim.new(0, e.right or all)
	p.Parent = parent
	return p
end

function W.list(parent: Instance, gap: number, dir: Enum.FillDirection?)
	local l = Instance.new("UIListLayout")
	l.FillDirection = dir or Enum.FillDirection.Vertical
	l.Padding = UDim.new(0, gap)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = parent
	return l
end

function W.grid(parent: Instance, cellW: number, cellH: number, gap: number)
	local g = Instance.new("UIGridLayout")
	g.CellSize = UDim2.fromOffset(cellW, cellH)
	g.CellPadding = UDim2.fromOffset(gap, gap)
	g.SortOrder = Enum.SortOrder.LayoutOrder
	g.Parent = parent
	return g
end

function W.frame(parent: Instance, size: UDim2, name: string?): Frame
	local f = Instance.new("Frame")
	f.Name = name or "Frame"
	f.Size = size
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

-- Card padrão: borda no tema, fundo levemente claro
function W.card(parent: Instance, size: UDim2, name: string?): Frame
	local f = W.frame(parent, size, name or "Card")
	f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	f.BackgroundTransparency = 0.98
	W.corner(f, 10)
	W.stroke(f, 0.22)
	return f
end

-- Card destacado: tint da categoria no fundo e borda mais forte
function W.cardAccent(parent: Instance, size: UDim2, name: string?): Frame
	local f = W.frame(parent, size, name or "CardAccent")
	Theme.register(f, "BackgroundColor3", 0.09)
	f.BackgroundTransparency = 0
	W.corner(f, 10)
	W.stroke(f, 0.45)
	return f
end

-- RÓTULO: neutro, nunca recebe a cor da categoria
function W.label(parent: Instance, text: string, size: number, name: string?): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = name or "Label"
	t.BackgroundTransparency = 1
	t.Text = text
	t.Font = Theme.FontBody
	t.TextSize = size
	t.TextColor3 = Theme.Muted
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Top
	t.Size = UDim2.new(1, 0, 0, size + 4)
	t.RichText = true
	t.Parent = parent
	return t
end

-- DESCRIÇÃO: herda a cor da categoria de Nen
function W.value(parent: Instance, text: string, size: number, name: string?): TextLabel
	local t = W.label(parent, text, size, name or "Value")
	t.Font = Theme.FontTitle
	Theme.register(t, "TextColor3")
	return t
end

function W.mono(parent: Instance, text: string, size: number, themed: boolean?): TextLabel
	local t = W.label(parent, text, size, "Mono")
	t.Font = Theme.FontMono
	if themed ~= false then Theme.register(t, "TextColor3") end
	return t
end

function W.icon(parent: Instance, id: number, px: number, name: string?): ImageLabel
	local i = Instance.new("ImageLabel")
	i.Name = name or "Icon"
	i.BackgroundTransparency = 1
	i.Size = UDim2.fromOffset(px, px)
	i.Image = Icons.asset(id)
	i.ScaleType = Enum.ScaleType.Fit
	Theme.register(i, "ImageColor3")
	i.Parent = parent
	return i
end

-- Barra de vital: cor FIXA, imune ao tema
function W.vitalBar(parent: Instance, color: Color3, height: number): (Frame, Frame)
	local track = W.frame(parent, UDim2.new(1, 0, 0, height), "Track")
	track.BackgroundColor3 = color
	track.BackgroundTransparency = 0.88
	W.corner(track, math.floor(height / 2))
	local fill = W.frame(track, UDim2.new(1, 0, 1, 0), "Fill")
	fill.BackgroundColor3 = color
	fill.BackgroundTransparency = 0
	W.corner(fill, math.floor(height / 2))
	return track, fill
end

-- Barra no tema (XP, reputação, espaço)
function W.themedBar(parent: Instance, height: number): (Frame, Frame)
	local track = W.frame(parent, UDim2.new(1, 0, 0, height), "Track")
	track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	track.BackgroundTransparency = 0.93
	W.corner(track, math.floor(height / 2))
	local fill = W.frame(track, UDim2.new(1, 0, 1, 0), "Fill")
	Theme.register(fill, "BackgroundColor3")
	fill.BackgroundTransparency = 0
	W.corner(fill, math.floor(height / 2))
	return track, fill
end

function W.pips(parent: Instance, total: number, filled: number, w: number, h: number): Frame
	local row = W.frame(parent, UDim2.new(0, (w + 4) * total, 0, h), "Pips")
	W.list(row, 4, Enum.FillDirection.Horizontal)
	for i = 1, total do
		local p = W.frame(row, UDim2.fromOffset(w, h), "Pip" .. i)
		p.LayoutOrder = i
		if i <= filled then
			Theme.register(p, "BackgroundColor3")
			p.BackgroundTransparency = 0
		else
			p.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			p.BackgroundTransparency = 0.9
		end
		W.corner(p, 2)
	end
	return row
end

function W.button(parent: Instance, text: string, size: UDim2, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Name = "Button_" .. text
	b.Size = size
	b.Text = text
	b.Font = Theme.FontMono
	b.TextSize = 11
	b.AutoButtonColor = false
	b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	b.BackgroundTransparency = 1
	Theme.register(b, "TextColor3")
	W.corner(b, 5)
	W.stroke(b, 0.45)
	b.Parent = parent
	b.MouseButton1Click:Connect(onClick)
	b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.85 end)
	b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
	return b
end

-- Tag/pílula: usada em condições, efeitos, restrições, gostos e desgostos
function W.tag(parent: Instance, text: string, warn: boolean?): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = "Tag"
	t.Text = " " .. text .. " "
	t.Font = Theme.FontBody
	t.TextSize = 12
	t.AutomaticSize = Enum.AutomaticSize.X
	t.Size = UDim2.new(0, 0, 0, 24)
	t.BackgroundTransparency = 0
	W.corner(t, 6)
	if warn then
		t.TextColor3 = Theme.Warn
		t.BackgroundColor3 = Theme.mix(0.08, Theme.Warn)
		local s = W.stroke(t, 0.5, false)
		s.Color = Theme.Warn
	else
		Theme.register(t, "TextColor3")
		Theme.register(t, "BackgroundColor3", 0.1)
		W.stroke(t, 0.4)
	end
	t.Parent = parent
	return t
end

return W
