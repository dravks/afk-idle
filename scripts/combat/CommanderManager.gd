extends Node
class_name CommanderManager
## Komutan manasi + buyu infazlari. Mana 0-100 (5/sn + oldurme basina +15).
## Hedef tipleri: AREA_ENEMY (hasar + buff), SINGLE_ALLY (buff/ani iyilesme),
## AREA_ALLY + HOT buff = 4sn'lik iyilesme bolgesi (sure/tick/yuzde buff'tan).

signal mana_changed(current: float, max: float)
signal spell_cast_success(spell: CommanderSpellData, target_position: Vector2)

const KILL_MANA := 15.0

var max_mana: float = 100.0
var current_mana: float = 20.0
var mana_regen_rate: float = 5.0
## Buyu guc carpan (kalinti). Savaslik ornek basina 1.0'dan baslar.
var spell_power_mult: float = 1.0
## Yetenek agaci bayraklari (apply_to_commander yazar).
var burning_meteor: bool = false
var divine_retribution: bool = false
var active_spells: Array[CommanderSpellData] = []
var spell_cooldowns: Dictionary = {}
## Patlama/sarsinti sahnesi (BattleScene grid'i atar; bossa da olsa ayni canvas).
var battle_root: Node2D

var _zones: Array = []  # {pos, radius, remaining, tick, buff, visual}

func _ready() -> void:
	add_to_group("commander")

func _process(delta: float) -> void:
	current_mana = minf(max_mana, current_mana + mana_regen_rate * delta)
	mana_changed.emit(current_mana, max_mana)
	for key in spell_cooldowns.keys():
		spell_cooldowns[key] = maxf(0.0, float(spell_cooldowns[key]) - delta)
	_tick_zones(delta)

func add_spell(spell: CommanderSpellData) -> void:
	if spell == null:
		return
	active_spells.append(spell)
	spell_cooldowns[spell.id] = 0.0

func add_mana(amount: float) -> void:
	current_mana = clampf(current_mana + amount, 0.0, max_mana)
	mana_changed.emit(current_mana, max_mana)

func get_cooldown(spell: CommanderSpellData) -> float:
	if spell == null:
		return 0.0
	return float(spell_cooldowns.get(spell.id, 0.0))

func can_cast_spell(spell: CommanderSpellData) -> bool:
	if spell == null:
		return false
	return current_mana >= float(spell.mana_cost) and get_cooldown(spell) <= 0.0

func cast_spell_at_position(spell: CommanderSpellData, world_pos: Vector2) -> bool:
	if not can_cast_spell(spell):
		return false
	var targets := _targets_for(spell, world_pos)
	if targets.is_empty():
		return false  # bosa mana harcanmaz
	current_mana -= float(spell.mana_cost)
	spell_cooldowns[spell.id] = spell.cooldown
	_execute(spell, world_pos, targets)
	spell_cast_success.emit(spell, world_pos)
	_blast(world_pos, spell)
	if str(spell.id) == "meteor":
		AudioManager.play_sfx("spell_meteor")
		var mcam := CameraShake.find_camera(get_tree())
		if mcam != null:
			mcam.add_trauma(0.55)
	elif str(spell.target_type) != "AREA_ENEMY":
		AudioManager.play_sfx("spell_shield")
	return true

func _targets_for(spell: CommanderSpellData, world_pos: Vector2) -> Array[Unit]:
	var out: Array[Unit] = []
	match str(spell.target_type):
		"SINGLE_ALLY":
			var best: Unit = null
			var best_d := INF
			for u in _live_units(Unit.Team.PLAYER):
				var d := u.global_position.distance_to(world_pos)
				if d < best_d:
					best_d = d
					best = u
			if best != null:
				out.append(best)
		"AREA_ALLY":
			for u in _live_units(Unit.Team.PLAYER):
				if u.global_position.distance_to(world_pos) <= spell.aoe_radius:
					out.append(u)
		_:  # AREA_ENEMY (varsayilan)
			for u in _live_units(Unit.Team.ENEMY):
				if u.global_position.distance_to(world_pos) <= spell.aoe_radius:
					out.append(u)
	return out

func _live_units(team: Unit.Team) -> Array[Unit]:
	var out: Array[Unit] = []
	var tree := get_tree()
	if tree == null:
		return out
	for node in tree.get_nodes_in_group("units"):
		var u := node as Unit
		if u != null and u.team == team and u.stats_component != null \
				and not u.stats_component.is_dead:
			out.append(u)
	return out

func _execute(spell: CommanderSpellData, world_pos: Vector2, targets: Array[Unit]) -> void:
	if str(spell.target_type) == "AREA_ALLY" and spell.applied_buff != null \
			and spell.applied_buff.buff_type == GlobalEnums.BuffType.HOT:
		_open_zone(spell, world_pos)
		return
	for t in targets:
		_apply_to_target(spell, t)
	if str(spell.id) == "meteor" and burning_meteor:
		var burn_dps := spell.base_power * spell.damage_mult * spell_power_mult * 0.3
		_open_zone(spell, world_pos, "harm", burn_dps, Color("#ff7a2a"))

func _apply_to_target(spell: CommanderSpellData, t: Unit) -> void:
	var tt := str(spell.target_type)
	if tt == "AREA_ENEMY":
		# damage_mult 0 ise salt-buff buyusudur (Zaman Bukme): hasar islemez.
		if spell.damage_mult > 0.0:
			var res := t.stats_component.calculate_and_take_damage(
				spell.base_power * spell.damage_mult * spell_power_mult,
				t.stats_component.faction, 0.0, 1.0, spell.damage_type, null)
			_spawn_text(t, str(int(res.amount)), Color("#ffb02e") if res.is_advantage else Color("#ffffff"), 20)
			t.flash_hit()
		if spell.applied_buff != null and t.buff_component != null:
			t.buff_component.apply_buff(spell.applied_buff, null)
	else:  # SINGLE_ALLY / AREA_ALLY ani etki
		if spell.base_power > 0.0:
			t.stats_component.heal(spell.base_power, null)
			_spawn_text(t, "+" + str(int(spell.base_power)), Color("#5fbf5f"), 20)
		if spell.applied_buff != null and t.buff_component != null:
			t.buff_component.apply_buff(spell.applied_buff, null)

## Bolge acar: heal (HOT buff verisi) veya harm (sn'lik hasar). Gorsel renkle ayrilir.
func _open_zone(spell: CommanderSpellData, world_pos: Vector2, mode: String = "heal", harm_dps: float = 0.0, col: Color = Color("#5fbf5f")) -> void:
	var buff := spell.applied_buff
	var visual := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r, col.g, col.b, 0.18)
	sb.border_color = col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(spell.aoe_radius))
	visual.add_theme_stylebox_override("panel", sb)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.size = Vector2(spell.aoe_radius * 2.0, spell.aoe_radius * 2.0)
	visual.position = world_pos - visual.size * 0.5
	_parent_for_fx().add_child(visual)
	_zones.append({
		"pos": world_pos, "radius": spell.aoe_radius,
		"remaining": buff.duration if buff != null else 3.0, "tick": 0.05,
		"interval": maxf(0.2, buff.tick_interval) if buff != null else 1.0,
		"pct": buff.value_percentage if buff != null else 0.0, "visual": visual,
		"mode": mode, "dps": harm_dps,
	})

func _tick_zones(delta: float) -> void:
	var done: Array = []
	for z in _zones:
		z["remaining"] = float(z["remaining"]) - delta
		z["tick"] = float(z["tick"]) - delta
		if float(z["tick"]) <= 0.0:
			z["tick"] = float(z.get("interval", 1.0))
			if str(z.get("mode", "heal")) == "harm":
				_zone_harm(z)
			else:
				_zone_heal(z)
		if float(z["remaining"]) <= 0.0:
			done.append(z)
	for z in done:
		_zones.erase(z)
		var v := z["visual"] as Control
		if v != null and is_instance_valid(v):
			var tw := create_tween()
			tw.tween_property(v, "modulate:a", 0.0, 0.4)
			tw.tween_callback(v.queue_free)

func _zone_heal(z: Dictionary) -> void:
	var pos: Vector2 = z["pos"]
	var radius: float = z["radius"]
	var pct: float = z["pct"]
	for u in _live_units(Unit.Team.PLAYER):
		if u.global_position.distance_to(pos) <= radius:
			var amount: float = u.stats_component.max_hp * pct
			u.stats_component.heal(amount, null)
			_spawn_text(u, "+" + str(int(amount)), Color("#5fbf5f"), 16)

func _zone_harm(z: Dictionary) -> void:
	var pos: Vector2 = z["pos"]
	var radius: float = z["radius"]
	var dps: float = z.get("dps", 0.0)
	for u in _live_units(Unit.Team.ENEMY):
		if u.global_position.distance_to(pos) <= radius:
			var res := u.stats_component.calculate_and_take_damage(
				dps, u.stats_component.faction, 0.0, 1.0,
				GlobalEnums.DamageType.MAGICAL, null)
			_spawn_text(u, str(int(res.amount)), Color("#ff7a2a"), 16)
			u.flash_hit()

func _spawn_text(t: Unit, text: String, col: Color, size: int) -> void:
	FloatingText.spawn_custom(_parent_for_fx(), t.position + Vector2(0, -70.0), text, col, size)

func _blast(world_pos: Vector2, spell: CommanderSpellData) -> void:
	var parent := _parent_for_fx()
	if parent == null:
		return
	var col := Color("#ff7a2a") if str(spell.target_type) == "AREA_ENEMY" else Color("#8fd3ff")
	var r := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = col
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(int(maxf(1.0, spell.aoe_radius)))
	r.add_theme_stylebox_override("panel", sb)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var from := 12.0
	var to := maxf(from + 1.0, spell.aoe_radius)
	r.size = Vector2(from, from)
	r.position = world_pos - Vector2(from, from) * 0.5
	parent.add_child(r)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(r, "size", Vector2(to, to), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "position", world_pos - Vector2(to, to) * 0.5, 0.3)
	tw.tween_property(r, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(r.queue_free)

func _parent_for_fx() -> Node:
	if battle_root != null and is_instance_valid(battle_root):
		return battle_root
	return get_parent()
