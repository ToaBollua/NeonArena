--!strict
-- src/shared/Config.luau
-- Configuración maestra de balance, movilidad, armas y colores de NeonArena

local Config = {}

-- --- PALETA DE COLORES NEÓN (RESONANCIA H0P3) ---
Config.COLORS = {
	Default = Color3.fromRGB(0, 255, 102),     -- Neon Green (#00FF66)
	Cyan = Color3.fromRGB(0, 229, 255),        -- Neon Cyan (#00E5FF)
	Magenta = Color3.fromRGB(255, 0, 85),      -- Neon Magenta (#FF0055)
	Amber = Color3.fromRGB(255, 179, 0),       -- Neon Amber (#FFB300)
	Purple = Color3.fromRGB(157, 0, 255),      -- Neon Purple (#9D00FF)
}

-- --- MECÁNICAS DE MOVIMIENTO FRENETICO ---
Config.MOVEMENT = {
	WalkSpeed = 24,
	SprintSpeed = 32,
	JumpPower = 52,
	MaxAirJumps = 1,              -- Permite Doble Salto (1 salto extra en el aire)
	
	-- Slide
	SlideSpeed = 46,
	SlideDuration = 0.55,
	SlideCooldown = 0.8,
	
	-- Dash
	DashSpeed = 90,
	DashDuration = 0.16,
	DashCooldown = 0.9,
	
	-- Wall Jump / Parkour
	WallJumpPower = 48,
	WallJumpPush = 42,
	WallRaycastDistance = 2.4,
}

-- --- PLATAFORMAS DE LUZ SÓLIDA ---
Config.PLATFORMS = {
	MaxActivePerPlayer = 3,
	Lifetime = 3.5,               -- Duración en segundos antes de desvanecerse
	Cooldown = 0.5,
	Size = Vector3.new(9, 0.8, 9),
	Transparency = 0.35,
	Material = Enum.Material.Neon,
}

-- --- SISTEMA DE ARMAS Y CLASES ---
Config.WEAPONS = {
	Aguijon = {
		Name = "Aguijón",
		Type = "RangedPrimary",
		Damage = 28,
		FireRate = 0.12,          -- Tiempo entre disparos
		MaxRange = 400,
		HeatPerShot = 0.08,
		CoolingRate = 0.35,       -- Calor disipado por segundo
		OverheatCooldown = 2.0,   -- Bloqueo térmico si llega a 1.0
	},
	NeonKatana = {
		Name = "Katana Glitch",
		Type = "MeleePrimary",
		Damage = 65,
		AttackRate = 0.38,
		SlashRange = 11,
		LungeSpeed = 50,          -- Pequeño dash hacia adelante al atacar
	},
	PulsePistol = {
		Name = "Pistola de Pulso",
		Type = "Secondary",
		Damage = 18,
		FireRate = 0.20,
		MaxRange = 300,
		HeatPerShot = 0.04,
		CoolingRate = 0.50,
		OverheatCooldown = 1.2,
	}
}

-- --- SALUD Y ESCUDO ---
Config.PLAYER_VITALITY = {
	MaxHealth = 100,
	MaxShield = 100,
	ShieldRegenDelay = 4.0,       -- Segundos sin recibir daño para iniciar recarga
	ShieldRegenRate = 25,         -- Escudo recuperado por segundo
}

-- --- CONFIGURACIÓN DE CÁMARA TERCERA PERSONA (OTS) ---
Config.CAMERA = {
	Distance = 7.5,
	HeightOffset = 1.2,
	ShoulderOffset = 1.8,
	MouseSensitivity = 0.0028,
	PitchMin = math.rad(-75),
	PitchMax = math.rad(75),
	DefaultFOV = 70,
	DashFOV = 82,
}

-- --- CONFIGURACIÓN DE OLEADAS (MVP: 4 RONDAS) ---
Config.WAVES = {
	[1] = { DroneCount = 6, SpawnInterval = 2.5, DroneHealth = 50, DroneSpeed = 16, DroneDamage = 15 },
	[2] = { DroneCount = 10, SpawnInterval = 2.0, DroneHealth = 70, DroneSpeed = 18, DroneDamage = 20 },
	[3] = { DroneCount = 16, SpawnInterval = 1.6, DroneHealth = 90, DroneSpeed = 20, DroneDamage = 25 },
	[4] = { DroneCount = 24, SpawnInterval = 1.2, DroneHealth = 120, DroneSpeed = 22, DroneDamage = 30 },
}

return Config
