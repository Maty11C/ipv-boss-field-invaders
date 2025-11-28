extends CanvasLayer

@onready var score_node: Control = $Score
@onready var score_time_label: Label = $Score/TimeLabel
@onready var score_powerup_label: Label = $Score/PowerupLabel
@onready var main_menu: Control = $MainMenu
@onready var end_menu: Control = $EndMenu
@onready var pause_menu: Control = $PauseMenu
@onready var controls_modal: Control = $ControlsModal
@onready var pacman_powerup: Node = $PacmanPowerup

signal start_game

var pending_start_game: bool = false
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
	var minutes = score / 60
	var seconds = score % 60
	score_time_label.text = "%02d:%02d" % [minutes, seconds]

func show_score():
	score_node.visible = true

func hide_score():
	score_node.visible = false

func show_timer_powerup():
	score_powerup_label.show()

func hide_timer_powerup():
	score_powerup_label.hide()
	
func show_pacman_powerup(_duration):
	pacman_powerup.show()
	
func hide_pacman_powerup():
	pacman_powerup.hide()

func _on_main_menu_start_game() -> void:
	pending_start_game = true
	show_controls_modal()

func _on_main_open_loser_hud() -> void:
	game_is_active = false
	hide_score()
	end_menu.show_end_menu()

func _on_end_menu_restart_game() -> void:
	game_is_active = true
	show_score()
	start_game.emit()

func _on_menu_return_to_main_menu() -> void:
	game_is_active = false
	hide_score()
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
	if pending_start_game:
		game_is_active = true
		start_game.emit()
		show_score()
		pending_start_game = false
