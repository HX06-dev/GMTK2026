extends TargetingStrategy
class_name TargetingBaseOnly

# Heads straight for the base. Will only attack a wall if physically
# blocked by one — never targets towers at all.
func select_target(enemy: Enemy) -> Node2D:
	if enemy.is_path_blocked_by_wall():
		var wall = enemy.get_blocking_wall()
		if wall:
			return wall
	return enemy.main_target
