# ResultArea.gd
extends Node3D

@onready var area: Area3D = $Area3D
@export var result_scene: PackedScene = preload("res://scenes/result.tscn")

var _triggered := false

func _ready() -> void:
	if not area.body_entered.is_connected(_on_area_body_entered):
		area.body_entered.connect(_on_area_body_entered)

func _on_area_body_entered(body: Node3D) -> void:
	if _triggered or not body.is_in_group("Player"):
		return
	_triggered = true
	area.set_deferred("monitoring", false)

	if Engine.has_singleton("GameManager"):
		GameManager.result_state = "victory"   # <<<< ส่งสัญญาณว่าชนะ

	get_tree().call_deferred("change_scene_to_packed", result_scene)
