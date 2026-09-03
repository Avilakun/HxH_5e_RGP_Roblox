local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local LoadingGui = script.LoadingGui

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = LoadingGui:Clone()
gui.Parent = playerGui

local canvasGroup = gui.CanvasGroup
local progressBar = canvasGroup.Content.ProgressBar

if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- ⚠️ "workspace.Rig" nao existe no jogo atual -- o script original
-- tentava pre-carregar as TAGS desse objeto (que nem sequer seria a
-- forma certa de listar assets pra pre-carregar; GetTags retorna
-- strings de CollectionService, nao instancias). Reescrito de forma
-- defensiva: pre-carrega tudo que ja esta no workspace (uso comum
-- desse padrao de loading screen), sem depender de um objeto
-- especifico que nunca foi criado. Se a intencao original era outra
-- (ex: uma pasta com personagens/props especificos pra pre-carregar),
-- precisa confirmar qual deveria ser a fonte real.
local assets = workspace:GetDescendants()
local totalAssets = #assets

-- Corrigido: PreloadAsync UM ASSET DE CADA VEZ era o gargalo real do
-- "Play lento" que o Lucas reportou -- medido em Play: 500 chamadas
-- individuais levaram 0.67s (projetando ~5s pros 3785 objetos todos),
-- contra 0.32s fazendo TUDO numa chamada so. Loop em LOTES mantem a
-- barra de progresso atualizando (nao trava tudo numa unica chamada
-- sem feedback visual), mas em lotes grandes o suficiente pra nao
-- sofrer o overhead de milhares de chamadas separadas.
local TAMANHO_LOTE = 200
for inicioLote = 1, totalAssets, TAMANHO_LOTE do
	local fimLote = math.min(inicioLote + TAMANHO_LOTE - 1, totalAssets)
	local lote = {}
	for i = inicioLote, fimLote do
		table.insert(lote, assets[i])
	end
	ContentProvider:PreloadAsync(lote)

	progressBar.Title.Text = "Loading Assets: " .. fimLote .. "/" .. totalAssets
	progressBar.Fill.Size = UDim2.new(fimLote / totalAssets, 0, 1, 0)
end

local fadeOut = TweenService:Create(
	canvasGroup,
	TweenInfo.new(1),
	{
		GroupTransparency = 1,
	}
)

fadeOut:Play()
fadeOut.Completed:Wait()

gui:Destroy()
