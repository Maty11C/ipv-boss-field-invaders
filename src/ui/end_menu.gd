extends Control

const Audio = preload("res://src/utils/audio.gd")

@onready var boo_audio: AudioStreamPlayer = $Audio/Boo
@onready var goal_audio: AudioStreamPlayer = $Audio/Goal
@onready var new_high_score: Control = $NewHighScore
@onready var time_score_label: Label = $ScoreContainer/TimeScoreLabel

signal restart_game
signal return_to_main_menu

func show_end_menu(score: String, show_new_high_score: bool = false) -> void:
	if (show_new_high_score):
		new_high_score.visible = true
		goal_audio.play()
	else:
		new_high_score.visible = false
		boo_audio.play()
	time_score_label.text = "Score " + score
	show()

func hide_end_menu() -> void:
	hide()
	if (goal_audio.playing):
		goal_audio.stop()
	if (boo_audio.playing):
		boo_audio.stop()

func _on_restart_button_pressed() -> void:
	Audio.play_whoosh(self)
	hide_end_menu()
	restart_game.emit()

func _on_main_menu_button_pressed() -> void:
	Audio.play_whoosh(self)
	hide_end_menu()
	return_to_main_menu.emit()
