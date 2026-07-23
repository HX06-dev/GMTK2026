extends Node
class_name TimeManager

@export var startTime: int = 100
@export var paused: CheckButton
@export var timeLabel: Label

var timeElapsed: float = 0
var timeLeft: int
static var timeModifications: int = 0

func _physics_process(delta: float):
	if paused.button_pressed:
		return
	timeElapsed += delta
	timeLeft = max(floor(startTime-timeElapsed+timeModifications), 0)
	timeLabel.text = "Time: " + str(timeLeft)

static func addTime(amount: int):
	timeModifications += amount

static func spendTime(amount: int):
	timeModifications -= amount
