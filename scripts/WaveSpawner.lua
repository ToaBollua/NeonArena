-- WaveSpawner.lua
-- Gestiona la creación y muerte de los drones en oleadas.
-- Ahora también gestiona el reinicio del juego cuando el jugador muere.

-- --- SERVICIOS Y VARIABLES ---
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local droneTemplate = ReplicatedStorage:WaitForChild("Dron")
local gameState = ReplicatedStorage:WaitForChild("GameState")
local waveStatus = gameState:WaitForChild("WaveStatus")
local dronesStatus = gameState:WaitForChild("DronesStatus")

-- --- CONFIGURACIÓN ---
local waveConfig = {
    { count = 3, health = 100 },
    { count = 5, health = 100 },
    { count = 7, health = 120 },
    { count = 10, health = 150 }
}
local timeBetweenWaves = 5

-- --- ESTADO DEL JUEGO ---
local currentWave = 0
local dronesAlive = 0
local activeDrones = {}

-- --- DECLARACIÓN ANTICIPADA ---
local function startNextWave() end

-- --- FUNCIONES ---

function warmUpSystems()
    -- ... (código de calentamiento se mantiene igual)
end

function onDroneDied(dronePart)
    dronesAlive = dronesAlive - 1
    dronesStatus.Value = "Drones restantes: " .. dronesAlive
    activeDrones[dronePart] = nil -- Elimina el dron de la lista de activos

    local tweenInfo = TweenInfo.new(0.5)
    local goal = { Transparency = 1 }
    local tween = TweenService:Create(dronePart, tweenInfo, goal)
    tween:Play()
    Debris:AddItem(dronePart, 0.5)

    if dronesAlive <= 0 then
        print("SPAWNER: ¡Oleada completada! Preparando la siguiente...")
        wait(timeBetweenWaves)
        startNextWave()
    end
end

function spawnDrone(health)
    local newDrone = droneTemplate:Clone()
    local humanoid = newDrone:WaitForChild("Humanoid")
    humanoid.MaxHealth = health
    humanoid.Health = health
    
    activeDrones[newDrone] = true -- Añade el dron a la lista de activos

    local isDead = false
    humanoid.HealthChanged:Connect(function(newHealth)
        if newHealth <= 0 and not isDead then
            isDead = true
            onDroneDied(newDrone)
        end
    end)

    local spawnX = math.random(-50, 50)
    local spawnZ = math.random(-50, 50)
    newDrone.Position = Vector3.new(spawnX, 5, spawnZ)
    newDrone.Parent = workspace
end

function startNextWave()
    currentWave = currentWave + 1
    waveStatus.Value = "Oleada " .. currentWave

    local config = waveConfig[currentWave]
    if not config then
        waveStatus.Value = "¡Has sobrevivido!"
        dronesStatus.Value = ""
        return
    end

    dronesAlive = config.count
    dronesStatus.Value = "Drones restantes: " .. dronesAlive
    for i = 1, dronesAlive do
        spawnDrone(config.health)
    end
end

function resetGame()
    print("SPAWNER: El jugador ha muerto. Reiniciando el juego.")
    -- Destruye todos los drones activos
    for drone, _ in pairs(activeDrones) do
        if drone and drone.Parent then
            drone:Destroy()
        end
    end
    table.clear(activeDrones)

    currentWave = 0
    dronesAlive = 0
    wait(timeBetweenWaves) -- Espera antes de reiniciar
    startNextWave()
end

function onCharacterDied(player)
    -- Cuando el humanoide del personaje muere, reinicia el juego
    resetGame()
end

function onCharacterAdded(character, player)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function() onCharacterDied(player) end)
end

function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character) onCharacterAdded(character, player) end)
    if player.Character then
        onCharacterAdded(player.Character, player)
    end
end

-- --- INICIO DEL SCRIPT ---

-- warmUpSystems() -- Desactivado temporalmente para acelerar pruebas

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

wait(3)
startNextWave()