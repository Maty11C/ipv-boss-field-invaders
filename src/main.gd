extends Node

@onready var music: AudioStreamPlayer2D = $Music
@onready var start_timer: Timer = $StartTimer
@onready var score_timer: Timer = $ScoreTimer
@onready var enemy_timer: Timer = $EnemyTimer
@onready var hud: CanvasLayer = $HUD
@onready var player: Node2D = $Environment/Entities/Player
@onready var entities_node: Node2D = $Environment/Entities
@onready var enemy_spawn_location: PathFollow2D = $EnemyPath/EnemySpawnLocation

@export var enemy_scene: PackedScene
@export var soccer_player_home_scene: PackedScene
@export var soccer_player_away_scene: PackedScene
@export var enemy_spawn_time: float = 2.0  # Tiempo en segundos entre spawns de policías
@export var home_players: int = 2  # Cantidad de jugadores del equipo local
@export var away_players: int = 2  # Cantidad de jugadores del equipo visitante

var score = 0

signal open_loser_hud

func _ready() -> void:
	player.hide()
	spawn_soccer_players()

func spawn_soccer_players() -> void:
	clear_soccer_players()
	var screen_size = get_viewport().get_visible_rect().size
	spawn_team_players("Home", home_players, screen_size)
	spawn_team_players("Away", away_players, screen_size)

func spawn_team_players(team: String, player_count: int, screen_size: Vector2) -> void:
	for i in range(player_count):
		spawn_player_by_team(team, i, screen_size)

func spawn_player_by_team(team: String, index: int, screen_size: Vector2) -> void:
	var scene_to_load: PackedScene = soccer_player_home_scene if team == "Home" else soccer_player_away_scene
	var soccer_player = scene_to_load.instantiate()
	soccer_player.scale = Vector2(2, 2)
	soccer_player.add_to_group("soccer_players")
	soccer_player.position = _calculate_team_position(team, index, screen_size)
	entities_node.add_child(soccer_player)

func _calculate_team_position(team: String, player_index: int, screen_size: Vector2) -> Vector2:
	var margin_x = screen_size.x * 0.1  # 10% de margen en los lados
	var margin_y = screen_size.y * 0.2  # 20% de margen arriba y abajo
	
	var playable_width = (screen_size.x - (margin_x * 2)) / 2  # Dividir el campo en dos mitades
	var playable_height = screen_size.y - (margin_y * 2)
	
	var team_players = home_players if team == "Home" else away_players
	
	var x_offset = margin_x if team == "Home" else margin_x + playable_width
	
	# Distribuir en filas y columnas dentro de su mitad
	var cols = ceil(sqrt(team_players))
	var rows = ceil(float(team_players) / cols)
	
	var col = player_index % int(cols)
	var row = player_index / int(cols)
	
	var x = x_offset + (col * (playable_width / cols)) + (playable_width / cols / 2)
	var y = margin_y + (row * (playable_height / rows)) + (playable_height / rows / 2)
	
	return Vector2(x, y)

func clear_soccer_players() -> void:
	var soccer_players = get_tree().get_nodes_in_group("soccer_players")
	for soccer_player in soccer_players:
		soccer_player.queue_free()

func new_game():
	player.show()
	player.invasion_finished.connect(_on_invasion_finished)
	
	clean_game()
	music.play()
	
	# Animación de invasión del jugador al centro de la cancha
	var screen_size = get_viewport().get_visible_rect().size
	var player_final_position = screen_size / 2
	player.start_invasion(player_final_position)
	
	hud.update_score(score)
	
func clean_game():
	score = 0
	score_timer.stop()
	enemy_timer.stop()
	start_timer.stop()
	var police_group = get_tree().get_nodes_in_group("police")
	for police in police_group:
		police.queue_free()

func _on_start_timer_timeout() -> void:
	score_timer.start()

func _on_score_timer_timeout() -> void:
	score += 1
	hud.update_score(score)

func _on_enemy_timer_timeout() -> void:
	var enemy = enemy_scene.instantiate()

	enemy_spawn_location.progress_ratio = randf()
	enemy.position = enemy_spawn_location.position
	enemy.set_target(player)
	
	enemy.player_caught.connect(game_over)

	add_child(enemy)

func _on_invasion_finished():
	start_timer.start()
	enemy_timer.wait_time = enemy_spawn_time
	enemy_timer.start()

func game_over() -> void:
	player.hide()
	clean_game()
	open_loser_hud.emit()

func _on_hud_start_game() -> void:
	new_game()
