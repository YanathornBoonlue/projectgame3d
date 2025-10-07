extends Control

@onready var retry_btn: Button = $RetryButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false

	if not retry_btn.pressed.is_connected(_on_retry_pressed):
		retry_btn.pressed.connect(_on_retry_pressed)

func _on_retry_pressed() -> void:
	# >>> เคลียร์เช็คพอยต์เพื่อให้เกิดที่จุดวาง Player
	if Engine.has_singleton("GameManager"):
		GameManager.clear_checkpoint()
		GameManager.checkpoint_id = &""   # กันเหตุผลเดิมค้าง

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GameManager.request_fresh_start()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
