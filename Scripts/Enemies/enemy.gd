extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)

enum State { MOVING, ATTACKING, DYING }

# --- Data ---
@export var enemy_data: EnemyData
var main_target: Node2D

# --- Runtime stats ---
var max_health: float
var move_speed: float
var attack_damage: float
var attack_range: float
var targeting_strategy: TargetingStrategy

# --- State ---
var current_health: float
var current_target: Node2D = null
var nearby_obstacles: Array[Node2D] = []
var state: State = State.MOVING

# --- Node refs ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_area: Area2D = $AttackArea
@onready var obstacle_detector: Area2D = $ObstacleDetector
@onready var obstacle_collision_shape: CollisionShape2D = $ObstacleDetector/CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	add_to_group("enemies")
	_apply_enemy_data()

	obstacle_detector.body_entered.connect(_on_obstacle_detected)
	obstacle_detector.body_exited.connect(_on_obstacle_lost)
	animated_sprite.animation_finished.connect(_on_animation_finished)

	_retarget()
	_play_animation("walk")


func _apply_enemy_data() -> void:
	if not enemy_data:
		push_warning("Enemy has no EnemyData assigned: %s" % name)
		return

	max_health = enemy_data.max_health
	current_health = max_health
	move_speed = enemy_data.move_speed
	attack_damage = enemy_data.attack_damage
	attack_range = enemy_data.attack_range
	targeting_strategy = enemy_data.targeting_strategy

	if not targeting_strategy:
		targeting_strategy = TargetingStrategy.new()

	if enemy_data.sprite_frames:
		animated_sprite.sprite_frames = enemy_data.sprite_frames

	if obstacle_collision_shape.shape is CircleShape2D:
		obstacle_collision_shape.shape.radius = enemy_data.obstacle_detect_range

	health_bar.max_value = max_health
	health_bar.value = current_health


func _physics_process(delta: float) -> void:
	if state == State.DYING:
		return  # let death animation play out, no movement/attacking

	_retarget()

	if not is_instance_valid(current_target):
		return

	var dist = global_position.distance_to(current_target.global_position)

	if dist <= attack_range:
		_set_state(State.ATTACKING)
		velocity = Vector2.ZERO
		_attack(delta)
	else:
		_set_state(State.MOVING)
		_move_toward_target()

	move_and_slide()
	_flip_sprite_toward_movement()


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
			_play_animation("death")


func _play_animation(anim_name: String) -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)


func _flip_sprite_toward_movement() -> void:
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0


func _on_animation_finished() -> void:
	if state == State.DYING:
		queue_free()


func _move_toward_target() -> void:
	if nav_agent.is_navigation_finished():
		return
	var next_point = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_point)
	velocity = direction * move_speed


func _attack(delta: float) -> void:
	if current_target and current_target.has_method("take_damage"):
		current_target.take_damage(attack_damage * delta)


func _retarget() -> void:
	var new_target = targeting_strategy.select_target(self)
	if new_target != current_target:
		current_target = new_target
		if current_target:
			nav_agent.target_position = current_target.global_position


func take_damage(amount: float) -> void:
	current_health -= amount
	health_bar.value = current_health
	if current_health <= 0:
		die()


func die() -> void:
	if state == State.DYING:
		return
	TimeManager.addTime(enemy_data.reward)
	died.emit(self)
	_set_state(State.DYING)
	velocity = Vector2.ZERO


func _on_obstacle_detected(body: Node2D) -> void:
	if body.is_in_group("towers") or body.is_in_group("walls"):
		nearby_obstacles.append(body)


func _on_obstacle_lost(body: Node2D) -> void:
	nearby_obstacles.erase(body)


func get_closest_obstacle() -> Node2D:
	nearby_obstacles = nearby_obstacles.filter(func(o): return is_instance_valid(o))
	if nearby_obstacles.is_empty():
		return null
	return nearby_obstacles.reduce(func(closest, o):
		if not closest:
			return o
		var d1 = global_position.distance_to(closest.global_position)
		var d2 = global_position.distance_to(o.global_position)
		return o if d2 < d1 else closest
	)


func is_path_blocked_by_wall() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, main_target.global_position)
	query.collision_mask = _get_wall_collision_mask()
	var result = space_state.intersect_ray(query)
	return not result.is_empty()


func get_blocking_wall() -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, main_target.global_position)
	query.collision_mask = _get_wall_collision_mask()
	var result = space_state.intersect_ray(query)
	return result.collider if result else null


func _get_wall_collision_mask() -> int:
	return 0b0010
