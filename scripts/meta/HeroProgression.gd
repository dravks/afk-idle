extends RefCounted
class_name HeroProgression
## Seviye maliyet/formul tek kaynagi. Tum fonksiyonlar statik (HeroDetailUI
## `HeroProgression.level_up(...)` diye cagirir).
##
## Seviye `crystal_mgr.hero_levels`'te yasar (tek kaynak); cuzdan daginik:
## altin profilde, EXP/toz AFK yoneticisinde (autoload isimleriyle erisilir).
## Baraj (20/40/60...): toz sarti + `profile.hero_milestones` kaydi. Yetenek
## acma etkisi henuz yok — `has_milestone()` sorgusu yetenek sistemi icin kanca.

static func get_level_cost(current_level: int) -> Dictionary:
	return {
		"gold": int(100.0 * pow(float(current_level), 1.3)),
		"exp": int(80.0 * pow(float(current_level), 1.25)),
		"dust": int(current_level * 10) if (current_level % 20 == 0) else 0,
	}

static func can_level_up(hero_id: String, profile, crystal_mgr) -> bool:
	if profile == null or crystal_mgr == null:
		return false
	if not crystal_mgr.hero_levels.has(hero_id):
		return false
	if hero_id in crystal_mgr.crystal_slots:
		return false  # kristaldekiler elle basilamaz
	var current := int(crystal_mgr.hero_levels.get(hero_id, 1))
	var tier := int(profile.hero_tiers.get(hero_id, 2))
	if current >= AscensionManager.get_max_level_for_tier(tier):
		return false  # kademe tavani (Tapinak'ta yukselt)
	var cost := get_level_cost(current)
	if int(profile.gold) < int(cost["gold"]):
		return false
	if int(AFKManager.hero_exp) < int(cost["exp"]):
		return false
	if int(AFKManager.dust) < int(cost["dust"]):
		return false
	return true

static func level_up(hero_id: String, profile, crystal_mgr) -> bool:
	if not can_level_up(hero_id, profile, crystal_mgr):
		return false
	var current := int(crystal_mgr.hero_levels[hero_id])
	var cost := get_level_cost(current)
	profile.gold -= int(cost["gold"])
	AFKManager.hero_exp -= int(cost["exp"])
	AFKManager.dust -= int(cost["dust"])
	crystal_mgr.set_hero_level(hero_id, current + 1)  # kristali de hesaplatir
	if current % 20 == 0:
		var marks: Array = profile.hero_milestones.get(hero_id, [])
		if not (current in marks):
			marks.append(current)
		profile.hero_milestones[hero_id] = marks
	QuestEvents.hero_leveled_up.emit()
	return true

static func has_milestone(profile, hero_id: String, milestone: int) -> bool:
	if profile == null:
		return false
	var marks: Array = profile.hero_milestones.get(hero_id, [])
	return milestone in marks
