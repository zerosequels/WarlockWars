extends Node

func get_block_type(x: int, y: int, z: int, noise: FastNoiseLite) -> int:
	if y < 15: return 2  # STONE with ceiling at y=15
	return 0  # AIR
