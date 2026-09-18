--!strict
-- src/client/UIController.client.luau
-- Interfaz de Usuario Cyberpunk CRT: Crosshair, Barras de Salud/Escudo, Calor de Arma y Oleadas

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local NetworkEvents = require(Shared:WaitForChild("NetworkEvents") :: ModuleScript)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local waveUpdateEvent = NetworkEvents.getRemoteEvent(NetworkEvents.WaveUpdate)
local playerDamagedEvent = NetworkEvents.getRemoteEvent(NetworkEvents.PlayerDamaged)

-- Crear ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NeonArenaHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- --- CROSSHAIR CENTRAL ---
local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.Size = UDim2.new(0, 6, 0, 6)
crosshair.Position = UDim2.new(0.5, -3, 0.5, -3)
crosshair.BackgroundColor3 = Config.COLORS.Default
crosshair.BorderSizePixel = 0
crosshair.Parent = screenGui

local chCorner = Instance.new("UICorner")
chCorner.CornerRadius = UDim.new(1, 0)
chCorner.Parent = crosshair

-- --- CONTENEDOR DE VITALIDAD (SALUD Y ESCUDO) ---
local vitalContainer = Instance.new("Frame")
vitalContainer.Name = "VitalContainer"
vitalContainer.Size = UDim2.new(0, 240, 0, 48)
vitalContainer.Position = UDim2.new(0, 24, 1, -72)
vitalContainer.BackgroundColor3 = Color3.fromRGB(10, 15, 12)
vitalContainer.BorderColor3 = Config.COLORS.Default
vitalContainer.BorderSizePixel = 1
vitalContainer.Parent = screenGui

-- Barra de Escudo
local shieldBar = Instance.new("Frame")
shieldBar.Name = "ShieldBar"
shieldBar.Size = UDim2.new(1, -8, 0, 16)
shieldBar.Position = UDim2.new(0, 4, 0, 4)
shieldBar.BackgroundColor3 = Config.COLORS.Cyan
shieldBar.BorderSizePixel = 0
shieldBar.Parent = vitalContainer

-- Barra de Salud
local healthBar = Instance.new("Frame")
healthBar.Name = "HealthBar"
healthBar.Size = UDim2.new(1, -8, 0, 16)
healthBar.Position = UDim2.new(0, 4, 0, 24)
healthBar.BackgroundColor3 = Config.COLORS.Default
healthBar.BorderSizePixel = 0
healthBar.Parent = vitalContainer

-- --- CONTENEDOR DE OLEADA (PARTE SUPERIOR) ---
local waveContainer = Instance.new("Frame")
waveContainer.Name = "WaveContainer"
waveContainer.Size = UDim2.new(0, 200, 0, 40)
waveContainer.Position = UDim2.new(0.5, -100, 0, 16)
waveContainer.BackgroundColor3 = Color3.fromRGB(10, 15, 12)
waveContainer.BorderColor3 = Config.COLORS.Default
waveContainer.BorderSizePixel = 1
waveContainer.Parent = screenGui

local waveLabel = Instance.new("TextLabel")
waveLabel.Name = "WaveLabel"
waveLabel.Size = UDim2.new(1, 0, 1, 0)
waveLabel.BackgroundTransparency = 1
waveLabel.TextColor3 = Config.COLORS.Default
waveLabel.Font = Enum.Font.Code
waveLabel.TextSize = 16
waveLabel.Text = "OLEADA 1 // DRONES: 0"
waveLabel.Parent = waveContainer

-- --- RECEPCIÓN DE EVENTOS DE RED ---
waveUpdateEvent.OnClientEvent:Connect(function(currentWave: number, dronesRemaining: number)
	waveLabel.Text = string.format("OLEADA %d // DRONES: %d", currentWave, dronesRemaining)
end)

playerDamagedEvent.OnClientEvent:Connect(function(health: number, shield: number)
	local healthScale = math.clamp(health / Config.PLAYER_VITALITY.MaxHealth, 0, 1)
	local shieldScale = math.clamp(shield / Config.PLAYER_VITALITY.MaxShield, 0, 1)

	TweenService:Create(healthBar, TweenInfo.new(0.2), { Size = UDim2.new(healthScale, -8 * healthScale, 0, 16) }):Play()
	TweenService:Create(shieldBar, TweenInfo.new(0.2), { Size = UDim2.new(shieldScale, -8 * shieldScale, 0, 16) }):Play()
end)
