extends Node
class_name BuffComponent
## Birim uzerindeki anlik etkiler: stat bufflari, kalkan, stun, DoT/HoT.
## Stat bufflari carpimsal uygulanir, suresi bitince geri alinir
## (coklu buff'lar bagimsiz cozulebilir). Hasar ruu:
## StatsComponent -> absorb_damage_with_shield -> can.

@onready var unit: Unit = get_parent() as Unit

var active_buffs: Array[Dictionary] = []

func apply_buff(buff_data: BuffData, caster: Unit) -> void:
	if buff_data == null or unit == null:
		return
	if unit.stats_component == null or unit.stats_component.is_dead:
		return
	# Ayni id'li buff tazelenir (sure sifirlanir), istiflenmez. Id'siz
	# buff'lar eski davranisla istiflenir (cift-stun testi bunu bekler).
	if not buff_data.id.is_empty():
		for entry in active_buffs:
			var eb := entry["data"] as BuffData
			if eb != null and eb.id == buff_data.id:
				entry["remaining"] = maxf(float(entry["remaining"]), buff_data.duration)
				return
	var cf: GlobalEnums.Faction = unit.stats_component.faction
	var caster_alive := caster != null and is_instance_valid(caster) and caster.stats_component != null
	if caster_alive:
		cf = caster.stats_component.faction
	var entry := {
		"data": buff_data,
		"remaining": buff_data.duration,
		"tick_timer": buff_data.tick_interval,
		"shield_hp": 0.0,
		"caster_faction": cf,
		"caster": caster if caster_alive else null,
	}
	match buff_data.buff_type:
		GlobalEnums.BuffType.ATK_BUFF:
			entry["applied"] = _apply_stat("atk", buff_data)
		GlobalEnums.BuffType.DEF_BUFF:
			entry["applied"] = _apply_stat("def", buff_data)
		GlobalEnums.BuffType.HASTE_BUFF:
			entry["applied"] = _apply_stat("haste", buff_data)
		GlobalEnums.BuffType.SHIELD:
			var atk: float = caster.stats_component.atk if caster != null and is_instance_valid(caster) and caster.stats_component != null else 0.0
			entry["shield_hp"] = buff_data.flat_value + atk * buff_data.value_percentage
			entry["shield_max"] = float(entry["shield_hp"])
		GlobalEnums.BuffType.STUN:
			if unit is BossUnit and (unit as BossUnit).is_immune_to_cc():
				return  # patron sersemlemez (girdi listeye eklenmeden cikar)
			if unit.state_machine != null:
				unit.state_machine.change_state("Stunned")
	active_buffs.append(entry)

## Kalkanlar sirasiyla emer; arta kalan net hasar doner. Kirilan kalkan silinir.
func absorb_damage_with_shield(incoming_damage: float) -> float:
	var left := incoming_damage
	var spent: Array = []
	for entry in active_buffs:
		if left <= 0.0:
			break
		var sh := float(entry.get("shield_hp", 0.0))
		if sh <= 0.0:
			continue
		var eaten := minf(sh, left)
		entry["shield_hp"] = sh - eaten
		left -= eaten
		if float(entry["shield_hp"]) <= 0.0:
			spent.append(entry)
	for entry in spent:
		_remove(entry)
	return maxf(0.0, left)

func has_stun() -> bool:
	for entry in active_buffs:
		var b := entry["data"] as BuffData
		if b != null and b.buff_type == GlobalEnums.BuffType.STUN:
			return true
	return false

func _process(delta: float) -> void:
	if unit == null or unit.stats_component == null:
		return
	var dead: bool = unit.stats_component.is_dead
	var expired: Array = []
	for entry in active_buffs:
		var b := entry["data"] as BuffData
		if b == null:
			expired.append(entry)
			continue
		entry["remaining"] = float(entry["remaining"]) - delta
		# DoT / HoT tickleri.
		if not dead and b.tick_interval > 0.0 \
				and (b.buff_type == GlobalEnums.BuffType.DOT or b.buff_type == GlobalEnums.BuffType.HOT):
			entry["tick_timer"] = float(entry["tick_timer"]) - delta
			while float(entry["tick_timer"]) <= 0.0:
				entry["tick_timer"] = float(entry["tick_timer"]) + b.tick_interval
				_tick(entry, b)
		if float(entry["remaining"]) <= 0.0:
			expired.append(entry)
	for entry in expired:
		_remove(entry)
	# Stun bitisi: baska stun yoksa ve olu degilse Idle'a don.
	if not dead and not has_stun() and _was_stunned(expired):
		if unit.state_machine != null and unit.state_machine.current_state_name() == "Stunned":
			unit.state_machine.change_state("Idle")

func _tick(entry: Dictionary, b: BuffData) -> void:
	var caster := entry.get("caster") as Unit
	if b.buff_type == GlobalEnums.BuffType.DOT:
		var res := unit.stats_component.calculate_and_take_damage(
			b.flat_value, entry["caster_faction"], 0.0, 1.0,
			GlobalEnums.DamageType.PHYSICAL, caster)
		FloatingText.spawn(unit.get_parent(), unit.position + Vector2(randf_range(-8.0, 8.0), -60.0), res)
	else:
		unit.stats_component.heal(b.flat_value, caster)
		FloatingText.spawn_custom(unit.get_parent(), unit.position + Vector2(0, -60.0),
			"+" + str(int(b.flat_value)), Color("#5fbf5f"), 16)

## Stat carpani uygula, geri-alim icin katsayilari dondur.
func _apply_stat(stat_name: String, b: BuffData) -> Array:
	var mult := 1.0 + b.value_percentage
	var flat := b.flat_value
	var st := unit.stats_component
	if stat_name == "atk":
		st.atk = st.atk * mult + flat
	elif stat_name == "def":
		st.def = st.def * mult + flat
	elif stat_name == "haste":
		st.haste = st.haste * mult + flat
	return [mult, flat]

func _remove(entry: Dictionary) -> void:
	var b := entry["data"] as BuffData
	if b != null and (b.buff_type == GlobalEnums.BuffType.ATK_BUFF \
			or b.buff_type == GlobalEnums.BuffType.DEF_BUFF \
			or b.buff_type == GlobalEnums.BuffType.HASTE_BUFF):
		var back: Array = entry.get("applied", [1.0, 0.0])
		var mult := float(back[0])
		var flat := float(back[1])
		var st := unit.stats_component
		if b.buff_type == GlobalEnums.BuffType.ATK_BUFF and mult != 0.0:
			st.atk = (st.atk - flat) / mult
		elif b.buff_type == GlobalEnums.BuffType.DEF_BUFF and mult != 0.0:
			st.def = (st.def - flat) / mult
		elif b.buff_type == GlobalEnums.BuffType.HASTE_BUFF and mult != 0.0:
			st.haste = (st.haste - flat) / mult
	elif b != null and b.buff_type == GlobalEnums.BuffType.SHIELD:
		_divine_burst(entry)
	active_buffs.erase(entry)

## Ilahi Ceza: biten/kirilan kalkan, ilk degerinin %50'sini cevredeki
## dusmanlara sacer (komutan yetenegi aciksa; olu birim sacmaz).
func _divine_burst(entry: Dictionary) -> void:
	if unit.stats_component.is_dead:
		return
	var tree := get_tree()
	if tree == null:
		return
	var cmd := tree.get_first_node_in_group("commander") as CommanderManager
	if cmd == null or not cmd.divine_retribution:
		return
	var power := float(entry.get("shield_max", 0.0)) * 0.5
	if power <= 0.0:
		return
	for node in tree.get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or u.team == unit.team:
			continue
		if u.stats_component == null or u.stats_component.is_dead:
			continue
		if u.global_position.distance_to(unit.global_position) > 220.0:
			continue
		var res := u.stats_component.calculate_and_take_damage(
			power, u.stats_component.faction, 0.0, 1.0,
			GlobalEnums.DamageType.MAGICAL, null)
		FloatingText.spawn_custom(_fx_parent(), u.position + Vector2(0, -60.0),
			str(int(res.amount)), Color("#8fd3ff"), 16)
		u.flash_hit()

func _fx_parent() -> Node:
	if unit != null and is_instance_valid(unit) and unit.get_parent() != null:
		return unit.get_parent()
	return self

func _was_stunned(expired: Array) -> bool:
	for entry in expired:
		var b := entry["data"] as BuffData
		if b != null and b.buff_type == GlobalEnums.BuffType.STUN:
			return true
	return false
