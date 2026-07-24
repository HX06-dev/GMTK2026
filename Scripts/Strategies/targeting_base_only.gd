extends TargetingStrategy
class_name TargetingBaseOnly

# Heads straight for the base. Will only attack a wall if physically
# blocked by one — never targets towers at all.
func select_target(enemy: Enemy) -> Node2D:
	if enemy.is_path_blocked():
		var blocked = enemy.get_blocking()
		if blocked:
			return blocked
	return enemy.main_target
