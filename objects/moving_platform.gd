extends AnimatableBody3D

@export var speed: float = 3.0
@export var wait_at_ends: float = 0.4

@onready var a: Marker3D = $PointA
@onready var b: Marker3D = $PointB

var _from: Vector3
var _to: Vector3
var _last_pos: Vector3
var _tween: Tween
var last_displacement: Vector3 = Vector3.ZERO  # << สำคัญ

func _ready() -> void:
	add_to_group("MovingPlatform")
	process_priority = -10                      # <<< ให้แพลตฟอร์มอัปเดตก่อน Player
	_from = a.global_position
	_to   = b.global_position
	global_position = _from
	_last_pos = global_position
	_start_tween()

func _start_tween() -> void:
	var dist := _from.distance_to(_to)
	var travel: float = maxf(0.001, dist / speed)
	_tween = create_tween().set_loops()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_interval(wait_at_ends)
	_tween.tween_property(self, "global_position", _to, travel).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_interval(wait_at_ends)
	_tween.tween_property(self, "global_position", _from, travel).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _physics_process(delta: float) -> void:
	var now := global_position
	last_displacement = now - _last_pos
	var follow_factor: float = 0.0001  # 0.0 = ไม่ขยับตามเลย, 1.0 = ขยับตามเต็มที่
	constant_linear_velocity = (last_displacement / max(delta, 0.000001)) * follow_factor
	_last_pos = now

func get_frame_displacement() -> Vector3:
	return last_displacement
