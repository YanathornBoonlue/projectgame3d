extends StaticBody3D

@onready var bottom_detector: Area3D = $BottomDetector
@onready var mesh: Node3D = $Bubble
@onready var particles: GPUParticles3D = $Particles
@onready var colshape: CollisionShape3D = $CollisionShape3D

var exploded := false

func _ready() -> void:
	if not bottom_detector.body_entered.is_connected(_on_bottom_hit):
		bottom_detector.body_entered.connect(_on_bottom_hit)

func _on_bottom_hit(body: Node3D) -> void:
	# ชื่อกลุ่มให้ตรงกับที่ใช้ใน Player (มักเป็น "Player")
	if not body.is_in_group("Player"):
		return
	explode()

func explode() -> void:
	if exploded:
		return
	exploded = true

	Audio.play("res://sounds/bubble-pop.ogg")  # เสียงแตก
	particles.restart()

	# ทุกอย่างที่กระทบฟิสิกส์ ให้ทำแบบ deferred
	mesh.set_deferred("visible", false)
	colshape.set_deferred("disabled", true)
	bottom_detector.set_deferred("monitoring", false)  # << สำคัญ แก้ error นี้

	# กันทริกเกอร์ซ้ำในเฟรมเดียวกัน (เผื่อไว้)
	bottom_detector.set_deferred("monitorable", false)

	await get_tree().create_timer(1.0).timeout
	queue_free()
