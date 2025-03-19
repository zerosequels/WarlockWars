extends Node

func get_block_type(x: int, y: int, z: int, noise: FastNoiseLite) -> int:
	var height = noise.get_noise_2d(x, z) * 10 + 10  # 0-20
	height = clamp(height, 0, 15)  # Max 15 for chunk_size=16
	if y < height - 1: return 1  # DIRT
	elif y == height - 1: return 6  # GRASS
	return 0  # AIR
