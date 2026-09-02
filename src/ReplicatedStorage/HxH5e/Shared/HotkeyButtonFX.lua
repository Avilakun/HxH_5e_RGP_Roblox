--[[
    HxH5e HotkeyButtonFX -- efeito visual reusavel pros botoes de
    hotkey (Atacar/Bloquear/Esquivar hoje; TEN/REN/KEN/GYO etc no
    futuro, exceto EN e ZETSU por enquanto -- pedido do Lucas).

    So o efeito de "piscar" ao clicar -- feedback visual imediato,
    antes mesmo da resposta do servidor chegar, pra confirmar que o
    clique registrou. Qualquer botao novo de hotkey deve chamar
    HotkeyButtonFX.Blink(botao) dentro do proprio handler de clique.
]]

local TweenService = game:GetService("TweenService")

local HotkeyButtonFX = {}

-- Pisca o botao: um overlay branco sobe rapido de transparencia e
-- desce de novo, por cima do icone (ZIndex maior). Cria o overlay na
-- primeira vez que o botao pisca e reaproveita depois (nao duplica
-- a cada clique).
function HotkeyButtonFX.Blink(button: GuiButton)
	local overlay = button:FindFirstChild("BlinkOverlay") :: Frame?
	if not overlay then
		overlay = Instance.new("Frame")
		overlay.Name = "BlinkOverlay"
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.ZIndex = button.ZIndex + 5
		overlay.Parent = button
		-- copia o arredondamento do botao (se tiver UICorner), pra o
		-- flash nao vazar quadrado por cima de um botao redondo.
		local corner = button:FindFirstChildOfClass("UICorner")
		if corner then
			corner:Clone().Parent = overlay
		end
	end

	overlay.BackgroundTransparency = 1
	local tweenIn = TweenService:Create(overlay, TweenInfo.new(0.4, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.35 })
	local tweenOut = TweenService:Create(overlay, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 })
	tweenIn:Play()
	tweenIn.Completed:Once(function()
		tweenOut:Play()
	end)
end

return HotkeyButtonFX
