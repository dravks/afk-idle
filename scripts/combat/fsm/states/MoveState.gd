extends State
class_name MoveState
## Hedefe yurume: menzile girince Attack, hedef olurse Idle.

const BASE_MOVE_SPEED := 150.0

func enter() -> void:
	unit.play_animation("move")

func physics_update(_delta: float) -> void:
	var targeting := unit.targeting_component
	if not targeting.is_target_valid():
		state_machine.change_state("Idle")
		return
	if targeting.is_target_in_range(unit.attack_range):
		state_machine.change_state("Attack")
		return
	var target := targeting.current_target
	var direction := (target.global_position - unit.global_position).normalized()
	var speed := BASE_MOVE_SPEED * (unit.stats_component.haste / 100.0)
	unit.velocity = direction * speed
	unit.move_and_slide()
	# Yurume yonune bak (takim varsayilanini ezer; dogru davranis).
	if absf(direction.x) > 0.01:
		unit.facing.scale.x = signf(direction.x)
