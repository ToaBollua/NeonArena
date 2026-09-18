--!strict
-- src/client/PlatformBuilder.client.luau
-- Generador de Plataformas de Luz Sólida en el aire (Parkour & Air-Combo System)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local NetworkEvents = require(Shared:WaitForChild("NetworkEvents") :: ModuleScript)

local player = Players.LocalPlayer
local spawnPlatformEvent = NetworkEvents.getRemoteEvent(NetworkEvents.SpawnPlatform)

local lastPlatformSpawnTime = 0.0
local playerSignatureColor = Config.COLORS.Default

local function spawnLightPlatform()
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
	if not rootPart or not humanoid or humanoid.Health <= 0 then return end

	local now = os.clock()
	if now - lastPlatformSpawnTime < Config.PLATFORMS.Cooldown then
		return
	end
	lastPlatformSpawnTime = now

	-- Calcular posición justo debajo de los pies del jugador
	local spawnPosition = rootPart.Position - Vector3.new(0, 3.0, 0)
	local spawnCFrame = CFrame.new(spawnPosition)

	-- Notificar al servidor para instanciación y replicación autoritaria
	spawnPlatformEvent:FireServer(spawnCFrame, playerSignatureColor)

	-- Feedback local: Restaurar estado de salto / maniobras aéreas
	humanoid:ChangeState(Enum.HumanoidStateType.Landed)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Tecla E o F para desplegar Plataforma de Luz Sólida
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.F then
		spawnLightPlatform()
	end
end)
