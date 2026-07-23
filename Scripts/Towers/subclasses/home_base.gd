extends Tower


func _ready() -> void:
	add_to_group("base")
	expiry.expires = false

	if not tower_data:
		push_warning("Tower has no TowerData assigned: %s" % name)
		return

	_apply_tower_data()
	_setup_navigation_obstacle()
	#expiry.expired.connect(_on_expired)
	#expiry.time_changed.connect(_on_time_changed)

	#_play_top_animation("idle")


func _apply_tower_data() -> void:

	if tower_data.base_texture:
		base_sprite.texture = tower_data.base_texture

	#expiry.max_lifetime = tower_data.max_health
	#expiry.current_lifetime = tower_data.max_health
	lifetime_bar.max_value = tower_data.max_health
	lifetime_bar.value = tower_data.max_health


func _setup_navigation_obstacle() -> void:
	nav_obstacle.avoidance_enabled = true


func _process(delta: float) -> void:
	if not tower_data:
		return


func _acquire_target() -> void:
	pass


func _aim_at_target() -> void:
	pass


func _shoot() -> void:
	pass


func _play_top_animation(anim_name: String) -> void:
	pass


func _on_top_animation_finished() -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	pass


func _on_body_exited(body: Node2D) -> void:
	pass


func take_damage(amount: float) -> void:
	expiry.take_damage(amount)


func _on_expired() -> void:
	queue_free()


func _on_time_changed(current: float, max_value: float) -> void:
	#lifetime_bar.value = current
	pass
