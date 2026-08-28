--[[
    HxH5e CombatService (M1.6.2)
    Boneco de Treino + ataque básico com rolagem detalhada
    (1d6 + FOR + REN) e revide com PV do jogador.
]]

local CombatService = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HxH5e = ReplicatedStorage:WaitForChild("HxH5e")

local BuffManager = require(script.Parent:WaitForChild("BuffManager"))
local NenService = require(script.Parent:WaitForChild("NenService"))

local CharacterService = nil
local dummyFolder = nil
local dummies = {} -- [modelo] = { hp, maxHp, respawning }

local DUMMY_MAX_HP = 20
local DUMMY_POS = Vector3.new(0, 3, 30)

local function rollDice(count, sides)
	local total = 0
	for _ = 1, count do
		total = total + math.random(1, sides)
	end
	return total
end

local function updateLabel(dummy)
	local data = dummies[dummy]
	local cabeca = dummy:FindFirstChild("Cabeca")
	local gui = cabeca and cabeca:FindFirstChild("HealthGui")
	if not gui then
		return
	end
	local bar = gui:FindFirstChild("Bg") and gui.Bg:FindFirstChild("Bar")
	local label = gui:FindFirstChild("Label")
	local pct = data and (data.hp / data.maxHp) or 0
	if bar then
		bar.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 0, 10)
		if pct > 0.5 then
			bar.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
		elseif pct > 0.25 then
			bar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
		else
			bar.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		end
	end
	if label then
		local hp = data and math.floor(math.max(0, data.hp)) or 0
		label.Text = "Boneco de Treino\nHP " .. hp .. "/" .. (data and data.maxHp or 0)
	end
end

local function placeDummy(dummy, pos)
	local torso = dummy:FindFirstChild("Torso")
	local cabeca = dummy:FindFirstChild("Cabeca")
	if torso then
		torso.CFrame = CFrame.new(pos)
	end
	if cabeca and torso then
		cabeca.CFrame = torso.CFrame * CFrame.new(0, 1.8, 0)
	end
end

local function buildDummy()
	local model = Instance.new("Model")
	model.Name = "BonecoTreino"

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2.4, 1)
	torso.Anchored = true
	torso.CanCollide = true
	torso.Color = Color3.fromRGB(120, 120, 130)
	torso.Material = Enum.Material.SmoothPlastic

	local cabeca = Instance.new("Part")
	cabeca.Name = "Cabeca"
	cabeca.Size = Vector3.new(1.2, 1.2, 1.2)
	cabeca.Anchored = true
	cabeca.CanCollide = true
	cabeca.Color = Color3.fromRGB(200, 180, 160)

	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthGui"
	gui.Size = UDim2.new(0, 140, 0, 44)
	gui.StudsOffset = Vector3.new(0, 2.2, 0)
	gui.AlwaysOnTop = true

	local bg = Instance.new("Frame")
	bg.Name = "Bg"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	bg.BackgroundTransparency = 0.2
	bg.BorderSizePixel = 0

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, 0, 0, 10)
	bar.Position = UDim2.new(0, 0, 0, 4)
	bar.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
	bar.BorderSizePixel = 0

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 0, 22)
	label.Position = UDim2.new(0, 0, 0, 16)
	label.BackgroundTransparency = 1
	label.Text = "Boneco de Treino"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold

	bg.Parent = gui
	bar.Parent = bg
	label.Parent = gui

	torso.Parent = model
	cabeca.Parent = model
	gui.Parent = cabeca

	model.PrimaryPart = torso
	dummies[model] = { hp = DUMMY_MAX_HP, maxHp = DUMMY_MAX_HP, respawning = false }
	placeDummy(model, DUMMY_POS)
	updateLabel(model)
	return model
end

local function respawnDummy(dummy)
	local data = dummies[dummy]
	data.hp = data.maxHp
	data.respawning = false
	for _, part in ipairs(dummy:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0
			part.CanCollide = true
		end
	end
	placeDummy(dummy, DUMMY_POS)
	updateLabel(dummy)
end

function CombatService.Setup(charService)
	CharacterService = charService
	dummyFolder = Workspace:FindFirstChild("HxH5eDummies")
	if not dummyFolder then
		dummyFolder = Instance.new("Folder")
		dummyFolder.Name = "HxH5eDummies"
		dummyFolder.Parent = Workspace
	end
	local dummy = buildDummy()
	dummy.Parent = dummyFolder
end

function CombatService.BasicAttack(player)
	if not CharacterService then
		return { success = false, error = "Sistema de combate não iniciado." }
	end
	local character = CharacterService.GetActiveCharacter(player)
	if not character then
		return { success = false, error = "Nenhum personagem ativo. Ative ou crie um na ficha." }
	end

	local plrChar = player.Character
	local origin = plrChar and plrChar:GetPivot().Position or Vector3.zero

	local nearest, bestDist = nil, math.huge
	for dummy in pairs(dummies) do
		local data = dummies[dummy]
		if data and not data.respawning then
			local primary = dummy.PrimaryPart
			local dummyPos = primary and primary.Position or dummy:GetPivot().Position
			local dist = (dummyPos - origin).Magnitude
			if dist < bestDist then
				nearest = dummy
				bestDist = dist
			end
		end
	end

	if not nearest then
		return { success = false, error = "Nenhum boneco de treino disponível." }
	end
	if bestDist > 25 then
		return { success = false, error = "Muito longe do boneco (" .. math.floor(bestDist) .. "m). Aproxime-se." }
	end

	-- Dano detalhado: 1d6 + FOR + REN (se ativo)
	local attrs = character.Attributes or {}
	local forVal = attrs.FOR and attrs.FOR.value or 10
	local forMod = math.max(0, math.floor((forVal - 10) / 2))

	local danoBase = rollDice(1, 6)
	local dano = danoBase + forMod
	local partes = { "1d6=" .. danoBase, "FOR+" .. forMod }

	local renBonus = 0
	if BuffManager.Has(player, "Ren") then
		local ren = NenService.CalcRenBonus and NenService.CalcRenBonus(character) or { grau = 0 }
		renBonus = ren.grau or 0
		dano = dano + renBonus
		table.insert(partes, "REN+" .. renBonus)
	end

	local data = dummies[nearest]
	data.hp = data.hp - dano
	local killed = data.hp <= 0
	if killed then
		data.hp = 0
	end
	updateLabel(nearest)

	local result = {
		success = true,
		dano = dano,
		partes = table.concat(partes, " + "),
		renBonus = renBonus,
		hpRestante = math.max(0, data.hp),
		hpMax = data.maxHp,
		killed = killed,
	}

	if killed then
		data.respawning = true
		for _, part in ipairs(nearest:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.9
				part.CanCollide = false
			end
		end
		task.delay(5, function()
			respawnDummy(nearest)
		end)
	elseif math.random() <= 0.3 then
		-- Boneco revida: dano tomado no PV do jogador
		local revida = rollDice(1, 4)
		local vitals = character.Vitals
		if vitals and vitals.HP then
			local atual = vitals.HP.Current or vitals.HP.Max
			vitals.HP.Current = math.max(0, atual - revida)
			result.revida = revida
			result.playerHP = math.max(0, vitals.HP.Current)
			result.playerMaxHP = vitals.HP.Max
			if vitals.HP.Current <= 0 then
				result.playerMorto = true
			end
			CharacterService.SavePlayer(player)
			if result.playerMorto then
				task.delay(5, function()
					local c = CharacterService.GetActiveCharacter(player)
					if c and c.Vitals and c.Vitals.HP then
						c.Vitals.HP.Current = c.Vitals.HP.Max
						CharacterService.SavePlayer(player)
					end
				end)
			end
		end
	end

	return result
end

return CombatService