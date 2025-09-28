extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var music: AudioStreamPlayer2D = $Music
@onready var play_sound: AudioStreamPlayer2D = $PlaySound

signal start_game

func _ready() -> void:
	music.play()

func update_score(score):
	score_label.text = "Score: %d" % [score]


func _on_play_button_pressed() -> void:
	$PlaySound.play()
	$PlayButton.hide()
	$MainMenuButton.hide()
	music.stop()
	start_game.emit()


func _on_main_open_loser_hud() -> void:
	$PlayButton.text = "PLAY AGAIN"
	$PlayButton.show()
	$MainMenuButton.show()


func _on_main_menu_button_pressed() -> void:
	$PlayButton.text = "PLAY"
	$MainMenuButton.hide()
