extends Node
## Oyuncu durumu (autoload singleton). Kadro .tres'lerden kurulur;
## dizilim/kaynak/bolum burada yasar. Kayit okuma/yazma GameFlowManager
## uzerinden SaveManager ile yapilir.

const ROSTER_FILES: Array[String] = [
	"res://data/heroes/guard.tres",
	"res://data/heroes/mage.tres",
	"res://data/heroes/striker.tres",
	"res://data/heroes/footman.tres",
	"res://data/heroes/cleric.tres",
]
const SLOT_KEYS: Array[String] = ["FRONT_TOP", "FRONT_BOT", "BACK_TOP", "BACK_MID", "BACK_BOT"]
## Tum cagrilabilir kahramanlar (taverna havuzu dahil). Kayit id listesi
## buradan cozumleneir; ROSTER_FILES baslangic kadrosudur.
const HERO_REGISTRY: Dictionary = {
	"guard": "res://data/heroes/guard.tres",
	"mage": "res://data/heroes/mage.tres",
	"striker": "res://data/heroes/striker.tres",
	"footman": "res://data/heroes/footman.tres",
	"cleric": "res://data/heroes/cleric.tres",
	"goblin": "res://data/heroes/goblin.tres",
	"orc": "res://data/heroes/orc.tres",
	"shaman": "res://data/heroes/shaman.tres",
	"wolf": "res://data/heroes/wolf.tres",
	"lucius": "res://data/heroes/hero_lucius.tres",
	"gwyneth": "res://data/heroes/hero_gwyneth.tres",
	"rowan": "res://data/heroes/hero_rowan.tres",
	"shemira": "res://data/heroes/hero_shemira.tres",
	"silvina": "res://data/heroes/hero_silvina.tres",
	"thorin": "res://data/heroes/hero_thorin.tres",
	"tasi": "res://data/heroes/hero_tasi.tres",
	"eironn": "res://data/heroes/hero_eironn.tres",
	"nemora": "res://data/heroes/hero_nemora.tres",
	"brutus": "res://data/heroes/hero_brutus.tres",
	"saveas": "res://data/heroes/hero_saveas.tres",
	"skreg": "res://data/heroes/hero_skreg.tres",
}

var gold: int = 1000
var diamonds: int = 300
var current_stage_index: int = 1
var owned_heroes: Array[HeroData] = []
var current_formation: Dictionary = {
	"FRONT_TOP": null, "FRONT_BOT": null,
	"BACK_TOP": null, "BACK_MID": null, "BACK_BOT": null,
}
var cleared_stages: Array[int] = []
## Kule ilerlemesi: mevcut kat + ilk-geçilen katlar.
var tower_floor: int = 1
var tower_cleared: Array[int] = []
## Arena durumu (tek kaynak): puan, bilet + tarih, savunma dizilimi.
var arena_points: int = 1000
var arena_tickets: int = 2
var arena_ticket_date: String = ""
var arena_defense_formation: Dictionary = {
	"FRONT_TOP": null, "FRONT_BOT": null,
	"BACK_TOP": null, "BACK_MID": null, "BACK_BOT": null,
}
## Boss rekoru (gunluk): skor + tarih (YYYY-MM-DD).
var boss_best_score: int = 0
var boss_best_date: String = ""
## Ayarlar: sessizlik tercihi (oturumlar arasi kalici).
var muted: bool = false
## Kademe: hero id -> AscensionTier int (kopyalar birlikte yukselir).
var hero_tiers: Dictionary = {}
## Esya envanteri (kusakli olmayanlar) + kusak haritasi (id -> slot -> esya).
var inventory_gears: Array[EquipmentData] = []
var hero_gear: Dictionary = {}
var next_gear_uid: int = 1
## Baraj kaydi: hero id -> gecilen baraj seviyeleri ([20, 40...]).
## Seviye kristal yoneticisinde yasar; burada sadece baraj izi tutulur.
var hero_milestones: Dictionary = {}

func _ready() -> void:
	for path in ROSTER_FILES:
		var h := load(path) as HeroData
		if h != null:
			owned_heroes.append(h)
		else:
			push_error("PlayerProfile: kadro yuklenemedi: %s" % path)
	for h in owned_heroes:
		if not hero_tiers.has(h.id):
			hero_tiers[h.id] = 2  # baslangic kadrosu ELITE

func get_hero(hero_id: String) -> HeroData:
	for h in owned_heroes:
		if h.id == hero_id:
			return h
	return null

func _defense_to_save() -> Dictionary:
	var out: Dictionary = {}
	for key in arena_defense_formation.keys():
		var h := arena_defense_formation[key] as HeroData
		out[str(key)] = h.id if h != null else ""
	return out

## Yuvaya ata (ayni kahraman baska yuvadaysa oradan kalkip tasinir).
func assign_to_slot(slot: String, hero_id: String) -> bool:
	var h := get_hero(hero_id)
	if h == null or not current_formation.has(slot):
		return false
	for key in current_formation.keys():
		if current_formation[key] == h:
			current_formation[key] = null
	current_formation[slot] = h
	return true

func remove_from_slot(slot: String) -> void:
	if current_formation.has(slot):
		current_formation[slot] = null

func formation_count() -> int:
	var n := 0
	for key in current_formation.keys():
		if current_formation[key] != null:
			n += 1
	return n

func is_hero_placed(hero_id: String) -> bool:
	for key in current_formation.keys():
		var h := current_formation[key] as HeroData
		if h != null and h.id == hero_id:
			return true
	return false

func assign_defense(slot: String, hero_id: String) -> bool:
	var h := get_hero(hero_id)
	if h == null or not arena_defense_formation.has(slot):
		return false
	for key in arena_defense_formation.keys():
		if arena_defense_formation[key] == h:
			arena_defense_formation[key] = null
	arena_defense_formation[slot] = h
	return true

func remove_defense(slot: String) -> void:
	if arena_defense_formation.has(slot):
		arena_defense_formation[slot] = null

func defense_count() -> int:
	var n := 0
	for key in arena_defense_formation.keys():
		if arena_defense_formation[key] != null:
			n += 1
	return n

func is_defense_placed(hero_id: String) -> bool:
	for key in arena_defense_formation.keys():
		var h := arena_defense_formation[key] as HeroData
		if h != null and h.id == hero_id:
			return true
	return false

## Kusanilmis esya haritasi (yoksa bos kur).
func gear_map_for(hero_id: String) -> Dictionary:
	if not hero_gear.has(hero_id):
		hero_gear[hero_id] = {0: null, 1: null, 2: null, 3: null}
	return hero_gear[hero_id]

## Otomatik kusak: her yuvaya envanterdeki en yuksek skorlu esya (degisen
## envantere doner).
func auto_equip(hero_id: String) -> void:
	var worn := gear_map_for(hero_id)
	for slot in [0, 1, 2, 3]:
		var best: EquipmentData = null
		var best_score := -1.0
		for g in inventory_gears:
			if g == null or int(g.slot_type) != slot:
				continue
			var s := _gear_score(g)
			if best == null or s > best_score:
				best = g
				best_score = s
		if best == null:
			continue
		var old := worn.get(slot) as EquipmentData
		if old != null:
			inventory_gears.append(old)
		worn[slot] = best
		inventory_gears.erase(best)

func _gear_score(g: EquipmentData) -> float:
	return g.bonus_atk + g.bonus_def + g.bonus_hp * 0.1 + g.bonus_haste * 2.0

## Bolum odulu esya uretici (yuvasi doner, gucu bolumle olceklenir).
func make_gear(slot: int, power: float) -> EquipmentData:
	var g := EquipmentData.new()
	g.uid = next_gear_uid
	next_gear_uid += 1
	g.id = "gear_%d" % g.uid
	g.slot_type = clampi(slot, 0, 3) as GlobalEnums.EquipSlot
	var names := ["Kılıç", "Zırh", "Miğfer", "Çizme"]
	g.item_name = "%s #%d" % [names[clampi(slot, 0, 3)], g.uid]
	match clampi(slot, 0, 3):
		0:
			g.bonus_atk = power
		1:
			g.bonus_def = power * 0.8
			g.bonus_hp = power * 5.0
		2:
			g.bonus_hp = power * 8.0
		_:
			g.bonus_haste = power * 0.3
			g.bonus_def = power * 0.3
	inventory_gears.append(g)
	return g

func get_save_data() -> Dictionary:
	var form: Dictionary = {}
	for key in current_formation.keys():
		var h := current_formation[key] as HeroData
		form[str(key)] = h.id if h != null else ""
	var marks: Dictionary = {}
	for key in hero_milestones.keys():
		marks[str(key)] = (hero_milestones[key] as Array).duplicate()
	var owned_ids: Array = []
	for h in owned_heroes:
		owned_ids.append(h.id)
	var tiers: Dictionary = {}
	for key in hero_tiers.keys():
		tiers[str(key)] = int(hero_tiers[key])
	var gears: Array = []
	var seen: Dictionary = {}
	# Kusakli esyalar envanterde DURMAZ; ama dosyaya hepsi yazilir (uid ile
	# baglanir). Yoksa yuklemede kusak haritasi oksuz kalirdi.
	for g in inventory_gears:
		var gd := g as EquipmentData
		if gd != null and not seen.has(gd.uid):
			seen[gd.uid] = true
			gears.append(gd.to_dict())
	for hid in hero_gear.keys():
		var mm: Dictionary = hero_gear[hid]
		for slot in mm.keys():
			var gd := mm[slot] as EquipmentData
			if gd != null and not seen.has(gd.uid):
				seen[gd.uid] = true
				gears.append(gd.to_dict())
	var worn: Dictionary = {}
	for hid in hero_gear.keys():
		var row: Dictionary = {}
		var m: Dictionary = hero_gear[hid]
		for slot in m.keys():
			var g := m[slot] as EquipmentData
			row[str(int(slot))] = g.uid if g != null else 0
		worn[str(hid)] = row
	return {
		"gold": gold,
		"diamonds": diamonds,
		"current_stage_index": current_stage_index,
		"cleared_stages": cleared_stages.duplicate(),
		"tower_floor": tower_floor,
		"tower_cleared": tower_cleared.duplicate(),
		"formation": form,
		"hero_milestones": marks,
		"owned_hero_ids": owned_ids,
		"hero_tiers": tiers,
		"boss_best_score": boss_best_score,
		"boss_best_date": boss_best_date,
		"muted": muted,
		"arena_points": arena_points,
		"arena_tickets": arena_tickets,
		"arena_ticket_date": arena_ticket_date,
		"arena_defense": _defense_to_save(),
		"gears": gears,
		"hero_gear": worn,
		"next_gear_uid": next_gear_uid,
	}

func apply_save_data(d: Dictionary) -> void:
	gold = int(d.get("gold", 1000))
	diamonds = int(d.get("diamonds", 300))
	current_stage_index = maxi(1, int(d.get("current_stage_index", 1)))
	cleared_stages.clear()
	for s in d.get("cleared_stages", []):
		cleared_stages.append(int(s))
	tower_floor = maxi(1, int(d.get("tower_floor", 1)))
	tower_cleared.clear()
	for s in d.get("tower_cleared", []):
		tower_cleared.append(int(s))
	var form: Dictionary = d.get("formation", {})
	for key in current_formation.keys():
		var hid := str(form.get(key, ""))
		current_formation[key] = get_hero(hid) if not hid.is_empty() else null
	hero_milestones.clear()
	var saved_marks: Dictionary = d.get("hero_milestones", {})
	for key in saved_marks.keys():
		var arr: Array = []
		for m in saved_marks[key]:
			arr.append(int(m))
		hero_milestones[str(key)] = arr
	# Taverna cagrilari kayitta yasar; kayit yoksa baslangic kadrosu.
	var saved_owned: Array = d.get("owned_hero_ids", [])
	if not saved_owned.is_empty():
		var rebuilt: Array[HeroData] = []
		for hid in saved_owned:
			var id := str(hid)
			if HERO_REGISTRY.has(id):
				var h := load(HERO_REGISTRY[id]) as HeroData
				if h != null:
					rebuilt.append(h)
		if not rebuilt.is_empty():
			owned_heroes = rebuilt
	hero_tiers.clear()
	var saved_tiers: Dictionary = d.get("hero_tiers", {})
	for key in saved_tiers.keys():
		hero_tiers[str(key)] = clampi(int(saved_tiers[key]), 0, 6)
	boss_best_score = maxi(0, int(d.get("boss_best_score", 0)))
	boss_best_date = str(d.get("boss_best_date", ""))
	muted = bool(d.get("muted", false))
	arena_points = maxi(0, int(d.get("arena_points", 1000)))
	arena_tickets = maxi(0, int(d.get("arena_tickets", 2)))
	arena_ticket_date = str(d.get("arena_ticket_date", ""))
	var saved_def: Dictionary = d.get("arena_defense", {})
	for key in arena_defense_formation.keys():
		var hid := str(saved_def.get(key, ""))
		arena_defense_formation[key] = get_hero(hid) if not hid.is_empty() else null
	inventory_gears.clear()
	next_gear_uid = maxi(1, int(d.get("next_gear_uid", 1)))
	var by_uid: Dictionary = {}
	for gd in d.get("gears", []):
		var g := EquipmentData.from_dict(gd)
		if g.uid <= 0:
			g.uid = next_gear_uid
			next_gear_uid += 1
		inventory_gears.append(g)
		by_uid[g.uid] = g
	hero_gear.clear()
	var saved_worn: Dictionary = d.get("hero_gear", {})
	for hid in saved_worn.keys():
		var row: Dictionary = {}
		var src: Dictionary = saved_worn[hid]
		for slot in src.keys():
			var uid := int(src[slot])
			var g := by_uid.get(uid) as EquipmentData
			row[int(slot)] = g
			# Kusanmis esya envantara donmez (kayit oncesi degismezi korunur).
			if g != null and inventory_gears.has(g):
				inventory_gears.erase(g)
		hero_gear[str(hid)] = row
