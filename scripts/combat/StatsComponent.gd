extends Node
class_name StatsComponent
## Unit'in canli savas statlari: HP/enerji/hasar kurallari burada.
## Gorsel tepki (bar, olum animasyonu) Unit sinifinda; savas karari (FSM)
## Prompt 3'te eklenecek.

signal hp_changed(current: float, max: float)
signal energy_changed(current: int, max: int)
signal died
## Istatistik hatti (CombatTracker): kim, kime, ne kadar.
signal damaged(amount: float, attacker: Unit)
signal healed(amount: float, healer: Unit)

var max_hp: float = 1.0
var current_hp: float = 1.0
var atk: float = 0.0
var def: float = 0.0
var haste: float = 100.0
var faction: GlobalEnums.Faction = GlobalEnums.Faction.LIGHTBEARER
## Tek kullanimlik olum pasifleri (savas basi sifirlanir).
var death_defiance_triggered: bool = false
var resurrection_triggered: bool = false
## Kardes bilesenler (Unit._ready baglar).
var buff_component: BuffComponent
var unit: Unit
var max_energy: int = 1000
var current_energy: int = 0
var is_dead: bool = false

func initialize(data: HeroData, level: int) -> void:
	var st: Dictionary = data.calculate_stats_at_level(level)
	max_hp = maxf(1.0, float(st["hp"]))
	current_hp = max_hp
	atk = maxf(0.0, float(st["atk"]))
	def = maxf(0.0, float(st["def"]))
	haste = maxf(1.0, data.base_haste)
	faction = data.faction
	max_energy = 1000
	current_energy = 0
	is_dead = false
	hp_changed.emit(current_hp, max_hp)
	energy_changed.emit(current_energy, max_energy)

## Tam hasar hatti: fraksiyon + kritik + savunma. Sonucu dondurur (FloatingText
## ve log icin). Olu birime islemez (bos sonuc doner).
func calculate_and_take_damage(
	raw_power: float,
	attacker_faction: GlobalEnums.Faction,
	attacker_crit_chance: float,
	attacker_crit_mult: float,
	dmg_type: GlobalEnums.DamageType,
	attacker: Unit = null
) -> DamageResult:
	var result := DamageResult.new()
	result.damage_type = dmg_type
	if is_dead:
		return result
	if _has_invulnerable_buff():
		result.amount = 0.0
		return result
	var f_mult := FactionMatrix.get_damage_multiplier(attacker_faction, faction)
	result.is_advantage = f_mult > 1.0
	result.is_crit = randf() < attacker_crit_chance
	var total_atk := raw_power * f_mult * (attacker_crit_mult if result.is_crit else 1.0)
	var effective := maxf(1.0, total_atk - def * 0.4)
	if buff_component != null:
		effective = buff_component.absorb_damage_with_shield(effective)
	result.amount = effective
	current_hp = maxf(0.0, current_hp - effective)
	hp_changed.emit(current_hp, max_hp)
	damaged.emit(effective, attacker)
	# Can calma: vuran hayattaysa verdigi net hasarin yuzdesini geri alir.
	if attacker != null and is_instance_valid(attacker) and attacker.stats_component != null \
			and attacker.lifesteal_pct > 0.0 and not attacker.stats_component.is_dead:
		attacker.stats_component.heal(effective * attacker.lifesteal_pct, attacker)
	add_energy(int(effective * 0.04))
	# Vurus hissi: her darbede ses + parlama; kritikte kamera sarsilir.
	AudioManager.play_sfx("hit")
	if unit != null and is_instance_valid(unit):
		unit.play_hit_flash()
	if result.is_crit:
		AudioManager.play_sfx("crit")
		var cam := CameraShake.find_camera(get_tree())
		if cam != null:
			cam.add_trauma(0.2)
	if current_hp <= 0.0:
		if _try_death_defiance():
			return result
		if _try_resurrection():
			return result
		is_dead = true
		died.emit()
	return result

## Olumsuzluk: ilk oldurucu darbede can 1'e kilitlenir + 4sn dokunulmazlik.
func _try_death_defiance() -> bool:
	if death_defiance_triggered:
		return false
	var hd := _hero_data()
	if hd == null or not hd.has_death_defiance:
		return false
	if unit == null or not is_instance_valid(unit):
		return false
	death_defiance_triggered = true
	current_hp = 1.0
	hp_changed.emit(current_hp, max_hp)
	var invuln := BuffData.new()
	invuln.id = "death_defiance"
	invuln.buff_type = GlobalEnums.BuffType.INVULNERABLE
	invuln.duration = 4.0
	if unit.buff_component != null:
		unit.buff_component.apply_buff(invuln, null)
	FloatingText.spawn_custom(unit.get_parent(), unit.position + Vector2(0, -80.0),
		"ÖLÜMSÜZLÜK!", Color("#ffd966"), 22)
	return true

## Dirilis: ilk sifirlanmada yere duser, 2sn sonra %50 canla kalkar (1 kez).
func _try_resurrection() -> bool:
	if resurrection_triggered:
		return false
	var hd := _hero_data()
	if hd == null or not hd.has_resurrection:
		return false
	if unit == null or not is_instance_valid(unit):
		return false
	resurrection_triggered = true
	current_hp = 0.0
	hp_changed.emit(current_hp, max_hp)
	unit.enter_resurrection()
	return true

func _hero_data() -> HeroData:
	if unit != null and is_instance_valid(unit):
		return unit.hero_data
	return null

func _has_invulnerable_buff() -> bool:
	if buff_component == null:
		return false
	for entry in buff_component.active_buffs:
		var b := entry["data"] as BuffData
		if b != null and b.buff_type == GlobalEnums.BuffType.INVULNERABLE:
			return true
	return false

func heal(amount: float, healer: Unit = null) -> void:
	if is_dead or amount <= 0.0:
		return
	current_hp = minf(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)
	healed.emit(amount, healer)

func add_energy(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_energy = mini(max_energy, current_energy + amount)
	energy_changed.emit(current_energy, max_energy)

func consume_energy(amount: int) -> void:
	current_energy = maxi(0, current_energy - amount)
	energy_changed.emit(current_energy, max_energy)
