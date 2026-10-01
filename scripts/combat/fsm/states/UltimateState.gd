extends State
class_name UltimateState
## 1000 enerji tetigi: enerjiyi tuket, sinematik perdesi + ulti bandi,
## 0.6sn odaklanma, infaz, Idle'a donus. Ara durum (olum) gelirse infaz
## yapilmaz (await sonrasi mevcut durum kontrolu).

const FOCUS_TIME := 0.6
const BANNER_COLOR := Color("#ffd966")

var ultimate_data: SkillData

func enter() -> void:
	unit.velocity = Vector2.ZERO
	unit.play_animation("attack")
	ultimate_data = unit.hero_data.ultimate_skill
	if ultimate_data == null:
		state_machine.change_state("Idle")
		return
	unit.stats_component.consume_energy(unit.stats_component.max_energy)
	AudioManager.play_sfx("ultimate")
	var ucam := CameraShake.find_camera(get_tree())
	if ucam != null:
		ucam.add_trauma(0.35)
	if UltimateOverlay.active != null:
		UltimateOverlay.active.play_cinematic_focus(unit, FOCUS_TIME)
	FloatingText.spawn_custom(unit.get_parent(), unit.position + Vector2(0, -95),
		"ULTI: " + ultimate_data.skill_name + "!", BANNER_COLOR, 26)
	await get_tree().create_timer(FOCUS_TIME).timeout
	if state_machine.current_state != self:
		return
	SkillExecutor.apply_skill(unit, ultimate_data, SkillExecutor.resolve_targets(unit, ultimate_data))
	state_machine.change_state("Idle")

func exit() -> void:
	ultimate_data = null
