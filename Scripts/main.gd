extends Node2D

@export var building: bool = false

func _process(delta: float):
	var towers = $Towers.get_children()
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			print("Left mouse button released")
