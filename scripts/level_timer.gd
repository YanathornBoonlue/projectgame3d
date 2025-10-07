extends Node

@export var total_seconds := 300
@export var blackhole_scene: PackedScene
@export var hud_label_path: NodePath = ^"HUD/TimerLabel"

# — ตกแต่ง —
@export var warn_seconds := 30
@export var critical_seconds := 10
@export var use_blink := true
@export var blink_freq := 6.0  # Hz

# --- ตั้งค่าเกิดไกล + ดีเลย์ตามเสียง 2 วิ ---
@export var spawn_delay := 2.0            # หน่วงให้ตรงกับเสียง
@export var spawn_distance := 30.0        # ระยะไกลจากผู้เล่น (เมตร)
@export var spawn_height := 0.5           # ยกขึ้นจากพื้นเล็กน้อย
@export var spawn_sound: AudioStream      # ใส่ไฟล์เสียง 2 วิที่นี่

var _time_left := 0.0
var _spawned := false
var _spawning := false
var _spawn_ticket := 0  # ใช้ยกเลิกงาน spawn เก่าเวลารีเซ็ต

var _hole: Node3D
@onready var _label: Label = get_node_or_null(hud_label_path)
@onready var _sfx := AudioStreamPlayer.new()

func _ready() -> void:
	_time_left = float(total_seconds)
	add_child(_sfx)
	set_process(true)
	_update_label()

	var player := get_tree().get_first_node_in_group("Player")
	if player and not player.respawned.is_connected(_on_player_respawned):
		player.respawned.connect(_on_player_respawned)

func _process(delta: float) -> void:
	if _time_left > 0.0:
		_time_left = maxf(_time_left - delta, 0.0)
		if _time_left == 0.0 and not _spawned and not _spawning:
			_spawn_blackhole()
	_update_label()

func _spawn_blackhole() -> void:
	_spawning = true
	_spawn_ticket += 1
	var ticket = _spawn_ticket

	var player := get_tree().get_first_node_in_group("Player") as Node3D
	if player == null or blackhole_scene == null:
		_spawning = false
		return

	# เล่นเสียงเตือน 2 วิ แล้วค่อยเกิดหลุมดำพอดีตอนจบเสียง
	if spawn_sound:
		_sfx.stream = spawn_sound
		_sfx.play()

	await get_tree().create_timer(spawn_delay).timeout
	# ถ้าระหว่างรอมีการรีเซ็ตเวลา ให้ยกเลิกสปอว์น
	if not _spawning or ticket != _spawn_ticket:
		return

	# คำนวณตำแหน่ง "ขณะจะเกิด" (อิงทิศปัจจุบันของผู้เล่น)
	var forward := -player.global_transform.basis.z.normalized()
	var target := player.global_position + forward * spawn_distance + Vector3.UP * spawn_height

	_hole = blackhole_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(_hole)
	_hole.global_position = target

	# เอฟเฟกต์โผล่นุ่ม ๆ
	_hole.scale = Vector3.ONE * 0.01
	var tw := _hole.create_tween()
	tw.tween_property(_hole, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_spawned = true
	_spawning = false

func reset_timer(seconds: int = -1) -> void:
	# ยกเลิกงาน spawn ที่กำลังรออยู่ และลบหลุมดำเก่า
	_spawning = false
	_spawn_ticket += 1
	if is_instance_valid(_hole):
		_hole.queue_free()
	_hole = null

	_spawned = false
	_time_left = float(total_seconds if seconds < 0 else seconds)
	_update_label()

func _on_player_respawned() -> void:
	# รีเซ็ตเวลาเฉพาะกรณีหมดเวลาเท่านั้น
	if GameManager.checkpoint_id == &"time_out":
		reset_timer()
		GameManager.checkpoint_id = &""

func _update_label() -> void:
	if _label == null:
		return

	var m := int(_time_left) / 60
	var s := int(_time_left) % 60
	_label.text = "%02d:%02d" % [m, s]  # เพิ่มไอคอนเล็กน้อยให้ดูเด่น

	# ขอบตัวอักษร
	_label.add_theme_constant_override("outline_size", 6)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))

	# สีตามระดับเวลา
	var col := Color(0.85, 1.0, 0.85)      # ปลอดภัย: เขียวอ่อน
	if _time_left <= critical_seconds:
		col = Color(1.0, 0.35, 0.35)       # วิกฤต: แดง
	elif _time_left <= warn_seconds:
		col = Color(1.0, 0.85, 0.35)       # เตือน: เหลือง
	_label.add_theme_color_override("font_color", col)

	# กระพริบตอนวิกฤต
	if use_blink and _time_left <= critical_seconds:
		var t := Time.get_ticks_msec() * 0.001
		var a := 0.55 + 0.45 * sin(t * blink_freq * PI * 2.0)
		_label.modulate.a = a
	else:
		_label.modulate.a = 1.0
