extends CharacterBody3D
signal respawned 
signal coin_collected

@export_subgroup("Components")
@export var view: Node3D

@export var fall_kill_y: float = -20.0  # ตกเกินนี้ให้ตาย/เกิดใหม่
@export_subgroup("Properties")
<<<<<<< Updated upstream
@export var movement_speed = 5
@export var jump_strength = 7
=======
@export var movement_speed: float = 250.0   # ความเร็วเดินปกติ
@export var sprint_speed: float = 420.0     # ความเร็วตอนกดวิ่ง (SPRINT)
@export var jump_strength: float = 7.0

# --- Combat ---
@export_subgroup("Combat")
@export var max_hp: int = 3
@export var invuln_duration: float = 0.6     # เวลาฟื้นตัว/ไร้เทียมทาน
@export var hit_stun_duration: float = 0.25  # เวลาชะงัก
@export var knockback_force: float = 9.0     # แรงน็อคแบ็กพื้นฐาน
>>>>>>> Stashed changes

var _attached_platform: Node3D = null
var movement_velocity: Vector3
var rotation_direction: float
var gravity := 0.0
var is_being_sucked := false
var previously_floored := false

<<<<<<< Updated upstream

var jump_single = true
var jump_double = true
=======
var jump_single := true
var jump_double := true
>>>>>>> Stashed changes
var controls_disabled := false
var coins := 0

var hp: int
var _invuln := false

@onready var particles_trail = $ParticlesTrail
@onready var sound_footsteps = $SoundFootsteps
@onready var model = $Fish
@onready var animation = $Fish/AnimationPlayer

<<<<<<< Updated upstream
@export_range(0.0, 2.0, 0.01) var floor_snap_len: float = 0.25  # 0.25–0.5 กำลังดี
@export_range(0.0, 89.0, 0.1) var floor_angle_deg: float = 46.0

=======
>>>>>>> Stashed changes
func _ready() -> void:
	add_to_group("Player")
	coins = GameManager.coins   # ซิงก์ยอดจาก GameManager เมื่อเข้าเลเวลใหม่
	GameManager.set_start(global_position)  # ส่งตำแหน่งเริ่ม
	velocity = Vector3.ZERO
	gravity = 0.0
	previously_floored = false
	jump_single = true
	jump_double = true
	controls_disabled = false

	# combat init
	hp = max_hp
	_invuln = false

	call_deferred("_do_respawn") 
	_apply_floor_tuning()
# Functions
func _physics_process(delta: float) -> void:
	# Handle functions
	handle_controls(delta)
	handle_gravity(delta)
	handle_effects(delta)

	# Movement
<<<<<<< Updated upstream

	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.z = Input.get_axis("move_forward", "move_back")
	input_dir = input_dir.rotated(Vector3.UP, view.rotation.y)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	# 2) บวก "ระยะที่แท่นขยับในเฟรมนี้" เข้าตำแหน่งผู้เล่น (เฉพาะ XZ) **ก่อน** move_and_slide()
	_apply_platform_displacement_pre()

	# 3) ตั้งความเร็วแนวนอนของผู้เล่น
	var desired_h: Vector3 = input_dir * float(movement_speed)
	if is_on_floor():
		velocity.x = desired_h.x
		velocity.z = desired_h.z
	else:
		var rate: float = 3.0 * delta
		var hv := Vector2(velocity.x, velocity.z).lerp(Vector2(desired_h.x, desired_h.z), rate)
		velocity.x = hv.x
		velocity.z = hv.y

	# 4) แรงโน้มถ่วงเดิม
	velocity.y = -gravity

=======
	var applied_velocity: Vector3
	applied_velocity = velocity.lerp(movement_velocity, delta * 10.0)
	applied_velocity.y = -gravity
	velocity = applied_velocity
>>>>>>> Stashed changes
	move_and_slide()
	# Rotation
	if Vector2(velocity.z, velocity.x).length() > 0.0:
		rotation_direction = Vector2(velocity.z, velocity.x).angle()
	rotation.y = lerp_angle(rotation.y, rotation_direction, delta * 10.0)

	# Falling/respawning
	if not is_being_sucked and global_position.y < fall_kill_y:
		respawn()

	# Animation for scale (jumping and landing)
	model.scale = model.scale.lerp(Vector3(1, 1, 1), delta * 10.0)

	# Animation when landing
	if is_on_floor() and gravity > 2.0 and !previously_floored:
		model.scale = Vector3(1.25, 0.75, 1.25)
		Audio.play("res://sounds/land.ogg")
	previously_floored = is_on_floor()

# Handle animation(s)
func handle_effects(delta: float) -> void:
	particles_trail.emitting = false
	sound_footsteps.stream_paused = true

	if is_on_floor():
<<<<<<< Updated upstream
		var horizontal_velocity = Vector2(velocity.x, velocity.z)
		var speed_factor = horizontal_velocity.length() / float(movement_speed) 
=======
		var horizontal_velocity := Vector2(velocity.x, velocity.z)
		var current_speed := sprint_speed if Input.is_action_pressed("sprint") else movement_speed
		var speed_factor := horizontal_velocity.length() / current_speed / delta

>>>>>>> Stashed changes
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
			animation.speed_scale = speed_factor
		else:
			animation.speed_scale = 1.0
	elif animation.current_animation != "jump":
		animation.play("jump", 0.1)

# Handle movement input
func handle_controls(delta: float) -> void:
	if controls_disabled:
		return

<<<<<<< Updated upstream
=======
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")

	# Fallback: ถ้า view ไม่ได้ตั้ง ให้ใช้มุมของ Player เอง (กัน view == null)
	var yaw := rotation.y
	if is_instance_valid(view):
		yaw = view.global_rotation.y
	input = input.rotated(Vector3.UP, yaw)

	if input.length() > 1.0:
		input = input.normalized()

	# --- SPRINT ---
	var current_speed := movement_speed
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	movement_velocity = input * current_speed * delta

>>>>>>> Stashed changes
	# Jumping
	if Input.is_action_just_pressed("jump"):
		if jump_single or jump_double:
			jump()

# Handle gravity
func handle_gravity(delta: float) -> void:
	if controls_disabled:
		return
	gravity += 25.0 * delta
	if gravity > 0.0 and is_on_floor():
		jump_single = true
		gravity = 0.0

# Jumping
func jump() -> void:
	Audio.play("res://sounds/jump.ogg")
	gravity = -jump_strength
	model.scale = Vector3(0.5, 1.5, 0.5)

	if jump_single:
		jump_single = false
		jump_double = true
	else:
		jump_double = false

# Collecting coins
<<<<<<< Updated upstream

func collect_coin(d):

	coins += d

=======
func collect_coin() -> void:
	coins = GameManager.add_coins(1)  # ได้ยอดรวมล่าสุดกลับมา
>>>>>>> Stashed changes
	coin_collected.emit(coins)

# === Combat: โดนตี / ตาย / ฟื้น ===
func hit(dir: Vector3, damage: int = 1, kb: float = -1.0) -> void:
	if _invuln:
		return

	if kb < 0.0:
		kb = knockback_force

	hp = max(hp - damage, 0)

	_invuln = true
	controls_disabled = true

	# น็อคแบ็ก + ดีดขึ้นเล็กน้อย
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
	# Audio.play("res://sounds/death.ogg")
	respawn()
	hp = max_hp

func heal(amount: int = 1) -> void:
	hp = clamp(hp + amount, 0, max_hp)

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
	# ดันขึ้นจากพื้นเล็กน้อยกันติด/ทะลุ
	global_position = p + Vector3.UP * 0.2
	respawned.emit()

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

	# สำคัญ 2 ตัวนี้
	floor_snap_length = floor_snap_len                       # <<< ดูดติดพื้น/แท่น
	floor_max_angle = deg_to_rad(floor_angle_deg)            # <<< มุมสูงสุดที่ยังนับว่าเป็นพื้น

	# ช่วยเรื่องไถลบนพื้นเอียง
	floor_stop_on_slope = true
	floor_constant_speed = true

	# สำคัญสำหรับแท่นที่เคลื่อนที่
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_ADD_VELOCITY

	# ให้ชนเฉพาะเลเยอร์แท่น (ถ้าจำแนก)
	# platform_floor_layers = 1 << <layer_index_of_platform>
	
func _apply_platform_displacement_pre() -> void:
	var plat := _get_floor_platform()
	if plat == null: return

	var disp := Vector3.ZERO
	if plat.has_method("get_frame_displacement"):
		disp = plat.get_frame_displacement()
	elif "last_displacement" in plat:
		disp = plat.last_displacement

	# บวกเฉพาะแนวนอน เพื่อไม่กระทบการกระโดด
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
