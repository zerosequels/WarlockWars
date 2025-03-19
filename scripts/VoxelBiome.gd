extends Node
class_name VoxelBiome
	

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

var noise = FastNoiseLite.new()
var materials = {}
var chunk_size: int = 16

func _init():
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.fractal_octaves = 4
	noise.frequency = 0.05
	
	# Load materials (adjust paths)
	materials[BlockType.DIRT] = preload("res://data/dirt.tres")
	materials[BlockType.STONE] = preload("res://data/stone.tres")
	materials[BlockType.SAND] = preload("res://data/sand.tres")
	materials[BlockType.SNOW] = preload("res://data/snow.tres")
	materials[BlockType.WATER] = preload("res://data/water.tres")
	materials[BlockType.GRASS] = preload("res://data/grass.tres")

# Virtual method for biome-specific generation
func generate_voxel_data(chunk_pos: Vector3i) -> Dictionary:
	var voxel_data = {}
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				var world_x = chunk_pos.x * chunk_size + x
				var world_y = chunk_pos.y * chunk_size + y
				var world_z = chunk_pos.z * chunk_size + z
				voxel_data[Vector3i(x, y, z)] = get_block_type(world_x, world_y, world_z)
	return voxel_data

# Virtual method to override
func get_block_type(x: int, y: int, z: int) -> int:
	return BlockType.AIR  # Default, overridden by biomes

func build_chunk_mesh(chunk: MeshInstance3D, voxel_data: Dictionary):
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var vertices = []
	var normals = []
	var indices = []
	
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				var pos = Vector3i(x, y, z)
				var block = voxel_data[pos]
				if block != BlockType.AIR:
					add_cube_mesh(pos, block, vertices, normals, indices, voxel_data)
	
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	chunk.mesh = mesh
	chunk.create_trimesh_collision()

func add_cube_mesh(pos: Vector3i, block: int, vertices: Array, normals: Array, indices: Array, voxel_data: Dictionary):
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
	
	# Apply material
	var mesh = chunk.mesh if chunk.mesh else ArrayMesh.new()
	mesh.surface_set_material(mesh.surface_get_array_len() - 1, materials[block])

func get_face_normal(v0_idx: int, v1_idx: int, v2_idx: int) -> Vector3i:
	match [v0_idx, v1_idx, v2_idx]:
		[0, 1, 2]: return Vector3i(0, 0, -1)  # Front
		[4, 5, 6]: return Vector3i(0, 0, 1)   # Back
		[5, 0, 3]: return Vector3i(-1, 0, 0)  # Left
		[1, 4, 7]: return Vector3i(1, 0, 0)   # Right
		[3, 2, 7]: return Vector3i(0, 1, 0)   # Top
		[0, 5, 4]: return Vector3i(0, -1, 0)  # Bottom
	return Vector3i.ZERO
