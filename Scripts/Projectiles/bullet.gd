extends Area2D
class_name Bullet

@export var speed: float = 400.0
@export var lifetime: float = 3.0

var target: Node2D = null
var damage: float = 0.0
var direction: Vector2 = Vector2.RIGHT
var homing: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired)


func setup(new_target: Node2D, new_damage: float) -> void:
	target = new_target
	damage = new_damage
	if is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)
	rotation = direction.angle()


# Called by towers that want straight-line spread shots instead of homing
# (e.g. the machine gun's spread_degrees) — must be called AFTER setup()
func set_direction_override(new_direction: Vector2) -> void:
	direction = new_direction
	homing = false
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if homing and is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)
		rotation = direction.angle()

	global_position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()


func _on_lifetime_expired() -> void:
	if is_instance_valid(self):
		queue_free()
