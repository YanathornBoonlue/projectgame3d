extends AnimatableBody3D

@export var speed: float = 3.0
@export var wait_at_ends: float = 0.4

@onready var a: Marker3D = $PointA
@onready var b: Marker3D = $PointB

var _from: Vector3
var _to: Vector3
var _last_pos: Vector3
var _tween: Tween

var last_displacement: Vector3 = Vector3.ZERO   # <<< ระยะที่แท่นขยับในเฟรมล่าสุด

func _ready() -> void:
	add_to_group("MovingPlatform")
	_from = a.global_position
	_to   = b.global_position
	global_position = _from
	_last_pos = global_position
	_start_tween()

func _start_tween() -> void:
	var dist: float = _from.distance_to(_to)
	var travel: float = max(0.001, dist / speed)
	_tween = create_tween()
	_tween.set_loops()
	_tween.tween_interval(wait_at_ends)
	_tween.tween_property(self, "global_position", _to, travel).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_interval(wait_at_ends)
	_tween.tween_property(self, "global_position", _from, travel).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _physics_process(delta: float) -> void:
	var new_pos := global_position
	var v: Vector3 = (global_position - _last_pos) / max(delta, 0.000001)
	constant_linear_velocity = v
	_last_pos = global_position

func get_frame_displacement() -> Vector3:     # ให้ Player เรียกใช้
	return last_displacement
