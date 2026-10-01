extends Node
class_name CommanderProgression
## Komutan seviyesi + yetenek agaci. Seviye basina 1 puan; T2 icin T1 sarti,
## T3 (buyu) icin T2 sarti vardir. Efektler savas basi komutana islenir.

signal progressed

const TALENT_DEFS := {
	"FAST_MANA": {"tier": 1, "name": "Hızlı Mana", "desc": "Mana dolumu +1.5/sn."},
	"STARTING_MANA": {"tier": 1, "name": "Hazır Mana", "desc": "Savaş +25 mana ile başlar."},
	"BURNING_METEOR": {"tier": 2, "name": "Yakan Meteor", "desc": "Meteor 3sn alev bırakır (%30/sn)."},
	"DIVINE_RETRIBUTION": {"tier": 2, "name": "İlahi Ceza", "desc": "Biten/kırılan kalkan, değerinin %50'sini saçar."},
	"TIME_WARP_SPELL": {"tier": 3, "name": "Zaman Bükme", "desc": "Yeni büyü: alanı %50 yavaşlatır."},
}
const TIER_ORDER := ["FAST_MANA", "STARTING_MANA", "BURNING_METEOR", "DIVINE_RETRIBUTION", "TIME_WARP_SPELL"]
const SPELL_TIME_WARP_PATH := "res://data/spells/spell_time_warp.tres"

var commander_level: int = 1
var current_exp: int = 0
var talent_points: int = 0
var unlocked_talents: Array[String] = []

func exp_needed() -> int:
	return int(100.0 * pow(float(commander_level), 1.2))

## EXP ekle; atlanan her seviye +1 puan. Seviye atladiysa true.
func add_exp(amount: int) -> bool:
	if amount <= 0:
		return false
	current_exp += amount
	var leveled := false
	while current_exp >= exp_needed():
		current_exp -= exp_needed()
		commander_level += 1
		talent_points += 1
		leveled = true
	if leveled:
		progressed.emit()
	return leveled

func _tier_of(talent_id: String) -> int:
	return int((TALENT_DEFS.get(talent_id, {}) as Dictionary).get("tier", 99))

func _tier_owned(tier: int) -> bool:
	for t in unlocked_talents:
		if _tier_of(t) == tier:
			return true
	return false

func can_unlock(talent_id: String) -> bool:
	if not TALENT_DEFS.has(talent_id):
		return false
	if talent_id in unlocked_talents:
		return false
	if talent_points < 1:
		return false
	var tier := _tier_of(talent_id)
	if tier == 2 and not _tier_owned(1):
		return false
	if tier == 3 and not _tier_owned(2):
		return false
	return true

func unlock_talent(talent_id: String) -> bool:
	if not can_unlock(talent_id):
		return false
	talent_points -= 1
	unlocked_talents.append(talent_id)
	progressed.emit()
	return true

func has_talent(talent_id: String) -> bool:
	return talent_id in unlocked_talents

func apply_to_commander(commander_mgr: CommanderManager) -> void:
	if commander_mgr == null:
		return
	if has_talent("FAST_MANA"):
		commander_mgr.mana_regen_rate += 1.5
	if has_talent("STARTING_MANA"):
		commander_mgr.current_mana += 25.0
	commander_mgr.burning_meteor = has_talent("BURNING_METEOR")
	commander_mgr.divine_retribution = has_talent("DIVINE_RETRIBUTION")
	if has_talent("TIME_WARP_SPELL"):
		var exists := false
		for s in commander_mgr.active_spells:
			if s.id == "time_warp":
				exists = true
		if not exists and ResourceLoader.exists(SPELL_TIME_WARP_PATH):
			commander_mgr.add_spell(load(SPELL_TIME_WARP_PATH) as CommanderSpellData)

func get_save_data() -> Dictionary:
	return {
		"commander_level": commander_level,
		"commander_exp": current_exp,
		"commander_points": talent_points,
		"commander_talents": unlocked_talents.duplicate(),
	}

func apply_save_data(d: Dictionary) -> void:
	commander_level = maxi(1, int(d.get("commander_level", 1)))
	current_exp = maxi(0, int(d.get("commander_exp", 0)))
	talent_points = maxi(0, int(d.get("commander_points", 0)))
	unlocked_talents.clear()
	for t in d.get("commander_talents", []):
		var id := str(t)
		if TALENT_DEFS.has(id) and not (id in unlocked_talents):
			unlocked_talents.append(id)
