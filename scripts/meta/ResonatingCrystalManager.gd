extends Node
## Yanki Kristali: en yuksek 5 kahraman (Pentagram) digerlerini yukseltir.
## Yuvadaki kahraman kristal seviyesinin altina dusmez; seviye yukseltme
## set_hero_level uzerinden otomatik yeniden hesaplanir.

signal crystal_level_updated(new_level: int)
signal hero_placed_in_slot(hero_id: String, effective_level: int)
signal hero_removed_from_slot(hero_id: String)

const MAX_SLOTS := 10
const PENTAGRAM := 5

var owned_heroes: Array[HeroData] = []
var hero_levels: Dictionary = {}
var crystal_slots: Array[String] = []
var crystal_level: int = 1

func add_hero(hero: HeroData, level: int = 1) -> void:
	if hero == null or has_hero(hero.id):
		return
	owned_heroes.append(hero)
	hero_levels[hero.id] = maxi(1, level)
	update_crystal_level()

func has_hero(hero_id: String) -> bool:
	for h in owned_heroes:
		if h.id == hero_id:
			return true
	return false

func set_hero_level(hero_id: String, level: int) -> void:
	if not has_hero(hero_id):
		return
	hero_levels[hero_id] = maxi(1, level)
	update_crystal_level()

func update_crystal_level() -> void:
	var levels: Array[int] = []
	for h in owned_heroes:
		levels.append(int(hero_levels.get(h.id, 1)))
	if levels.is_empty():
		_set_crystal(1)
		return
	levels.sort()
	levels.reverse()
	var new_level: int
	if levels.size() >= PENTAGRAM:
		new_level = levels[PENTAGRAM - 1]
	else:
		new_level = levels[levels.size() - 1]  # en dusuk
	_set_crystal(new_level)

func _set_crystal(v: int) -> void:
	v = maxi(1, v)
	if v == crystal_level:
		return
	crystal_level = v
	crystal_level_updated.emit(crystal_level)

## Seviyeye gore ilk 5 kahraman id'si (yuva kurali icin).
func pentagram_ids() -> Array[String]:
	var ids: Array[String] = []
	var lv := hero_levels
	var sorted := owned_heroes.duplicate()
	sorted.sort_custom(
		func(a: HeroData, b: HeroData) -> bool:
			return int(lv.get(a.id, 1)) > int(lv.get(b.id, 1)))
	for i in mini(PENTAGRAM, sorted.size()):
		ids.append((sorted[i] as HeroData).id)
	return ids

func place_hero_in_slot(hero_id: String) -> bool:
	if not has_hero(hero_id):
		return false
	if hero_id in crystal_slots:
		return false
	if crystal_slots.size() >= MAX_SLOTS:
		return false
	if hero_id in pentagram_ids():
		return false
	crystal_slots.append(hero_id)
	hero_placed_in_slot.emit(hero_id, get_effective_level(hero_id))
	return true

func remove_hero_from_slot(hero_id: String) -> void:
	if crystal_slots.has(hero_id):
		crystal_slots.erase(hero_id)
		hero_removed_from_slot.emit(hero_id)

func get_effective_level(hero_id: String) -> int:
	var own := int(hero_levels.get(hero_id, 1))
	if hero_id in crystal_slots:
		return maxi(own, crystal_level)
	return own

## Kayit dilimi: sahip listesi TEKRAR EDILMEZ (profil diliminde coklu kumeyle
## durur). Seviye sozlugunun anahtarlari id'leri tasir; apply ayni dosyadan okur.
func get_save_data() -> Dictionary:
	var lv: Dictionary = {}
	for key in hero_levels.keys():
		lv[str(key)] = int(hero_levels[key])
	return {
		"hero_levels": lv,
		"crystal_slots": crystal_slots.duplicate(),
	}

## Kayittan kurulum: HeroData nesnelerini kadro listesinden eslestirir.
func apply_save_data(d: Dictionary, roster: Array[HeroData] = []) -> void:
	owned_heroes.clear()
	hero_levels.clear()
	crystal_slots.clear()
	var by_id: Dictionary = {}
	for h in roster:
		if h != null:
			by_id[h.id] = h
	var saved_levels: Dictionary = d.get("hero_levels", {})
	for hid in d.get("owned_hero_ids", []):
		var id := str(hid)
		if by_id.has(id):
			owned_heroes.append(by_id[id])
			hero_levels[id] = maxi(1, int(saved_levels.get(id, 1)))
	for sid in d.get("crystal_slots", []):
		var id := str(sid)
		if has_hero(id) and crystal_slots.size() < MAX_SLOTS and not id in crystal_slots:
			crystal_slots.append(id)
	update_crystal_level()
