class_name SoccerPlayer

extends CharacterBody2D

signal player_penalized

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

func take_damage(_damage: int) -> void:
	player_penalized.emit()
