--[[
	HxH5e MikeChaser
	Faz o Mike (rig quadrupede, SEM Humanoid -- usa AnimationController
	+ Bones) perseguir o jogador mais proximo, igual o boneco de treino
	faz (CombatService.lua), mas com o DOBRO do alcance de deteccao
	(pedido do Lucas: "Mike esta o dobro da distancia e mesmo assim vem
	atras de mim").

	Diferenca tecnica principal: o boneco de treino usa
	Humanoid:MoveTo() pra se mover -- o Mike NAO TEM Humanoid (rig
	baseado em Bones, mais avancado), entao a movimentacao aqui e
	manual: reposiciona o RootPart a cada frame, interpolando na
	direcao do jogador.

	So MOVIMENTO por enquanto -- sem ataque/dano ainda (o pedido foi
	especificamente sobre perseguir + animacao, nao combate).
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local mike = workspace:WaitForChild("Mike_walk")
local rootPart = mike:WaitForChild("RootPart")

-- Boneco de treino usa DETECTION_RANGE = 40 -- Mike e o DOBRO.
local DETECTION_RANGE = 80
local STOP_DISTANCE = 6 -- para de andar quando chega perto (nao empurra o jogador)
local WALK_SPEED = 10 -- studs/segundo

-- Animacao de caminhada -- ainda em formato cru (KeyframeSequence,
-- nao publicada como Animation com ID real) no momento desta
-- implementacao. Carregada de forma resiliente: se falhar (ainda nao
-- publicada), o Mike so nao anima, mas continua se movendo
-- normalmente.
local animator = mike.AnimationController:FindFirstChildOfClass("Animator")
local walkTrack = nil
local animSaves = mike:FindFirstChild("AnimSaves")
if animator and animSaves and animSaves.Value then
	local scene = animSaves.Value:FindFirstChild("Scene")
	if scene and scene:IsA("KeyframeSequence") then
		local ok, track = pcall(function()
			return animator:LoadAnimation(scene)
		end)
		if ok then
			walkTrack = track
		else
			warn("[HxH5e] Mike: nao consegui carregar a animacao de caminhada ainda (provavelmente precisa ser publicada primeiro): " .. tostring(track))
		end
	end
end

local andando = false
local function atualizarAnimacao(estaAndando)
	if estaAndando == andando then return end
	andando = estaAndando
	if not walkTrack then return end
	if andando then
		walkTrack:Play()
	else
		walkTrack:Stop()
	end
end

RunService.Heartbeat:Connect(function(dt)
	local nearestPlayer, bestDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		if char and char.PrimaryPart then
			local dist = (char.PrimaryPart.Position - rootPart.Position).Magnitude
			if dist < bestDist then
				nearestPlayer = plr
				bestDist = dist
			end
		end
	end

	if not nearestPlayer or bestDist > DETECTION_RANGE then
		atualizarAnimacao(false)
		return
	end

	local alvoPos = nearestPlayer.Character.PrimaryPart.Position
	if bestDist <= STOP_DISTANCE then
		atualizarAnimacao(false)
		-- Mesmo parado, encara o jogador
		local direcaoPlana = Vector3.new(alvoPos.X - rootPart.Position.X, 0, alvoPos.Z - rootPart.Position.Z)
		if direcaoPlana.Magnitude > 0.001 then
			rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + direcaoPlana)
		end
		return
	end

	atualizarAnimacao(true)
	local direcao = (alvoPos - rootPart.Position)
	local direcaoPlana = Vector3.new(direcao.X, 0, direcao.Z)
	if direcaoPlana.Magnitude > 0.001 then
		local passo = direcaoPlana.Unit * math.min(WALK_SPEED * dt, direcaoPlana.Magnitude)
		local novaPos = rootPart.Position + passo
		rootPart.CFrame = CFrame.lookAt(novaPos, novaPos + direcaoPlana)
	end
end)
