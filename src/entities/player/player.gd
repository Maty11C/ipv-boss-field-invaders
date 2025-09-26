class_name Player

extends CharacterBody2D

@onready var body_anim: AnimatedSprite2D = $Body

@export var speed = 400 # (pixels/sec).
@export var clamp_offset: Vector2 = Vector2(20.0, 40.0)

var input_vector: Vector2 = Vector2.ZERO
var is_invading: bool = false

signal invasion_finished

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
	# No procesar animaciones si está invadiendo
	if is_invading:
		return
		
	if input_vector == Vector2.ZERO:
		_play_animation("idle")
	else:
		if abs(input_vector.x) > abs(input_vector.y):
			body_anim.flip_h = input_vector.x < 0
			_play_animation("walk_side")
		elif input_vector.y > 0:
			_play_animation("walk_front")
		else:
			_play_animation("walk_back")

func start_invasion(target_position: Vector2):
	is_invading = true
	set_physics_process(false)  # Deshabilitar input durante invasión
	
	# Elegir un lateral aleatorio para la invasión
	var screen_size = get_viewport().get_visible_rect().size
	var invasion_sides = ["top", "bottom"]
	var chosen_side = invasion_sides[randi() % invasion_sides.size()]
	
	# Definir posición inicial y animación según el lateral elegido
	match chosen_side:
		"top":
			position = Vector2(target_position.x, -50)
			_play_animation("walk_front")  # Viniendo desde arriba, camina hacia adelante
		"bottom":
			position = Vector2(target_position.x, screen_size.y + 50)
			_play_animation("walk_back")   # Viniendo desde abajo, camina hacia atrás
	
	# Calcular duración basada en la distancia y velocidad
	var distance = position.distance_to(target_position)
	var invasion_duration = distance / speed
	
	# Tween para la animación
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", target_position, invasion_duration)
	await tween.finished
	
	finish_invasion()

func finish_invasion():
	is_invading = false
	_play_animation("idle")
	set_physics_process(true)
	invasion_finished.emit()

func _play_animation(animation: String) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)
