extends Node3D

# Biome enum
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

# Block types
enum BlockType {
	AIR,
	DIRT,
	STONE,
	SAND,
	SNOW,
	WATER,
	GRASS
}

@export var biome_type: BiomeType = BiomeType.PLAINS
@export var chunk_size: int = 16
@export var world_size: Vector3i = Vector3i(2, 1, 2)  # 2x1x2 chunks

var noise = FastNoiseLite.new()
var chunks = {}
var materials = {}
var biome_script

func create_voxel_world_by_biome(target_biome:BiomeType):
	biome_type = target_biome
	# Setup noise
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.fractal_octaves = 4
	noise.frequency = 0.05
	
	# Load materials
	materials[BlockType.DIRT] = preload("res://data/dirt.tres")
	materials[BlockType.STONE] = preload("res://data/stone.tres")
	materials[BlockType.SAND] = preload("res://data/sand.tres")
	materials[BlockType.SNOW] = preload("res://data/snow.tres")
	materials[BlockType.WATER] = preload("res://data/water.tres")
	materials[BlockType.GRASS] = preload("res://data/grass.tres")
	
	# Load biome script
	match biome_type:
		BiomeType.PLAINS: biome_script = preload("res://scripts/biomes/PlainsBiome.gd").new()
		BiomeType.DESERT: biome_script = preload("res://scripts/biomes/DesertBiome.gd").new()
		BiomeType.FOREST: biome_script = preload("res://scripts/biomes/ForestBiome.gd").new()
		BiomeType.PLANE_OF_THUNDER: biome_script = preload("res://scripts/biomes/PlaneOfThunderBiome.gd").new()
		BiomeType.PLANE_OF_FIRE: biome_script = preload("res://scripts/biomes/PlaneOfFireBiome.gd").new()
		BiomeType.PLANE_OF_WATER: biome_script = preload("res://scripts/biomes/PlaneOfWaterBiome.gd").new()
		BiomeType.PLANE_OF_EARTH: biome_script = preload("res://scripts/biomes/PlaneOfEarthBiome.gd").new()
		BiomeType.WINTER_TUNDRA: biome_script = preload("res://scripts/biomes/WinterTundraBiome.gd").new()
		BiomeType.NIGHT: biome_script = preload("res://scripts/biomes/NightBiome.gd").new()
		BiomeType.DUNGEON_INTERIOR: biome_script = preload("res://scripts/biomes/DungeonInteriorBiome.gd").new()
	
	generate_world()

func generate_world():
	for x in range(world_size.x):
		for y in range(world_size.y):
			for z in range(world_size.z):
				generate_chunk(Vector3i(x, y, z))

func generate_chunk(chunk_pos: Vector3i):
	var chunk = MeshInstance3D.new()
	chunk.name = "Chunk_%d_%d_%d" % [chunk_pos.x, chunk_pos.y, chunk_pos.z]
	chunk.position = Vector3(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size, chunk_pos.z * chunk_size)
	add_child(chunk)
	var voxel_data = generate_voxel_data(chunk_pos)
	build_chunk_mesh(chunk, voxel_data)
	chunks[chunk_pos] = chunk
	
func generate_voxel_data(chunk_pos: Vector3i) -> Dictionary:
	var voxel_data = {}
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				var world_x = chunk_pos.x * chunk_size + x
				var world_y = chunk_pos.y * chunk_size + y
				var world_z = chunk_pos.z * chunk_size + z
				voxel_data[Vector3i(x, y, z)] = biome_script.get_block_type(world_x, world_y, world_z, noise)
	return voxel_data

func build_chunk_mesh(chunk: MeshInstance3D, voxel_data: Dictionary):
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var vertices = []
	var normals = []
	var indices = []
	var block_types = []
	
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				var pos = Vector3i(x, y, z)
				var block = voxel_data[pos]
				if block != BlockType.AIR:
					add_cube_mesh(chunk, pos, block, vertices, normals, indices, voxel_data, block_types)
					
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	chunk.mesh = mesh
	chunk.create_trimesh_collision()

func add_cube_mesh(chunk: MeshInstance3D, pos: Vector3i, block: int, vertices: Array, normals: Array, indices: Array, voxel_data: Dictionary, block_types: Array):
	var cube_vertices = [
		Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0),  # Front
		Vector3(1, 0, 1), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1)   # Back
		]
	var cube_normals = [
		Vector3(0, 0, -1), Vector3(0, 0, -1), Vector3(0, 0, -1), Vector3(0, 0, -1),  # Front
		Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1)      # Back
		]
	var cube_faces = [
		[0, 1, 2, 0, 2, 3],  # Front
		[4, 5, 6, 4, 6, 7],  # Back
		[5, 0, 3, 5, 3, 6],  # Left
		[1, 4, 7, 1, 7, 2],  # Right
		[3, 2, 7, 3, 7, 6],  # Top
		[0, 5, 4, 0, 4, 1]   # Bottom
	]
	
	var base_index = vertices.size()
	for i in range(8):
		vertices.append(cube_vertices[i] + Vector3(pos))
		normals.append(cube_normals[i])
	
	for face in cube_faces:
		var neighbor = pos + get_face_normal(face[0], face[1], face[2])
		if not voxel_data.get(neighbor, BlockType.AIR) == BlockType.AIR:
			continue
		for idx in face:
			indices.append(base_index + idx)
			# Apply material (fixed scope issue)
	block_types.append(block)

func get_face_normal(v0_idx: int, v1_idx: int, v2_idx: int) -> Vector3i:
	match [v0_idx, v1_idx, v2_idx]:
		[0, 1, 2]: return Vector3i(0, 0, -1)  # Front
		[4, 5, 6]: return Vector3i(0, 0, 1)   # Back
		[5, 0, 3]: return Vector3i(-1, 0, 0)  # Left
		[1, 4, 7]: return Vector3i(1, 0, 0)   # Right
		[3, 2, 7]: return Vector3i(0, 1, 0)   # Top
		[0, 5, 4]: return Vector3i(0, -1, 0)  # Bottom
	return Vector3i.ZERO
