extends CanvasLayer

@onready var score_label: Label = $ScoreLabel

signal start_game

func update_score(score):
	score_label.text = "Score: %d" % [score]


func _on_play_button_pressed() -> void:
	$PlayButton.hide()
	start_game.emit()


func _on_main_open_loser_hud() -> void:
	$PlayButton.text = "PLAY AGAIN"
	$PlayButton.show()
	$MainMenuButton.show()


func _on_main_menu_button_pressed() -> void:
	$PlayButton.text = "PLAY"
	$MainMenuButton.hide()
