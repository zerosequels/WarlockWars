extends Node

func get_block_type(x: int, y: int, z: int, noise: FastNoiseLite) -> int:
	var height = noise.get_noise_2d(x, z) * 5 + 12  # Taller, jagged
	height = clamp(height, 0, 15)
	if y < height: return 2  # STONE
	return 0  # AIR
