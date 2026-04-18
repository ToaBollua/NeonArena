-- PlayerController.lua
-- Un controlador de personaje personalizado para un movimiento más ágil y responsivo.

-- --- SERVICIOS Y VARIABLES ---
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

-- --- CONFIGURACIÓN ---
local WALK_SPEED = 20
local JUMP_POWER = 50
local DEFAULT_FOV = 70
local AIM_FOV = 40
local AIM_SPEED = 0.2

-- Configuración del Dash
local DASH_SPEED = 80
local DASH_DURATION = 0.15
local DASH_COOLDOWN = 1
local DASH_KEY = Enum.KeyCode.Q
local DASH_ACTION = "PlayerDash"

-- --- VARIABLES LOCALES ---
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local moveVector = Vector3.new(0, 0, 0)
local keybinds = {
    [Enum.KeyCode.W] = Vector3.new(0, 0, -1),
    [Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.S] = Vector3.new(0, 0, 1),
    [Enum.KeyCode.D] = Vector3.new(1, 0, 0)
}

local connections = {}
local lastDashTime = 0

-- --- FUNCIONES ---

function onCharacterAdded(character)
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
    ContextActionService:UnbindAction(DASH_ACTION)

    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    local playerScripts = player:WaitForChild("PlayerScripts")
    local playerModule = playerScripts:WaitForChild("PlayerModule")
    require(playerModule):GetControls():Disable()

    humanoid.AutoRotate = false

    local function tweenFov(targetFov)
        local tweenInfo = TweenInfo.new(AIM_SPEED, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local goal = { FieldOfView = targetFov }
        local tween = TweenService:Create(camera, tweenInfo, goal)
        tween:Play()
    end

    local function handleDash(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin and tick() - lastDashTime > DASH_COOLDOWN then
            lastDashTime = tick()

            local dashDirection = moveVector
            if dashDirection.Magnitude == 0 then -- Si está quieto, hace el dash hacia adelante
                dashDirection = Vector3.new(0, 0, -1)
            end

            local worldDashDir = camera.CFrame:VectorToWorldSpace(dashDirection).Unit
            local flatDashDir = Vector3.new(worldDashDir.X, 0, worldDashDir.Z).Unit

            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
            bodyVelocity.Velocity = flatDashDir * DASH_SPEED
            bodyVelocity.Parent = rootPart

            Debris:AddItem(bodyVelocity, DASH_DURATION)
            print("PLAYER: Dash!")
        end
        return Enum.ContextActionResult.Sink
    end

    local function onInput(input, gameProcessed)
        if gameProcessed then return end

        if keybinds[input.KeyCode] then
            if input.UserInputState == Enum.UserInputState.Begin then
                moveVector = moveVector + keybinds[input.KeyCode]
            elseif input.UserInputState == Enum.UserInputState.End then
                moveVector = moveVector - keybinds[input.KeyCode]
            end
        elseif input.KeyCode == Enum.KeyCode.Space and input.UserInputState == Enum.UserInputState.Begin then
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid.JumpPower = JUMP_POWER
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            if input.UserInputState == Enum.UserInputState.Begin then
                tweenFov(AIM_FOV)
            elseif input.UserInputState == Enum.UserInputState.End then
                tweenFov(DEFAULT_FOV)
            end
        end
    end

    local function onHeartbeat(deltaTime)
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        humanoid.WalkSpeed = WALK_SPEED

        local cameraLookVector = camera.CFrame.LookVector
        local flatLookVector = Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z).Unit
        if flatLookVector.Magnitude > 0.01 then
            rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + flatLookVector)
        end

        local cameraDirection = camera.CFrame:VectorToWorldSpace(moveVector).Unit
        local flatMoveDirection = Vector3.new(cameraDirection.X, 0, cameraDirection.Z).Unit
        local currentVelocity = rootPart.Velocity
        local newVelocity
        if moveVector.Magnitude > 0 then
            newVelocity = Vector3.new(flatMoveDirection.X * WALK_SPEED, currentVelocity.Y, flatMoveDirection.Z * WALK_SPEED)
        else
            newVelocity = Vector3.new(0, currentVelocity.Y, 0)
        end
        rootPart.Velocity = newVelocity
    end

    table.insert(connections, UserInputService.InputBegan:Connect(onInput))
    table.insert(connections, UserInputService.InputEnded:Connect(onInput))
    table.insert(connections, RunService.Heartbeat:Connect(onHeartbeat))
    ContextActionService:BindAction(DASH_ACTION, handleDash, false, DASH_KEY)
end

-- --- CONEXIONES INICIALES ---

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end
