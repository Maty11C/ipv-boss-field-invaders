extends Node

const HIGH_SCORE_FILE := "user://high_score.save"
var high_score: int = 0

func load_high_score() -> void:
	var file = FileAccess.open(HIGH_SCORE_FILE, FileAccess.READ)
	if file:
		high_score = file.get_32()
		file.close()
	else:
		high_score = 0

func save_high_score() -> void:
	var file = FileAccess.open(HIGH_SCORE_FILE, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()

func check_and_save_high_score(score: int) -> bool:
	if score > high_score:
		high_score = score
		save_high_score()
		return true
	return false

func get_high_score() -> int:
	return high_score
