--!strict
-- src/server/WaveSpawner.server.luau
-- Motor de Control de Oleadas de Combate (Rondas 1 a 4 del MVP)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local NetworkEvents = require(Shared:WaitForChild("NetworkEvents") :: ModuleScript)
local DroneAI = require(script.Parent:WaitForChild("DroneAI") :: ModuleScript)

local waveUpdateEvent = NetworkEvents.getRemoteEvent(NetworkEvents.WaveUpdate)

local currentWave = 1
local maxMVPWaves = 4
local activeDronesCount = 0

local SPAWN_RADIUS = 75
local ARENA_CENTER = Vector3.new(0, 5, 0)

local function getSpawnLocation(): Vector3
	local angle = math.random() * math.pi * 2
	local offset = Vector3.new(math.cos(angle) * SPAWN_RADIUS, 5, math.sin(angle) * SPAWN_RADIUS)
	return ARENA_CENTER + offset
end

local function startWaveLoop()
	task.wait(4.0) -- Espera inicial para carga de clientes

	while true do
		local waveData = Config.WAVES[currentWave]
		if not waveData then
			currentWave = 1
			waveData = Config.WAVES[currentWave]
		end

		local dronesToSpawn = waveData.DroneCount
		activeDronesCount = dronesToSpawn
		waveUpdateEvent:FireAllClients(currentWave, activeDronesCount)

		print(string.format("⚡ [WAVE SPINNER] Iniciando Oleada %d con %d Drones.", currentWave, dronesToSpawn))

		for i = 1, dronesToSpawn do
			local spawnPos = getSpawnLocation()
			local drone = DroneAI.spawnDrone(spawnPos, waveData.DroneHealth, waveData.DroneSpeed, waveData.DroneDamage)
			
			local humanoid = drone:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Died:Connect(function()
					activeDronesCount = math.max(0, activeDronesCount - 1)
					waveUpdateEvent:FireAllClients(currentWave, activeDronesCount)
				end)
			end

			task.wait(waveData.SpawnInterval)
		end

		-- Esperar a que todos los drones sean eliminados
		while activeDronesCount > 0 do
			task.wait(0.5)
		end

		print(string.format("✅ [WAVE CLEAR] Oleada %d completada.", currentWave))

		if currentWave < maxMVPWaves then
			currentWave += 1
			task.wait(5.0) -- Intermedio de 5s entre oleadas
		else
			print("🏆 [MVP COMPLETADO] Has sobrevivido a las 4 rondas de NeonArena. Reiniciando ciclo de prueba.")
			task.wait(8.0)
			currentWave = 1
		end
	end
end

task.spawn(startWaveLoop)
