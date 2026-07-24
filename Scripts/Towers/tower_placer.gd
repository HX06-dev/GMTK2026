extends Node2D
class_name TowerPlacer

@export var tile_map: TileMapLayer
@export var towers_container: Node2D
@export var preview_top: AnimatedSprite2D
@export var preview_base: Sprite2D
@export var towerSelecter: OptionButton
@export var timeManager: TimeManager

@onready var machine_gun_data: TowerData = preload("res://Data/machine_gun.tres")
@onready var wall_data: TowerData = preload("res://Data/wall.tres")
@onready var towerDataIndex = [machine_gun_data, wall_data]

var selected_tower_data: TowerData = null
var occupied_tiles: Dictionary = {}


func _ready() -> void:
	towerSelecter.item_selected.connect(_change_tower_selection)
	preview_top.visible = false
	preview_base.visible = false
	select_tower(machine_gun_data)


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

	preview_top.visible = true
	preview_top.global_position = snapped_world_pos
	preview_base.visible = true
	preview_base.global_position = snapped_world_pos
	if not _is_tile_valid(tile_coords):
		preview_base.modulate = Color(1,0.5,0.5,0.5)
		preview_top.modulate = Color(1,0.5,0.5,0.5)
	else:
		preview_base.modulate = Color(1,1,1,0.5)
		preview_top.modulate = Color(1,1,1,0.5)

func select_tower(tower_data: TowerData) -> void:
	selected_tower_data = tower_data
	preview_top.visible = true
	preview_top.sprite_frames = tower_data.top_sprite_frames
	preview_top.play("idle")
	preview_base.visible = true
	preview_base.texture = tower_data.base_texture


func cancel_placement() -> void:
	selected_tower_data = null
	preview_top.visible = false
	preview_base.visible = false


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
	TimeManager.spendTime(tower.tower_data.cost)


func _is_tile_valid(tile_coords: Vector2i) -> bool:
	if occupied_tiles.has(tile_coords):
		return false
		
	if selected_tower_data.cost > timeManager.timeLeft:
		return false

	var tile_data: TileData = tile_map.get_cell_tile_data(tile_coords)
	if not tile_data:
		return false

	return tile_data.get_custom_data("buildable") == true


func _change_tower_selection(index: int) -> void:
	select_tower(towerDataIndex[index])
