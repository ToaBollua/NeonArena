--!strict
-- src/server/CombatServer.server.luau
-- Servidor de Combate: Validación de Daño Autoritario, Escudos y Salud del Jugador

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local NetworkEvents = require(Shared:WaitForChild("NetworkEvents") :: ModuleScript)

local fireRangedEvent = NetworkEvents.getRemoteEvent(NetworkEvents.FireRangedWeapon)
local meleeAttackEvent = NetworkEvents.getRemoteEvent(NetworkEvents.MeleeAttack)
local playerDamagedEvent = NetworkEvents.getRemoteEvent(NetworkEvents.PlayerDamaged)

-- Estado de vitalidad por jugador: [UserId] -> { Health, Shield, LastDamageTime }
local playerVitals: { [number]: { Health: number, Shield: number, LastDamageTime: number } } = {}

local function initializePlayerVitals(player: Player)
	playerVitals[player.UserId] = {
		Health = Config.PLAYER_VITALITY.MaxHealth,
		Shield = Config.PLAYER_VITALITY.MaxShield,
		LastDamageTime = 0.0,
	}
	playerDamagedEvent:FireClient(player, Config.PLAYER_VITALITY.MaxHealth, Config.PLAYER_VITALITY.MaxShield)
end

local function applyDamageToPlayer(player: Player, damage: number)
	local vitals = playerVitals[player.UserId]
	if not vitals then return end

	vitals.LastDamageTime = os.clock()

	if vitals.Shield > 0 then
		if vitals.Shield >= damage then
			vitals.Shield -= damage
			damage = 0
		else
			damage -= vitals.Shield
			vitals.Shield = 0
		end
	end

	if damage > 0 then
		vitals.Health = math.max(0, vitals.Health - damage)
	end

	playerDamagedEvent:FireClient(player, vitals.Health, vitals.Shield)

	-- Si la salud llega a 0, ejecutar muerte
	if vitals.Health <= 0 then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
	end
end

-- Exponer función global para que DroneAI pueda dañar jugadores
_G.ApplyDamageToPlayer = applyDamageToPlayer

-- --- RECEPCIÓN DE DISPAROS A RANGO ---
fireRangedEvent.OnServerEvent:Connect(function(player: Player, origin: Vector3, direction: Vector3, hitInstance: Instance?, weaponName: string)
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	-- Validar origen razonable
	if (rootPart.Position - origin).Magnitude > 30 then
		return
	end

	local weaponConf = Config.WEAPONS[weaponName] or Config.WEAPONS.Aguijon
	local damage = weaponConf.Damage

	if hitInstance then
		local targetModel = hitInstance:FindFirstAncestorOfClass("Model")
		if targetModel and targetModel ~= character then
			local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
			if targetHumanoid and targetHumanoid.Health > 0 then
				targetHumanoid:TakeDamage(damage)
			end
		end
	end
end)

-- --- RECEPCIÓN DE ATAQUES MELEE ---
meleeAttackEvent.OnServerEvent:Connect(function(player: Player, origin: Vector3, direction: Vector3, targetsHit: { Model }, weaponName: string)
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	local weaponConf = Config.WEAPONS.NeonKatana
	local damage = weaponConf.Damage

	for _, targetModel in ipairs(targetsHit) do
		if targetModel and targetModel ~= character and targetModel.Parent then
			local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
			if targetHumanoid and targetHumanoid.Health > 0 then
				-- Validar distancia de melee
				local targetRoot = targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart
				if targetRoot and (rootPart.Position - targetRoot.Position).Magnitude <= weaponConf.SlashRange + 8 then
					targetHumanoid:TakeDamage(damage)
				end
			end
		end
	end
end)

-- --- BUCLE DE REGENERACIÓN DE ESCUDO ---
RunService.Heartbeat:Connect(function(deltaTime)
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local vitals = playerVitals[player.UserId]
		if vitals and vitals.Health > 0 and vitals.Shield < Config.PLAYER_VITALITY.MaxShield then
			if now - vitals.LastDamageTime >= Config.PLAYER_VITALITY.ShieldRegenDelay then
				vitals.Shield = math.min(Config.PLAYER_VITALITY.MaxShield, vitals.Shield + (Config.PLAYER_VITALITY.ShieldRegenRate * deltaTime))
				playerDamagedEvent:FireClient(player, vitals.Health, vitals.Shield)
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		initializePlayerVitals(player)
	end)
	if player.Character then
		initializePlayerVitals(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	playerVitals[player.UserId] = nil
end)
