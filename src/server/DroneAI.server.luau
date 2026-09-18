--!strict
-- src/server/DroneAI.server.luau
-- Motor de IA de Drones Enemigos: Persecución Autónoma, Ataques a Distancia y Explosión por Contacto

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DroneAI = {}

local dronesFolder = Instance.new("Folder")
dronesFolder.Name = "ActiveDrones"
dronesFolder.Parent = workspace

local function findNearestPlayer(dronePos: Vector3): (Player?, number)
	local nearestPlayer: Player? = nil
	local shortestDist = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if humanoid and humanoid.Health > 0 and root then
				local dist = (dronePos - root.Position).Magnitude
				if dist < shortestDist then
					shortestDist = dist
					nearestPlayer = player
				end
			end
		end
	end
	return nearestPlayer, shortestDist
end

function DroneAI.spawnDrone(spawnPosition: Vector3, health: number, speed: number, damage: number): Model
	local drone = Instance.new("Model")
	drone.Name = "CyberDrone"

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(3, 2, 3)
	rootPart.Position = spawnPosition
	rootPart.Material = Enum.Material.Neon
	rootPart.Color = Color3.fromRGB(255, 0, 85) -- Magenta agresivo
	rootPart.CanCollide = true
	rootPart.Parent = drone

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = health
	humanoid.Health = health
	humanoid.WalkSpeed = speed
	humanoid.Parent = drone

	drone.PrimaryPart = rootPart
	drone.Parent = dronesFolder

	local lastAttackTime = 0.0

	-- Bucle de IA en hilo independiente
	task.spawn(function()
		while drone and drone.Parent and humanoid.Health > 0 do
			task.wait(0.1)
			local targetPlayer, distance = findNearestPlayer(rootPart.Position)

			if targetPlayer and targetPlayer.Character then
				local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if targetRoot then
					-- Mover hacia el jugador
					humanoid:MoveTo(targetRoot.Position)

					-- Ataque de proximidad (Explosión / impacto si está a menos de 7 studs)
					if distance <= 7.0 then
						if _G.ApplyDamageToPlayer then
							_G.ApplyDamageToPlayer(targetPlayer, damage * 1.5)
						end
						humanoid.Health = 0 -- El dron se autodestruye al detonar
						break
					end

					-- Disparo a distancia si está entre 10 y 45 studs
					local now = os.clock()
					if distance <= 45.0 and now - lastAttackTime >= 1.8 then
						lastAttackTime = now
						if _G.ApplyDamageToPlayer then
							_G.ApplyDamageToPlayer(targetPlayer, damage)
						end
					end
				end
			end
		end

		-- Efecto de Desvanecimiento al Morir
		if rootPart and rootPart.Parent then
			local fadeTween = TweenService:Create(rootPart, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1,
				Size = Vector3.new(0.2, 0.2, 0.2)
			})
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				if drone and drone.Parent then
					drone:Destroy()
				end
			end)
		end
	end)

	return drone
end

return DroneAI
