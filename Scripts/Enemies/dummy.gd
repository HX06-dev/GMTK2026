extends Node2D

func _ready() -> void:
	add_to_group("enemies")

func take_damage(amount: float) -> void:
	print("dummy enemy took ", amount, " damage")
