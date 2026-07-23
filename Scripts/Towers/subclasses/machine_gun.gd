extends Tower
class_name MachineGunTower

@export var spread_degrees: float = 6.0

var using_muzzle_a: bool = true  # tracks which barrel fires next

@onready var muzzle_point_a: Marker2D = $TopSprite/MuzzlePoint
@onready var muzzle_point_b: Marker2D = $TopSprite/MuzzlePoint2


func _shoot() -> void:
	if not projectile_scene or not current_target:
		return

	_play_top_animation("fire")

	var active_muzzle: Marker2D = muzzle_point_a if using_muzzle_a else muzzle_point_b
	using_muzzle_a = not using_muzzle_a  # flip for next shot

	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = active_muzzle.global_position

	if proj.has_method("set_direction_override"):
		var base_dir = active_muzzle.global_position.direction_to(current_target.global_position)
		var spread_rad = deg_to_rad(randf_range(-spread_degrees, spread_degrees))
		var spread_dir = base_dir.rotated(spread_rad)
		proj.set_direction_override(spread_dir)

	proj.setup(current_target, damage)
