extends CharacterBody3D

var speed = 2.5
var direction = Vector3.ZERO
var timer = 0.0

func _ready():
	randomize()
	pick_new_direction()

func _physics_process(delta):
	timer -= delta
	if timer <= 0:
		pick_new_direction()
	velocity = direction * speed
	move_and_slide()

func pick_new_direction():
	direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	timer = randf_range(1.5, 4.0)
