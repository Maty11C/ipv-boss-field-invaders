extends Node

@onready var music: AudioStreamPlayer2D = $Music
@onready var start_timer: Timer = $StartTimer
@onready var score_timer: Timer = $ScoreTimer
@onready var enemy_timer: Timer = $EnemyTimer
@onready var hud: CanvasLayer = $HUD
@onready var player: Node2D = $Environment/Entities/Player
@onready var soccer_player: Node2D = $Environment/Entities/SoccerPlayer
@onready var soccer_player2: Node2D = $Environment/Entities/SoccerPlayer2
@onready var enemy_spawn_location: PathFollow2D = $EnemyPath/EnemySpawnLocation

@export var enemy_scene: PackedScene
@export var enemy_spawn_time: float = 2.0  # Tiempo en segundos entre spawns de policías

var score = 0

signal open_loser_hud

func _ready() -> void:
	player.hide()
	spawn_soccer_players()

func spawn_soccer_players() -> void:
	soccer_player.show()
	soccer_player2.show()
	
	# Configurar posiciones iniciales de los jugadores de fútbol
	var screen_size = get_viewport().get_visible_rect().size
	soccer_player.set_idle_position(Vector2(screen_size.x * 0.3, screen_size.y * 0.6))
	soccer_player2.set_idle_position(Vector2(screen_size.x * 0.7, screen_size.y * 0.4))

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
