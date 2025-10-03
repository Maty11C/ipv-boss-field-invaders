extends Node2D

@export var speed: int = 200

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D
@onready var offset = Vector2(randf_range(-128, 128), randf_range(-128, 128))

var target: Node2D

signal player_caught

func _ready() -> void:
	_play_animation("idle")

func set_target(enemy: Node2D) -> void:
	target = enemy

func _physics_process(delta: float) -> void:
	if target:
		# Aplicamos un offset en la distancia al enemigo para evitar solapamiento
		var dist = global_position.distance_to(target.global_position)
		var factor = clamp(dist / 200.0, 0.0, 1.0)
		var target_position = target.global_position + offset * factor
		var direction = (target_position - global_position).normalized()
		global_position += direction * speed * delta
		
		if abs(direction.x) > abs(direction.y):
			anim.flip_h = direction.x < 0
			_play_animation("walk_side")
		elif direction.y > 0:
			_play_animation("walk_front")
		else:
			_play_animation("walk_back")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		player_caught.emit()

func _play_animation(animation: String) -> void:
	if anim.sprite_frames.has_animation(animation):
		anim.play(animation)
