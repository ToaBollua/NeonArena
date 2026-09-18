--!strict
-- src/client/WeaponController.client.luau
-- Controlador de Armas y Modelos Visuales 3D Procedurales: Aguijón, Katana Glitch y Pistola de Pulso

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local NetworkEvents = require(Shared:WaitForChild("NetworkEvents") :: ModuleScript)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local fireRangedEvent = NetworkEvents.getRemoteEvent(NetworkEvents.FireRangedWeapon)
local meleeAttackEvent = NetworkEvents.getRemoteEvent(NetworkEvents.MeleeAttack)

-- --- LOADOUT Y ESTADO DE ARMAS ---
local loadout = {
	Slot1 = "Aguijon",     -- Aguijon (Rango) o NeonKatana (Melee)
	Slot2 = "PulsePistol", -- Pistola de Pulso
}
local activeSlot = 1
local currentHeat = 0.0
local isOverheated = false
local lastFireTime = 0.0
local isAttackingMelee = false

local playerColor = Config.COLORS.Default
local currentVisualModel: Model? = nil
local weaponGripMotor: Motor6D? = nil
local activeMuzzlePart: BasePart? = nil

local function getActiveWeaponKey(): string
	return activeSlot == 1 and loadout.Slot1 or loadout.Slot2
end

local function getActiveWeaponConfig(): any
	local key = getActiveWeaponKey()
	return Config.WEAPONS[key] or Config.WEAPONS.Aguijon
end

-- --- CONSTRUCCIÓN PROCEDURAL DE MODELOS VISUALES 3D ---
local function createWeaponPart(name: string, size: Vector3, color: Color3, material: Enum.Material, parent: Instance): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false
	part.Anchored = false
	part.Parent = parent
	return part
end

local function attachPart(part0: BasePart, part1: BasePart, relC0: CFrame): Weld
	local weld = Instance.new("Weld")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = relC0
	weld.Parent = part0
	return weld
end

local function buildVisualWeapon(weaponKey: string, handPart: BasePart): (Model, Motor6D, BasePart)
	local model = Instance.new("Model")
	model.Name = "NeonArena_VisualWeapon"

	local handle = Instance.new("Part")
	handle.Name = "WeaponHandle"
	handle.Size = Vector3.new(0.2, 0.2, 0.2)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Anchored = false
	handle.Parent = model

	local motor = Instance.new("Motor6D")
	motor.Name = "WeaponGrip"
	motor.Part0 = handPart
	motor.Part1 = handle
	motor.Parent = handPart

	local muzzlePart: BasePart = handle

	if weaponKey == "Aguijon" then
		-- --- RIFLE DE ASALTO AGUIJÓN ---
		motor.C0 = CFrame.new(0, -0.6, -0.6) * CFrame.Angles(0, 0, 0)

		-- Chasis central
		local body = createWeaponPart("RifleBody", Vector3.new(0.3, 0.45, 1.8), Color3.fromRGB(20, 22, 28), Enum.Material.Metal, model)
		attachPart(handle, body, CFrame.new(0, 0.2, -0.2))

		-- Cañón alargado
		local barrel = createWeaponPart("RifleBarrel", Vector3.new(0.18, 0.18, 1.2), Color3.fromRGB(35, 38, 45), Enum.Material.Metal, model)
		attachPart(body, barrel, CFrame.new(0, 0.08, -1.3))

		-- Riel Neón Superior
		local neonTop = createWeaponPart("NeonRail", Vector3.new(0.12, 0.08, 1.5), playerColor, Enum.Material.Neon, model)
		attachPart(body, neonTop, CFrame.new(0, 0.24, -0.1))

		-- Tiras Neón Laterales
		local neonLeft = createWeaponPart("NeonSideL", Vector3.new(0.05, 0.12, 0.8), playerColor, Enum.Material.Neon, model)
		attachPart(body, neonLeft, CFrame.new(-0.16, 0, -0.1))

		local neonRight = createWeaponPart("NeonSideR", Vector3.new(0.05, 0.12, 0.8), playerColor, Enum.Material.Neon, model)
		attachPart(body, neonRight, CFrame.new(0.16, 0, -0.1))

		-- Batería de energía
		local mag = createWeaponPart("BatteryCell", Vector3.new(0.24, 0.6, 0.35), Color3.fromRGB(15, 15, 18), Enum.Material.Metal, model)
		attachPart(body, mag, CFrame.new(0, -0.4, 0.2) * CFrame.Angles(math.rad(15), 0, 0))

		-- Muzzle
		local muzzle = createWeaponPart("MuzzleTip", Vector3.new(0.22, 0.22, 0.1), playerColor, Enum.Material.Neon, model)
		attachPart(barrel, muzzle, CFrame.new(0, 0, -0.65))
		muzzlePart = muzzle

	elseif weaponKey == "NeonKatana" then
		-- --- KATANA GLITCH ---
		motor.C0 = CFrame.new(0, -0.4, -0.3) * CFrame.Angles(math.rad(-45), math.rad(90), 0)

		-- Empuñadura (Tsuka)
		local hilt = createWeaponPart("KatanaHilt", Vector3.new(0.16, 0.16, 1.0), Color3.fromRGB(15, 15, 15), Enum.Material.SmoothPlastic, model)
		attachPart(handle, hilt, CFrame.new(0, 0, 0.4))

		-- Guarda (Tsuba)
		local tsuba = createWeaponPart("KatanaTsuba", Vector3.new(0.35, 0.35, 0.08), Color3.fromRGB(40, 40, 45), Enum.Material.Metal, model)
		attachPart(handle, tsuba, CFrame.new(0, 0, -0.1))

		-- Hoja de Luz Neón (Blade)
		local blade = createWeaponPart("KatanaBlade", Vector3.new(0.08, 0.3, 3.2), playerColor, Enum.Material.Neon, model)
		attachPart(handle, blade, CFrame.new(0, 0.05, -1.7))

		-- Punta afilada
		local tip = createWeaponPart("KatanaTip", Vector3.new(0.08, 0.22, 0.4), playerColor, Enum.Material.Neon, model)
		attachPart(blade, tip, CFrame.new(0, 0.04, -1.7) * CFrame.Angles(math.rad(30), 0, 0))

		local light = Instance.new("PointLight")
		light.Color = playerColor
		light.Brightness = 1.5
		light.Range = 8
		light.Parent = blade

		muzzlePart = tip

	else
		-- --- PISTOLA DE PULSO ---
		motor.C0 = CFrame.new(0, -0.5, -0.4) * CFrame.Angles(0, 0, 0)

		local frame = createWeaponPart("PistolBody", Vector3.new(0.25, 0.35, 0.9), Color3.fromRGB(25, 28, 32), Enum.Material.Metal, model)
		attachPart(handle, frame, CFrame.new(0, 0.15, -0.1))

		local slide = createWeaponPart("PistolSlide", Vector3.new(0.2, 0.1, 0.85), playerColor, Enum.Material.Neon, model)
		attachPart(frame, slide, CFrame.new(0, 0.2, 0))

		local grip = createWeaponPart("PistolGrip", Vector3.new(0.22, 0.45, 0.25), Color3.fromRGB(15, 15, 18), Enum.Material.SmoothPlastic, model)
		attachPart(frame, grip, CFrame.new(0, -0.3, 0.2) * CFrame.Angles(math.rad(15), 0, 0))

		local muzzle = createWeaponPart("PistolMuzzle", Vector3.new(0.18, 0.18, 0.1), playerColor, Enum.Material.Neon, model)
		attachPart(frame, muzzle, CFrame.new(0, 0.05, -0.5))
		muzzlePart = muzzle
	end

	model.PrimaryPart = handle
	model.Parent = handPart.Parent

	return model, motor, muzzlePart
end

-- --- GESTIÓN DE EQUIPAMIENTO VISUAL ---
local function equipVisualWeapon()
	if currentVisualModel then
		currentVisualModel:Destroy()
		currentVisualModel = nil
	end
	if weaponGripMotor then
		weaponGripMotor:Destroy()
		weaponGripMotor = nil
	end

	local character = player.Character
	if not character then return end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then return end

	local weaponKey = getActiveWeaponKey()
	local model, motor, muzzle = buildVisualWeapon(weaponKey, hand)
	currentVisualModel = model
	weaponGripMotor = motor
	activeMuzzlePart = muzzle
end

-- --- EFECTO VISUAL DE DISPARO Y TRACER ---
local function createTracerBeam(origin: Vector3, targetPos: Vector3, color: Color3)
	local distance = (targetPos - origin).Magnitude
	local tracer = Instance.new("Part")
	tracer.Name = "NeonTracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.CanTouch = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = color
	tracer.Size = Vector3.new(0.18, 0.18, distance)
	tracer.CFrame = CFrame.lookAt(origin:Lerp(targetPos, 0.5), targetPos)
	tracer.Parent = workspace

	local fadeTween = TweenService:Create(tracer, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(0.04, 0.04, distance)
	})
	fadeTween:Play()
	fadeTween.Completed:Connect(function()
		tracer:Destroy()
	end)
end

local function triggerMuzzleFlash(pos: Vector3, color: Color3)
	local flash = Instance.new("PointLight")
	flash.Color = color
	flash.Brightness = 3.5
	flash.Range = 12
	flash.Parent = activeMuzzlePart or workspace

	task.delay(0.05, function()
		flash:Destroy()
	end)
end

-- --- DISPARO A RANGO (AGUIJÓN / PISTOLA) ---
local function fireRangedWeapon(weaponConf: any)
	local now = os.clock()
	if now - lastFireTime < weaponConf.FireRate or isOverheated then
		return
	end
	lastFireTime = now

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	-- Aumentar calor
	currentHeat = math.clamp(currentHeat + weaponConf.HeatPerShot, 0.0, 1.0)
	if currentHeat >= 1.0 then
		isOverheated = true
		task.delay(weaponConf.OverheatCooldown, function()
			isOverheated = false
			currentHeat = 0.0
		end)
	end

	-- Raycast desde la cámara hacia el centro de la retícula
	local rayOrigin = camera.CFrame.Position
	local rayDirection = camera.CFrame.LookVector * weaponConf.MaxRange

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	local hitPosition = result and result.Position or (rayOrigin + rayDirection)
	local hitInstance = result and result.Instance or nil

	-- Origen del rayo visual desde el cañón del arma 3D
	local muzzlePos = activeMuzzlePart and activeMuzzlePart.Position or (rootPart.Position + rootPart.CFrame.RightVector * 1.5 + Vector3.new(0, 0.5, 0))
	triggerMuzzleFlash(muzzlePos, playerColor)
	createTracerBeam(muzzlePos, hitPosition, playerColor)

	-- Retroceso visual leve en el grip
	if weaponGripMotor then
		local origC0 = weaponGripMotor.C0
		weaponGripMotor.C0 = origC0 * CFrame.new(0, 0, 0.15) * CFrame.Angles(math.rad(6), 0, 0)
		task.delay(0.04, function()
			if weaponGripMotor then
				weaponGripMotor.C0 = origC0
			end
		end)
	end

	-- Enviar evento al servidor
	fireRangedEvent:FireServer(rayOrigin, camera.CFrame.LookVector, hitInstance, weaponConf.Name)
end

-- --- ATAQUE MELEE (KATANA GLITCH) ---
local function performMeleeAttack(weaponConf: any)
	local now = os.clock()
	if now - lastFireTime < weaponConf.AttackRate or isAttackingMelee then
		return
	end
	lastFireTime = now
	isAttackingMelee = true

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	-- Animación de corte visual (Slash Arc)
	if weaponGripMotor then
		local origC0 = weaponGripMotor.C0
		local slashC0 = origC0 * CFrame.Angles(math.rad(80), math.rad(-90), math.rad(45))
		local slashTween = TweenService:Create(weaponGripMotor, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = slashC0 })
		slashTween:Play()

		task.delay(0.14, function()
			if weaponGripMotor then
				local resetTween = TweenService:Create(weaponGripMotor, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = origC0 })
				resetTween:Play()
			end
		end)
	end

	-- Impulso frontal
	rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + (rootPart.CFrame.LookVector * weaponConf.LungeSpeed * 0.4)

	-- Detección de impacto frontal
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { character }

	local hitCenter = rootPart.Position + (rootPart.CFrame.LookVector * (weaponConf.SlashRange / 2))
	local partsHit = workspace:GetPartBoundsInRadius(hitCenter, weaponConf.SlashRange / 2, overlapParams)

	local validTargets = {}
	for _, part in ipairs(partsHit) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and model ~= character and not table.find(validTargets, model) then
			table.insert(validTargets, model)
		end
	end

	meleeAttackEvent:FireServer(rootPart.Position, rootPart.CFrame.LookVector, validTargets, weaponConf.Name)

	task.delay(weaponConf.AttackRate, function()
		isAttackingMelee = false
	end)
end

-- --- GESTIÓN DE ENTRADAS DE COMBATE ---
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- DISPARAR / ATACAR (Click Izquierdo)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local weaponConf = getActiveWeaponConfig()
		if weaponConf.Type == "MeleePrimary" then
			performMeleeAttack(weaponConf)
		else
			fireRangedWeapon(weaponConf)
		end

	-- CAMBIAR DE ARMA (Teclas 1 y 2)
	elseif input.KeyCode == Enum.KeyCode.One then
		if activeSlot ~= 1 then
			activeSlot = 1
			equipVisualWeapon()
		end
	elseif input.KeyCode == Enum.KeyCode.Two then
		if activeSlot ~= 2 then
			activeSlot = 2
			equipVisualWeapon()
		end
	end
end)

-- --- ENFRIAMIENTO TÉRMICO CONTINUO ---
RunService.Heartbeat:Connect(function(deltaTime)
	local weaponConf = getActiveWeaponConfig()
	if not isOverheated and currentHeat > 0 and weaponConf.CoolingRate then
		currentHeat = math.clamp(currentHeat - (weaponConf.CoolingRate * deltaTime), 0.0, 1.0)
	end
end)

-- --- INICIALIZACIÓN DE EQUIPAMIENTO ---
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("HumanoidRootPart")
	task.wait(0.2)
	equipVisualWeapon()
end)

if player.Character then
	task.spawn(function()
		player.Character:WaitForChild("HumanoidRootPart")
		task.wait(0.2)
		equipVisualWeapon()
	end)
end
