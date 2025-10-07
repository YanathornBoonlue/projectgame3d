extends Area3D

@export var suction_radius := 12.0      # ยังใช้ถ้าอยากเปิดโหมดรัศมี
@export var global_pull := true         # <<< ดูดทั้งแมพ
@export var base_pull_speed := 4.0      # ความเร็วดูดขั้นต่ำ (m/s)
@export var distance_gain := 1.2        # คูณระยะให้ยิ่งไกลยิ่งแรง
@export var max_pull_speed := 45.0      # ความเร็วดูดสูงสุด (m/s)
@export var kill_distance := 0.7
@export var life_time := 8.0
var _sucking := false

var _player: CharacterBody3D
var _active := true

func _ready() -> void:
	monitoring = true
	monitorable = true
	_player = get_tree().get_first_node_in_group("Player") as CharacterBody3D
	if life_time > 0.0:
		get_tree().create_timer(life_time).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	if not _active or _player == null:
		return

	var to_hole := global_position - _player.global_position
	var dist := to_hole.length()
	if not global_pull and dist > suction_radius:
		return

	# เปิดโหมดถูกดูดครั้งแรก
	if not _sucking and _player.has_method("set_sucked_state"):
		_sucking = true
		_player.call_deferred("set_sucked_state", true)

	# ดึงเข้าหาศูนย์ (ตามโค้ดเวอร์ชันก่อนหน้าของคุณ)
	var dir: Vector3 = (to_hole / maxf(dist, 0.0001))
	var speed: float = clampf(base_pull_speed + dist * distance_gain, base_pull_speed, max_pull_speed)
	_player.global_position += dir * speed * delta
	_player.rotation.y += 4.0 * delta

	if dist <= kill_distance:
		_active = false
		_consume_player()


func _consume_player() -> void:
	if GameManager.has_method("set_checkpoint"):
		GameManager.set_checkpoint(GameManager.start_position, &"time_out")
	if _player:
		_player.call_deferred("set_sucked_state", false)  # <<< ปลดก่อนเกิดใหม่
		_player.call_deferred("respawn")
	call_deferred("queue_free")

func _exit_tree() -> void:
	# เผื่อเคสหลุมดำหายไปกลางคัน ให้คืนคอนโทรลผู้เล่น
	if _sucking and _player and _player.is_inside_tree():
		_player.call_deferred("set_sucked_state", false)
