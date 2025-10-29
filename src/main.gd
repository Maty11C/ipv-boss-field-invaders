extends Node

const AudioUtils = preload("res://src/utils/audio.gd")

@onready var stadium_ambience: AudioStreamPlayer2D = $StadiumAmbience
@onready var start_timer: Timer = $StartTimer
@onready var score_timer: Timer = $ScoreTimer
@onready var enemy_timer: Timer = $EnemyTimer
@onready var hud: CanvasLayer = $HUD
@onready var player: Node2D = $Environment/Entities/Player
@onready var enemies_node: Node2D = $Environment/Entities/Enemies
@onready var enemy_spawn_location: PathFollow2D = $EnemyPath/EnemySpawnLocation

@export var enemy_scene: PackedScene
@export var enemy_spawn_time: float = 2.0  # Tiempo en segundos entre spawns de policías
@export var min_spawn_coldown: float = 0.8
@export var spawn_acceleration_time: float = 90.0

@export var camera_smooth_duration: float = 3 # Tiempo en segundos de animación de cámara enfocando al player

var score = 0
var elapsed_time: float = 0.0
var score_multiplier = 1
var near_player_bonus = false
var current_bonus_soccer_player = null

signal open_loser_hud

func _ready() -> void:
	player.hide()
	setup_ambience()

#region Game

func new_game():
	clean_game()
	hud.update_score(score)
	
	AudioUtils.fade_bus_volume(self, "Ambience", -6.0, 1.5)
	
	player.show()
	
	player.invasion_finished.connect(_on_invasion_finished)
	player.near_soccer_player.connect(_on_player_near_soccer_player)
	player.left_soccer_player.connect(_on_player_left_soccer_player)
	player.caught_by_police.connect(game_over)
	
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
	var enemies = enemies_node.get_children()
	for enemy in enemies:
		enemy.queue_free()

func game_over() -> void:
	player.disable_camera_smooth(1)
	player.hide()
	AudioUtils.fade_bus_volume(self, "Ambience", -20.0, 1.5)
	clean_game()
	open_loser_hud.emit()

# Función para configurar el sonido ambiente
func setup_ambience() -> void:
	stadium_ambience.bus = "Ambience"
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), -20.0) # Se inicia el sonido ambiente en volumen bajo
	stadium_ambience.play()

#endregion

#region Señales

func _on_hud_start_game() -> void:
	new_game()
	
func _on_invasion_finished():
	player.enable_camera_smooth(camera_smooth_duration)
	start_timer.start()
	enemy_timer.wait_time = enemy_spawn_time
	enemy_timer.start()

func _on_start_timer_timeout() -> void:
	score_timer.start()

func _on_score_timer_timeout() -> void:
	score += score_multiplier
	hud.update_score(score)
	elapsed_time += 1.0

func _on_enemy_timer_timeout() -> void:
	var enemy = enemy_scene.instantiate()
	enemy_spawn_location.progress_ratio = randf()
	enemy.position = enemy_spawn_location.position
	enemy.set_target(player)
	enemies_node.add_child(enemy)
	
	var time = min(elapsed_time, spawn_acceleration_time)
	var wait_time = lerp(
		enemy_spawn_time,
		min_spawn_coldown,
		time / spawn_acceleration_time
	)
	enemy_timer.wait_time = wait_time


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
