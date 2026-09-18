--!strict
-- src/server/PlatformManager.server.luau
-- Gestor Autorizado de Plataformas de Luz Sólida en el Servidor (Replicación y Desvanecimiento)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local NetworkEvents = require(Shared:WaitForChild("NetworkEvents") :: ModuleScript)

local spawnPlatformEvent = NetworkEvents.getRemoteEvent(NetworkEvents.SpawnPlatform)

-- Registro de plataformas por jugador: [UserId] -> { Part, Part, ... }
local playerPlatforms: { [number]: { BasePart } } = {}

local platformsFolder = Instance.new("Folder")
platformsFolder.Name = "SolidLightPlatforms"
platformsFolder.Parent = workspace

local function onSpawnPlatform(player: Player, targetCFrame: CFrame, color: Color3?)
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	-- Validar distancia para evitar exploits de teletransporte de plataformas
	if (rootPart.Position - targetCFrame.Position).Magnitude > 20 then
		return
	end

	local userId = player.UserId
	if not playerPlatforms[userId] then
		playerPlatforms[userId] = {}
	end

	-- Limitar a un máximo de plataformas activas por jugador
	if #playerPlatforms[userId] >= Config.PLATFORMS.MaxActivePerPlayer then
		local oldestPlatform = table.remove(playerPlatforms[userId], 1)
		if oldestPlatform and oldestPlatform.Parent then
			oldestPlatform:Destroy()
		end
	end

	-- Crear la plataforma de luz sólida
	local platform = Instance.new("Part")
	platform.Name = "SolidLightPlatform_" .. player.Name
	platform.Size = Config.PLATFORMS.Size
	platform.CFrame = targetCFrame
	platform.Anchored = true
	platform.CanCollide = true
	platform.Material = Config.PLATFORMS.Material
	platform.Color = color or Config.COLORS.Default
	platform.Transparency = Config.PLATFORMS.Transparency
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth
	platform.Parent = platformsFolder

	table.insert(playerPlatforms[userId], platform)

	-- Auto-desvanecimiento tras su tiempo de vida
	task.delay(Config.PLATFORMS.Lifetime - 0.6, function()
		if platform and platform.Parent then
			local fadeTween = TweenService:Create(platform, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			})
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				if platform and platform.Parent then
					platform:Destroy()
				end
			end)
		end
	end)
end

spawnPlatformEvent.OnServerEvent:Connect(onSpawnPlatform)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	if playerPlatforms[userId] then
		for _, part in ipairs(playerPlatforms[userId]) do
			if part and part.Parent then
				part:Destroy()
			end
		end
		playerPlatforms[userId] = nil
	end
end)
