extends Node
class_name TowerManager
## Kralin Kulesi: dikey sonsuz tirmanis. Kat verisi formulle uretilir,
## oduller ilk-gecekte tam, tekrarda %20 altindir (ciftlik onler).
## Otomatik tirmanis bayragi oturumluk tutulur (kaydedilmez).

signal floor_cleared(floor_number: int, rewards: Dictionary)
signal auto_climb_state_changed(is_active: bool)

const ENEMY_POOL: Array[String] = [
	"res://data/heroes/goblin.tres",
	"res://data/heroes/orc.tres",
	"res://data/heroes/wolf.tres",
	"res://data/heroes/shaman.tres",
	"res://data/heroes/hero_gwyneth.tres",
	"res://data/heroes/hero_eironn.tres",
	"res://data/heroes/hero_saveas.tres",
	"res://data/heroes/hero_skreg.tres",
]

var current_floor: int = 1
var is_auto_climb_active: bool = false

func set_auto_climb_active(v: bool) -> void:
	if is_auto_climb_active == v:
		return
	is_auto_climb_active = v
	auto_climb_state_changed.emit(v)

func is_elite_floor(floor_num: int) -> bool:
	return floor_num % 5 == 0

func get_floor_stage_data(floor_num: int) -> StageData:
	var f := maxi(1, floor_num)
	var st := StageData.new()
	st.stage_id = "Tower-%d" % f
	st.stage_number = 1000 + f
	var lv := int(2.0 + float(f) * 1.8)
	var comp := _floor_comp(f)
	if is_elite_floor(f):
		lv += 2
	st.enemy_team_level = lv
	st.enemy_front_top = comp[0]
	st.enemy_front_bot = comp[1]
	st.enemy_back_top = comp[2]
	st.enemy_back_mid = comp[3]
	st.enemy_back_bot = comp[4]
	st.first_clear_gold = 2000 + f * 500
	st.first_clear_diamonds = 150 if is_elite_floor(f) else 20
	return st

func process_victory(profile) -> Dictionary:
	var st := get_floor_stage_data(current_floor)
	var first: bool = not (current_floor in profile.tower_cleared)
	var rewards := {}
	var gold := st.first_clear_gold if first else int(float(st.first_clear_gold) * 0.2)
	profile.gold += gold
	rewards["gold"] = gold
	if first:
		var dust := 30 + current_floor * 5
		AFKManager.dust += dust
		rewards["dust"] = dust
		profile.diamonds += st.first_clear_diamonds
		rewards["diamonds"] = st.first_clear_diamonds
		if is_elite_floor(current_floor):
			var tavern := TavernManager.new()
			add_child(tavern)
			var pulled := tavern.summon_single(profile, true)
			tavern.queue_free()
			rewards["summon"] = pulled.hero_name if pulled != null else "-"
		profile.tower_cleared.append(current_floor)
	QuestEvents.tower_floor_cleared.emit(current_floor)
	var cleared_floor := current_floor
	current_floor += 1
	profile.tower_floor = current_floor
	floor_cleared.emit(cleared_floor, rewards)
	return rewards

func _floor_comp(floor_num: int) -> Array:
	var pool: Array = []
	for path in ENEMY_POOL:
		var h := load(path) as HeroData
		if h != null:
			pool.append(h)
	if pool.is_empty():
		return []
	if is_elite_floor(floor_num):
		var orc: HeroData = pool[1]
		var shaman: HeroData = pool[3]
		var wolf: HeroData = pool[2]
		return [orc, orc, shaman, wolf, shaman]
	var f := floor_num
	var n := pool.size()
	return [pool[f % n], pool[(f + 2) % n], pool[(f + 1) % n], pool[(f + 3) % n], pool[(f + 5) % n]]

func floor_cp_estimate(floor_num: int) -> int:
	var st := get_floor_stage_data(floor_num)
	var total := 0
	for h in [st.enemy_front_top, st.enemy_front_bot, st.enemy_back_top, st.enemy_back_mid, st.enemy_back_bot]:
		var hd := h as HeroData
		if hd == null:
			continue
		var s := hd.calculate_stats_at_level(st.enemy_team_level)
		total += int(float(s["atk"]) + float(s["hp"]) / 10.0)
	return total
