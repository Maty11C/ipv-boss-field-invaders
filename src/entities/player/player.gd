extends CharacterBody2D

@onready var body_animation: AnimationPlayer = $BodyAnimation

@export var speed = 400 # (pixels/sec).

func _ready() -> void:
	initialize()

func initialize() -> void:
	body_animation.play("idle")

func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO

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
	move_and_slide()
