--[[
	HxH5e MouseLockCamera
	Trava a camera na direcao do mouse (estilo "shift lock" custom) --
	o personagem gira pra sempre ficar de frente pra onde a camera
	esta olhando, com o cursor preso no centro da tela.

	NAO usa a tecla Shift nativa do Roblox de proposito -- Shift ja
	esta ocupado pelo menu radial de Nen (ActionBarClient.lua). Alterna
	(toggle) com VIRGULA ou APOSTROFO, o que o Lucas preferir usar.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local ativo = false
local humanoid = nil
local rootPart = nil

local function conectarPersonagem(character)
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	-- Se o personagem renasceu com o modo ja ativo, garante que o
	-- AutoRotate comeca desligado de novo (senao ligaria sozinho no
	-- estado padrao do Humanoid novo).
	if ativo then
		humanoid.AutoRotate = false
	end
end

player.CharacterAdded:Connect(conectarPersonagem)
if player.Character then
	conectarPersonagem(player.Character)
end

local function ativar()
	ativo = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	if humanoid then
		humanoid.AutoRotate = false
	end
end

local function desativar()
	ativo = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	if humanoid then
		humanoid.AutoRotate = true
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == Enum.KeyCode.Comma or input.KeyCode == Enum.KeyCode.Quote then
		if ativo then
			desativar()
		else
			ativar()
		end
	end
end)

-- A cada frame, gira o personagem pra encarar a MESMA direcao
-- horizontal que a camera (ignora a inclinacao vertical -- senao o
-- personagem tentaria "olhar pra cima/baixo" tambem, o que nao faz
-- sentido pra um corpo humanoide preso ao chao).
RunService.RenderStepped:Connect(function()
	if not ativo or not rootPart then return end
	-- Le a camera ATUAL a cada frame (workspace.CurrentCamera pode
	-- ser recriada pelo Roblox, ex: ao respawnar -- se eu guardasse
	-- so uma referencia fixa no inicio do script, ela ficaria presa
	-- numa camera antiga e abandonada quando isso acontecesse,
	-- travando a rotacao do personagem mesmo com a camera de verdade
	-- respondendo ao mouse normalmente. Bug real que o Lucas reportou:
	-- "camera nao funciona mais com o mouse".
	local camera = workspace.CurrentCamera
	if not camera then return end
	local lookVector = camera.CFrame.LookVector
	local direcaoPlana = Vector3.new(lookVector.X, 0, lookVector.Z)
	if direcaoPlana.Magnitude > 0.001 then
		rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + direcaoPlana)
	end
end)
