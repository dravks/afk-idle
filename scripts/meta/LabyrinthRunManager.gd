extends Node
class_name LabyrinthRunManager
## Labirent kosusu durumu (autoload "LabyrinthRun"): can/enerji tasima,
## kat/dugum ilerlemesi, kalintilar (cocuk RelicManager).
## Desen sabit 5 adim: savas, elit, pinar, dirilis, boss (dogrusal).

enum LabyrinthNodeType { BATTLE_NORMAL, BATTLE_ELITE, FOUNTAIN, RESURRECTION, BOSS }

const NODES_PER_FLOOR := 5
const FLOOR_PATTERN := [0, 1, 2, 3, 4]

const ENEMY_GOBLIN := "res://data/heroes/goblin.tres"
const ENEMY_ORC := "res://data/heroes/orc.tres"
const ENEMY_WOLF := "res://data/heroes/wolf.tres"
const ENEMY_SHAMAN := "res://data/heroes/shaman.tres"

var relics: RelicManager
var hero_hp_states: Dictionary = {}
var hero_energy_states: Dictionary = {}
var current_floor: int = 1
var current_node_index: int = 0
var completed_nodes: Array[int] = []

func _ready() -> void:
	relics = RelicManager.new()
	add_child(relics)

func reset_run() -> void:
	hero_hp_states.clear()
	hero_energy_states.clear()
	current_floor = 1
	current_node_index = 0
	completed_nodes.clear()
	relics.clear_run_relics()

func node_type(_floor: int, index: int) -> int:
	return int(FLOOR_PATTERN[clampi(index, 0, NODES_PER_FLOOR - 1)])

func node_label(floor: int, index: int) -> String:
	match node_type(floor, index):
		LabyrinthNodeType.BATTLE_NORMAL:
			return "%d. Goblin Pususu" % (index + 1)
		LabyrinthNodeType.BATTLE_ELITE:
			return "%d. Elit Devriye" % (index + 1)
		LabyrinthNodeType.FOUNTAIN:
			return "%d. Sifa Pinari" % (index + 1)
		LabyrinthNodeType.RESURRECTION:
			return "%d. Dirilis Sunagi" % (index + 1)
		_:
			return "%d. Magara Lordu" % (index + 1)

## Dugum dusmanlari: [{hero, level}]. Seviye = 1 + (kat-1)*2 + tip bonusu.
func get_node_enemies(floor: int, index: int) -> Array:
	var lv := 1 + (maxi(1, floor) - 1) * 2
	var out: Array = []
	match node_type(floor, index):
		LabyrinthNodeType.BATTLE_NORMAL:
			for i in 3:
				out.append({"hero": _foe(ENEMY_GOBLIN), "level": lv})
		LabyrinthNodeType.BATTLE_ELITE:
			out.append({"hero": _foe(ENEMY_ORC), "level": lv + 1})
			out.append({"hero": _foe(ENEMY_ORC), "level": lv + 1})
			out.append({"hero": _foe(ENEMY_WOLF), "level": lv + 1})
			out.append({"hero": _foe(ENEMY_SHAMAN), "level": lv + 1})
			out.append({"hero": _foe(ENEMY_GOBLIN), "level": lv + 1})
		_:
			for i in 2:
				out.append({"hero": _foe(ENEMY_ORC), "level": lv + 2})
			out.append({"hero": _foe(ENEMY_SHAMAN), "level": lv + 2})
			out.append({"hero": _foe(ENEMY_SHAMAN), "level": lv + 2})
			out.append({"hero": _foe(ENEMY_WOLF), "level": lv + 2})
	return out

func _foe(path: String) -> HeroData:
	return load(path) as HeroData

## Savas sonu: yasayanlarin can/enerji oranini yaz (oluler 0.0).
func save_battle_end_states(units: Array[Unit]) -> void:
	for u in units:
		if u == null or not is_instance_valid(u) or u.hero_data == null:
			continue
		var st := u.stats_component
		if st == null:
			continue
		hero_hp_states[u.hero_data.id] = clampf(st.current_hp / maxf(1.0, st.max_hp), 0.0, 1.0)
		hero_energy_states[u.hero_data.id] = st.current_energy if not st.is_dead else 0

## Savas basi: kayitli can/enerjiyi uygula (bar sinyalleriyle).
func apply_states_to_spawned_units(units: Array[Unit]) -> void:
	for u in units:
		if u == null or not is_instance_valid(u) or u.hero_data == null:
			continue
		var st := u.stats_component
		if st == null:
			continue
		var hid: String = u.hero_data.id
		if hero_hp_states.has(hid):
			# Sifirla dogmus savunmasi: dizilim zaten oluleri engeller.
			st.current_hp = maxf(1.0, st.max_hp * clampf(float(hero_hp_states[hid]), 0.0, 1.0))
			st.hp_changed.emit(st.current_hp, st.max_hp)
		if hero_energy_states.has(hid):
			# Kalinti bonusu (START_ENERGY) ezilmez: buyuk olan yasar.
			st.current_energy = maxi(clampi(int(hero_energy_states[hid]), 0, st.max_energy), st.current_energy)
			st.energy_changed.emit(st.current_energy, st.max_energy)

func is_hero_dead(hero_id: String) -> bool:
	return hero_hp_states.has(hero_id) and float(hero_hp_states[hero_id]) <= 0.0

## Pinar: yasayan kayitlilari +0.50 doldur (kayitsizlar zaten full).
func use_fountain() -> void:
	for key in hero_hp_states.keys():
		var r := float(hero_hp_states[key])
		if r > 0.0:
			hero_hp_states[key] = minf(1.0, r + 0.5)

## Sunak: ilk oluyu %100 dirilt, id'sini don (yoksa "").
func use_resurrection() -> String:
	for key in hero_hp_states.keys():
		if float(hero_hp_states[key]) <= 0.0:
			hero_hp_states[key] = 1.0
			hero_energy_states[str(key)] = 0
			return str(key)
	return ""

func complete_node(index: int) -> void:
	if not (index in completed_nodes):
		completed_nodes.append(index)
	current_node_index = index + 1
	if node_type(current_floor, index) == LabyrinthNodeType.BOSS:
		current_floor += 1
		current_node_index = 0
		completed_nodes.clear()

func get_save_data() -> Dictionary:
	var hp: Dictionary = {}
	for key in hero_hp_states.keys():
		hp[str(key)] = float(hero_hp_states[key])
	var en: Dictionary = {}
	for key in hero_energy_states.keys():
		en[str(key)] = int(hero_energy_states[key])
	var done: Array = []
	for i in completed_nodes:
		done.append(i)
	var data := {
		"lab_floor": current_floor, "lab_node": current_node_index,
		"lab_completed": done, "lab_hp": hp, "lab_energy": en,
	}
	for key in relics.get_save_data().keys():
		data[key] = relics.get_save_data()[key]
	return data

func apply_save_data(d: Dictionary) -> void:
	current_floor = maxi(1, int(d.get("lab_floor", 1)))
	current_node_index = maxi(0, int(d.get("lab_node", 0)))
	completed_nodes.clear()
	for i in d.get("lab_completed", []):
		completed_nodes.append(int(i))
	hero_hp_states.clear()
	var hp: Dictionary = d.get("lab_hp", {})
	for key in hp.keys():
		hero_hp_states[str(key)] = clampf(float(hp[key]), 0.0, 1.0)
	hero_energy_states.clear()
	var en: Dictionary = d.get("lab_energy", {})
	for key in en.keys():
		hero_energy_states[str(key)] = int(en[key])
	relics.apply_save_data(d)
