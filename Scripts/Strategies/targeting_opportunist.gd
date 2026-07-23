extends TargetingStrategy
class_name TargetingOpportunist

# Attacks whichever is closer: the base, or any tower/wall in detection range.
func select_target(enemy: Enemy) -> Node2D:
	var closest_obstacle: Node2D = enemy.get_closest_obstacle()
	if not closest_obstacle:
		return enemy.main_target

	var dist_to_obstacle = enemy.global_position.distance_to(closest_obstacle.global_position)
	var dist_to_base = enemy.global_position.distance_to(enemy.main_target.global_position)

	return closest_obstacle if dist_to_obstacle < dist_to_base else enemy.main_target
