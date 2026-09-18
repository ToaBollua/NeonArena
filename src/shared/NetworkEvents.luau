--!strict
-- src/shared/NetworkEvents.luau
-- Gestor centralizado y seguro de RemoteEvents y RemoteFunctions para NeonArena

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NetworkEvents = {}

local EVENTS_FOLDER_NAME = "NeonArenaEvents"

local function getEventsFolder(): Folder
	local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
	local eventsFolder = sharedFolder:FindFirstChild(EVENTS_FOLDER_NAME) :: Folder?
	if not eventsFolder then
		if RunService:IsServer() then
			local newFolder = Instance.new("Folder")
			newFolder.Name = EVENTS_FOLDER_NAME
			newFolder.Parent = sharedFolder
			return newFolder
		else
			return sharedFolder:WaitForChild(EVENTS_FOLDER_NAME) :: Folder
		end
	end
	return eventsFolder
end

function NetworkEvents.getRemoteEvent(name: string): RemoteEvent
	local folder = getEventsFolder()
	local remote = folder:FindFirstChild(name) :: RemoteEvent?
	if not remote then
		if RunService:IsServer() then
			local newRemote = Instance.new("RemoteEvent")
			newRemote.Name = name
			newRemote.Parent = folder
			return newRemote
		else
			return folder:WaitForChild(name) :: RemoteEvent
		end
	end
	return remote
end

function NetworkEvents.getRemoteFunction(name: string): RemoteFunction
	local folder = getEventsFolder()
	local remote = folder:FindFirstChild(name) :: RemoteFunction?
	if not remote then
		if RunService:IsServer() then
			local newRemote = Instance.new("RemoteFunction")
			newRemote.Name = name
			newRemote.Parent = folder
			return newRemote
		else
			return folder:WaitForChild(name) :: RemoteFunction
		end
	end
	return remote
end

-- Lista de Eventos Estándar
NetworkEvents.SpawnPlatform = "SpawnPlatform"       -- Cliente -> Servidor (Posición, Color)
NetworkEvents.FireRangedWeapon = "FireRangedWeapon" -- Cliente -> Servidor (Origin, Direction, TargetPart)
NetworkEvents.MeleeAttack = "MeleeAttack"           -- Cliente -> Servidor (Origin, Direction, TargetsHit)
NetworkEvents.PlayerDamaged = "PlayerDamaged"       -- Servidor -> Cliente (Health, Shield)
NetworkEvents.WaveUpdate = "WaveUpdate"             -- Servidor -> Cliente (CurrentWave, DronesRemaining, State)
NetworkEvents.WeaponHeatUpdate = "WeaponHeatUpdate" -- Cliente -> Servidor/Local

return NetworkEvents
