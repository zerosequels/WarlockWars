extends Node3D  # Assuming "World" is a Node3D

# Enum for biome types
enum BiomeType {
	PLAINS,
	DESERT,
	FOREST,
	PLANE_OF_THUNDER,
	PLANE_OF_FIRE,
	PLANE_OF_WATER,
	PLANE_OF_EARTH,
	WINTER_TUNDRA,
	NIGHT,
	DUNGEON_INTERIOR
}

@export var biome_type: BiomeType = BiomeType.PLAINS  # Exported enum variable
@onready var world_environment = $WorldEnvironment  # Adjust path if needed
@onready var directional_light = $DirectionalLight3D  # Adjust path if needed


func setup_sky():
	# Create and configure Environment
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	
	# Create and configure Sky
	var sky = Sky.new()
	var procedural_sky = ProceduralSkyMaterial.new()
	
	# Configure based on biome_type
	match biome_type:
		BiomeType.PLAINS:
			procedural_sky.sky_energy_multiplier = 1.0
			procedural_sky.sky_top_color = Color("#87CEEB")  # Light blue
			procedural_sky.sky_horizon_color = Color("#B0E0E6")  # Pale blue-green
			procedural_sky.ground_bottom_color = Color("#8B4513")  # Brown
			procedural_sky.ground_horizon_color = Color("#D2B48C")  # Tan
			procedural_sky.sun_angle_max = 15.0
			procedural_sky.sun_curve = 0.1
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.02
			env.volumetric_fog_albedo = Color("#D3D8E0")
			env.volumetric_fog_emission = Color("#000000")
			env.volumetric_fog_length = 50.0
			env.volumetric_fog_detail_spread = 2.0
		
		BiomeType.DESERT:
			procedural_sky.sky_energy_multiplier = 1.2
			procedural_sky.sky_top_color = Color("#FFD700")  # Golden sky
			procedural_sky.sky_horizon_color = Color("#FFA500")  # Orange horizon
			procedural_sky.ground_bottom_color = Color("#EDC9AF")  # Sandy ground
			procedural_sky.ground_horizon_color = Color("#F4A460")  # Sandy tan
			procedural_sky.sun_angle_max = 20.0
			procedural_sky.sun_curve = 0.05
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.01
			env.volumetric_fog_albedo = Color("#FFE4B5")
			env.volumetric_fog_emission = Color("#000000")
			env.volumetric_fog_length = 100.0
			env.volumetric_fog_detail_spread = 1.5
		
		BiomeType.FOREST:
			procedural_sky.sky_energy_multiplier = 0.8
			procedural_sky.sky_top_color = Color("#4682B4")  # Steel blue
			procedural_sky.sky_horizon_color = Color("#6B8E23")  # Olive green
			procedural_sky.ground_bottom_color = Color("#2F4F4F")  # Dark slate
			procedural_sky.ground_horizon_color = Color("#556B2F")  # Dark olive
			procedural_sky.sun_angle_max = 10.0
			procedural_sky.sun_curve = 0.15
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.03
			env.volumetric_fog_albedo = Color("#9ACD32")
			env.volumetric_fog_emission = Color("#000000")
			env.volumetric_fog_length = 30.0
			env.volumetric_fog_detail_spread = 2.5
		
		BiomeType.PLANE_OF_THUNDER:
			procedural_sky.sky_energy_multiplier = 1.1
			procedural_sky.sky_top_color = Color("#800080")  # Purple
			procedural_sky.sky_horizon_color = Color("#4B0082")  # Indigo
			procedural_sky.ground_bottom_color = Color("#2E0854")  # Dark purple
			procedural_sky.ground_horizon_color = Color("#483D8B")  # Slate blue
			procedural_sky.sun_angle_max = 15.0
			procedural_sky.sun_curve = 0.1
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.025
			env.volumetric_fog_albedo = Color("#9370DB")
			env.volumetric_fog_emission = Color("#000000")
			env.volumetric_fog_length = 40.0
			env.volumetric_fog_detail_spread = 2.0
		
		BiomeType.PLANE_OF_FIRE:
			procedural_sky.sky_energy_multiplier = 1.5
			procedural_sky.sky_top_color = Color("#FF0000")  # Bright red
			procedural_sky.sky_horizon_color = Color("#FF4500")  # Orange-red
			procedural_sky.ground_bottom_color = Color("#8B0000")  # Dark red
			procedural_sky.ground_horizon_color = Color("#FF6347")  # Tomato
			procedural_sky.sun_angle_max = 20.0
			procedural_sky.sun_curve = 0.05
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.015
			env.volumetric_fog_albedo = Color("#FF8C00")
			env.volumetric_fog_emission = Color("#000000")
			env.volumetric_fog_length = 60.0
			env.volumetric_fog_detail_spread = 1.8
		
		BiomeType.PLANE_OF_WATER:
			procedural_sky.sky_energy_multiplier = 0.7
			procedural_sky.sky_top_color = Color("#0000FF")  # Blue
			procedural_sky.sky_horizon_color = Color("#1E90FF")  # Dodger blue
			procedural_sky.ground_bottom_color = Color("#00008B")  # Dark blue
			procedural_sky.ground_horizon_color = Color("#4169E1")  # Royal blue
			procedural_sky.sun_angle_max = 10.0
			procedural_sky.sun_curve = 0.15
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.04
			env.volumetric_fog_albedo = Color("#00CED1")
			env.volumetric_fog_emission = Color("#000000")
			env.volumetric_fog_length = 25.0
			env.volumetric_fog_detail_spread = 2.5
		
		BiomeType.PLANE_OF_EARTH:
			procedural_sky.sky_energy_multiplier = 0.6
			procedural_sky.sky_top_color = Color("#696969")  # Dim gray
			procedural_sky.sky_horizon_color = Color("#808080")  # Gray
			procedural_sky.ground_bottom_color = Color("#2F2F2F")  # Dark stone
			procedural_sky.ground_horizon_color = Color("#4A4A4A")  # Darker gray
			procedural_sky.sun_angle_max = 8.0
			procedural_sky.sun_curve = 0.2
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.035
			env.volumetric_fog_albedo = Color("#A9A9A9")
			env.volumetric_fog_emission = Color("#000000")
			env.volumetric_fog_length = 35.0
			env.volumetric_fog_detail_spread = 2.0
		
		BiomeType.WINTER_TUNDRA:
			procedural_sky.sky_energy_multiplier = 0.9
			procedural_sky.sky_top_color = Color("#ADD8E6")  # Light blue
			procedural_sky.sky_horizon_color = Color("#B0C4DE")  # Light steel blue
			procedural_sky.ground_bottom_color = Color("#F0F8FF")  # Alice blue (snow)
			procedural_sky.ground_horizon_color = Color("#D3D3D3")  # Light gray
			procedural_sky.sun_angle_max = 12.0
			procedural_sky.sun_curve = 0.12
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.03
			env.volumetric_fog_albedo = Color("#E6E6FA")
			env.volumetric_fog_emission = Color("#000000")
			env.volumetric_fog_length = 40.0
			env.volumetric_fog_detail_spread = 2.2
		
		BiomeType.NIGHT:
			procedural_sky.sky_energy_multiplier = 0.3  # Very dim
			procedural_sky.sky_top_color = Color("#191970")  # Midnight blue
			procedural_sky.sky_horizon_color = Color("#000080")  # Navy
			procedural_sky.ground_bottom_color = Color("#000033")  # Near black
			procedural_sky.ground_horizon_color = Color("#2F0047")  # Dark purple
			procedural_sky.sun_angle_max = 0.0  # No sun, starry sky
			procedural_sky.sun_curve = 0.0  # No sun effect
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.02  # Light mist
			env.volumetric_fog_albedo = Color("#4682B4")  # Steel blue fog
			env.volumetric_fog_emission = Color("#000000")
			env.volumetric_fog_length = 50.0
			env.volumetric_fog_detail_spread = 2.0
		
		BiomeType.DUNGEON_INTERIOR:
			procedural_sky.sky_energy_multiplier = 0.1  # Barely visible
			procedural_sky.sky_top_color = Color("#1C2526")  # Dark slate
			procedural_sky.sky_horizon_color = Color("#2F3536")  # Slightly lighter slate
			procedural_sky.ground_bottom_color = Color("#0F1415")  # Near black stone
			procedural_sky.ground_horizon_color = Color("#252A2B")  # Dark gray
			procedural_sky.sun_angle_max = 0.0  # No sun
			procedural_sky.sun_curve = 0.0  # No sun effect
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.05  # Thick, oppressive fog
			env.volumetric_fog_albedo = Color("#696969")  # Dim gray fog
			env.volumetric_fog_emission = Color("#000000")
			env.volumetric_fog_length = 20.0  # Short range for enclosed feel
			env.volumetric_fog_detail_spread = 2.0
	
	# Assign material to sky, sky to environment
	sky.sky_material = procedural_sky
	env.sky = sky
	
	# Apply to WorldEnvironment
	world_environment.environment = env
	
	# Configure DirectionalLight3D with shadows
	if directional_light:
		directional_light.light_energy = 1.5
		directional_light.rotation_degrees = Vector3(-45, 45, 0)
		directional_light.shadow_enabled = true
		directional_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		directional_light.directional_shadow_max_distance = 100.0
		directional_light.directional_shadow_fade_start = 0.8
		directional_light.shadow_bias = 0.1
