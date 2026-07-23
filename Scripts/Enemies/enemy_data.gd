extends Resource
class_name EnemyData

@export var enemy_name: String = "Basic Enemy"
@export var max_health: float = 50.0
@export var move_speed: float = 100.0
@export var attack_damage: float = 5.0
@export var attack_range: float = 40.0
@export var obstacle_detect_range: float = 100.0
@export var reward: int = 10
@export var sprite_frames: SpriteFrames    # <-- replaces `sprite: Texture2D`
@export var targeting_strategy: TargetingStrategy
