extends Tower
class_name LaserTower

@export var TOWER_NAME: String
@export var RANGE: int
@export var DAMAGE: int
@export var FIRE_RATE: float
@export var PROJECTILE_SCENE: PackedScene
@export var COST: int

func _init():
	attack_range = RANGE
	damage = DAMAGE
	fire_rate = FIRE_RATE
	projectile_scene = PROJECTILE_SCENE
	cost = COST
