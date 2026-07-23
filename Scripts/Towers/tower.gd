extends Node2D
class_name Tower

# --- Data ---
@export var tower_data: TowerData
const rotation_speed = 1;

# --- Runtime stats (populated from tower_data in _ready) ---
var damage: float
var fire_rate: float
var attack_range: float
var projectile_scene: PackedScene

# --- Targeting/combat state ---
var enemies_in_range: Array[Node2D] = []
var current_target: Node2D = null
var time_since_last_shot: float = 0.0

# --- Node refs ---
@onready var base_sprite: Sprite2D = $BaseSprite
@onready var top_sprite: Sprite2D = $TopSprite
@onready var muzzle_point: Marker2D = $TopSprite/MuzzlePoint
@onready var range_area: Area2D = $RangeArea
@onready var collision_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var expiry: ExpiryComponent = $ExpiryComponent
@onready var lifetime_bar: ProgressBar = $LifetimeBar


func _ready() -> void:
	add_to_group("towers")
	_apply_tower_data()

	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)
	expiry.expired.connect(_on_expired)
	expiry.time_changed.connect(_on_time_changed)


func _apply_tower_data() -> void:
	if not tower_data:
		push_warning("Tower has no TowerData assigned: %s" % name)
		return

	damage = tower_data.damage
	fire_rate = tower_data.fire_rate
	attack_range = tower_data.range
	projectile_scene = tower_data.projectile_scene

	if tower_data.base_texture:
		base_sprite.texture = tower_data.base_texture
	if tower_data.top_texture:
		top_sprite.texture = tower_data.top_texture

	expiry.max_lifetime = tower_data.max_health
	expiry.current_lifetime = tower_data.max_health

	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = attack_range

	lifetime_bar.max_value = tower_data.max_health
	lifetime_bar.value = tower_data.max_health


func _process(delta: float) -> void:
	time_since_last_shot += delta
	_acquire_target()

	if current_target:
		_aim_at_target(delta)
		if time_since_last_shot >= 1.0 / fire_rate:
			_shoot()
			time_since_last_shot = 0.0


func _acquire_target() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))

	if current_target and current_target in enemies_in_range:
		return  # keep current target; swap this out for closest/strongest/etc later

	current_target = enemies_in_range[0] if enemies_in_range.size() > 0 else null


func _aim_at_target(delta: float) -> void:
	var direction = global_position.direction_to(current_target.global_position)
	var target_angle = direction.angle()
	top_sprite.rotation = lerp_angle(top_sprite.rotation, target_angle, delta * rotation_speed)


func _shoot() -> void:
	if not projectile_scene or not current_target:
		return

	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle_point.global_position
	proj.setup(current_target, damage)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)


func _on_body_exited(body: Node2D) -> void:
	enemies_in_range.erase(body)


# --- Health (expiry-based) ---

func take_damage(amount: float) -> void:
	expiry.take_damage(amount)


func _on_expired() -> void:
	queue_free()


func _on_time_changed(current: float, max_value: float) -> void:
	lifetime_bar.value = current
