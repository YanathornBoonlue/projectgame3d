extends Node

var start_position: Vector3
var checkpoint_position: Vector3
var checkpoint_id: StringName = ""

func _ready() -> void:
	checkpoint_position = Vector3.ZERO

func set_start(pos: Vector3) -> void:
	start_position = pos
	if checkpoint_position == Vector3.ZERO:
		checkpoint_position = pos

func set_checkpoint(pos: Vector3, id: StringName = "") -> void:
	checkpoint_position = pos
	checkpoint_id = id
	# print_debug("Checkpoint:", id, "at", pos)

func get_respawn_position() -> Vector3:
	return (checkpoint_position if checkpoint_position != Vector3.ZERO else start_position)
