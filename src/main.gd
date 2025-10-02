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
var score_multiplier = 1
var near_player_bonus = false
var current_bonus_soccer_player = null

signal open_loser_hud

func _ready() -> void:
	player.hide()
	spawn_soccer_players()

#region Soccer players

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
	soccer_player.setup(team, home_players if team == "Home" else away_players, index, screen_size)
	entities_node.add_child(soccer_player)

func clear_soccer_players() -> void:
	var soccer_players = get_tree().get_nodes_in_group("soccer_players")
	for soccer_player in soccer_players:
		soccer_player.queue_free()

#endregion

#region Game

func new_game():
	clean_game()
	hud.update_score(score)
	music.play()
	
	player.show()
	
	player.invasion_finished.connect(_on_invasion_finished)
	player.near_soccer_player.connect(_on_player_near_soccer_player)
	player.left_soccer_player.connect(_on_player_left_soccer_player)
	
	# Animación de invasión del jugador al centro de la cancha
	var screen_size = get_viewport().get_visible_rect().size
	var player_final_position = screen_size / 2
	player.start_invasion(player_final_position)
	
func clean_game():
	score = 0
	score_multiplier = 1
	near_player_bonus = false
	current_bonus_soccer_player = null
	hud.hide_powerup()  # Ocultar indicador de power-up
	score_timer.stop()
	enemy_timer.stop()
	start_timer.stop()
	var police_group = get_tree().get_nodes_in_group("police")
	for police in police_group:
		police.queue_free()

func game_over() -> void:
	player.hide()
	clean_game()
	open_loser_hud.emit()

#endregion

#region Señales

func _on_hud_start_game() -> void:
	new_game()
	
func _on_invasion_finished():
	start_timer.start()
	enemy_timer.wait_time = enemy_spawn_time
	enemy_timer.start()

func _on_start_timer_timeout() -> void:
	score_timer.start()

func _on_score_timer_timeout() -> void:
	score += score_multiplier
	hud.update_score(score)

func _on_enemy_timer_timeout() -> void:
	var enemy = enemy_scene.instantiate()
	enemy_spawn_location.progress_ratio = randf()
	enemy.position = enemy_spawn_location.position
	enemy.set_target(player)
	enemy.player_caught.connect(game_over)
	add_child(enemy)

func _on_player_near_soccer_player(soccer_player: Node2D) -> void:
	if not near_player_bonus:
		near_player_bonus = true
		current_bonus_soccer_player = soccer_player
		score_multiplier = 2
		hud.show_powerup("¡PUNTOS X2!")

func _on_player_left_soccer_player(soccer_player: Node2D) -> void:
	if near_player_bonus and current_bonus_soccer_player == soccer_player:
		near_player_bonus = false
		current_bonus_soccer_player = null
		score_multiplier = 1
		hud.hide_powerup()

#endregion
