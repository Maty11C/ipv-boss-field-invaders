extends CharacterBody2D
class_name Police

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
		# Eliminar el indicador y canvas si existen
		if canvas_layer and is_instance_valid(canvas_layer):
			canvas_layer.queue_free()
		self.queue_free()


func _ready() -> void:
	_play_animation("idle")
	hey_sfx.pitch_scale = randf_range(0.92, 1.15)
	hey_sfx.play()
	
	# Buscar la cámara en la escena
	camera = get_viewport().get_camera_2d()
	
	# Crear el indicador directamente desde código
	if camera:
		# Cargar la escena del indicador
		var indicator_scene = load("res://src/environment/entities/enemies/indicator.tscn")
		if indicator_scene:
			indicator = indicator_scene.instantiate()
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
		# Aplicamos un offset en la distancia al enemigo para evitar solapamiento
		var dist = global_position.distance_to(target.global_position)
		var factor = clamp(dist / 200.0, 0.0, 1.0)
		var target_position = target.global_position + offset * factor
		var direction = (target_position - global_position).normalized()
		
		velocity = direction * speed
		move_and_slide()
		
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
