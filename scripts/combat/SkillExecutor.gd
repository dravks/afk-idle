extends RefCounted
class_name SkillExecutor
## Yetenek cozumu paylasilan yardimci: SkillState ve UltimateState ayni
## kodu kullanir (hedef cozme + hasar/iyilesme uygulama).
##
## Kural: ALL_ALLIES / SELF -> DESTEK (ATK * damage_multiplier kadar iyilesme).
## Diger kurallar -> HASAR (ATK * damage_multiplier ham guc).
## `applied_buffs` henuz uygulanmaz: buff runtime sistemi ayri prompt'ta
## gelecek; veri alanda sakli durur.

const HEAL_COLOR := Color("#5fbf5f")

static func resolve_targets(caster: Unit, skill: SkillData) -> Array[Unit]:
	var out: Array[Unit] = []
	if caster == null or not is_instance_valid(caster) or skill == null:
		return out
	var tree := caster.get_tree()
	if tree == null:
		return out
	match skill.target_rule:
		GlobalEnums.TargetRule.ALL_ENEMIES:
			for node in tree.get_nodes_in_group("units"):
				var u := node as Unit
				if u != null and u.team != caster.team and _alive(u):
					out.append(u)
		GlobalEnums.TargetRule.ALL_ALLIES:
			for node in tree.get_nodes_in_group("units"):
				var u := node as Unit
				if u != null and u.team == caster.team and _alive(u):
					out.append(u)
		GlobalEnums.TargetRule.SELF:
			out.append(caster)
		_:
			var t := caster.targeting_component.current_target
			if t == null or not caster.targeting_component.is_target_valid():
				t = caster.targeting_component.acquire_target(skill.target_rule)
			if t != null:
				out.append(t)
	return out

static func apply_skill(caster: Unit, skill: SkillData, targets: Array[Unit]) -> void:
	if caster == null or not is_instance_valid(caster) or skill == null:
		return
	if targets.is_empty():
		return
	var atk: float = caster.stats_component.atk
	if skill.target_rule == GlobalEnums.TargetRule.ALL_ALLIES \
			or skill.target_rule == GlobalEnums.TargetRule.SELF:
		for t in targets:
			if not _alive(t):
				continue
			var amount := atk * skill.damage_multiplier
			t.stats_component.heal(amount, caster)
			FloatingText.spawn_custom(t.get_parent(), t.position + Vector2(0, -70),
				"+" + str(int(amount)), HEAL_COLOR, 20)
	else:
		for t in targets:
			if not _alive(t):
				continue
			var res := t.stats_component.calculate_and_take_damage(
				atk * skill.damage_multiplier,
				caster.hero_data.faction,
				caster.effective_crit(),
				caster.hero_data.crit_multiplier,
				skill.damage_type,
				caster)
			FloatingText.spawn(t.get_parent(),
				t.position + Vector2(randf_range(-8.0, 8.0), -70.0), res)
			t.flash_hit()
	# Yetenek buff'lari runtime'a islenir (stat/kalkan/stun/DoT/HoT).
	for t in targets:
		if not _alive(t) or t.buff_component == null:
			continue
		for b in skill.applied_buffs:
			t.buff_component.apply_buff(b, caster)

static func _alive(u: Unit) -> bool:
	return u != null and is_instance_valid(u) \
		and u.stats_component != null and not u.stats_component.is_dead
