extends Resource
class_name TargetingStrategy

# Returns the Node2D this enemy should be targeting right now.
# Override in subclasses. Default: always go for the base.
func select_target(enemy: Enemy) -> Node2D:
	return enemy.main_target
