extends CharacterBody2D
class_name Police

signal police_defeated

@export var speed: int = 280
@export var health: int = 1
@export var max_health: int = 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var offset = Vector2(randf_range(-128, 128), randf_range(-128, 128))
@onready var hey_sfx: AudioStreamPlayer2D = $Hey
@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var target: Node2D
var indicator: Node2D  # Referencia al indicador
var camera: Camera2D
var canvas_layer: CanvasLayer

func take_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		police_defeated.emit()  # Emitir señal antes de destruir
		# Eliminar el indicador y canvas si existen
		if canvas_layer and is_instance_valid(canvas_layer):
			canvas_layer.queue_free()
		self.queue_free()

func _ready() -> void:
	_play_animation("idle")
	hey_sfx.pitch_scale = randf_range(0.92, 1.15)
	hey_sfx.play()
	add_to_group("police")
	
	# Buscar la cámara en la escena
	camera = get_viewport().get_camera_2d()
	
	# Crear el indicador directamente desde código
	if camera:
		# Cargar la escena del indicador
		var indicator_scene = load("res://src/environment/entities/enemies/indicator.tscn")
		if indicator_scene:
			indicator = indicator_scene.instantiate()
			# Cambiar el color del indicador a violeta para la policía
			var sprite = indicator.get_node("Sprite2D")
			if sprite:
				sprite.modulate = Color(0.8, 0.2, 1.0)  # Violeta llamativo
		else:
			# Si no existe la escena, crear el nodo directamente
			indicator = preload("res://src/environment/entities/enemies/indicator.gd").new()
		
		# Crear CanvasLayer para que esté siempre visible encima
		canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 100
		get_tree().root.add_child(canvas_layer)
		canvas_layer.add_child(indicator)
		
		indicator.set_target(self)
		indicator.set_camera(camera)
		
		# Conectar señales del visibility notifier
		visibility_notifier.screen_entered.connect(_on_screen_entered)
		visibility_notifier.screen_exited.connect(_on_screen_exited)
		
		# Verificar el estado inicial de visibilidad
		# Esperar un frame para que el notifier se actualice
		await get_tree().process_frame
		var on_screen = visibility_notifier.is_on_screen()
		indicator.on_target_visibility_changed(on_screen)


func _on_screen_entered() -> void:
	if indicator:
		indicator.on_target_visibility_changed(true)


func _on_screen_exited() -> void:
	if indicator:
		indicator.on_target_visibility_changed(false)


func set_target(enemy: Node2D) -> void:
	target = enemy

func _physics_process(_delta: float) -> void:
	if target:
		var direction: Vector2
		if target.is_pacman_powered_up:
			# Escapar del jugador
			direction = (global_position - target.global_position).normalized()
		else:
			# Perseguir al jugador
			var dist = global_position.distance_to(target.global_position)
			var factor = clamp(dist / 200.0, 0.0, 1.0)
			var target_position = target.global_position + offset * factor
			direction = (target_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

		# Limitar posición dentro de la cancha usando los límites de la cámara
		if camera:
			position.x = clamp(position.x, camera.limit_left, camera.limit_right)
			position.y = clamp(position.y, camera.limit_top, camera.limit_bottom)

		if abs(direction.x) > abs(direction.y):
			anim.flip_h = direction.x < 0
			_play_animation("walk_side")
		elif direction.y > 0:
			_play_animation("walk_front")
		else:
			_play_animation("walk_back")

func _play_animation(animation: String) -> void:
	if anim.sprite_frames.has_animation(animation):
		anim.play(animation)

func _on_area_2d_body_entered(body: Node2D) -> void:
	print(body)
