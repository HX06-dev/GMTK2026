extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)

enum State { MOVING, ATTACKING, DYING }

@export var enemy_data: EnemyData
@export var main_target: Node2D

var max_health: float = 0.0
var current_health: float = 0.0
var move_speed: float = 0.0
var attack_damage: float = 0.0
var attack_range: float = 0.0
var obstacle_detect_range: float = 0.0
var reward: int = 0
var targeting_strategy: TargetingStrategy

var current_target: Node2D = null
var nearby_obstacles: Array[Node2D] = []
var state: State = State.MOVING
var _death_queued: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_area: Area2D = $AttackArea
@onready var obstacle_detector: Area2D = $ObstacleDetector
@onready var obstacle_collision_shape: CollisionShape2D = $ObstacleDetector/CollisionShape2Db
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	add_to_group("enemies")
	_load_enemy_data()
	_configure_navigation()
	_connect_signals()
	_refresh_target()
	_update_health_bar()
	_set_state(State.MOVING)


func _load_enemy_data() -> void:
	if not enemy_data:
		push_warning("Enemy has no EnemyData assigned: %s" % name)
		return

	max_health = enemy_data.max_health
	current_health = max_health
	move_speed = enemy_data.move_speed
	attack_damage = enemy_data.attack_damage
	attack_range = enemy_data.attack_range
	obstacle_detect_range = enemy_data.obstacle_detect_range
	reward = enemy_data.reward
	targeting_strategy = enemy_data.targeting_strategy

	if not targeting_strategy:
		targeting_strategy = TargetingStrategy.new()

	if enemy_data.sprite_frames:
		animated_sprite.sprite_frames = enemy_data.sprite_frames

	if obstacle_collision_shape.shape is CircleShape2D:
		obstacle_collision_shape.shape.radius = obstacle_detect_range


func _configure_navigation() -> void:
	nav_agent.avoidance_enabled = true
	nav_agent.velocity_computed.connect(_on_velocity_computed)


func _connect_signals() -> void:
	obstacle_detector.area_entered.connect(_on_obstacle_detected)
	obstacle_detector.area_exited.connect(_on_obstacle_lost)
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(_delta: float) -> void:
	if state == State.DYING:
		return

	_refresh_target()

	if not is_instance_valid(current_target):
		_stop_motion()
		return

	nav_agent.target_position = current_target.global_position

	var distance_to_target = global_position.distance_to(current_target.global_position)
	if distance_to_target <= attack_range:
		_set_state(State.ATTACKING)
		_stop_motion()
		_attack(_delta)
		return

	_set_state(State.MOVING)
	_move_toward_target()


func _move_toward_target() -> void:
	if nav_agent.is_navigation_finished():
		_stop_motion()
		return

	var next_point = nav_agent.get_next_path_position()
	var desired_velocity = global_position.direction_to(next_point) * move_speed
	desired_velocity = _apply_local_avoidance(desired_velocity)
	nav_agent.set_velocity(desired_velocity)


func _apply_local_avoidance(desired_velocity: Vector2) -> Vector2:
	if desired_velocity == Vector2.ZERO:
		return desired_velocity

	var closest_obstacle = get_closest_obstacle()
	if not closest_obstacle:
		return desired_velocity

	var to_obstacle = global_position - closest_obstacle.global_position
	var distance = max(to_obstacle.length(), 1.0)
	var radius = max(obstacle_detect_range, 1.0)
	var strength = clamp(1.0 - distance / radius, 0.0, 1.0)
	if strength <= 0.0:
		return desired_velocity

	var path_direction = desired_velocity.normalized()
	var away_from_obstacle = to_obstacle.normalized()
	var side_step = Vector2(-away_from_obstacle.y, away_from_obstacle.x)
	if side_step.dot(path_direction) < 0.0:
		side_step = -side_step

	var combined_direction = (path_direction + away_from_obstacle * (1.5 * strength) + side_step * (0.75 * strength)).normalized()
	if combined_direction == Vector2.ZERO:
		return desired_velocity

	return combined_direction * move_speed


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
	_flip_sprite_toward_movement()


func _refresh_target() -> void:
	var new_target = targeting_strategy.select_target(self)
	if new_target != current_target:
		current_target = new_target


func _set_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state
	match state:
		State.MOVING:
			_play_animation("walk")
		State.ATTACKING:
			_play_animation("attack")
		State.DYING:
			_play_death()


func _play_animation(anim_name: String) -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)


func _play_death() -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		return

	queue_free()


func _flip_sprite_toward_movement() -> void:
	if velocity.x != 0.0:
		animated_sprite.flip_h = velocity.x < 0.0


func _attack(delta: float) -> void:
	if current_target and current_target.has_method("take_damage"):
		current_target.take_damage(attack_damage * delta)


func take_damage(amount: float) -> void:
	if state == State.DYING:
		return

	current_health = max(current_health - amount, 0.0)
	_update_health_bar()
	if current_health <= 0.0:
		die()


func die() -> void:
	if state == State.DYING:
		return

	if is_instance_valid(TimeManager) and reward > 0:
		TimeManager.addTime(reward)

	died.emit(self)
	_set_state(State.DYING)
	_stop_motion()


func _stop_motion() -> void:
	velocity = Vector2.ZERO
	nav_agent.set_velocity(Vector2.ZERO)


func _on_animation_finished() -> void:
	if state == State.DYING:
		queue_free()


func _on_obstacle_detected(area: Area2D) -> void:
	var obstacle = _resolve_obstacle(area)
	if obstacle and not nearby_obstacles.has(obstacle):
		nearby_obstacles.append(obstacle)


func _on_obstacle_lost(area: Area2D) -> void:
	var obstacle = _resolve_obstacle(area)
	if obstacle:
		nearby_obstacles.erase(obstacle)


func _resolve_obstacle(area: Area2D) -> Node2D:
	var parent_node = area.get_parent()
	return parent_node if parent_node is Node2D else null


func get_closest_obstacle() -> Node2D:
	nearby_obstacles = nearby_obstacles.filter(func(o): return is_instance_valid(o))
	if nearby_obstacles.is_empty():
		return null

	return nearby_obstacles.reduce(func(closest: Node2D, obstacle: Node2D):
		if not closest:
			return obstacle

		var closest_distance = global_position.distance_to(closest.global_position)
		var obstacle_distance = global_position.distance_to(obstacle.global_position)
		return obstacle if obstacle_distance < closest_distance else closest
	)


func is_path_blocked() -> bool:
	if not is_instance_valid(main_target):
		return false

	var query = PhysicsRayQueryParameters2D.create(global_position, main_target.global_position)
	query.collision_mask = _get_wall_collision_mask()
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func get_blocking() -> Node2D:
	if not is_instance_valid(main_target):
		return null

	var query = PhysicsRayQueryParameters2D.create(global_position, main_target.global_position)
	query.collision_mask = _get_wall_collision_mask()
	var result = get_world_2d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null

	var collider = result.collider
	if collider is Area2D and collider.get_parent() is Node2D:
		return collider.get_parent()
	return collider if collider is Node2D else null


func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health


func _get_wall_collision_mask() -> int:
	return (1 << 1) | (1 << 2)
