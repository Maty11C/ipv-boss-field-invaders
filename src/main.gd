extends Node

@onready var music: AudioStreamPlayer2D = $Music
@onready var start_timer: Timer = $StartTimer
@onready var score_timer: Timer = $ScoreTimer
@onready var hud: CanvasLayer = $HUD

var score = 0

func _ready() -> void:
	new_game()
	
func new_game():
	music.play()
	start_timer.start()
	hud.update_score(score)

func _on_start_timer_timeout() -> void:
	score_timer.start()

func _on_score_timer_timeout() -> void:
	score += 1
	hud.update_score(score)
