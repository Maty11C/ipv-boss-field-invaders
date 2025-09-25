extends Node

@onready var music: AudioStreamPlayer2D = $Music
@onready var start_timer: Timer = $StartTimer
@onready var score_timer: Timer = $ScoreTimer
@onready var enemy_timer: Timer = $EnemyTimer
@onready var hud: CanvasLayer = $HUD
@onready var enemy_target: Node2D = $Environment/Entities/Player
@onready var enemy_spawn_location: PathFollow2D = $EnemyPath/EnemySpawnLocation

@export var enemy_scene: PackedScene
@export var enemy_spawn_time: float = 2.0  # Tiempo en segundos entre spawns de policías

var score = 0

func _ready() -> void:
	new_game()
	
func new_game():
	clean_game()
	music.play()
	start_timer.start()
	enemy_timer.wait_time = enemy_spawn_time
	enemy_timer.start()
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
	enemy.set_target(enemy_target)
	
	enemy.player_caught.connect(game_over)

	add_child(enemy)

func game_over(player: CharacterBody2D) -> void:
	print("Game over!")
	new_game()
