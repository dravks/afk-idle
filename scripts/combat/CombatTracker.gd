extends RefCounted
class_name CombatTracker
## Mac ici performans kaydi: birim basina verilen/alinan hasar + iyilestirme.
## Unit anahtarli sozluk; olu/silinen birimler get_team_stats'te elenir.

var stats: Dictionary = {}

func _entry(unit: Unit) -> Dictionary:
	if not stats.has(unit):
		stats[unit] = {"damage_dealt": 0.0, "damage_taken": 0.0, "healing_done": 0.0}
	return stats[unit]

## Birimi izlemeye al (yeni ise true). CombatManager baglantilari tekler.
func register(unit: Unit) -> bool:
	if unit == null or stats.has(unit):
		return false
	stats[unit] = {"damage_dealt": 0.0, "damage_taken": 0.0, "healing_done": 0.0}
	return true

func record_damage_dealt(unit: Unit, amount: float) -> void:
	if unit == null or amount <= 0.0:
		return
	_entry(unit)["damage_dealt"] = float(_entry(unit)["damage_dealt"]) + amount

func record_damage_taken(unit: Unit, amount: float) -> void:
	if unit == null or amount <= 0.0:
		return
	_entry(unit)["damage_taken"] = float(_entry(unit)["damage_taken"]) + amount

func record_healing_done(unit: Unit, amount: float) -> void:
	if unit == null or amount <= 0.0:
		return
	_entry(unit)["healing_done"] = float(_entry(unit)["healing_done"]) + amount

## Takimin satirlari: ad + rol + 3 metrik (UI Damage Meters bunu cizer).
func get_team_stats(team: Unit.Team) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for key in stats.keys():
		var u := key as Unit
		if u == null or not is_instance_valid(u):
			continue
		if u.team != team:
			continue
		var e: Dictionary = stats[key]
		out.append({
			"unit": u,
			"name": u.hero_data.hero_name if u.hero_data != null else "?",
			"role": u.hero_data.role if u.hero_data != null else GlobalEnums.Role.WARRIOR,
			"damage_dealt": float(e["damage_dealt"]),
			"damage_taken": float(e["damage_taken"]),
			"healing_done": float(e["healing_done"]),
		})
	return out

func clear() -> void:
	stats.clear()

## Silinmis birimlerin girdilerini at (baglantilariyla birlikte olurler).
## start_battle basi cagrilir; baglanti tekligi kayit defterde yasar.
func purge_invalid() -> void:
	var dead_keys: Array = []
	for key in stats.keys():
		if not is_instance_valid(key):
			dead_keys.append(key)
	for key in dead_keys:
		stats.erase(key)
