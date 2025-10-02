class_name SoccerPlayer

extends CharacterBody2D

@onready var body_anim: AnimatedSprite2D = $Body

func _ready() -> void:
	_play_animation("idle")

func _play_animation(animation: String) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)
