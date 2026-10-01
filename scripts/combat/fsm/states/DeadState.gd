extends State
class_name DeadState
## Olum: dur, carpismayi kapat, hedef havuzundan ("units" grubu) cik.
## Gorsel gizleme Unit._on_died'de yapilir; burasi FSM tarafidir.

func enter() -> void:
	unit.velocity = Vector2.ZERO
	unit.play_animation("death")
	unit.collision_layer = 0
	unit.collision_mask = 0
	unit.collision_shape.set_deferred("disabled", true)
	if unit.is_in_group("units"):
		unit.remove_from_group("units")
