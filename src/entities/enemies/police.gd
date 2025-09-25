extends Node2D

@export var speed: int = 200
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D

var target: Node2D

signal player_caught(player)

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

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		print("Hincha capturado!")
		player_caught.emit(body)
