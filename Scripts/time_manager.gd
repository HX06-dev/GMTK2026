extends Node
class_name TimeManager

@export var startTime: int = 100
@export var paused: bool = false
var timeElapsed: float = 0
static var timeModifications: int = 0

func _physics_process(delta: float):
	if paused:
		return
	timeElapsed += delta
	var timeLeft: int = floor(startTime-timeElapsed+timeModifications)
	print("Time left: ", timeLeft)

static func addTime(amount: int):
	timeModifications += amount

static func spendTime(amount: int):
	timeModifications -= amount
