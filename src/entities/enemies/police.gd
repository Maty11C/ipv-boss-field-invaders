extends Node2D

@export var speed: int = 200
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var target: Node2D

func _ready() -> void:
	anim.play("idle")

func set_target(enemy: Node2D) -> void:
	target = enemy

func _physics_process(delta: float) -> void:
	if target:
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		
		if abs(direction.x) > abs(direction.y):
			anim.flip_h = direction.x < 0
			anim.play("walk_side")
		elif direction.y > 0:
			anim.play("walk_front")
		else:
			anim.play("walk_back")
