# FlagCheckpoint.gd
extends Node3D

@export var id: StringName = &"cp_flag_1"
@export var trigger_only_once: bool = true

@onready var area: Area3D = $Area3D
@onready var sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")

var _activated := false

func _ready() -> void:
	# กันต่อสัญญาณซ้ำ
	if area and not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)
	# ฟังสัญญาณรีเซ็ตจาก GameManager (หมดเวลา/หลุมดำ)
	if not GameManager.flags_reset.is_connected(_on_flags_reset):
		GameManager.flags_reset.connect(_on_flags_reset)

	_update_state()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	if trigger_only_once and _activated:
		return

	_activated = true
	GameManager.set_checkpoint(global_position, id)

	# ปิดตรวจจับเมื่อเป็น one-shot (แบบ deferred กัน callback ฟิสิกส์)
	if trigger_only_once and area:
		area.set_deferred("monitoring", false)

	# เล่นอนิเมชันชักธงถ้ามี
	if anim and anim.has_animation("Take 001"):
		anim.play("Take 001")
	if sfx:
		sfx.play()

func _on_flags_reset() -> void:
	# เรียกเมื่อโดนหลุมดำดูด (time_out)
	_activated = false
	if area:
		area.set_deferred("monitoring", true)
	# ถ้ามีอนิเมชันลดธงให้เล่น; ถ้าไม่มี ก็ข้ามได้
	if anim:
		if anim.has_animation("lower"):
			anim.play("lower")
		elif anim.has_animation("Take 001"):
			anim.stop()

	_update_state()

func _update_state() -> void:
	# ให้สถานะ Area ตรงกับ activated/one-shot ตั้งแต่เริ่มฉาก
	if area:
		area.monitoring = not (trigger_only_once and _activated)
