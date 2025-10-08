extends Control

@onready var title_label: Label = $TitleLabel          # เปลี่ยน path ให้ตรงฉากจริงถ้าอยู่ใต้ Panel
@onready var retry_btn: Button = $RetryButton

@export_file("*.tscn") var main_scene_path := "res://scenes/main.tscn"

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false

	# อ่านสถานะที่ถูกตั้งจาก GameManager
	var state := "defeat"
	if Engine.has_singleton("GameManager") and "result_state" in GameManager:
		state = str(GameManager.result_state)

	if state == "victory":
		_setup_victory_ui()
	else:
		_setup_defeat_ui()

	if not retry_btn.pressed.is_connected(_on_retry_pressed):
		retry_btn.pressed.connect(_on_retry_pressed)

func _setup_victory_ui() -> void:
	if is_instance_valid(title_label):
		title_label.text = "VICTORY!"
	if is_instance_valid(retry_btn):
		retry_btn.text = "Play Again"

func _setup_defeat_ui() -> void:
	if is_instance_valid(title_label):
		title_label.text = "Try Again"
	if is_instance_valid(retry_btn):
		retry_btn.text = "Retry"

func _on_retry_pressed() -> void:
	# เคลียร์เช็คพอยต์และรีเซ็ตสถานะ
	if Engine.has_singleton("GameManager"):
		if "clear_checkpoint" in GameManager:
			GameManager.clear_checkpoint()
		if "checkpoint_id" in GameManager:
			GameManager.checkpoint_id = &""
		if "request_fresh_start" in GameManager:
			GameManager.request_fresh_start()
		GameManager.result_state = "none"
		# ใน result.gd ปุ่ม Retry
		if Engine.has_singleton("GameManager"):
			GameManager.reset_progress()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file(main_scene_path)
