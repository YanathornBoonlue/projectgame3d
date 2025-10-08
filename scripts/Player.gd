extends CharacterBody3D
signal respawned
signal coin_collected

@export_subgroup("Components")
@export var view: Node3D

@export var fall_kill_y: float = -20.0
@export_subgroup("Properties")
@export var movement_speed: float = 5.0
@export var jump_strength: float = 7.0

@export var sprint_multiplier: float = 1.5
var is_sprinting := false

@export var footstep_interval_walk: float = 0.42
@export var footstep_interval_run: float = 0.30
@export var footstep_min_interval: float = 0.18
var _footstep_timer: float = 0.0

var rotation_direction: float
var gravity: float = 0.0
var is_being_sucked := false
var previously_floored := false
var controls_disabled := false

var jump_single := true
var jump_double := true
var coins := 0

# ติดตามแพลตฟอร์มจากเฟรมก่อนหน้า (ใช้กับ displacement-carry)
var _attached_platform: Node3D = null

@onready var particles_trail: GPUParticles3D = $ParticlesTrail
@onready var sound_footsteps: AudioStreamPlayer = $SoundFootsteps
@onready var model: Node3D = $Fish
@onready var animation: AnimationPlayer = $Fish/AnimationPlayer

@export_range(0.0, 2.0, 0.01) var floor_snap_len: float = 0.5
@export_range(0.0, 89.0, 0.1) var floor_angle_deg: float = 46.0

func _ready() -> void:
	add_to_group("Player")
	GameManager.set_start(global_position)
	velocity = Vector3.ZERO
	gravity = 0.0
	previously_floored = false
	jump_single = true
	jump_double = true
	controls_disabled = false
	call_deferred("_do_respawn")
	_apply_floor_tuning()

func _physics_process(delta: float) -> void:
	# 1) อินพุตแนวนอน
	var input_dir := Vector3.ZERO
	if not controls_disabled:
		input_dir.x = Input.get_axis("move_left", "move_right")
		input_dir.z = Input.get_axis("move_forward", "move_back")
		input_dir = input_dir.rotated(Vector3.UP, view.rotation.y)
		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()
		if Input.is_action_just_pressed("jump") and (jump_single or jump_double):
			jump()

	# 2) สปรินต์
	is_sprinting = (not controls_disabled) and Input.is_action_pressed("sprint")
	var current_speed: float = movement_speed * (sprint_multiplier if is_sprinting else 1.0)
	var desired_h: Vector3 = input_dir * current_speed

	# 3) บวกระยะที่แท่นขยับ (เฉพาะ XZ) ก่อนคิดฟิสิกส์เฟรมนี้
	_apply_platform_displacement_pre()

	# 4) ตั้งความเร็วแนวนอน
	if is_on_floor():
		velocity.x = desired_h.x
		velocity.z = desired_h.z
	else:
		var rate: float = 3.0 * delta
		var hv := Vector2(velocity.x, velocity.z).lerp(Vector2(desired_h.x, desired_h.z), rate)
		velocity.x = hv.x
		velocity.z = hv.y

	# 5) แรงโน้มถ่วง
	if not controls_disabled:
		gravity += 25.0 * delta
	if gravity > 0.0 and is_on_floor():
		jump_single = true
		gravity = 0.0
	velocity.y = -gravity

	# 6) ฟิสิกส์ชน
	move_and_slide()

	# 7) อัปเดตแพลตฟอร์มที่เหยียบอยู่ (ไว้ใช้เฟรมถัดไป)
	_update_attached_platform()

	# 8) หมุนโมเดล & เอฟเฟกต์/อนิเมชัน (หลังได้ velocity เฟรมนี้)
	if Vector2(velocity.z, velocity.x).length() > 0.0:
		rotation_direction = Vector2(velocity.z, velocity.x).angle()
	rotation.y = lerp_angle(rotation.y, rotation_direction, delta * 10.0)
	handle_effects(delta)

	# 9) ตกเหว = รีสปอน
	if not is_being_sucked and global_position.y < fall_kill_y:
		respawn()

	# 10) squash & stretch เล็กน้อย
	model.scale = model.scale.lerp(Vector3(1, 1, 1), delta * 10.0)
	if is_on_floor() and gravity > 2.0 and not previously_floored:
		model.scale = Vector3(1.25, 0.75, 1.25)
		Audio.play("res://sounds/land.ogg")
	previously_floored = is_on_floor()

# ---- Effects / Anim -------------------------------------------------
func handle_effects(_delta: float) -> void:
	particles_trail.emitting = false
	# ลบการ pause/unpause ออก เพื่อไม่ให้เว็บรีสตาร์ทเสียงทุกเฟรม
	# sound_footsteps.stream_paused = true  # << เอาออก

	if is_on_floor():
		var horizontal_velocity: Vector2 = Vector2(velocity.x, velocity.z)
		var speed_len: float = horizontal_velocity.length()
		var current_speed_local: float = movement_speed * (sprint_multiplier if is_sprinting else 1.0)
		var speed_factor: float = speed_len / maxf(0.001, current_speed_local)

		if speed_factor > 0.05:
			if is_sprinting and animation.has_animation("run"):
				if animation.current_animation != "run": animation.play("run", 0.1)
			else:
				if animation.current_animation != "walk": animation.play("walk", 0.1)

			if speed_factor > 0.75:
				particles_trail.emitting = true
		else:
			if animation.current_animation != "idle":
				animation.play("idle", 0.1)

		if animation.current_animation == "walk" or animation.current_animation == "run":
			animation.speed_scale = clampf(speed_factor, 0.6, 1.6)
		else:
			animation.speed_scale = 1.0

		# เล่นเสียงฝีเท้าแบบ one-shot ตามจังหวะ
		_update_footsteps(_delta, speed_len)
	elif animation.current_animation != "jump":
		animation.play("jump", 0.1)

# ---- Jump / Gravity -------------------------------------------------
func jump() -> void:
	Audio.play("res://sounds/jump.ogg")
	gravity = -jump_strength
	model.scale = Vector3(0.5, 1.5, 0.5)
	if jump_single:
		jump_single = false
		jump_double = true
	else:
		jump_double = false

# ---- Respawn --------------------------------------------------------
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
	var p := GameManager.get_respawn_position()
	global_position = p + Vector3.UP * 0.2
	respawned.emit()

# ---- Helpers --------------------------------------------------------
func set_controls_disabled(v: bool) -> void:
	controls_disabled = v

func set_sucked_state(v: bool) -> void:
	is_being_sucked = v
	controls_disabled = v
	if v:
		gravity = 0.0
		velocity = Vector3.ZERO

func _apply_floor_tuning() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	up_direction = Vector3.UP
	floor_snap_length = floor_snap_len
	floor_max_angle = deg_to_rad(floor_angle_deg)
	floor_stop_on_slope = true
	floor_constant_speed = true
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_ADD_VELOCITY

# ---- Moving platform (displacement-carry แบบแข็ง) -------------------
func _apply_platform_displacement_pre() -> void:
	if _attached_platform == null:
		return
	var disp := Vector3.ZERO
	if _attached_platform.has_method("get_frame_displacement"):
		disp = _attached_platform.get_frame_displacement()
	elif "last_displacement" in _attached_platform:
		disp = _attached_platform.last_displacement
	if disp != Vector3.ZERO:
		global_position += Vector3(disp.x, 0.0, disp.z)  # เฉพาะ XZ

func _update_attached_platform() -> void:
	# เรียกหลัง move_and_slide(): เก็บแพลตฟอร์มที่ยืนอยู่ไว้ใช้เฟรมถัดไป
	_attached_platform = _get_floor_platform()

func _get_floor_platform() -> Node3D:
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c and c.get_normal().y > 0.55:
			var n := c.get_collider()
			if n is Node3D and n.is_in_group("MovingPlatform"):
				return n
	return null

func add_coins(amount: int = 1) -> void:
	coins += amount
	coin_collected.emit(coins)
	# ถ้ามีเสียงเก็บเหรียญ:
	if Engine.has_singleton("Audio"):
		Audio.play("res://sounds/coin.ogg")

# รองรับโค้ดเก่า/โค้ดอื่นที่ยังเรียก collect_coin()
func collect_coin(amount: int = 1) -> void:
	add_coins(amount)
	
func _update_footsteps(delta: float, speed_len: float) -> void:
	# ไม่อยู่พื้น/โดนล็อกคอนโทรล/ช้ามาก → ไม่ยิงเสียง
	if not is_on_floor() or controls_disabled or speed_len < 0.2:
		_footstep_timer = 0.0
		return

	# เลือกช่วงตามโหมดเดิน/วิ่ง แล้วปรับตามความเร็วจริงเล็กน้อย
	var base_interval: float = (footstep_interval_run if is_sprinting else footstep_interval_walk)
	var current_speed_local: float = movement_speed * (sprint_multiplier if is_sprinting else 1.0)
	var speed_ratio: float = speed_len / maxf(0.001, current_speed_local)
	var interval: float = maxf(footstep_min_interval, base_interval * (1.0 - 0.25 * (speed_ratio - 1.0)))

	# เคาท์ดาวน์จังหวะ
	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return

	# one-shot พร้อมสุ่ม pitch เล็กน้อยให้ไม่ซ้ำกัน
	var pitch: float = clampf(1.0 + (randf() * 0.10 - 0.05), 0.85, 1.3)
	sound_footsteps.pitch_scale = pitch
	sound_footsteps.play()

	_footstep_timer = interval
