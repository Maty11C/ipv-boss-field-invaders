extends Node

@onready var music: AudioStreamPlayer2D = $Music
@onready var start_timer: Timer = $StartTimer
@onready var score_timer: Timer = $ScoreTimer
@onready var enemy_timer: Timer = $EnemyTimer
@onready var hud: CanvasLayer = $HUD
@onready var player: Node2D = $Environment/Entities/Player
@onready var enemy_spawn_location: PathFollow2D = $EnemyPath/EnemySpawnLocation

@export var enemy_scene: PackedScene
@export var enemy_spawn_time: float = 2.0
@export var min_spawn_coldown: float = 0.8
@export var spawn_acceleration_time: float = 90.0

var score = 0
var elapsed_time: float = 0.0

signal open_loser_hud

func _ready() -> void:
	player.hide()

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
	elapsed_time += 1.0

func _on_enemy_timer_timeout() -> void:
	var enemy = enemy_scene.instantiate()

	enemy_spawn_location.progress_ratio = randf()
	enemy.position = enemy_spawn_location.position
	enemy.set_target(player)
	
	enemy.player_caught.connect(game_over)
	
	add_child(enemy)
	
	var time = min(elapsed_time, spawn_acceleration_time)
	var wait_time = lerp(
		enemy_spawn_time,
		min_spawn_coldown,
		time / spawn_acceleration_time
	)
	enemy_timer.wait_time = wait_time


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
