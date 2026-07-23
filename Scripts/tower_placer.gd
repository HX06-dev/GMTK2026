extends Node2D
class_name TowerPlacer

@export var tile_map: TileMapLayer
@export var towers_container: Node2D
@export var preview: Node2D

var selected_tower_data: TowerData = null
var occupied_tiles: Dictionary = {}


func _ready() -> void:
	preview.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not selected_tower_data:
		return

	if event is InputEventMouseButton and event.pressed:
		print("click detected, button: ", event.button_index)
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_tower()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_placement()


func _process(_delta: float) -> void:
	if not selected_tower_data:
		return

	var mouse_pos = get_global_mouse_position()
	var tile_coords = tile_map.local_to_map(tile_map.to_local(mouse_pos))
	var snapped_world_pos = tile_map.to_global(tile_map.map_to_local(tile_coords))

	preview.visible = true
	preview.global_position = snapped_world_pos
	preview.modulate = Color.WHITE if _is_tile_valid(tile_coords) else Color(1, 0.3, 0.3, 0.6)


func select_tower(tower_data: TowerData) -> void:
	selected_tower_data = tower_data
	preview.visible = true


func cancel_placement() -> void:
	selected_tower_data = null
	preview.visible = false


func _try_place_tower() -> void:
	var mouse_pos = get_global_mouse_position()
	var tile_coords = tile_map.local_to_map(tile_map.to_local(mouse_pos))
	print("trying to place at tile: ", tile_coords, " valid: ", _is_tile_valid(tile_coords))

	if not _is_tile_valid(tile_coords):
		return

	_place_tower(tile_coords)


func _place_tower(tile_coords: Vector2i) -> void:
	var tower_scene: PackedScene = selected_tower_data.tower_scene
	var tower: Tower = tower_scene.instantiate()

	tower.tower_data = selected_tower_data
	towers_container.add_child(tower)
	tower.global_position = tile_map.to_global(tile_map.map_to_local(tile_coords))

	occupied_tiles[tile_coords] = tower
	tower.tree_exited.connect(func(): occupied_tiles.erase(tile_coords))

	cancel_placement()


func _is_tile_valid(tile_coords: Vector2i) -> bool:
	if occupied_tiles.has(tile_coords):
		return false

	var tile_data: TileData = tile_map.get_cell_tile_data(tile_coords)
	if not tile_data:
		return false

	return tile_data.get_custom_data("buildable") == true
