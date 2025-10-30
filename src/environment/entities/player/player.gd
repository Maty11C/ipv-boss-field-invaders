class_name Player

extends CharacterBody2D

@onready var body_anim: AnimatedSprite2D = $Body
@onready var detection_area: Area2D = $DetectionArea
@onready var camera: Camera2D = $Camera2D
@onready var stamina_bar: ProgressBar = $ProgressBar
@onready var running_sfx: AudioStreamPlayer2D = $Running
@onready var breathing_sfx: AudioStreamPlayer2D = $Breathing

@export var max_stamina: float = 100.0
@export var stamina_recovery_rate: float = 20
@export var speed = 380 # (pixels/sec).
@export var clamp_offset: Vector2 = Vector2(20.0, 40.0)
@export var camera_zoom: float = 1.5  # Nivel de zoom de la cámara
@export var invasion_duration: int = 2 # Tiempo de duración en segundos

var input_vector: Vector2 = Vector2.ZERO
var is_invading: bool = false
var run_speed_scale: float = 1.0
var stamina: float = max_stamina

signal invasion_finished
signal near_soccer_player(soccer_player: Node2D)
signal left_soccer_player(soccer_player: Node2D)
signal caught_by_police

func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	setup_camera()

func _physics_process(_delta: float) -> void:
	_process_input(_delta)
	_process_animation()
	_process_audio()
	_stats_recovery(_delta)

func _stats_recovery(delta: float) -> void:
	if !Input.is_action_pressed("run"):
		stamina = clamp(stamina + stamina_recovery_rate * delta, 0, max_stamina)
		stamina_bar.value = stamina

func _process_input(delta: float) -> void:
	input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	
	var can_run: bool = stamina > 0.6
	if Input.is_action_pressed("run") and can_run:
		run_speed_scale = 1.6
		stamina -= 20.0 * delta
		stamina = max (stamina, 0)
		stamina_bar.value = stamina
	else:
		run_speed_scale = 1.0
	
	input_vector = input_vector.normalized()
	velocity = input_vector * speed * run_speed_scale
	
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

func _process_audio() -> void:
	if is_invading:
		return
		
	if input_vector != Vector2.ZERO:
		running_sfx.pitch_scale = 1.2 if Input.is_action_pressed("run") else 1.0
		if not running_sfx.playing:
			running_sfx.play()
	else:
		if running_sfx.playing:
			running_sfx.stop()
	
	if stamina_bar.value < max_stamina and !Input.is_action_pressed("run"):
		if not breathing_sfx.playing:
			breathing_sfx.play()
	else:
		if breathing_sfx.playing:
			breathing_sfx.stop()

func start_invasion(target_position: Vector2):
	is_invading = true
	set_physics_process(false)  # Deshabilitar input durante invasión
	
	if not running_sfx.playing:
		running_sfx.play()
	
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
	if running_sfx.playing:
		running_sfx.stop()
	invasion_finished.emit()


func _play_animation(animation: String) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("soccer_players"):
		near_soccer_player.emit(body)
	elif body is Police:
		caught_by_police.emit()

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("soccer_players"):
		left_soccer_player.emit(body)

#region Cámara

func setup_camera() -> void:
	if camera:
		camera.enabled = false  # Iniciar deshabilitada
		camera.zoom = Vector2(1.0, 1.0)  # Iniciar sin zoom
		camera.position_smoothing_enabled = false  # Sin suavizado inicial
		camera.position_smoothing_speed = 5.0
		
		# Configurar límites de la cámara para que no se salga del mundo
		var screen_size = get_viewport().get_visible_rect().size
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(screen_size.x)
		camera.limit_bottom = int(screen_size.y)

func enable_camera_smooth(duration: float = 2.0) -> void:
	if camera:
		camera.enabled = true
		camera.zoom = Vector2(1.0, 1.0) # Comenzar con zoom 1.0 (vista normal)
		
		# Transición suave al zoom objetivo
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_QUART)
		tween.tween_property(camera, "zoom", Vector2(camera_zoom, camera_zoom), duration)
		
		# Activar suavizado gradualmente
		await get_tree().create_timer(duration * 0.3).timeout

func disable_camera_smooth(duration: float = 1.5) -> void:
	if camera and camera.enabled:
		# Transición suave de vuelta al zoom normal
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_QUART)
		tween.tween_property(camera, "zoom", Vector2(1.0, 1.0), duration)
		
		# Desactivar suavizado gradualmente
		camera.position_smoothing_enabled = false
		
		await tween.finished
		camera.enabled = false

#endregion
