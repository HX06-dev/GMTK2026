extends TargetingStrategy
class_name TargetingBaseOnly

# Heads straight for the base. If a wall/tower physically blocks the path,
# retarget that blocker so it can take damage.
func select_target(enemy: Enemy) -> Node2D:
	if enemy.is_path_blocked():
		var blocked = enemy.get_blocking()
		if blocked:
			return blocked
	return enemy.main_target
