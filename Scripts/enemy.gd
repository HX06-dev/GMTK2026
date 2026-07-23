extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)

enum State { MOVING, ATTACKING }
enum TargetMode { IGNORE_OBSTACLES, AGGRO_OBSTACLES }

@export var max_health: float
@export var move_speed: float
@export var attack_damage: float # per second, continuous DPS
@export var attack_range: float
@export var target_mode: TargetMode = TargetMode.IGNORE_OBSTACLES
@export var reward: int # time given on enemy death

var current_health: float
var state: State = State.MOVING
var current_target: Node2D = null  # the base, or a wall if not possible
var main_target: Node2D = null      # the "real" goal
var nearby_obstacles: Array[Node2D] = []

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_area: Area2D = $AttackArea
@onready var obstacle_detector: Area2D = $ObstacleDetector
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	current_target = main_target
	if current_target:
		nav_agent.target_position = current_target.global_position

	if target_mode == TargetMode.AGGRO_OBSTACLES:
		obstacle_detector.body_entered.connect(_on_obstacle_detected)
		obstacle_detector.body_exited.connect(_on_obstacle_lost)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(current_target):
		_retarget()
		return

	var dist_to_target = global_position.distance_to(current_target.global_position)

	if dist_to_target <= attack_range:
		state = State.ATTACKING
		velocity = Vector2.ZERO
		_attack(delta)
	else:
		state = State.MOVING
		_move_toward_target()

	move_and_slide()

func _move_toward_target() -> void:
	nav_agent.target_position = current_target.global_position
	if nav_agent.is_navigation_finished():
		return
	var next_point = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_point)
	velocity = direction * move_speed

func _attack(delta: float) -> void:
	if current_target and current_target.has_method("take_damage"):
		current_target.take_damage(attack_damage * delta)

func _on_obstacle_detected(body: Node2D) -> void:
	if not body.is_in_group("towers") and not body.is_in_group("walls"):
		return
	nearby_obstacles.append(body)
	# Aggro logic: switch target to the obstacle if it's blocking/close
	_retarget()

func _on_obstacle_lost(body: Node2D) -> void:
	nearby_obstacles.erase(body)

func _retarget() -> void:
	nearby_obstacles = nearby_obstacles.filter(func(o): return is_instance_valid(o))
	if target_mode == TargetMode.AGGRO_OBSTACLES and nearby_obstacles.size() > 0:
		current_target = nearby_obstacles[0]  # or closest, see below
	else:
		current_target = main_target

func take_damage(amount: float) -> void:
	current_health -= amount
	health_bar.value = current_health
	if current_health <= 0:
		die()

func die() -> void:
	died.emit(self)
	queue_free()
