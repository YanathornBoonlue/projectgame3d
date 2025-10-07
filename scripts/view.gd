extends Node3D

@export_group("Target")
@export var target: Node3D

@export_group("Zoom")
@export var zoom_minimum := 16.0           # ไกลสุด (ตัวเลขมาก)
@export var zoom_maximum := 4.0            # ใกล้สุด (ตัวเลขน้อย)
@export var zoom_speed   := 10.0           # สำหรับคีย์บอร์ด (ถ้าใช้)
@export var zoom_step_wheel := 1.0         # ขั้นซูมของล้อเมาส์

@export_group("Rotation")
@export var rotation_speed := 120.0        # สำหรับคีย์บอร์ด (ถ้าใช้)
@export var mouse_sensitivity := Vector2(0.2, 0.2)  # องศาต่อพิกเซล (Yaw, Pitch)
@export var pitch_min := -80.0
@export var pitch_max := -10.0
@export var capture_mouse := true          # จับเมาส์อัตโนมัติ

var camera_rotation: Vector3
var zoom := 10.0

@onready var camera: Camera3D = $Camera

func _ready() -> void:
	camera_rotation = rotation_degrees
	camera_rotation.x = clampf(camera_rotation.x, pitch_min, pitch_max)
	if capture_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process_input(true)

func _input(event: InputEvent) -> void:
	# หมุนอิสระเมื่อเมาส์ถูกจับ (กัน UI กลืน event)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mm: InputEventMouseMotion = event
		var d: Vector2 = mm.relative
		camera_rotation.y -= d.x * mouse_sensitivity.x
		camera_rotation.x -= d.y * mouse_sensitivity.y
		camera_rotation.x = clampf(camera_rotation.x, pitch_min, pitch_max)

	# ซูมด้วยล้อเมาส์
	elif event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:   zoom -= zoom_step_wheel
			MOUSE_BUTTON_WHEEL_DOWN: zoom += zoom_step_wheel
			MOUSE_BUTTON_RIGHT:
				# คลิกขวาสลับจับ/ปล่อยเมาส์ (เผื่อมีเมนู)
				if capture_mouse:
					Input.set_mouse_mode(
						Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
						else Input.MOUSE_MODE_CAPTURED
					)
		zoom = clampf(zoom, zoom_maximum, zoom_minimum)

	# กด ESC ก็สลับจับ/ปล่อยได้
	if capture_mouse and event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

func _physics_process(delta: float) -> void:
	if target:
		position = position.lerp(target.position, 4.0 * delta)

	# ไล่มุมกล้องให้เนียน
	rotation_degrees = rotation_degrees.lerp(camera_rotation, 6.0 * delta)

	# ไล่ระยะซูม
	camera.position = camera.position.lerp(Vector3(0, 0, zoom), 8.0 * delta)

	# (ยังรองรับปุ่มเดิมถ้าอยากใช้คู่กัน)
	_handle_keyboard(delta)

func _handle_keyboard(delta: float) -> void:
	var input_vec: Vector3 = Vector3.ZERO
	input_vec.y = Input.get_axis("camera_left", "camera_right")
	input_vec.x = Input.get_axis("camera_up", "camera_down")
	if input_vec.length() > 0.0:
		camera_rotation += input_vec.limit_length(1.0) * rotation_speed * delta
		camera_rotation.x = clampf(camera_rotation.x, pitch_min, pitch_max)

	var z_axis := Input.get_axis("zoom_in", "zoom_out")
	if z_axis != 0.0:
		zoom += z_axis * zoom_speed * delta
		zoom = clampf(zoom, zoom_maximum, zoom_minimum)
