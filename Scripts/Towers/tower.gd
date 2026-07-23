extends Node2D
class_name Tower

@export var tower_data: TowerData
@export var angle_offset: float

var damage: float
var fire_rate: float
var attack_range: float
var projectile_scene: PackedScene

var enemies_in_range: Array[Node2D] = []
var current_target: Node2D = null
var time_since_last_shot: float = 0.0

@onready var base_sprite: Sprite2D = $BaseSprite
@onready var top_sprite: AnimatedSprite2D = $TopSprite
@onready var muzzle_point: Marker2D = $TopSprite/MuzzlePoint
@onready var range_area: Area2D = $RangeArea
@onready var collision_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var nav_obstacle: NavigationObstacle2D = $NavigationObstacle2D
@onready var expiry: Node = $ExpiryComponent
@onready var lifetime_bar: ProgressBar = $LifetimeBar


func _ready() -> void:
	add_to_group("towers")

	if not tower_data:
		push_warning("Tower has no TowerData assigned: %s" % name)
		return

	_apply_tower_data()
	_setup_navigation_obstacle()

	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)
	expiry.expired.connect(_on_expired)
	expiry.time_changed.connect(_on_time_changed)
	top_sprite.animation_finished.connect(_on_top_animation_finished)

	_play_top_animation("idle")


func _apply_tower_data() -> void:
	damage = tower_data.damage
	fire_rate = tower_data.fire_rate
	attack_range = tower_data.range
	projectile_scene = tower_data.projectile_scene

	if tower_data.base_texture:
		base_sprite.texture = tower_data.base_texture
	if tower_data.top_sprite_frames:
		top_sprite.sprite_frames = tower_data.top_sprite_frames

	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = attack_range

	expiry.max_lifetime = tower_data.max_health
	expiry.current_lifetime = tower_data.max_health
	lifetime_bar.max_value = tower_data.max_health
	lifetime_bar.value = tower_data.max_health


func _setup_navigation_obstacle() -> void:
	nav_obstacle.avoidance_enabled = true


func _process(delta: float) -> void:
	if not tower_data:
		return

	time_since_last_shot += delta
	_acquire_target()

	if current_target:
		_aim_at_target()
		if time_since_last_shot >= 1.0 / fire_rate:
			_shoot()
			time_since_last_shot = 0.0


func _acquire_target() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))

	if current_target and current_target in enemies_in_range:
		return

	current_target = enemies_in_range[0] if enemies_in_range.size() > 0 else null


func _aim_at_target() -> void:
	var direction = global_position.direction_to(current_target.global_position)
	var offset = deg_to_rad(angle_offset)
	top_sprite.rotation = direction.angle() + offset


func _shoot() -> void:
	if not projectile_scene or not current_target:
		return

	_play_top_animation("shoot")

	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle_point.global_position
	proj.setup(current_target, damage)


func _play_top_animation(anim_name: String) -> void:
	if top_sprite.sprite_frames and top_sprite.sprite_frames.has_animation(anim_name):
		if top_sprite.animation != anim_name:
			top_sprite.play(anim_name)


func _on_top_animation_finished() -> void:
	if top_sprite.animation == "shoot":
		_play_top_animation("idle")


func _on_body_entered(body: Node2D) -> void:
	print("body entered range: ", body.name, " in enemies group: ", body.is_in_group("enemies"))
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)


func _on_body_exited(body: Node2D) -> void:
	enemies_in_range.erase(body)


func take_damage(amount: float) -> void:
	expiry.take_damage(amount)


func _on_expired() -> void:
	queue_free()


func _on_time_changed(current: float, max_value: float) -> void:
	lifetime_bar.value = current
