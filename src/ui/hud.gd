extends CanvasLayer

@onready var score_label: Label = $Score/ScoreLabel
@onready var powerup_label: Label = $Score/ScoreLabel/PowerupLabel
@onready var main_menu: Control = $MainMenu
@onready var end_menu: Control = $EndMenu
@onready var pause_menu: Control = $PauseMenu
@onready var controls_modal: Control = $ControlsModal

signal start_game

var game_is_active: bool = false

func _ready() -> void:
	# Conectar las señales del MainMenu y EndMenu
	main_menu.start_game.connect(_on_main_menu_start_game)
	main_menu.controls_requested.connect(_on_main_menu_controls_requested)
	end_menu.restart_game.connect(_on_end_menu_restart_game)
	end_menu.return_to_main_menu.connect(_on_menu_return_to_main_menu)
	pause_menu.return_to_main_menu.connect(_on_menu_return_to_main_menu)
	pause_menu.controls_requested.connect(_on_pause_menu_controls_requested)
	# Conectar señales del modal de controles
	controls_modal.modal_opened.connect(_on_controls_modal_opened)
	controls_modal.modal_closed.connect(_on_controls_modal_closed)

func update_score(score):
	score_label.text = "Score: %d" % [score]

func show_powerup(text: String):
	powerup_label.text = text
	powerup_label.show()
	powerup_label.modulate = Color.YELLOW

func hide_powerup():
	powerup_label.hide()

func _on_main_menu_start_game() -> void:
	game_is_active = true
	start_game.emit()

func _on_main_open_loser_hud() -> void:
	game_is_active = false
	end_menu.show_end_menu()

func _on_end_menu_restart_game() -> void:
	game_is_active = true
	start_game.emit()

func _on_menu_return_to_main_menu() -> void:
	game_is_active = false
	main_menu.show_main_menu()
	get_parent().return_to_main_menu()

func show_controls_modal() -> void:
	controls_modal.show_modal()

func is_controls_modal_visible() -> bool:
	return controls_modal.visible

func is_game_active() -> bool:
	return game_is_active

func _on_main_menu_controls_requested() -> void:
	show_controls_modal()

func _on_pause_menu_controls_requested() -> void:
	show_controls_modal()

func _on_controls_modal_opened() -> void:
	# El modal se encarga de ocultar el pause menu si es necesario
	pass

func _on_controls_modal_closed() -> void:
	# El modal se encarga de restaurar el pause menu si es necesario
	pass
