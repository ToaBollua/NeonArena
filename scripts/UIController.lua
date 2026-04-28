-- UIController.lua
-- Gestiona los elementos de la interfaz de usuario del juego.

-- --- SERVICIOS Y VARIABLES ---
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- --- REFERENCIAS A LA UI ---
local gui = script.Parent
local crosshair = gui:WaitForChild("Crosshair")
local waveLabel = gui:WaitForChild("WaveLabel")
local dronesLabel = gui:WaitForChild("DronesLabel")
local heatBarBackground = gui:WaitForChild("HeatBarBackground")
local heatBarFill = heatBarBackground:WaitForChild("HeatBarFill")

-- --- REFERENCIAS AL ESTADO DEL JUEGO ---
local gameState = ReplicatedStorage:WaitForChild("GameState")
local waveStatus = gameState:WaitForChild("WaveStatus")
local dronesStatus = gameState:WaitForChild("DronesStatus")
local heatStatus = gameState:WaitForChild("HeatStatus")

-- --- CONFIGURACIÓN DE LA BARRA DE CALOR ---
local MAX_HEAT_DISPLAY = 100 -- Debe coincidir con MAX_HEAT en Aguijon_Client

-- --- FUNCIONES ---

-- Actualiza el texto de una etiqueta
function updateLabel(label, valueObject)
    label.Text = valueObject.Value
end

-- Actualiza la barra de calor
function updateHeatBar(currentHeatValue)
    local fillRatio = currentHeatValue / MAX_HEAT_DISPLAY
    heatBarFill.Size = UDim2.new(fillRatio, 0, 1, 0)

    -- Cambia el color de la barra de verde a rojo
    local color = Color3.new(1 - fillRatio, fillRatio, 0) -- Interpolación de color
    heatBarFill.BackgroundColor3 = color
end

-- Se ejecuta cuando el jugador presiona o suelta un botón del ratón
function onInput(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if input.UserInputState == Enum.UserInputState.Begin then
            -- Al apuntar, se oculta el punto de mira
            crosshair.Visible = false
        elseif input.UserInputState == Enum.UserInputState.End then
            -- Al dejar de apuntar, se muestra de nuevo
            crosshair.Visible = true
        end
    end
end

-- --- ELEMENTOS DINÁMICOS (Salud y Dash) ---

-- Barra de Salud
local healthBarBackground = Instance.new("Frame")
healthBarBackground.Name = "HealthBarBackground"
healthBarBackground.Size = UDim2.new(0, 200, 0, 20)
healthBarBackground.Position = UDim2.new(0.5, -100, 1, -110)
healthBarBackground.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
healthBarBackground.BorderSizePixel = 0
healthBarBackground.Parent = gui

local healthBarFill = Instance.new("Frame")
healthBarFill.Name = "HealthBarFill"
healthBarFill.Size = UDim2.new(1, 0, 1, 0)
healthBarFill.BackgroundColor3 = Color3.new(0, 1, 0)
healthBarFill.BorderSizePixel = 0
healthBarFill.Parent = healthBarBackground

local function updateHealthBar(health, maxHealth)
    local fillRatio = math.clamp(health / maxHealth, 0, 1)
    healthBarFill.Size = UDim2.new(fillRatio, 0, 1, 0)
    healthBarFill.BackgroundColor3 = Color3.new(1 - fillRatio, fillRatio, 0)
end

local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    updateHealthBar(humanoid.Health, humanoid.MaxHealth)
    humanoid.HealthChanged:Connect(function(health)
        updateHealthBar(health, humanoid.MaxHealth)
    end)
end

if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Indicador de Dash
local dashIndicatorBackground = Instance.new("Frame")
dashIndicatorBackground.Name = "DashIndicatorBackground"
dashIndicatorBackground.Size = UDim2.new(0, 100, 0, 10)
dashIndicatorBackground.Position = UDim2.new(0.5, -50, 1, -80)
dashIndicatorBackground.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
dashIndicatorBackground.BorderSizePixel = 0
dashIndicatorBackground.Parent = gui

local dashIndicatorFill = Instance.new("Frame")
dashIndicatorFill.Name = "DashIndicatorFill"
dashIndicatorFill.Size = UDim2.new(1, 0, 1, 0)
dashIndicatorFill.BackgroundColor3 = Color3.new(0, 0.8, 1)
dashIndicatorFill.BorderSizePixel = 0
dashIndicatorFill.Parent = dashIndicatorBackground

local DASH_COOLDOWN = 1 -- Sincronizado con PlayerController.lua

RunService.RenderStepped:Connect(function()
    local lastDashTime = player:GetAttribute("LastDashTime") or 0
    local timeSinceDash = tick() - lastDashTime
    local fillRatio = math.clamp(timeSinceDash / DASH_COOLDOWN, 0, 1)

    dashIndicatorFill.Size = UDim2.new(fillRatio, 0, 1, 0)
    if fillRatio < 1 then
        dashIndicatorFill.BackgroundColor3 = Color3.new(0.2, 0.4, 0.5) -- Oscurecido
    else
        dashIndicatorFill.BackgroundColor3 = Color3.new(0, 0.8, 1) -- Listo
    end
end)

-- --- INICIALIZACIÓN Y CONEXIONES ---

-- Actualiza las etiquetas con los valores iniciales
updateLabel(waveLabel, waveStatus)
updateLabel(dronesLabel, dronesStatus)
updateHeatBar(heatStatus.Value)

-- Conecta las actualizaciones futuras
waveStatus.Changed:Connect(function() updateLabel(waveLabel, waveStatus) end)
dronesStatus.Changed:Connect(function() updateLabel(dronesLabel, dronesStatus) end)
heatStatus.Changed:Connect(function() updateHeatBar(heatStatus.Value) end)

UserInputService.InputBegan:Connect(onInput)
UserInputService.InputEnded:Connect(onInput)