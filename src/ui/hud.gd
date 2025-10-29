extends CanvasLayer

const AudioUtils = preload("res://src/utils/audio.gd")

@onready var score_label: Label = $ScoreLabel
@onready var powerup_label: Label = $ScoreLabel/PowerupLabel
@onready var play_button: Button = $PlayButton
@onready var main_menu_button: Button = $MainMenuButton
@onready var music: AudioStreamPlayer2D = $Music
@onready var play_sound: AudioStreamPlayer2D = $PlaySound

signal start_game

func _ready() -> void:
	music.bus = "Music"
	music.play()

func update_score(score):
	score_label.text = "Score: %d" % [score]

func show_powerup(text: String):
	powerup_label.text = text
	powerup_label.show()
	powerup_label.modulate = Color.YELLOW

func hide_powerup():
	powerup_label.hide()

func _on_play_button_pressed() -> void:
	play_sound.play()
	play_button.hide()
	main_menu_button.hide()
	
	AudioUtils.fade_bus_volume(self, "Music", -80.0, 1.5, music.stop)
	
	start_game.emit()
	main_menu_button.hide()

func _on_main_open_loser_hud() -> void:
	play_button.text = "PLAY AGAIN"
	play_button.show()
	main_menu_button.show()
	# Reanudar música del menú cuando vuelve la pantalla de fin de partida
	if not music.playing:
		# Restaurar volumen del bus de música
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 0.0)
		music.play()

func _on_main_menu_button_pressed() -> void:
	play_button.text = "PLAY"
	main_menu_button.hide()
