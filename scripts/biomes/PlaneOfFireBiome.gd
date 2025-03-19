extends Node

func get_block_type(x: int, y: int, z: int, noise: FastNoiseLite) -> int:
	var height = noise.get_noise_2d(x, z) * 8 + 8  # Lower, rugged
	height = clamp(height, 0, 15)
	if y < height - 1: return 2  # STONE
	elif y == height - 1: return 1  # DIRT
	return 0  # AIR
