extends Node2D

@onready var placer: TowerPlacer = $TowerPlacer
@onready var machine_gun_data: TowerData = preload("res://Data/machine_gun.tres")


func _ready() -> void:
	placer.select_tower(machine_gun_data)
