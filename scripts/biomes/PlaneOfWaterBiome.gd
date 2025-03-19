extends Node

func get_block_type(x: int, y: int, z: int, noise: FastNoiseLite) -> int:
	var height = 8  # Flat water level
	if y < height - 2: return 2  # STONE
	elif y < height: return 5  # WATER
	return 0  # AIR
