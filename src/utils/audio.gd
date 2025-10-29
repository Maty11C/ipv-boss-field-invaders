extends Node
class_name AudioUtils

## Hace un fade del volumen de un bus de audio
## @param node: El nodo que crea el tween (necesario para create_tween())
## @param bus_name: Nombre del bus de audio
## @param target_volume: Volumen objetivo en dB
## @param duration: Duración del fade en segundos
## @param callback: Función opcional a llamar al finalizar el fade
static func fade_bus_volume(
	node: Node,
	bus_name: String, 
	target_volume: float, 
	duration: float,
	callback: Callable = Callable()
) -> Tween:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_error("Bus de audio '%s' no encontrado" % bus_name)
		return null
	
	var tween = node.create_tween()
	tween.tween_method(
		func(vol): AudioServer.set_bus_volume_db(bus_idx, vol),
		AudioServer.get_bus_volume_db(bus_idx),
		target_volume,
		duration
	)
	
	if callback.is_valid():
		tween.tween_callback(callback)
	
	return tween
