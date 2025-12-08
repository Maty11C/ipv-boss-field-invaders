extends Sprite2D
class_name Projectile

@export var speed: float = 300
@export var rotation_speed: float = 9.0
@export var damage: int = 1

var direction: Vector2

signal delete_requested(projectile)

func _ready() -> void:
	set_physics_process(false)

func set_starting_values(starting_position: Vector2, dir: Vector2, custom_texture: Texture2D = null, custom_scale: Vector2 = Vector2.ZERO):
	global_position = starting_position
	direction = dir
	if custom_texture != null:
		texture = custom_texture
	if custom_scale != Vector2.ZERO:
		scale = custom_scale
	$Timer.start()
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation += rotation_speed * delta

func _on_timer_timeout() -> void:
	emit_signal("delete_requested", self)


func _on_enemy_entered(body: Node2D) -> void:
	if body.name != "Player":
		if body.has_method("take_damage"):
			body.take_damage(damage)
		self.queue_free()
