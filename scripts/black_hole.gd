extends Area3D

@export var suction_radius := 12.0      # ยังใช้ถ้าอยากเปิดโหมดรัศมี
@export var global_pull := true         # <<< ดูดทั้งแมพ
@export var base_pull_speed := 4.0      # ความเร็วดูดขั้นต่ำ (m/s)
@export var distance_gain := 1.2        # คูณระยะให้ยิ่งไกลยิ่งแรง
@export var max_pull_speed := 45.0      # ความเร็วดูดสูงสุด (m/s)
@export var kill_distance := 0.7
@export var life_time := 8.0

@export var over_texture: Texture2D        # ตั้งเป็น res://ui/over.png
@export var over_sound: AudioStream        # ตั้งเป็น res://sounds/time_over.ogg (หรือไฟล์เสียงของคุณ)
@export var over_duration: float = 4.5     # แสดงกี่วินาที

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
	_show_time_over() 
	if GameManager.has_method("set_checkpoint"):
		GameManager.set_checkpoint(GameManager.start_position, GameManager.REASON_TIMEOUT)
	if _player:
		_player.call_deferred("set_sucked_state", false)  # <<< ปลดก่อนเกิดใหม่
		_player.call_deferred("respawn")
	call_deferred("queue_free")

func _exit_tree() -> void:
	# เผื่อเคสหลุมดำหายไปกลางคัน ให้คืนคอนโทรลผู้เล่น
	if _sucking and _player and _player.is_inside_tree():
		_player.call_deferred("set_sucked_state", false)
		
func _show_time_over() -> void:
	var root := get_tree().current_scene
	if root == null:
		return

	# ชั้น UI บนสุด
	var layer := CanvasLayer.new()
	layer.layer = 128  # ให้ชัวร์ว่าอยู่บนสุด
	layer.process_mode = Node.PROCESS_MODE_ALWAYS  # ทำงานแม้เกมหยุดชั่วคราว
	root.add_child(layer)

	# ภาพ over.png กลางจอ
	var img := TextureRect.new()
	img.name = "TimeOverImage"
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	img.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	img.size_flags_vertical = Control.SIZE_EXPAND_FILL
	img.anchor_left = 0.0; img.anchor_top = 0.0
	img.anchor_right = 1.0; img.anchor_bottom = 1.0
	img.offset_left = 0; img.offset_top = 0; img.offset_right = 0; img.offset_bottom = 0
	img.modulate = Color(1, 1, 1, 1)
	img.texture = over_texture
	layer.add_child(img)

	# เล่นเสียง (ถ้ามีไฟล์)
	if over_sound:
		var sfx := AudioStreamPlayer.new() # ใช้ 2D ก็ได้ แต่ 3D ไม่จำเป็นกับ UI
		sfx.stream = over_sound
		sfx.volume_db = 0.0
		layer.add_child(sfx)
		sfx.play()

	# ตั้งเวลา 3 วิ แล้วลบทิ้งเอง
	var t := get_tree().create_timer(over_duration)
	t.timeout.connect(func():
		if is_instance_valid(layer):
			layer.queue_free()
	)
