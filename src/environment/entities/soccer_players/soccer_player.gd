class_name SoccerPlayer

extends CharacterBody2D

@onready var body_anim: AnimatedSprite2D = $Body

@export var animation_resource: SpriteFrames

func _ready() -> void:
	if animation_resource != null:
		body_anim.sprite_frames = animation_resource.duplicate(true)
		_play_animation("idle")
	add_to_group("soccer_players")

func _play_animation(animation: String) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)
