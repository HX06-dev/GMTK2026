extends Tower
class_name MachineGunTower

@export var spin_up_time: float = 0.6
@export var max_heat: float = 100.0
@export var heat_per_shot: float = 8.0
@export var heat_cooldown_rate: float = 25.0
@export var spread_degrees: float = 6.0

var spin_up_progress: float = 0.0
var heat: float = 0.0
var overheated: bool = false
var using_muzzle_a: bool = true  # tracks which barrel fires next

@onready var muzzle_point_a: Marker2D = $TopSprite/MuzzlePoint
@onready var muzzle_point_b: Marker2D = $TopSprite/MuzzlePoint2


func _process(delta: float) -> void:
	time_since_last_shot += delta
	_acquire_target()

	if current_target:
		_aim_at_target(delta)
		_handle_spin_up(delta)
	else:
		spin_up_progress = 0.0

	_handle_heat(delta)


func _handle_spin_up(delta: float) -> void:
	if overheated:
		return

	spin_up_progress = min(spin_up_progress + delta, spin_up_time)

	var spun_up = spin_up_progress >= spin_up_time
	if spun_up and time_since_last_shot >= 1.0 / fire_rate:
		_shoot()
		time_since_last_shot = 0.0


func _handle_heat(delta: float) -> void:
	if overheated:
		heat = max(heat - heat_cooldown_rate * delta, 0.0)
		if heat <= 0.0:
			overheated = false
		return

	heat = max(heat - heat_cooldown_rate * 0.3 * delta, 0.0)


func _shoot() -> void:
	if not projectile_scene or not current_target:
		return

	heat += heat_per_shot
	if heat >= max_heat:
		overheated = true

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
