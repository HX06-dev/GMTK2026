extends Node2D
class_name Tower

var health: int
var range: int
var deadzone: int
var damage: int
var firerate: float

func inRange(pos: Vector2) -> bool:
	var dist = position.distance_to(pos)
	return dist < range and dist > deadzone
	
func receiveDamage(damageTaken: int) -> void:
	health -= damageTaken
	if health <= 0:
		queue_free()
