extends Node

@onready var stadium_ambience_audio: AudioStreamPlayer = $StadiumAmbience
@onready var boo_audio: AudioStreamPlayer = $Boo
@onready var referee_whistle: AudioStreamPlayer = $RefereeWhistle

@onready var start_timer: Timer = $StartTimer
@onready var score_timer: Timer = $ScoreTimer
@onready var enemy_timer: Timer = $EnemyTimer
@onready var soccer_ball_timer: Timer = $SoccerBallTimer
@onready var hud: CanvasLayer = $HUD
@onready var player: Player = $Environment/Entities/Player
@onready var enemies_node: Node2D = $Environment/Entities/Enemies
@onready var objects_node: Node2D = $Environment/Objects
@onready var enemy_spawn_location: PathFollow2D = $EnemyPath/EnemySpawnLocation

@export var enemy_scene: PackedScene
@export var enemy_spawn_time: float = 2.0 # Tiempo en segundos entre spawns de policías
@export var min_spawn_coldown: float = 0.8
@export var spawn_acceleration_time: float = 90.0

@export var camera_smooth_duration: float = 3 # Tiempo en segundos de animación de cámara enfocando al player

@export var soccer_ball_scene: PackedScene
@export var soccer_ball_min_spawn_time: float = 10.0  # Tiempo mínimo de respawn en segundos
@export var soccer_ball_max_spawn_time: float = 20.0  # Tiempo máximo de respawn en segundos
@export var max_soccer_balls: int = 1  # Máximo de pelotas que pueden estar en juego
@export var score_per_soccer_ball: int = 10  # Puntos por cada pelota recogida
@export var score_per_policie_defeated: int = 5  # Puntos por cada policía derrotado
@export var score_penalty: int = 10 # Puntos a restar

# Intensificación del ambiente durante el juego
const AMBIENCE_GAME_START_DB := -10.0 # Comienza más bajo al iniciar la partida
const AMBIENCE_GAME_MAX_DB := 0.0 # Termina en 0dB
const AMBIENCE_RAMP_DURATION := 120.0 # Sube gradualmente en ~120 segundos
const AMBIENCE_RAMP_TWEEN := 0.5 # duración del tween por paso (suaviza cambios)

var score = 0
var elapsed_time: float = 0.0
var score_multiplier = 1
var timer_normal_wait_time = 1.0
var near_player_bonus = false
var current_bonus_soccer_player = null
var current_soccer_balls_count: int = 0  # Cantidad actual de pelotas en juego

# Variables para rastrear los goles
var home_goals: int = 0
var away_goals: int = 0
var home_goal_23_reached: bool = false
var home_goal_36_reached: bool = false
var home_goal_108_reached: bool = false
var away_goal_80_reached: bool = false
var away_goal_81_reached: bool = false
var away_goal_118_reached: bool = false

signal open_loser_hud

func _ready() -> void:
	player.hide()
	setup_sounds()
	$Environment/Entities/Player.set_projectile_container(self)
	timer_normal_wait_time = score_timer.wait_time


#region Game

func new_game():
	clean_game()
	hud.update_score(score)
	
	AudioUtils.fade_bus_volume(self, "Ambience", AMBIENCE_GAME_START_DB, 1.5)
	referee_whistle.play()
	
	player.show()
	player.set_game_active(true) # Activar inputs del jugador
	
	player.invasion_finished.connect(_on_invasion_finished)
	player.near_soccer_player.connect(_on_player_near_soccer_player)
	player.left_soccer_player.connect(_on_player_left_soccer_player)
	player.caught_by_police.connect(game_over)
	for sp in get_tree().get_nodes_in_group("soccer_players"):
		sp.player_penalized.connect(_on_player_penalized)
	
	# Animación de invasión del jugador al centro de la cancha
	var screen_size = get_viewport().get_visible_rect().size
	var player_final_position = screen_size / 2
	player.start_invasion(player_final_position)


func clean_game():
	score = 0
	score_multiplier = 1
	near_player_bonus = false
	current_bonus_soccer_player = null
	elapsed_time = 0.0
	current_soccer_balls_count = 0  # Resetear contador de pelotas
	
	# Resetear todos los goles
	home_goals = 0
	away_goals = 0
	home_goal_23_reached = false
	home_goal_36_reached = false
	home_goal_108_reached = false
	away_goal_80_reached = false
	away_goal_81_reached = false
	away_goal_118_reached = false
	
	hud.hide_timer_powerup()  # Ocultar indicador de power-up
	hud.update_home_score(0)  # Resetear HomeScore a 0
	hud.update_away_score(0)  # Resetear AwayScore a 0
	player.disable_outline_shader()
	score_timer.stop()
	enemy_timer.stop()
	soccer_ball_timer.stop()
	start_timer.stop()
	player.set_game_active(false) # Desactivar inputs del jugador
	var enemies = enemies_node.get_children()
	for enemy in enemies:
		enemy.queue_free()
	
	# Limpiar soccer balls
	var soccer_balls = objects_node.get_children()
	for ball in soccer_balls:
		ball.queue_free()
	
	# Limpiar proyectiles que pueden estar volando
	var projectiles = get_children().filter(func(child): return child is Projectile)
	for projectile in projectiles:
		projectile.queue_free()


func game_over() -> void:
	player.set_game_active(false) # Desactivar inputs del jugador
	player.disable_camera_smooth(1)
	player.hide()
	boo_audio.play()
	AudioUtils.fade_bus_volume(self, "Ambience", -20.0, 1.5)
	clean_game()
	open_loser_hud.emit()


func setup_sounds() -> void:
	stadium_ambience_audio.bus = "Ambience"
	boo_audio.bus = "SFX"
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), -20.0) # Se inicia el sonido ambiente en volumen bajo
	stadium_ambience_audio.play()


func stop_boo_sound() -> void:
	if boo_audio.playing:
		boo_audio.stop()


func return_to_main_menu() -> void:
	player.set_game_active(false) # Desactivar inputs del jugador
	player.reset_player_state()
	clean_game()
	player.hide()
	AudioUtils.fade_bus_volume(self, "Ambience", -20.0, 1.5)
	stop_boo_sound()

#endregion

#region Señales

func _on_hud_start_game() -> void:
	if boo_audio.playing:
		boo_audio.stop()
	new_game()


func _on_invasion_finished():
	player.enable_camera_smooth(camera_smooth_duration)
	start_timer.start()
	enemy_timer.wait_time = enemy_spawn_time
	enemy_timer.start()
	# Iniciar timer de soccer ball con tiempo aleatorio
	var initial_wait = randf_range(soccer_ball_min_spawn_time, soccer_ball_max_spawn_time)
	soccer_ball_timer.wait_time = initial_wait
	soccer_ball_timer.start()


func _on_start_timer_timeout() -> void:
	score_timer.start()


func _on_score_timer_timeout() -> void:
	score += score_multiplier
	hud.update_score(score)
	elapsed_time += 1.0
	_update_ambience_intensity()
	
	_check_goal_milestones()

func _check_goal_milestones() -> void:
	# Goles del equipo local (Home/ARG) en minutos 23, 36 y 108
	if elapsed_time >= 1380 and not home_goal_23_reached:  # 23 minutos = 1380 segundos
		home_goal_23_reached = true
		home_goals += 1
		hud.update_home_score(home_goals)
	
	if elapsed_time >= 2160 and not home_goal_36_reached:  # 36 minutos = 2160 segundos
		home_goal_36_reached = true
		home_goals += 1
		hud.update_home_score(home_goals)
	
	if elapsed_time >= 6480 and not home_goal_108_reached:  # 108 minutos = 6480 segundos
		home_goal_108_reached = true
		home_goals += 1
		hud.update_home_score(home_goals)
	
	# Goles del equipo visitante (Away/FRA) en minutos 80, 81 y 118
	if elapsed_time >= 4800 and not away_goal_80_reached:  # 80 minutos = 4800 segundos
		away_goal_80_reached = true
		away_goals += 1
		hud.update_away_score(away_goals)
	
	if elapsed_time >= 4860 and not away_goal_81_reached:  # 81 minutos = 4860 segundos
		away_goal_81_reached = true
		away_goals += 1
		hud.update_away_score(away_goals)
	
	if elapsed_time >= 7080 and not away_goal_118_reached:  # 118 minutos = 7080 segundos
		away_goal_118_reached = true
		away_goals += 1
		hud.update_away_score(away_goals)


func _on_enemy_timer_timeout() -> void:
	# No spawnear policías si el player tiene el power-up activo
	if player.is_pacman_powered_up:
		return
	
	var enemy = enemy_scene.instantiate()
	enemy_spawn_location.progress_ratio = randf()
	enemy.position = enemy_spawn_location.position
	enemy.set_target(player)
	# Conectar señal para sumar puntos cuando el policía sea eliminado
	if enemy.has_signal("police_defeated"):
		enemy.police_defeated.connect(_on_police_defeated)
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
		score_timer.wait_time = timer_normal_wait_time / 2.0
		hud.show_timer_powerup()
		player.enable_outline_shader()


func _on_player_left_soccer_player(soccer_player: Node2D) -> void:
	if near_player_bonus and current_bonus_soccer_player == soccer_player:
		near_player_bonus = false
		current_bonus_soccer_player = null
		score_timer.wait_time = timer_normal_wait_time
		player.disable_outline_shader()
		hud.hide_timer_powerup()


func _on_police_defeated() -> void:
	# Sumar 5 segundos al score cuando se elimina un policía
	score += score_per_policie_defeated
	elapsed_time += score_per_policie_defeated  # Sumar 5 segundos al tiempo transcurrido
	hud.update_score(score)
	hud.show_score_bonus(score_per_policie_defeated)
	_update_ambience_intensity()  # Actualizar intensidad del sonido con el nuevo tiempo
	
<<<<<<< Updated upstream
func _on_player_penalized() -> void:
	score = max(0, score - score_penalty)
	elapsed_time = max(0, elapsed_time - score_penalty)
	hud.update_score(score)
	hud.show_score_penalty(score_penalty)
=======
	# Verificar si se alcanzó algún hito de gol con estos segundos adicionales
	_check_goal_milestones()
>>>>>>> Stashed changes

#endregion

#region Ambience ramp

# Incrementa gradualmente el volumen del ambiente en función del tiempo transcurrido
func _update_ambience_intensity() -> void:
	# Progreso entre 0 y 1 en base al tiempo transcurrido de la partida
	var t: float = clamp(elapsed_time / AMBIENCE_RAMP_DURATION, 0.0, 1.0)
	var target_db: float = lerp(AMBIENCE_GAME_START_DB, AMBIENCE_GAME_MAX_DB, t)
	AudioUtils.fade_bus_volume(self, "Ambience", target_db, AMBIENCE_RAMP_TWEEN)

#endregion


func _on_soccer_ball_timer_timeout() -> void:
	# Solo crear una nueva pelota si no se ha alcanzado el máximo
	if current_soccer_balls_count >= max_soccer_balls:
		# Ya hay el máximo de pelotas, reiniciar el timer
		soccer_ball_timer.wait_time = randf_range(soccer_ball_min_spawn_time, soccer_ball_max_spawn_time)
		return
	
	var soccer_ball = soccer_ball_scene.instantiate()
	
	# Generar posición aleatoria dentro del área de juego usando los límites de la cámara
	var camera = player.camera
	if camera:
		var margin = 50 # Margen desde los bordes
		var random_x = randf_range(camera.limit_left + margin, camera.limit_right - margin)
		var random_y = randf_range(camera.limit_top + margin, camera.limit_bottom - margin)
		soccer_ball.position = Vector2(random_x, random_y)
	
	objects_node.add_child(soccer_ball)
	current_soccer_balls_count += 1 # Incrementar contador
	
	# Conectar señal para decrementar el contador cuando la pelota sea recogida
	if soccer_ball.has_signal("picked_up"):
		soccer_ball.picked_up.connect(_on_soccer_ball_picked_up)
	
	# Establecer tiempo de respawn aleatorio
	soccer_ball_timer.wait_time = randf_range(soccer_ball_min_spawn_time, soccer_ball_max_spawn_time)


func _on_soccer_ball_picked_up() -> void:
	current_soccer_balls_count = max(0, current_soccer_balls_count - 1) # Decrementar contador
