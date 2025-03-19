extends Node3D

@onready var environment = $Environment
@onready var voxel_world = $VoxelWorld
@export var biome_type: BiomeType = BiomeType.PLAINS  # Exported enum variable

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

func _ready():
	environment.biome_type = biome_type
	environment.setup_sky()
	voxel_world.create_voxel_world_by_biome(biome_type)
