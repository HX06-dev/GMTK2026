extends Node2D

@onready var placer: TowerPlacer = $TowerPlacer
@onready var machine_gun_data: TowerData = preload("res://Data/machine_gun.tres")
@onready var wall_data: TowerData = preload("res://Data/wall.tres")
@onready var home_base_data: TowerData = preload("res://Data/home_base.tres")


func _ready() -> void:
	placer.select_tower(home_base_data)
