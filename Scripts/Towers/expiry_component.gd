extends Node
class_name ExpiryComponent

signal expired
signal time_changed(current: float, max: float)

@export var max_lifetime: float
var current_lifetime: float
var expires: bool = true

func _ready() -> void:
	current_lifetime = max_lifetime

func _process(delta: float) -> void:
	if not expires:
		return
	_reduce(delta)  # natural decay: 1 second per second, always running

func _reduce(amount: float) -> void:
	if current_lifetime <= 0:
		return
	current_lifetime = max(current_lifetime - amount, 0.0)
	time_changed.emit(current_lifetime, max_lifetime)
	if current_lifetime <= 0:
		expired.emit()

func take_damage(amount: float) -> void:
	_reduce(amount)  # enemy attacks stack on top of natural decay

func add_time(amount: float) -> void:
	current_lifetime = min(current_lifetime + amount, max_lifetime)
	time_changed.emit(current_lifetime, max_lifetime)
