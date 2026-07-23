extends Node2D
class_name Tower

var tower_name: String
var damage: float
var fire_rate: float
var range: float
var projectile_scene: PackedScene
var cost: int

var enemies_in_range: Array[Node2D] = []
var current_target: Node2D = null
var time_since_last_shot: float = 0.0

@onready var range_area: Area2D = $RangeArea
@onready var collision_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var expiry: ExpiryComponent = $ExpiryComponent
@onready var lifetime_bar: ProgressBar = $LifetimeBar

func _ready() -> void:
	add_to_group("towers")
	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)
	_update_range_shape()
	expiry.expired.connect(_on_expired)
	expiry.time_changed.connect(_on_time_changed)
	lifetime_bar.max_value = expiry.max_lifetime

func _update_range_shape() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = range

func _process(delta: float) -> void:
	time_since_last_shot += delta
	_acquire_target()
	if current_target and time_since_last_shot >= 1.0 / fire_rate:
		_shoot()
		time_since_last_shot = 0.0

func _acquire_target() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	if current_target and current_target in enemies_in_range:
		return  # keep current target
	current_target = enemies_in_range[0] if enemies_in_range.size() > 0 else null

func _shoot() -> void:
	if not projectile_scene:
		return
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.setup(current_target, damage)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)

func _on_body_exited(body: Node2D) -> void:
	enemies_in_range.erase(body)
	
func take_damage(amount: float) -> void:
	expiry.take_damage(amount)

func _on_expired() -> void:
	queue_free()

func _on_time_changed(current: float, max: float) -> void:
	lifetime_bar.value = current
