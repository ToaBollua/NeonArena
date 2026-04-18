-- Aguijon_Client.lua
-- Script local para el arma Disruptor de Pulso "Aguijón".
-- Se encarga de la entrada del jugador, efectos visuales y de notificar al servidor del disparo.
-- Ahora incluye lógica de sobrecalentamiento.

-- --- SERVICIOS Y VARIABLES ---
local tool = script.Parent
local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Referencias a las partes del arma y el evento
local handle = tool:WaitForChild("Handle")
local muzzle = tool:WaitForChild("Muzzle")
local onFireEvent = tool:WaitForChild("OnFire")

-- Referencia al valor de estado del calor del arma
local gameState = ReplicatedStorage:WaitForChild("GameState")
local heatStatus = gameState:WaitForChild("HeatStatus")

-- --- CONFIGURACIÓN DE SOBRECALENTAMIENTO ---
local MAX_HEAT = 100        -- Calor máximo antes de sobrecalentarse
local HEAT_PER_SHOT = 15    -- Calor generado por cada disparo
local COOL_RATE = 20        -- Velocidad de enfriamiento por segundo
local OVERHEAT_COOLDOWN = 2 -- Segundos que el arma está inutilizable al sobrecalentarse

-- --- ESTADO DEL ARMA ---
local currentHeat = 0
local isOverheated = false
local canFire = true -- Controla si el arma puede disparar

-- --- FUNCIONES ---

-- Actualiza el valor de calor en ReplicatedStorage
function updateHeatStatus()
    heatStatus.Value = currentHeat
end

-- Crea el efecto visual del disparo (un rayo de luz)
function crearEfectoDisparo(origen, destino)
    local distancia = (origen - destino).Magnitude
    
    local attachment0 = Instance.new("Attachment", muzzle)
    attachment0.Position = muzzle.CFrame:PointToObjectSpace(origen)

    local attachment1 = Instance.new("Attachment", workspace.Terrain)
    attachment1.Position = destino

    local beam = Instance.new("Beam")
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Color = ColorSequence.new(Color3.new(0, 1, 0)) -- Color Verde
    beam.FaceCamera = true
    beam.Width0 = 0.2
    beam.Width1 = 0.2
    beam.Transparency = NumberSequence.new(0.2)
    beam.Parent = tool

    Debris:AddItem(beam, 0.1)
    Debris:AddItem(attachment0, 0.1)
    Debris:AddItem(attachment1, 0.1)
end

function onEquip()
    print("Aguijón equipado.")
    currentHeat = 0
    isOverheated = false
    canFire = true
    updateHeatStatus()
end

function onUnequip()
    print("Aguijón guardado.")
    currentHeat = 0
    isOverheated = false
    canFire = true
    updateHeatStatus()
end

function onActivated()
    if not canFire or isOverheated then return end -- No dispara si no puede o está sobrecalentada
    
    -- Genera calor
    currentHeat = currentHeat + HEAT_PER_SHOT
    updateHeatStatus()

    if currentHeat >= MAX_HEAT then
        isOverheated = true
        canFire = false
        print("CLIENTE: ¡Arma sobrecalentada! Enfriamiento forzado.")

        -- Efecto de sonido: Alarma de sobrecalentamiento
        local overheatSound = Instance.new("Sound")
        overheatSound.SoundId = "rbxassetid://255060411" -- Zumbido de alarma
        overheatSound.Volume = 0.8
        overheatSound.Parent = handle
        overheatSound:Play()
        Debris:AddItem(overheatSound, 3)

        -- Inicia el enfriamiento forzado
        task.delay(OVERHEAT_COOLDOWN, function()
            currentHeat = 0
            isOverheated = false
            canFire = true
            updateHeatStatus()
            print("CLIENTE: Arma lista para disparar de nuevo.")
        end)
    else
        -- Efecto de sonido: Disparo
        local fireSound = Instance.new("Sound")
        fireSound.SoundId = "rbxassetid://131257121" -- Sonido de disparo láser de alta frecuencia
        fireSound.Volume = 0.6
        fireSound.Parent = handle
        fireSound:Play()
        Debris:AddItem(fireSound, 1)
    end

    local origen = muzzle.Position
    local destino = mouse.Hit.p

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character, tool}

    local camera = workspace.CurrentCamera
    local raycastResult = workspace:Raycast(camera.CFrame.Position, (destino - camera.CFrame.Position).Unit * 500, raycastParams)

    if raycastResult then
        destino = raycastResult.Position
        print("CLIENTE: Raycast impactó en '" .. raycastResult.Instance.Name .. "'. Avisando al servidor.")
        onFireEvent:FireServer(raycastResult.Instance)
    else
        destino = camera.CFrame.Position + (destino - camera.CFrame.Position).Unit * 500
        print("CLIENTE: Raycast no impactó en nada.")
    end

    crearEfectoDisparo(origen, destino)
end

-- Enfriamiento pasivo
RunService.Heartbeat:Connect(function(deltaTime)
    if not isOverheated and currentHeat > 0 then
        currentHeat = math.max(0, currentHeat - COOL_RATE * deltaTime)
        updateHeatStatus()
    end
end)

-- --- CONEXIONES ---

tool.Equipped:Connect(onEquip)
tool.Unequipped:Connect(onUnequip)
tool.Activated:Connect(onActivated)
