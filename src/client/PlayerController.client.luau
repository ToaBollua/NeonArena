--!strict
-- src/client/PlayerController.client.luau
-- Controlador de Jugador en Tercera Persona (OTS Scriptable Camera) con Movimiento Mecánico Frenético (Parkour, Doble Salto, Slide, Dash, Wall-Jump)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- --- ESTADO DE MOVILIDAD ---
local airJumpsRemaining = Config.MOVEMENT.MaxAirJumps
local isSliding = false
local lastSlideTime = 0.0
local lastDashTime = 0.0
local isDashing = false

-- Key tracking
local activeKeys = {
	W = false,
	A = false,
	S = false,
	D = false,
}

-- --- ESTADO DE CÁMARA TERCERA PERSONA SCRIPTABLE ---
local cameraYaw = 0.0
local cameraPitch = 0.0
local shoulderSideTarget = 1.0  -- 1.0 = Hombro Derecho, -1.0 = Hombro Izquierdo
local currentShoulderSide = 1.0
local isMenuOpen = false

local function computeMoveVector(): Vector3
	local z = (activeKeys.S and 1 or 0) - (activeKeys.W and 1 or 0)
	local x = (activeKeys.D and 1 or 0) - (activeKeys.A and 1 or 0)
	local raw = Vector3.new(x, 0, z)
	return raw.Magnitude > 0 and raw.Unit or Vector3.zero
end

-- Control de Menú de Pausa (ESC)
GuiService.MenuOpened:Connect(function()
	isMenuOpen = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end)

GuiService.MenuClosed:Connect(function()
	isMenuOpen = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end)

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	humanoid.AutoRotate = false
	humanoid.WalkSpeed = Config.MOVEMENT.WalkSpeed
	humanoid.JumpPower = Config.MOVEMENT.JumpPower

	-- Configurar cámara scriptable
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = Config.CAMERA.DefaultFOV
	if not isMenuOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end

	-- Inicializar orientación de la cámara
	local _, rootYaw, _ = rootPart.CFrame:ToOrientation()
	cameraYaw = rootYaw
	cameraPitch = 0.0

	-- Attachments para movilidad y orientación física limpia (sin sobreescribir CFrame en física)
	local rootAttachment = rootPart:FindFirstChild("RootAttachment") :: Attachment?
	if not rootAttachment then
		rootAttachment = Instance.new("Attachment")
		rootAttachment.Name = "RootAttachment"
		rootAttachment.Parent = rootPart
	end

	local moveAttachment = rootPart:FindFirstChild("MovementAttachment") :: Attachment?
	if not moveAttachment then
		moveAttachment = Instance.new("Attachment")
		moveAttachment.Name = "MovementAttachment"
		moveAttachment.Parent = rootPart
	end

	local alignOrientation = rootPart:FindFirstChild("BodyAlignOrientation") :: AlignOrientation?
	if not alignOrientation then
		alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.Name = "BodyAlignOrientation"
		alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		alignOrientation.Attachment0 = rootAttachment
		alignOrientation.RigidityEnabled = true
		alignOrientation.Responsiveness = 200
		alignOrientation.Parent = rootPart
	end

	-- Función para resetear saltos en el aire
	local function resetAirState()
		airJumpsRemaining = Config.MOVEMENT.MaxAirJumps
		isSliding = false
	end

	-- Detectar aterrizaje en suelo o plataforma de luz
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
			resetAirState()
		end
	end)

	-- --- EJECUTAR DASH ---
	local function performDash()
		local now = os.clock()
		if now - lastDashTime < Config.MOVEMENT.DashCooldown or isDashing then
			return
		end
		lastDashTime = now
		isDashing = true

		local moveVec = computeMoveVector()
		local rotCFrame = CFrame.Angles(0, cameraYaw, 0)
		local worldDir: Vector3

		if moveVec.Magnitude > 0 then
			worldDir = rotCFrame:VectorToWorldSpace(moveVec)
		else
			worldDir = rotCFrame.LookVector
		end
		local flatDir = Vector3.new(worldDir.X, 0, worldDir.Z).Unit

		local linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.Name = "DashVelocity"
		linearVelocity.MaxForce = 120000
		linearVelocity.VectorVelocity = flatDir * Config.MOVEMENT.DashSpeed
		linearVelocity.Attachment0 = moveAttachment
		linearVelocity.Parent = rootPart

		-- Efecto de FOV Punch
		local fovTween = TweenService:Create(camera, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = Config.CAMERA.DashFOV })
		fovTween:Play()

		task.delay(Config.MOVEMENT.DashDuration, function()
			linearVelocity:Destroy()
			isDashing = false
			local fovReset = TweenService:Create(camera, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = Config.CAMERA.DefaultFOV })
			fovReset:Play()
		end)
	end

	-- --- EJECUTAR SLIDE ---
	local function performSlide()
		local now = os.clock()
		if now - lastSlideTime < Config.MOVEMENT.SlideCooldown or isSliding or isDashing then
			return
		end
		if humanoid.FloorMaterial == Enum.Material.Air then
			return -- Solo deslizar en suelo
		end

		lastSlideTime = now
		isSliding = true

		local rotCFrame = CFrame.Angles(0, cameraYaw, 0)
		local moveVec = computeMoveVector()
		local dir = moveVec.Magnitude > 0 and rotCFrame:VectorToWorldSpace(moveVec) or rotCFrame.LookVector
		local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit

		local linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.Name = "SlideVelocity"
		linearVelocity.MaxForce = 90000
		linearVelocity.VectorVelocity = flatDir * Config.MOVEMENT.SlideSpeed
		linearVelocity.Attachment0 = moveAttachment
		linearVelocity.Parent = rootPart

		task.delay(Config.MOVEMENT.SlideDuration, function()
			linearVelocity:Destroy()
			isSliding = false
		end)
	end

	-- --- VERIFICAR Y EJECUTAR WALL JUMP ---
	local function checkWallJump(): boolean
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			return false
		end

		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { character }

		local rayDirections = {
			rootPart.CFrame.RightVector * Config.MOVEMENT.WallRaycastDistance,
			-rootPart.CFrame.RightVector * Config.MOVEMENT.WallRaycastDistance,
			rootPart.CFrame.LookVector * Config.MOVEMENT.WallRaycastDistance,
		}

		for _, dir in ipairs(rayDirections) do
			local result = workspace:Raycast(rootPart.Position, dir, rayParams)
			if result and result.Instance and result.Instance.CanCollide then
				local wallNormal = result.Normal
				local pushDir = (wallNormal + Vector3.new(0, 1.2, 0)).Unit

				local linearVelocity = Instance.new("LinearVelocity")
				linearVelocity.Name = "WallJumpVelocity"
				linearVelocity.MaxForce = 120000
				linearVelocity.VectorVelocity = pushDir * Config.MOVEMENT.WallJumpPush + Vector3.new(0, Config.MOVEMENT.WallJumpPower, 0)
				linearVelocity.Attachment0 = moveAttachment
				linearVelocity.Parent = rootPart

				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				airJumpsRemaining = 1 -- Recarga el doble salto tras saltar de la pared

				task.delay(0.12, function()
					linearVelocity:Destroy()
				end)
				return true
			end
		end
		return false
	end

	-- --- GESTIÓN DE ENTRADAS ---
	local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.W then activeKeys.W = true
		elseif input.KeyCode == Enum.KeyCode.A then activeKeys.A = true
		elseif input.KeyCode == Enum.KeyCode.S then activeKeys.S = true
		elseif input.KeyCode == Enum.KeyCode.D then activeKeys.D = true
		
		-- CAMBIAR DE HOMBRO (Tecla V)
		elseif input.KeyCode == Enum.KeyCode.V then
			shoulderSideTarget = -shoulderSideTarget

		-- DASH (Q o LeftShift)
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftShift then
			performDash()

		-- SLIDE (LeftControl o C)
		elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.C then
			performSlide()

		-- SALTO / DOBLE SALTO / WALL JUMP (Espacio)
		elseif input.KeyCode == Enum.KeyCode.Space then
			if humanoid.FloorMaterial == Enum.Material.Air then
				local wallJumped = checkWallJump()
				if not wallJumped and airJumpsRemaining > 0 then
					airJumpsRemaining -= 1
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					rootPart.AssemblyLinearVelocity = Vector3.new(
						rootPart.AssemblyLinearVelocity.X,
						Config.MOVEMENT.JumpPower,
						rootPart.AssemblyLinearVelocity.Z
					)
				end
			end
		end
	end)

	local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.W then activeKeys.W = false
		elseif input.KeyCode == Enum.KeyCode.A then activeKeys.A = false
		elseif input.KeyCode == Enum.KeyCode.S then activeKeys.S = false
		elseif input.KeyCode == Enum.KeyCode.D then activeKeys.D = false
		end
	end)

	humanoid.Died:Connect(function()
		inputBeganConn:Disconnect()
		inputEndedConn:Disconnect()
	end)
end

-- --- CAPTURA DE MOVIMIENTO DEL RATÓN PARA CÁMARA OTS ---
UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if isMenuOpen then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Delta
		local sensitivity = Config.CAMERA.MouseSensitivity or 0.0028
		cameraYaw = cameraYaw - delta.X * sensitivity
		cameraPitch = math.clamp(
			cameraPitch - delta.Y * sensitivity,
			Config.CAMERA.PitchMin or math.rad(-75),
			Config.CAMERA.PitchMax or math.rad(75)
		)
	end
end)

UserInputService.WindowFocused:Connect(function()
	if not isMenuOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end
end)

-- --- BUCLE PRINCIPAL DE CÁMARA OTS Y ORIENTACIÓN DEL JUGADOR ---
RunService:BindToRenderStep("NeonArenaCamera", Enum.RenderPriority.Camera.Value + 10, function(deltaTime: number)
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
	if not rootPart or not humanoid or humanoid.Health <= 0 then return end

	-- Comportamiento de Mouse seguro (respeta ESC)
	if not isMenuOpen and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end

	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- 1. Transición suave del hombro (Key V)
	currentShoulderSide = currentShoulderSide + (shoulderSideTarget - currentShoulderSide) * math.min(1.0, deltaTime * 14.0)

	-- 2. Rotación esférica de la cámara (Yaw + Pitch)
	local camRotation = CFrame.Angles(0, cameraYaw, 0) * CFrame.Angles(cameraPitch, 0, 0)
	local focusPoint = rootPart.Position + Vector3.new(0, Config.CAMERA.HeightOffset, 0)

	-- 3. Offset de hombro y distancia hacia atrás
	local shoulderOffsetVec = camRotation.RightVector * (Config.CAMERA.ShoulderOffset * currentShoulderSide)
	local targetCamPos = focusPoint + shoulderOffsetVec - (camRotation.LookVector * Config.CAMERA.Distance)

	-- 4. Raycast Anti-Clipping (Evitar que la cámara atraviese paredes)
	local camRayParams = RaycastParams.new()
	camRayParams.FilterType = Enum.RaycastFilterType.Exclude
	camRayParams.FilterDescendantsInstances = { character }

	local rayDir = targetCamPos - focusPoint
	local rayResult = workspace:Raycast(focusPoint, rayDir, camRayParams)
	local finalCamPos = targetCamPos

	if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
		finalCamPos = rayResult.Position + (rayResult.Normal * 0.4)
	end

	-- 5. Aplicar CFrame a la Cámara
	camera.CFrame = CFrame.lookAt(finalCamPos, finalCamPos + camRotation.LookVector)

	-- 6. Orientación física con AlignOrientation (sin congelar posición física de HumanoidRootPart)
	local alignOrientation = rootPart:FindFirstChild("BodyAlignOrientation") :: AlignOrientation?
	if alignOrientation then
		alignOrientation.CFrame = CFrame.Angles(0, cameraYaw, 0)
	end

	-- 7. Movimiento WASD relativo al frente de la cámara
	if not isSliding and not isDashing then
		local localMove = computeMoveVector()
		if localMove.Magnitude > 0 then
			local rotCFrame = CFrame.Angles(0, cameraYaw, 0)
			local worldMove = rotCFrame:VectorToWorldSpace(localMove)
			local flatMove = Vector3.new(worldMove.X, 0, worldMove.Z).Unit
			humanoid:Move(flatMove, false)
		else
			humanoid:Move(Vector3.zero, false)
		end
	end
end)

-- Inicialización
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
