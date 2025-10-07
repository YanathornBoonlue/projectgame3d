extends Node3D

@export var id: StringName = &"cp_1"
@export var trigger_only_once: bool = true

@onready var area: Area3D = $Area3D
@onready var sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")

var _activated := false

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	if trigger_only_once and _activated:
		return

	_activated = true
	GameManager.set_checkpoint(global_position, &"cp_flag_1")
	
	# เล่นอนิเมชันชักธงถ้ามี
	if anim and anim.has_animation("Take 001"):
		anim.play("Take 001")

	if sfx:
		sfx.play()
