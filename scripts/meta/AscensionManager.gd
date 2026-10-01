extends Node
class_name AscensionManager
## Tapinak motoru: kopya birlestirme + kademe/seviye tavani.
## Prototip kural: AYNI kahramandan 2 kopya (ayni kademe) -> kademe +1.
## Yem kopya dizilimde kilitli olamaz. Kademe hero BAZINDA degil ID bazinda
## tutulur (profil.hero_tiers): tum kopyalar birlikte yukselir (sadelestirme).

const TIER_MAX := {0: 60, 1: 80, 2: 100, 3: 120, 4: 140, 5: 160, 6: 240}
const TIER_NAMES := {
	0: "COMMON", 1: "RARE", 2: "ELITE", 3: "ELITE+",
	4: "LEGENDARY", 5: "MYTHIC", 6: "ASCENDED",
}
const MAX_TIER := 6

static func get_max_level_for_tier(tier: GlobalEnums.AscensionTier) -> int:
	return int(TIER_MAX.get(int(tier), 60))

static func tier_name(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 0, MAX_TIER), "?"))

func get_tier(profile, hero_id: String) -> int:
	if profile == null:
		return 2
	return int(profile.hero_tiers.get(hero_id, 2))

func can_ascend(main_hero_id: String, fodder_hero_id: String, profile) -> bool:
	if profile == null or main_hero_id.is_empty() or fodder_hero_id.is_empty():
		return false
	if main_hero_id != fodder_hero_id:
		return false  # prototip: sadece ayni kahraman birlesir
	if get_tier(profile, main_hero_id) >= MAX_TIER:
		return false
	var copies := _copies(profile, main_hero_id)
	if copies.size() < 2:
		return false
	for c in copies:
		if not _is_placed(profile, c):
			return true
	return false

func ascend_hero(main_hero_id: String, fodder_hero_id: String, profile) -> bool:
	if not can_ascend(main_hero_id, fodder_hero_id, profile):
		return false
	for c in _copies(profile, main_hero_id):
		if not _is_placed(profile, c):
			profile.owned_heroes.erase(c)
			break
	profile.hero_tiers[main_hero_id] = get_tier(profile, main_hero_id) + 1
	return true

func _copies(profile, hero_id: String) -> Array:
	var out: Array = []
	for h in profile.owned_heroes:
		var hd := h as HeroData
		if hd != null and hd.id == hero_id:
			out.append(hd)
	return out

func _is_placed(profile, hero: HeroData) -> bool:
	for key in profile.current_formation.keys():
		if profile.current_formation[key] == hero:
			return true
	return false
