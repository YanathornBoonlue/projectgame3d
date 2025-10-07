extends Node

var start_position: Vector3 = Vector3.ZERO
var checkpoint_position: Vector3 = Vector3.ZERO

var has_start := false
var has_checkpoint := false
var checkpoint_id: StringName = &""
signal flags_reset
const REASON_TIMEOUT: StringName = &"time_out"

func set_start(pos: Vector3) -> void:
	start_position = pos
	has_start = true
	# ถ้ายังไม่มีเช็คพอยต์ ให้เริ่มเท่ากับจุดเริ่มต้น
	if not has_checkpoint:
		checkpoint_position = pos
		has_checkpoint = true

func set_checkpoint(pos: Vector3, id: StringName = &"") -> void:
	checkpoint_position = pos
	checkpoint_id = id
	has_checkpoint = true
	
	# ถ้าเป็นกรณีหมดเวลา ให้รีเซ็ตธงทั้งแมพ
	if id == REASON_TIMEOUT:
		flags_reset.emit()
func clear_checkpoint() -> void:
	if has_start:
		checkpoint_position = start_position
		checkpoint_id = &""
		has_checkpoint = true
	else:
		has_checkpoint = false

func get_respawn_position() -> Vector3:
	if has_checkpoint:
		return checkpoint_position
	elif has_start:
		return start_position
	else:
		push_warning("Respawn requested but start not set; returning Vector3.ZERO")
		return Vector3.ZERO
