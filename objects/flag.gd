extends Node3D

# เรียกใช้เมื่อ node ถูกเพิ่มเข้าฉาก
func _ready() -> void:
	# สมมติว่าตัว flag เป็น Area3D ที่เป็น child ของ Node นี้
	$Area3D.body_entered.connect(_on_area_3d_body_entered)

# ฟังก์ชันเรียกเมื่อมีวัตถุชนกับ Area3D
func _on_area_3d_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/result.tscn")
