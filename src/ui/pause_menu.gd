extends Control

signal return_to_main_menu
signal controls_requested

var hud_parent: Node = null

func _ready() -> void:
	hide()
	# Obtener referencia al HUD parent
	hud_parent = get_parent()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("pause_menu"):
		# Solo permitir pausa si el juego está activo
		if hud_parent and hud_parent.has_method("is_game_active") and not hud_parent.is_game_active():
			return
		# No activar pausa si el modal de controles está visible
		if hud_parent and hud_parent.has_method("is_controls_modal_visible") and hud_parent.is_controls_modal_visible():
			return
		visible = !visible
		get_tree().paused = visible	

func _on_resume_button_pressed() -> void:
	# No permitir despausar si el modal de controles está visible
	if hud_parent and hud_parent.has_method("is_controls_modal_visible") and hud_parent.is_controls_modal_visible():
		return
	hide()
	get_tree().paused = false

func _on_main_menu_button_pressed() -> void:
	# No permitir regresar al menú principal si el modal de controles está visible
	if hud_parent and hud_parent.has_method("is_controls_modal_visible") and hud_parent.is_controls_modal_visible():
		return
	get_tree().paused = false
	hide()
	return_to_main_menu.emit()

func _on_controls_button_pressed() -> void:
	controls_requested.emit()
