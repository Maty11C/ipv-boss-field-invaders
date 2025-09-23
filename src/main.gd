extends Node

@onready var music: AudioStreamPlayer2D = $Music
@onready var start_timer: Timer = $StartTimer
@onready var score_timer: Timer = $ScoreTimer
@onready var enemy_timer: Timer = $EnemyTimer
@onready var hud: CanvasLayer = $HUD
@onready var enemy_target: Node2D = $Environment/Entities/Player

@export var enemy_scene: PackedScene

var score = 0

func _ready() -> void:
	new_game()
	
func new_game():
	music.play()
	start_timer.start()
	enemy_timer.start()
	hud.update_score(score)

func _on_start_timer_timeout() -> void:
	score_timer.start()

func _on_score_timer_timeout() -> void:
	score += 1
	hud.update_score(score)

func _on_enemy_timer_timeout() -> void:
	var enemy = enemy_scene.instantiate()
	var enemy_spawn_location = $EnemyPath/EnemySpawnLocation

	enemy_spawn_location.progress_ratio = randf()
	enemy.position = enemy_spawn_location.position
	enemy.set_target(enemy_target)

	add_child(enemy)
