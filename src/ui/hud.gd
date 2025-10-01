extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var play_button: Button = $PlayButton
@onready var main_menu_button: Button = $MainMenuButton
@onready var music: AudioStreamPlayer2D = $Music
@onready var play_sound: AudioStreamPlayer2D = $PlaySound

signal start_game

func _ready() -> void:
	music.play()

func update_score(score):
	score_label.text = "Score: %d" % [score]

func _on_play_button_pressed() -> void:
	play_sound.play()
	play_button.hide()
	main_menu_button.hide()
	music.stop()
	start_game.emit()
	main_menu_button.hide()

func _on_main_open_loser_hud() -> void:
	play_button.text = "PLAY AGAIN"
	play_button.show()
	main_menu_button.show()

func _on_main_menu_button_pressed() -> void:
	play_button.text = "PLAY"
	main_menu_button.hide()
