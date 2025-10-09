extends CharacterBody3D
signal respawned 
signal coin_collected

@export_subgroup("Components")
@export var view: Node3D                         # โหนดหมุนมุมกล้อง (เช่น View/CameraPivot)

@export var fall_kill_y: float = -20.0           # ตกเกินนี้ให้ตาย/เกิดใหม่
@export_subgroup("Movement")
@export var movement_speed: float = 250.0        # เดินปกติ (หน่วย: u/s)
@export var sprint_speed: float = 420.0          # วิ่งเร็ว (ต้องมี action: "sprint")
@export var jump_strength: float = 7.0

@export_subgroup("Combat")
@export var max_hp: int = 3                      # พลังชีวิตสูงสุด
@export var invuln_duration: float = 0.6         # เวลาไร้เทียมทานหลังโดนตี
@export var hit_stun_duration: float = 0.25      # เวลาชะงัก
@export var knockback_force: float = 9.0         # แรงน็อคแบ็กพื้นฐาน

@export_subgroup("Floor / Platforms")
@export_range(0.0, 2.0, 0.01) var floor_snap_len: float = 0.25
@export_range(0.0, 89.0, 0.1) var floor_angle_deg: float = 46.0

var rotation_direction: float
var gravity: float = 0.0
var is_being_sucked := false
var previously_floored := false

var jump_single := true
var jump_double := true
var controls_disabled := false
var coins := 0

var hp: int
var _invuln := false

@onready var particles_trail: Node3D = $ParticlesTrail
@onready var sound_footsteps: AudioStreamPlayer = $SoundFootsteps
@onready var model: Node3D = $Fish
@onready var animation: AnimationPlayer = $Fish/AnimationPlayer

func _ready() -> void:
	add_to_group("Player")

	# เหรียญสะสมข้ามฉาก
	if Engine.has_singleton("GameManager"):
		coins = GameManager.coins
		GameManager.set_start(global_position)

	# Init movement/combat
	velocity = Vector3.ZERO
	gravity = 0.0
	previously_floored = false
	jump_single = true
	jump_double = true
	controls_disabled = false
	hp = max_hp
	_invuln = false

	call_deferred("_do_respawn")
	_apply_floor_tuning()

func _physics_process(delta: float) -> void:
	# ===== Movement (พร้อมแท่นเลื่อน) =====
	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.z = Input.get_axis("move_forward", "move_back")

	# หมุนอินพุตตาม yaw ของ view ถ้ามี ไม่งั้นตามตัวเอง
	var yaw := rotation.y
	if is_instance_valid(view):
		yaw = view.global_rotation.y
	input_dir = input_dir.rotated(Vector3.UP, yaw)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	# บวกการเคลื่อนที่ของแท่น (เฉพาะ XZ) ก่อนคำนวณฟิสิกส์
	_apply_platform_displacement_pre()

	# ตั้งความเร็วแนวนอน (หน่วย u/s — ไม่คูณ delta)
	var current_speed := sprint_speed if Input.is_action_pressed("sprint") else movement_speed
	var desired_h: Vector3 = input_dir * current_speed

	if is_on_floor():
		velocity.x = desired_h.x
		velocity.z = desired_h.z
	else:
		var rate: float = 3.0 * delta
		var hv := Vector2(velocity.x, velocity.z).lerp(Vector2(desired_h.x, desired_h.z), rate)
		velocity.x = hv.x
		velocity.z = hv.y

	# แรงโน้มถ่วง
	velocity.y = -gravity

	move_and_slide()

	# ===== Facing =====
	if Vector2(velocity.z, velocity.x).length() > 0.0:
		rotation_direction = Vector2(velocity.z, velocity.x).angle()
	rotation.y = lerp_angle(rotation.y, rotation_direction, delta * 10.0)

	# ตกเหว
	if not is_being_sucked and global_position.y < fall_kill_y:
		die()  # หรือ respawn() ถ้าต้องการ

	# สเกลตอนขึ้น/ลงพื้น
	model.scale = model.scale.lerp(Vector3.ONE, delta * 10.0)

	# แตะพื้นแรง ๆ
	if is_on_floor() and gravity > 2.0 and !previously_floored:
		model.scale = Vector3(1.25, 0.75, 1.25)
		Audio.play("res://sounds/land.ogg")
	previously_floored = is_on_floor()

	# ===== sub-steppers =====
	handle_gravity(delta)
	handle_effects(delta)
	handle_controls(delta)

# ---------- FX / Animation ----------
func handle_effects(delta: float) -> void:
	particles_trail.emitting = false
	sound_footsteps.stream_paused = true

	if is_on_floor():
		var horizontal_velocity := Vector2(velocity.x, velocity.z)
		var current_speed := sprint_speed if Input.is_action_pressed("sprint") else movement_speed
		var speed_factor := 0.0
		if current_speed > 0.0:
			speed_factor = horizontal_velocity.length() / current_speed

		if speed_factor > 0.05:
			if animation.current_animation != "walk":
				animation.play("walk", 0.1)

			if speed_factor > 0.3:
				sound_footsteps.stream_paused = false
				sound_footsteps.pitch_scale = speed_factor

			if speed_factor > 0.75:
				particles_trail.emitting = true
		elif animation.current_animation != "idle":
			animation.play("idle", 0.1)

		if animation.current_animation == "walk":
			animation.speed_scale = max(speed_factor, 0.2)
		else:
			animation.speed_scale = 1.0
	elif animation.current_animation != "jump":
		animation.play("jump", 0.1)

# ---------- Input (เฉพาะกระโดด) ----------
func handle_controls(_delta: float) -> void:
	if controls_disabled:
		return
	if Input.is_action_just_pressed("jump"):
		if jump_single or jump_double:
			jump()

# ---------- Gravity / Jump ----------
func handle_gravity(delta: float) -> void:
	if controls_disabled:
		return
	gravity += 25.0 * delta
	if gravity > 0.0 and is_on_floor():
		jump_single = true
		gravity = 0.0

func jump() -> void:
	Audio.play("res://sounds/jump.ogg")
	gravity = -jump_strength
	model.scale = Vector3(0.5, 1.5, 0.5)

	if jump_single:
		jump_single = false
		jump_double = true
	else:
		jump_double = false

# ---------- Coins ----------
func collect_coin() -> void:
	if Engine.has_singleton("GameManager"):
		coins = GameManager.add_coins(1)  # ได้ยอดรวมล่าสุดกลับมา
	else:
		coins += 1
	coin_collected.emit(coins)

# ---------- Combat ----------
func hit(dir: Vector3, damage: int = 1, kb: float = -1.0) -> void:
	if _invuln:
		return

	if kb < 0.0:
		kb = knockback_force

	hp = max(hp - damage, 0)

	_invuln = true
	controls_disabled = true

	# น็อคแบ็ก + เด้งขึ้นเล็กน้อย
	var n := dir.normalized()
	velocity.x = n.x * kb
	velocity.z = n.z * kb
	gravity = -jump_strength * 0.5

	# เอฟเฟกต์โดนตี
	if is_instance_valid(model):
		model.modulate = Color(1.0, 0.6, 0.6)
		var tw := create_tween()
		tw.tween_property(model, "modulate", Color(1,1,1), invuln_duration)

	await get_tree().create_timer(hit_stun_duration).timeout
	controls_disabled = false

	var remain: float = max(invuln_duration - hit_stun_duration, 0.0)
	if remain > 0.0:
		await get_tree().create_timer(remain).timeout
	_invuln = false

	if hp <= 0:
		die()

func die() -> void:
	# ตายแล้วขึ้นหน้าผลลัพธ์ (แพ้)
	if Engine.has_singleton("GameManager"):
		GameManager.result_state = "defeat"
	get_tree().change_scene_to_file("res://scenes/result.tscn")

func heal(amount: int = 1) -> void:
	hp = clamp(hp + amount, 0, max_hp)

# ---------- Respawn ----------
func respawn() -> void:
	controls_disabled = false
	is_being_sucked = false
	velocity = Vector3.ZERO
	gravity = 0.0
	previously_floored = false
	jump_single = true
	jump_double = true
	call_deferred("_do_respawn")
	
func _do_respawn() -> void:
	var p := global_position
	if Engine.has_singleton("GameManager") and "get_respawn_position" in GameManager:
		p = GameManager.get_respawn_position()
	# ดันขึ้นจากพื้นเล็กน้อยกันติด/ทะลุ
	global_position = p + Vector3.UP * 0.2
	respawned.emit()

# ---------- Platforms / Floor tuning ----------
func _apply_floor_tuning() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	up_direction = Vector3.UP
	floor_snap_length = floor_snap_len                 # ดูดติดพื้น/แท่น
	floor_max_angle = deg_to_rad(floor_angle_deg)      # มุมสูงสุดที่ยังนับเป็นพื้น
	floor_stop_on_slope = true
	floor_constant_speed = true
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_ADD_VELOCITY

func _apply_platform_displacement_pre() -> void:
	var plat := _get_floor_platform()
	if plat == null:
		return

	var disp := Vector3.ZERO
	if plat.has_method("get_frame_displacement"):
		disp = plat.get_frame_displacement()
	elif "last_displacement" in plat:
		disp = plat.last_displacement

	if disp != Vector3.ZERO:
		global_position += Vector3(disp.x, 0.0, disp.z)

func _get_floor_platform() -> Node3D:
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c and c.get_normal().y > 0.55:
			var n := c.get_collider()
			if n is Node3D and n.is_in_group("MovingPlatform"):
				return n
	return null

# ---------- Misc ----------
func set_controls_disabled(v: bool) -> void:
	controls_disabled = v

func set_sucked_state(v: bool) -> void:
	is_being_sucked = v
	controls_disabled = v
	if v:
		gravity = 0.0
		velocity = Vector3.ZERO
