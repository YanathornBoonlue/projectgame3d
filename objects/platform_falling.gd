extends Node3D

@export var respawn_time := 5.0     # เวลาก่อนเกิดใหม่ (วินาที)
@export var reset_y := -10.0        # ต่ำกว่านี้ซ่อนแพลตฟอร์มไว้ก่อน

var falling := false
var fall_velocity := 0.0

var _original_transform: Transform3D
@onready var _timer: Timer = Timer.new()

func _ready() -> void:
	# เก็บตำแหน่ง/สเกล/หมุน เดิมไว้เพื่อตอนเกิดใหม่
	_original_transform = global_transform

	# ตั้ง Timer one-shot แล้วต่อสัญญาณ
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_respawn)

func _physics_process(delta: float) -> void:
	# เอฟเฟกต์ย่อ/ขยายค่อยๆ กลับปกติ
	scale = scale.lerp(Vector3.ONE, delta * 10.0)

	if falling:
		fall_velocity += 15.0 * delta
		position.y -= fall_velocity * delta

		# พอตกพ้นจอ/ล่างฉากให้ซ่อนไว้
		if position.y < reset_y and visible:
			visible = false
	else:
		fall_velocity = 0.0

func _on_body_entered(_body: Node) -> void:
	if not falling:
		Audio.play("res://sounds/fall.ogg")
		scale = Vector3(1.25, 1.0, 1.25)  # เอฟเฟกต์เด้งก่อนตก
		falling = true
		_timer.start(respawn_time)        # เริ่มจับเวลา 5 วิ

func _respawn() -> void:
	# รีเซ็ตสถานะทั้งหมดและวาร์ปกลับตำแหน่งเดิม
	falling = false
	fall_velocity = 0.0
	global_transform = _original_transform
	scale = Vector3.ONE
	visible = true
