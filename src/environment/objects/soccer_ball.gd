extends RigidBody2D

signal picked_up

@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var indicator: Node2D  # Referencia al indicador
var camera: Camera2D
var canvas_layer: CanvasLayer

func _ready():
	freeze = true  # Mantener la pelota estática en su posición
	set_contact_monitor(true)
	max_contacts_reported = 1
	add_to_group("soccer_ball")
	
	# Buscar la cámara en la escena
	camera = get_viewport().get_camera_2d()
	
	# Crear el indicador directamente desde código
	if camera:
		# Cargar la escena del indicador
		var indicator_scene = load("res://src/environment/entities/enemies/indicator.tscn")
		if indicator_scene:
			indicator = indicator_scene.instantiate()
			# Activar inversión de dirección para que apunte hacia la pelota
			indicator.invert_direction = true
			# Usar color por defecto del indicador (rojo)
		else:
			# Si no existe la escena, crear el nodo directamente
			indicator = preload("res://src/environment/entities/enemies/indicator.gd").new()
			indicator.invert_direction = true
		
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

func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("picked_up")
		# Eliminar el indicador y canvas si existen
		if canvas_layer and is_instance_valid(canvas_layer):
			canvas_layer.queue_free()
		queue_free()
