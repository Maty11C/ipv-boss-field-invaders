extends CharacterBody2D

@onready var body_anim: AnimatedSprite2D = $Body

@export var speed = 400 # (pixels/sec).
@export var clamp_offset: Vector2 = Vector2(20.0, 40.0)

var input_vector: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	_process_input()
	_process_animation()

func _process_input() -> void:
	input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1

	input_vector = input_vector.normalized()
	
	velocity = input_vector * speed
	
	var screenSize = get_viewport()
	position.x = clamp(
		position.x,
		clamp_offset.x,
		screenSize.size.x - clamp_offset.x
	)
	position.y = clamp(
		position.y,
		clamp_offset.y,
		screenSize.size.y
	)
	
	move_and_slide()

func _process_animation() -> void:
	if input_vector == Vector2.ZERO:
		body_anim.play("idle")
	else:
		if abs(input_vector.x) > abs(input_vector.y):
			body_anim.flip_h = input_vector.x < 0
			body_anim.play("walk_side")
		elif input_vector.y > 0:
			body_anim.play("walk_front")
		else:
			body_anim.play("walk_back")
