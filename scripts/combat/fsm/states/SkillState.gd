extends State
class_name SkillState
## Cooldown'u dolan normal aktif yetenek: 0.4sn cast, infaz, Idle'a donus.
## Cooldown giriste tuketilir (cast bozulsa bile harcanmis sayilir).

const CAST_TIME := 0.4

var active_skill_data: SkillData
var _cast_tween: Tween

func enter() -> void:
	unit.velocity = Vector2.ZERO
	unit.play_animation("attack")
	if active_skill_data == null:
		state_machine.change_state("Idle")
		return
	unit.set_skill_on_cooldown(active_skill_data)
	unit.stats_component.add_energy(active_skill_data.energy_generated)
	unit.flash_hit()
	unit.visual.pivot_offset = unit.visual.size * 0.5
	_cast_tween = create_tween()
	_cast_tween.tween_property(unit.visual, "scale", Vector2(1.15, 1.15), 0.15)
	_cast_tween.tween_property(unit.visual, "scale", Vector2.ONE, 0.25)
	await get_tree().create_timer(CAST_TIME).timeout
	if state_machine.current_state != self:
		return
	SkillExecutor.apply_skill(unit, active_skill_data, SkillExecutor.resolve_targets(unit, active_skill_data))
	state_machine.change_state("Idle")

func exit() -> void:
	if _cast_tween != null and _cast_tween.is_valid():
		_cast_tween.kill()
	if unit != null and is_instance_valid(unit):
		unit.visual.scale = Vector2.ONE
	active_skill_data = null
