extends Control
@onready var coins_label: Label = $Coins

func _ready() -> void:
	coins_label.text = str(GameManager.coins)
	if not GameManager.coins_changed.is_connected(_on_coins_changed):
		GameManager.coins_changed.connect(_on_coins_changed)

func _on_coins_changed(total: int) -> void:
	coins_label.text = str(total)

# ถ้ายังอยากรองรับสัญญาณจาก Player เดิมไว้ด้วยก็ได้
func _on_coin_collected(total: int) -> void:
	coins_label.text = str(total)
