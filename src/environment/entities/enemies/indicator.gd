extends Node2D

@export var edge_margin: float = 20.0  # Distancia desde el borde de la pantalla
@export var arrow_size: float = 1.0  # Tamaño de la flecha
@export var invert_direction: bool = false  # Si true, apunta hacia el target en lugar de desde el target

var target: Node2D
var camera: Camera2D
var is_target_visible: bool = true


func _ready() -> void:
	visible = false


func set_target(police: Node2D) -> void:
	target = police


func set_camera(cam: Camera2D) -> void:
	camera = cam


func on_target_visibility_changed(visible_on_screen: bool) -> void:
	is_target_visible = visible_on_screen


func _process(_delta: float) -> void:
	if not target or not is_instance_valid(target) or not camera:
		visible = false
		return
	
	if not is_target_visible:
		visible = true
		
		# Obtenemos los límites de la viewport
		var viewport_rect = get_viewport_rect()
		var viewport_size = viewport_rect.size
		
		# Posición del target en coordenadas de pantalla (relativo a la cámara)
		var target_global = target.global_position
		var camera_global = camera.global_position
		var viewport_center = viewport_size / 2.0
		
		# Calcular posición en pantalla del target
		var target_screen_pos = target_global - camera_global + viewport_center
		
		# Calcular la dirección hacia el target
		var screen_center = viewport_size / 2.0
		var direction_to_target = (target_screen_pos - screen_center).normalized()
		
		# Calcular dónde la línea desde el centro intersecta con el borde de la pantalla
		# Dividimos por el componente más grande para encontrar el factor de escala
		var scale_x = abs(viewport_size.x / 2.0 / direction_to_target.x) if direction_to_target.x != 0 else INF
		var scale_y = abs(viewport_size.y / 2.0 / direction_to_target.y) if direction_to_target.y != 0 else INF
		var edge_scale = min(scale_x, scale_y)
		
		# Posición en el borde
		var edge_pos = screen_center + direction_to_target * edge_scale
		
		# Aplicar margen hacia el interior
		var final_pos = edge_pos - direction_to_target * edge_margin
		
		# Asegurar que está dentro de los límites
		final_pos.x = clamp(final_pos.x, edge_margin, viewport_size.x - edge_margin)
		final_pos.y = clamp(final_pos.y, edge_margin, viewport_size.y - edge_margin)
		
		# La posición ya está en coordenadas de pantalla (CanvasLayer)
		global_position = final_pos
		
		# Rotar el indicador
		# Si invert_direction es false (policías): apunta hacia adentro/jugador (+PI)
		# Si invert_direction es true (pelota): apunta hacia afuera/target (sin PI)
		if invert_direction:
			# Para la pelota: apunta en la dirección del target
			rotation = direction_to_target.angle()
		else:
			# Para policías: apunta hacia el jugador (opuesto)
			rotation = direction_to_target.angle() + PI
	else:
		visible = false
