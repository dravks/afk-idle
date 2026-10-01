extends State
class_name IdleState
## Bekleme: hedef yoksa ara, varsa menzile gore Move/Attack'a gec.

func enter() -> void:
	unit.velocity = Vector2.ZERO
	unit.play_animation("idle")

func physics_update(_delta: float) -> void:
	if not unit.targeting_component.is_target_valid():
		unit.targeting_component.acquire_target()
	if not unit.targeting_component.is_target_valid():
		return  # tum dusmanlar olu; CombatManager (Prompt 6) sonucu okur.
	# 1) Ultimate her seyi bozar (yurume/saldiri iptal).
	if unit.stats_component.current_energy >= unit.stats_component.max_energy:
		state_machine.change_state("Ultimate")
		return
	# 2) Cooldown'u dolmus aktif yetenek (menzildeyse).
	var ready := unit.get_ready_active_skill()
	if ready != null and unit.targeting_component.is_target_in_range(_skill_range(ready)):
		if unit.try_enter_skill(ready):
			return
	# 3) Standart karar.
	if unit.targeting_component.is_target_in_range(unit.attack_range):
		state_machine.change_state("Attack")
	else:
		state_machine.change_state("Move")

## Aktif yetenegin kendi menzili de gecerli (uzun menzilli skill + yakin dovuscu).
func _skill_range(skill: SkillData) -> float:
	return maxf(unit.attack_range, skill.range)
