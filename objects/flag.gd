extends Node3D

@onready var area: Area3D = $Area3D

func _ready() -> void:
	if not area.body_entered.is_connected(_on_area_3d_body_entered):
		area.body_entered.connect(_on_area_3d_body_entered)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Player"):  # ชื่อกลุ่มให้ตรงกับที่ใส่ใน Player
		return

	# กันทริกเกอร์ซ้ำในเฟรมเดียวกัน
	area.set_deferred("monitoring", false)

	# สลับซีนแบบ deferred เพื่อไม่ให้กระทบ physics callback
	get_tree().call_deferred(
		"change_scene_to_file",
		"res://scenes/result.tscn"
	)
