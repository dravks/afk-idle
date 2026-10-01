extends State
class_name StunnedState
## Sersemleme: hicbir eylem yok. BuffComponent stun bitince (baska stun
## yoksa) Idle'a dondurur; olum olursa Dead devralir.

func enter() -> void:
	unit.velocity = Vector2.ZERO
	unit.play_animation("hit")
	FloatingText.spawn_custom(unit.get_parent(), unit.position + Vector2(0, -80.0),
		"STUN!", Color("#ffd966"), 16)
	unit.flash_hit()

func physics_update(_delta: float) -> void:
	unit.velocity = Vector2.ZERO
