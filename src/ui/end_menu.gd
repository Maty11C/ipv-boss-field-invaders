extends Control

const Audio = preload("res://src/utils/audio.gd")

@onready var new_high_score: Control = $NewHighScore
@onready var time_score_label: Label = $ScoreContainer/TimeScoreLabel

signal restart_game
signal return_to_main_menu

func show_end_menu(score: String, show_new_high_score: bool = false) -> void:
	new_high_score.visible = show_new_high_score
	time_score_label.text = "Score " + score
	show()

func hide_end_menu() -> void:
	hide()

func _on_restart_button_pressed() -> void:
	Audio.play_whoosh(self)
	hide_end_menu()
	restart_game.emit()

func _on_main_menu_button_pressed() -> void:
	Audio.play_whoosh(self)
	hide_end_menu()
	return_to_main_menu.emit()
