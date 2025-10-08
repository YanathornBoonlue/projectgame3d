# SkyDomeFollow.gd
extends MeshInstance3D
@export var camera: Node3D   # ลากกล้องหลัก (เช่น View/Camera3D) มาใส่ได้

func _process(_dt: float) -> void:
	var cam := camera
	if cam == null:
		cam = get_viewport().get_camera_3d()
	if cam:
		# ตาม "ตำแหน่ง" กล้องเสมอ แต่ไม่ยุ่งกับการหมุน
		global_position = cam.global_position
