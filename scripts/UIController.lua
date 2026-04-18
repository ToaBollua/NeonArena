-- UIController.lua
-- Gestiona los elementos de la interfaz de usuario del juego.

-- --- SERVICIOS Y VARIABLES ---
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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