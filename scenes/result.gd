extends Control

# เรียกเมื่อ scene พร้อมทำงาน
func _ready() -> void:
	# เชื่อมสัญญาณ pressed ของ RetryButton กับฟังก์ชัน _on_retry_pressed
	$RetryButton.pressed.connect(_on_retry_pressed)

# ฟังก์ชันสำหรับโหลด scene main.tscn
func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
