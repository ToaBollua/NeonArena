-- DroneAI.lua
-- IA básica para un dron enemigo.
-- Hace que el Part al que está asociado persiga al jugador más cercano.
-- Ahora incluye salud, secuencia de muerte optimizada y lógica de ataque.

-- --- CONFIGURACIÓN ---
local MOVE_SPEED = 15       -- Velocidad del dron (en studs por segundo)
local ATTACK_RANGE = 5      -- Distancia a la que el dron se detiene del jugador
local SENSE_RADIUS = 100    -- Distancia máxima a la que el dron puede detectar a un jugador
local ATTACK_DAMAGE = 10    -- Daño que el dron hace por ataque
local ATTACK_COOLDOWN = 1.5 -- Segundos entre ataques del dron

-- --- SERVICIOS Y VARIABLES ---
local drone = script.Parent
local humanoid = drone:WaitForChild("Humanoid") -- Espera a que el humanoide exista
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local target = nil
local connection = nil
local lastAttackTime = tick() -- Inicializa con el tiempo actual para que pueda atacar de inmediato

-- --- FUNCIONES ---

-- Función para encontrar al jugador más cercano
function findNearestPlayer()
    local nearestPlayer = nil
    local minDistance = SENSE_RADIUS

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.Humanoid.Health > 0 then
            local character = player.Character
            local humanoidRootPart = character.HumanoidRootPart
            local distance = (drone.Position - humanoidRootPart.Position).Magnitude

            if distance < minDistance then
                minDistance = distance
                nearestPlayer = character
            end
        end
    end

    return nearestPlayer
end

-- Función que se ejecuta en cada frame del juego
function onHeartbeat(deltaTime)
    -- Si el dron está muerto, no hace nada.
    if humanoid.Health <= 0 then
        -- Desconecta el bucle para que el dron muerto no consuma recursos
        if connection then
            connection:Disconnect()
        end
        return
    end

    -- Busca un objetivo si no tiene uno o si el actual está muerto/desconectado
    if not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0 then
        target = findNearestPlayer()
        if not target then return end -- Si no hay jugadores, no hace nada
    end

    -- Mueve el dron hacia el objetivo
    local targetPosition = target.HumanoidRootPart.Position
    local dronePosition = drone.Position
    local direction = (targetPosition - dronePosition).Unit
    local distance = (targetPosition - dronePosition).Magnitude

    -- Solo se mueve si está más lejos que el rango de ataque
    if distance > ATTACK_RANGE then
        drone.CFrame = drone.CFrame + direction * MOVE_SPEED * deltaTime
    else
        -- Si está dentro del rango de ataque, intenta atacar
        local currentTime = tick()
        if currentTime - lastAttackTime >= ATTACK_COOLDOWN then
            print("DRON: Atacando a " .. target.Name .. ". Daño: " .. ATTACK_DAMAGE)
            target.Humanoid:TakeDamage(ATTACK_DAMAGE)
            lastAttackTime = currentTime
        end
    end
end

-- --- CONEXIONES ---

-- Conecta la función onHeartbeat para que se ejecute en cada frame
connection = RunService.Heartbeat:Connect(onHeartbeat)