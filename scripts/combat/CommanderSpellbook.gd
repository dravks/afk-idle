extends RefCounted
class_name CommanderSpellbook
## Komutan buyu seti tek kaynaktan (savas + boss sahnesi paylasir).

static func default_spells() -> Array[CommanderSpellData]:
	return [_meteor(), _aegis(), _circle()]

static func _base(id: String, nm: String, cost: int, cd: float, aoe: float, target: String) -> CommanderSpellData:
	var s := CommanderSpellData.new()
	s.id = id
	s.spell_name = nm
	s.mana_cost = cost
	s.cooldown = cd
	s.aoe_radius = aoe
	s.target_type = target
	return s

static func _meteor() -> CommanderSpellData:
	var s := _base("meteor", "Meteor", 40, 8.0, 120.0, "AREA_ENEMY")
	s.base_power = 200.0
	s.damage_mult = 1.5
	s.damage_type = GlobalEnums.DamageType.MAGICAL
	var stun := BuffData.new()
	stun.id = "cmd_stun"
	stun.buff_type = GlobalEnums.BuffType.STUN
	stun.duration = 1.5
	s.applied_buff = stun
	s.icon = IconLoader.get_icon("meteor-impact")
	return s

static func _aegis() -> CommanderSpellData:
	var s := _base("aegis", "Kutsal Kalkan", 30, 10.0, 60.0, "SINGLE_ALLY")
	s.base_power = 0.0
	var shield := BuffData.new()
	shield.id = "cmd_aegis"
	shield.buff_type = GlobalEnums.BuffType.SHIELD
	shield.duration = 12.0
	shield.flat_value = 500.0
	s.applied_buff = shield
	s.icon = IconLoader.get_icon("bordered-shield")
	return s

static func _circle() -> CommanderSpellData:
	var s := _base("circle", "Sifa Halesi", 50, 15.0, 130.0, "AREA_ALLY")
	s.base_power = 0.0
	var hot := BuffData.new()
	hot.id = "cmd_circle"
	hot.buff_type = GlobalEnums.BuffType.HOT
	hot.duration = 4.0
	hot.tick_interval = 1.0
	hot.value_percentage = 0.15
	s.applied_buff = hot
	s.icon = IconLoader.get_icon("life-support")
	return s
