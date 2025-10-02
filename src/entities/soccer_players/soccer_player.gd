class_name SoccerPlayer

extends CharacterBody2D

@onready var body_anim: AnimatedSprite2D = $Body

@export var idle_position: Vector2 = Vector2.ZERO  # Posición donde debe permanecer

var is_active: bool = false

func _ready() -> void:
	_play_animation("idle")

func _play_animation(animation: String) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)

func set_idle_position(new_position: Vector2) -> void:
	idle_position = new_position
	position = new_position
