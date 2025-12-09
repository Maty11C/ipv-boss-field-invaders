class_name Player

extends CharacterBody2D

@onready var body_anim: AnimatedSprite2D = $Body
@onready var detection_area: Area2D = $DetectionArea
@onready var camera: Camera2D = $Camera2D
@onready var stamina_bar: ProgressBar = $ProgressBar
@onready var powerup_bar: ProgressBar = $PowerupBar
@onready var steps_sfx: AudioStreamPlayer2D = $Steps
@onready var giant_steps_sfx: AudioStreamPlayer2D = $GiantSteps
@onready var breathing_sfx: AudioStreamPlayer2D = $Breathing
@onready var goal_sfx: AudioStreamPlayer2D = $Goal
@onready var fire_position: Marker2D = $FirePosition
@onready var fire_coldown: Timer = $FireColdown
@onready var pacman_powerup_timer: Timer = $PacmanPowerupTimer

@export var god_mode: bool = false  # Modo invencible - el jugador no puede ser atrapado por la policía
@export var max_stamina: float = 100.0
@export var stamina_recovery_rate: float = 20
@export var speed = 350 # (pixels/sec).
@export var play_area_margin: Vector2 = Vector2(10.0, 20.0)  # Margen desde los bordes del área de juego
@export var camera_zoom: float = 1.5  # Nivel de zoom de la cámara
@export var invasion_duration: int = 2 # Tiempo de duración en segundos
@export var projectile_scene: PackedScene
@export var pacman_powerup_duration: float = 10 # segundos
@export var growth_scale: float = 1.4 # Escala de crecimiento al obtener powerup

var input_vector: Vector2 = Vector2.ZERO
var is_invading: bool = false
var is_pacman_powered_up: bool = false
var run_speed_scale: float = 1.0
var stamina: float = max_stamina
var projectile_container: Node
var can_fire: bool = true
var can_run: bool
var game_active: bool = false
var outline_material: Material
var current_steps_sfx: AudioStreamPlayer2D

signal invasion_finished
signal near_soccer_player(soccer_player: Node2D)
signal left_soccer_player(soccer_player: Node2D)
signal caught_by_police
signal pacman_powerup_ended

func _ready() -> void:
	set_physics_process(false)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	fire_coldown.timeout.connect(_on_cooldown_timeout)
	pacman_powerup_timer.wait_time = pacman_powerup_duration
	outline_material = body_anim.material
	setup_camera()
	current_steps_sfx = steps_sfx

func _physics_process(_delta: float) -> void:
	_process_input(_delta)
	_process_animation()
	_process_audio()
	_process_bars(_delta)

func _process_bars(delta: float) -> void:
	# Barra de stamina
	if !Input.is_action_pressed("run"):
		stamina = clamp(stamina + stamina_recovery_rate * delta, 0, max_stamina)
		stamina_bar.value = stamina
		
	# Barra de powerup
	powerup_bar.value = pacman_powerup_timer.time_left

func set_projectile_container(container: Node):
	projectile_container = container

func set_game_active(active: bool):
	game_active = active

func can_process_inputs() -> bool:
	# No procesar inputs si el juego está pausado o no está activo
	return game_active and not get_tree().paused


func _process_input(delta: float) -> void:
	# No procesar inputs si el juego no está activo o está pausado
	if not can_process_inputs():
		input_vector = Vector2.ZERO
		return
		
	input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_just_pressed("fire") and can_fire:
		fire()

	if Input.is_action_pressed("run") and can_run:
		run_speed_scale = 1.6
		stamina -= 20.0 * delta
		stamina = max (stamina, 0)
		stamina_bar.value = stamina
	else:
		run_speed_scale = 1.0
	can_run = stamina_bar.value > 0
	
	input_vector = input_vector.normalized()
	velocity = input_vector * speed * run_speed_scale
	
	move_and_slide()
	
	# Limitar al jugador dentro del área de juego usando los límites de la cámara
	if camera:
		position.x = clamp(
			position.x,
			camera.limit_left + play_area_margin.x,
			camera.limit_right - play_area_margin.x
		)
		position.y = clamp(
			position.y,
			camera.limit_top + play_area_margin.y,
			camera.limit_bottom - play_area_margin.y
		)


func fire():
	var projectile_instance: Projectile = projectile_scene.instantiate()
	projectile_container.add_child(projectile_instance)
	projectile_instance.set_starting_values(
		fire_position.global_position,
		(get_global_mouse_position() - global_position).normalized()
	)
	projectile_instance.delete_requested.connect(_on_projectile_delete_requested)
	can_fire = false
	fire_coldown.start()


func _on_projectile_delete_requested(projectile):
	projectile_container.remove_child(projectile)
	projectile.queue_free()


func _on_cooldown_timeout() -> void:
	can_fire = true


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
		current_steps_sfx.pitch_scale = 1.2 if Input.is_action_pressed("run") else 1.0
		if not current_steps_sfx.playing:
			current_steps_sfx.play()
	else:
		if current_steps_sfx.playing:
			current_steps_sfx.stop()

	if stamina_bar.value < max_stamina and !Input.is_action_pressed("run"):
		if not breathing_sfx.playing:
			breathing_sfx.play()
	else:
		if breathing_sfx.playing:
			breathing_sfx.stop()

func start_invasion(target_position: Vector2):
	is_invading = true
	
	if not steps_sfx.playing:
		steps_sfx.play()

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
	if steps_sfx.playing:
		steps_sfx.stop()
	invasion_finished.emit()


func _play_animation(animation: String) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("soccer_players"):
		near_soccer_player.emit(body)
	elif body.is_in_group("police"):
		if is_pacman_powered_up:
			if body.has_signal("police_defeated"):
				body.police_defeated.emit()  # Emitir señal antes de destruir
			body.queue_free()
		elif not god_mode:  # Solo emitir si god_mode está desactivado
			caught_by_police.emit()
	elif body.name == "SoccerBall":
		_on_pacman_powerup_picked()
		body.queue_free()


func _on_pacman_powerup_picked():
	is_pacman_powered_up = true
	pacman_powerup_timer.start()
	var hud = get_tree().root.get_node("Main/HUD")
	hud.show_pacman_powerup(pacman_powerup_duration)
	powerup_bar.visible = true
	powerup_bar.max_value = pacman_powerup_duration
	powerup_bar.value = pacman_powerup_duration
	goal_sfx.play()

	# Cambiar SFX de pasos a gigante
	current_steps_sfx = giant_steps_sfx

	# Aumentar tamaño del jugador un 20%
	var new_scale = scale * growth_scale
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", new_scale, 0.4)

	# Reducir velocidad de todos los policías un 15%
	var police_group = get_tree().get_nodes_in_group("police")
	for police in police_group:
		if police.has_method("set_speed_modifier"):
			police.set_speed_modifier(0.2)


func _on_pacman_powerup_timer_timeout() -> void:
	is_pacman_powered_up = false
	var hud = get_tree().root.get_node("Main/HUD")
	hud.hide_pacman_powerup()
	powerup_bar.visible = false
	giant_steps_sfx.stop()
	goal_sfx.stop()

	# Restaurar SFX de pasos a normal
	current_steps_sfx = steps_sfx
	
	# Emitir señal de que el powerup terminó
	pacman_powerup_ended.emit()

	# Restaurar tamaño
	var original_scale = scale / growth_scale
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", original_scale, 0.3)

	# Restaurar velocidad normal de todos los policías
	var police_group = get_tree().get_nodes_in_group("police")
	for police in police_group:
		if police.has_method("set_speed_modifier"):
			police.set_speed_modifier(1.0)  # 100% de velocidad


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

func reset_player_state() -> void:
	# Resetear estado de invasión
	is_invading = false
	is_pacman_powered_up = false
	body_anim.modulate = Color(1, 1, 1)
	
	# Resetear input y velocidad
	input_vector = Vector2.ZERO
	velocity = Vector2.ZERO
	
	# Resetear stamina
	stamina = max_stamina
	stamina_bar.value = stamina
	
	# Resetear estado de disparo
	can_fire = true
	if fire_coldown:
		fire_coldown.stop()
	
	# Parar sonidos
	if steps_sfx.playing:
		steps_sfx.stop()
	if giant_steps_sfx.playing:
		giant_steps_sfx.stop()
	if breathing_sfx.playing:
		breathing_sfx.stop()
	
	# Resetear animación
	_play_animation("idle")
	
	# Habilitar procesamiento de física
	set_physics_process(true)
	
	# Resetear cámara
	disable_camera_smooth(0.1)

func enable_outline_shader() -> void:
	if outline_material and body_anim.material != outline_material:
		body_anim.material = outline_material

func disable_outline_shader() -> void:
	if body_anim.material != null:
		body_anim.material = null

#endregion
