class_name SoccerPlayer

extends CharacterBody2D

@onready var body_anim: AnimatedSprite2D = $Body
@onready var idle_timer: Timer = Timer.new()

@export var team: String = "Argentina"  # Tipo de equipo
@export var idle_position: Vector2 = Vector2.ZERO  # Posición donde debe permanecer

var is_active: bool = false

func _ready() -> void:
	_process_animation()
	
	# Si tiene una posición idle definida, moverse ahí
	if idle_position != Vector2.ZERO:
		position = idle_position
		
func _process_animation() -> void:
	_play_animation("idle")

func _play_animation(animation: String) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)

func set_team(new_team: String) -> void:
	team = new_team
	# Aquí se podría cambiar los sprites según el equipo si fuera necesario

func set_idle_position(new_position: Vector2) -> void:
	idle_position = new_position
	position = new_position
