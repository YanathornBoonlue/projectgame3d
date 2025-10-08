extends Node3D

@onready var spawns: Node = $"Spawns"
var zombie: PackedScene = load("res://scenes/zombo.tscn")

func _ready() -> void:
	randomize()
	# ถ้าใช้ Timer สำหรับสแปวน์ ตั้งโหมดให้ยิงในฟิสิกส์ (กัน interpolation warning)
	var t: Timer = $ZombieSpawnTimer
	if is_instance_valid(t):
		t.process_callback = Timer.TIMER_PROCESS_PHYSICS   # <<< สำคัญ

# --- ดึงจุดเกิดแบบปลอดภัย ---
func _get_random_spawn_point() -> Node3D:
	if not is_instance_valid(spawns):
		push_warning("Spawns node missing")
		return null
	var count := spawns.get_child_count()
	if count <= 0:
		push_warning("No spawn points under Spawns")
		return null
	var idx := randi() % count
	var n := spawns.get_child(idx)
	return n as Node3D   # อาจคืน null ถ้าไม่ใช่ Node3D

# --- สร้างซอมบี้ให้ถูกขั้นตอน ---
func _spawn_zombie_at(sp: Node3D) -> void:
	if sp == null or not sp.is_inside_tree():
		push_warning("Spawn point invalid or not in tree")
		return
	var inst := zombie.instantiate() as Node3D
	# ปิด interpolation ของตัวที่เพิ่งเกิด เผื่อคุณเปิดไว้ทั้งโปรเจกต์
	inst.physics_interpolation_mode = Node3D.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(inst)
	# ตั้งตำแหน่งหลัง add_child เพื่อให้ world พร้อมแน่ ๆ
	inst.global_transform = sp.global_transform

func _on_zombie_spawn_timer_timeout() -> void:
	var sp := _get_random_spawn_point()
	if sp == null:
		return
	_spawn_zombie_at(sp)
