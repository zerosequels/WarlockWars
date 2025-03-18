extends CharacterBody3D

@onready var spring_arm = $SpringArm
@onready var camera = $SpringArm/Camera3D
var speed = 6.0
var mouse_sensitivity = 0.002

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		spring_arm.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x - event.relative.y * mouse_sensitivity, -1.2, 0.5)

func _physics_process(delta):
	var input_dir = Vector3(
		Input.get_axis("ui_left", "ui_right"),
		0,
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	if input_dir:
		input_dir = input_dir.rotated(Vector3.UP, spring_arm.rotation.y)
	velocity = input_dir * speed
	move_and_slide()
