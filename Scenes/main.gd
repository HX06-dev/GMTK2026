extends Node2D

const ArcherTower = preload("res://Scenes/Towers/Archer.tscn")
const BombTower = preload("res://Scenes/Towers/Bomb.tscn")
@export var Towers: Node2D

enum TowerType { Arhcer, Bomb }
const TowerMap: Dictionary[TowerType, PackedScene] = { TowerType.Arhcer: ArcherTower, TowerType.Bomb: BombTower}

func _ready() -> void:
	return
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			var mousePos = get_viewport().get_mouse_position()
			createTower(TowerType.Arhcer, mousePos)
			

func createTower(towerType: TowerType, pos: Vector2):
	var tower: Node2D = TowerMap[towerType].instantiate()
	tower.position = pos
	Towers.add_child(tower)
