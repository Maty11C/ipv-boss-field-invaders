extends CharacterBody2D
class_name Police

@export var speed: int = 280
@export var health: int = 1
@export var max_health: int = 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var offset = Vector2(randf_range(-128, 128), randf_range(-128, 128))
@onready var hey_sfx: AudioStreamPlayer2D = $Hey

var target: Node2D


func take_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		self.queue_free()


func _ready() -> void:
	_play_animation("idle")
	hey_sfx.pitch_scale = randf_range(0.92, 1.15)
	hey_sfx.play()


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
