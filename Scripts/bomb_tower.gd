extends Tower
class_name BombTower

@export var HEALTH: int
@export var RANGE: int
@export var DEADZONE: int
@export var DAMAGE: int
@export var FIRERATE: float

func _init():
	health = HEALTH
	range = RANGE
	deadzone = DEADZONE
	damage = DAMAGE
	firerate = FIRERATE
