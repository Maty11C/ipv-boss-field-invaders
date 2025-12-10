extends Control

const Audio = preload("res://src/utils/audio.gd")

signal modal_opened
signal modal_closed

var was_paused_before: bool = false
var pause_menu_was_visible: bool = false

func _ready() -> void:
	hide()

func show_modal() -> void:
	# Guardar el estado de pausa anterior
	was_paused_before = get_tree().paused
	# Verificar si el pause menu está visible y guardarlo
	var hud_parent = get_parent()
	if hud_parent and hud_parent.has_node("PauseMenu"):
		pause_menu_was_visible = hud_parent.get_node("PauseMenu").visible
		if pause_menu_was_visible:
			hud_parent.get_node("PauseMenu").hide()
	# Pausar el juego solo si está activo
	if hud_parent and hud_parent.has_method("is_game_active") and hud_parent.is_game_active():
		get_tree().paused = true
	show()
	modal_opened.emit()

func hide_modal() -> void:
	hide()
	# Restaurar el estado de pausa anterior
	get_tree().paused = was_paused_before
	# Restaurar la visibilidad del pause menu si estaba visible
	var hud_parent = get_parent()
	if hud_parent and hud_parent.has_node("PauseMenu") and pause_menu_was_visible:
		hud_parent.get_node("PauseMenu").show()
	pause_menu_was_visible = false
	modal_closed.emit()

func _on_close_button_pressed() -> void:
	Audio.play_whoosh(self)
	hide_modal()

# Permitir cerrar el modal con ESC
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause_menu"):
		hide_modal()
		# Consumir el evento para evitar que active el pause_menu
		get_viewport().set_input_as_handled()

# Cerrar el modal cuando se hace clic fuera de él
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_modal()

# Prevenir que se cierre cuando se hace clic dentro del panel
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Consume el evento para evitar que llegue al fondo
		get_viewport().set_input_as_handled()
