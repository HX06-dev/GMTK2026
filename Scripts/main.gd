extends Node2D

@export var building: bool = false
@onready var ground: TileMapLayer = $Ground

#func _process(delta: float):
	#var towers = $Towers.get_children()
	
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			var tile = ground.local_to_map(get_global_mouse_position())
			var tilepos = ground.map_to_local(tile)
			print(tile, tilepos)
