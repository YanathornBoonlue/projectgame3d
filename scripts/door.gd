extends Node3D

@onready var area: Area3D = $Area3D
@onready var sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
	if not area.body_entered.is_connected(_on_area_3d_body_entered):
		area.body_entered.connect(_on_area_3d_body_entered)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return

	area.set_deferred("monitoring", false)

	# เล่นผ่าน Audio singleton (อยู่รอดข้ามซีน)
	if Engine.has_singleton("Audio"):
		Audio.play("res://sounds/yay_cRiHGGR.ogg")
	else:
		if sfx and sfx.stream:
			sfx.play()

	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://scenes/result.tscn")
