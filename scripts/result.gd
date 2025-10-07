extends Control

@onready var retry_btn: Button = $RetryButton

func _ready() -> void:
	if not retry_btn.pressed.is_connected(_on_retry_pressed):
		retry_btn.pressed.connect(_on_retry_pressed)

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
