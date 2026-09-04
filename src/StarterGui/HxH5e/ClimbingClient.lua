--[[
	HxH5e ClimbingClient
	Mecanica de Escalada (Lucas, regras detalhadas): detecta quando o
	personagem esta de frente pra uma parede escalavel (superficie
	vertical, nao-vidro), mostra um prompt, e ao clicar M1 dispara um
	teste de Atletismo no servidor (CombatService.TentarEscalada) com
	dificuldade crescente conforme a altura ja escalada.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local HxH5e = ReplicatedStorage:WaitForChild("HxH5e")
local TentarEscalada = HxH5e:WaitForChild("TentarEscalada")
local AvisarAterrissagem = HxH5e:WaitForChild("AvisarAterrissagem")

local ALCANCE_PROMPT = 5
local COOLDOWN_ESCALADA = 0.4 -- evita clique duplo instantaneo

-- ================= UI do prompt =================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HxH5eClimbPrompt"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local prompt = Instance.new("TextLabel")
prompt.Name = "ClimbPrompt"
prompt.Size = UDim2.new(0, 260, 0, 40)
prompt.Position = UDim2.new(0.5, -130, 0.62, 0)
prompt.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
prompt.BackgroundTransparency = 0.25
prompt.TextColor3 = Color3.fromRGB(255, 255, 255)
prompt.Font = Enum.Font.GothamBold
prompt.TextSize = 16
prompt.Text = "Clique (M1) para Escalar"
prompt.Visible = false
prompt.Parent = screenGui

local msgLabel = Instance.new("TextLabel")
msgLabel.Name = "ClimbMsg"
msgLabel.Size = UDim2.new(0, 320, 0, 30)
msgLabel.Position = UDim2.new(0.5, -160, 0.56, 0)
msgLabel.BackgroundTransparency = 1
msgLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
msgLabel.Font = Enum.Font.Gotham
msgLabel.TextSize = 14
msgLabel.Text = ""
msgLabel.Parent = screenGui

local msgTimer = nil
local function mostrarMsg(texto)
	msgLabel.Text = texto
	if msgTimer then task.cancel(msgTimer) end
	msgTimer = task.delay(3, function() msgLabel.Text = "" end)
end

-- ================= Deteccao de parede =================
local paredeValidaAgora = false

local function checarParede(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	local origem = root.Position
	local direcao = root.CFrame.LookVector * ALCANCE_PROMPT
	local result = workspace:Raycast(origem, direcao, rayParams)

	if result and result.Instance then
		local ehVidro = result.Instance.Material == Enum.Material.Glass
		-- Superficie vertical: normal do impacto aproximadamente
		-- horizontal (perpendicular ao "para cima").
		local ehVertical = math.abs(result.Normal.Y) < 0.4
		paredeValidaAgora = (not ehVidro) and ehVertical
	else
		paredeValidaAgora = false
	end

	prompt.Visible = paredeValidaAgora
end

RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then
		prompt.Visible = false
		return
	end
	checarParede(character)
end)

-- ================= Clique M1 =================
local emCooldown = false

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not paredeValidaAgora or emCooldown then return end

	emCooldown = true
	task.delay(COOLDOWN_ESCALADA, function() emCooldown = false end)

	local result = TentarEscalada:InvokeServer()
	if not result or not result.success then
		if result and result.error then mostrarMsg(result.error) end
		return
	end

	local statusTexto = result.sucesso and "SUCESSO" or "FALHA"
	mostrarMsg(string.format(
		"Escalada: 1d20(%d)+Atletismo(%d)=%d vs CD %d -- %s",
		result.rolagem, result.bonusAtletismo, result.total, result.cd, statusTexto
	))
end)

-- ================= Aviso de aterrissagem (reseta a sessao de escalada) =================
local function conectarAterrissagem(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			AvisarAterrissagem:FireServer()
		end
	end)
end

if player.Character then
	conectarAterrissagem(player.Character)
end
player.CharacterAdded:Connect(conectarAterrissagem)
