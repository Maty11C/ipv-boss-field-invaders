class_name SoccerPlayer

extends CharacterBody2D

@onready var body_anim: AnimatedSprite2D = $Body

func _ready() -> void:
	_play_animation("idle")
	
func setup(team: String, team_players: int, index: int, screen_size: Vector2) -> void:
	add_to_group("soccer_players")
	scale = Vector2(2, 2)
	position = calculate_team_position(team, team_players, index, screen_size)
	
func calculate_team_position(team: String, team_players: int, player_index: int, screen_size: Vector2) -> Vector2:
	var margin_x = screen_size.x * 0.1  # 10% de margen en los lados
	var margin_y = screen_size.y * 0.2  # 20% de margen arriba y abajo
	
	var playable_width = (screen_size.x - (margin_x * 2)) / 2  # Dividir el campo en dos mitades
	var playable_height = screen_size.y - (margin_y * 2)
	
	var x_offset = margin_x if team == "Home" else margin_x + playable_width
	
	# Distribuir en filas y columnas dentro de su mitad
	var cols = ceil(sqrt(team_players))
	var rows = ceil(float(team_players) / cols)
	
	var col = player_index % int(cols)
	var row = player_index / int(cols)
	
	var x = x_offset + (col * (playable_width / cols)) + (playable_width / cols / 2)
	var y = margin_y + (row * (playable_height / rows)) + (playable_height / rows / 2)
	
	return Vector2(x, y)

func _play_animation(animation: String) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)
