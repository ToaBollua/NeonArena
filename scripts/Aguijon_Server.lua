-- Aguijon_Server.lua
-- Script de servidor para el arma Disruptor de Pulso "Aguijón".
-- Se encarga de verificar y aplicar el daño.

-- --- CONFIGURACIÓN ---
local DAMAGE = 35 -- Daño por disparo

-- --- SERVICIOS Y VARIABLES ---
local tool = script.Parent
local onFireEvent = tool:WaitForChild("OnFire")

-- --- FUNCIONES ---

function onFire(player, targetPart)
    print("SERVIDOR: Evento 'onFire' recibido. Verificando impacto en '" .. tostring(targetPart) .. "'.")

    -- Verificaciones de seguridad
    if not targetPart or not targetPart.Parent then return end

    -- Busca un humanoide en la pieza impactada o en su padre
    local targetHumanoid = targetPart:FindFirstChildOfClass("Humanoid") or (targetPart.Parent and targetPart.Parent:FindFirstChildOfClass("Humanoid"))

    if targetHumanoid then
        -- Si encuentra un humanoide, le hace daño
        print("SERVIDOR: Impacto confirmado en " .. targetPart.Parent.Name .. ". Aplicando " .. DAMAGE .. " de daño.")
        targetHumanoid:TakeDamage(DAMAGE)
    else
        print("SERVIDOR: El objeto impactado no tiene Humanoide.")
    end
end

-- --- CONEXIONES ---

onFireEvent.OnServerEvent:Connect(onFire)