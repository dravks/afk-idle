extends Node
class_name ArenaManager
## Asenkron PvP arenasi: puan/lig/bilet + 3 kademeli rakip uretimi.
## Puanlar profilde yasar (tek kaynak); bu sinif kosu-anlik aynadir.
## Savunma dizilimi + biletler de profilde; bilet kontrolu burada.

signal points_updated(new_points: int, league_name: String)
signal tickets_updated(remaining: int)

const NAME_POOL: Array[String] = [
	"Gladiator", "Kara Şövalye", "Fırtına", "Demir Yumruk", "Gece Avcısı",
	"Taş Dev", "Kuzgun", "Asil", "Barbar", "Avcı",
]
const SLOTS := ["FRONT_TOP", "FRONT_BOT", "BACK_TOP", "BACK_MID", "BACK_BOT"]

var current_points: int = 1000
var free_tickets: int = 2
var generated_opponents: Array[ArenaOpponentData] = []

func _ready() -> void:
	sync_from_profile()

func sync_from_profile() -> void:
	current_points = maxi(0, int(PlayerProfile.arena_points))
	refresh_tickets()

func refresh_tickets() -> void:
	var today := BossCombatManager.today_key()
	if PlayerProfile.arena_ticket_date != today:
		PlayerProfile.arena_ticket_date = today
		PlayerProfile.arena_tickets = 2
	free_tickets = maxi(0, int(PlayerProfile.arena_tickets))
	tickets_updated.emit(free_tickets)

func get_league_name() -> String:
	if current_points < 1200:
		return "BRONZ LİGİ"
	if current_points < 1500:
		return "GÜMÜŞ LİGİ"
	if current_points < 1900:
		return "ALTIN LİGİ"
	return "ELMAS LİGİ"

## Dizilim gucu: atk + can/10 + def*5 toplami (rakip olceklemede iki taraf
## ayni cetvelle olculur).
static func formation_cp(form: Dictionary) -> int:
	var total := 0
	for key in form.keys():
		var h := form[key] as HeroData
		if h == null:
			continue
		var lv := ResonatingCrystalManager.get_effective_level(h.id)
		total += _cp_at(h, lv)
	return total

static func formation_cp_for_list(heroes: Array, level: int) -> int:
	var total := 0
	for h in heroes:
		var hd := h as HeroData
		if hd != null:
			total += _cp_at(hd, level)
	return total

static func _cp_at(h: HeroData, level: int) -> int:
	var st := h.calculate_stats_at_level(level)
	return int(float(st["atk"]) + float(st["hp"]) / 10.0 + float(st["def"]) * 5.0)

func generate_opponents(player_cp: int) -> Array[ArenaOpponentData]:
	generated_opponents.clear()
	var defs := [
		{"dpts": -30, "cpm": 0.85},
		{"dpts": 5, "cpm": 1.0},
		{"dpts": 40, "cpm": 1.20},
	]
	var names := NAME_POOL.duplicate()
	names.shuffle()
	for i in 3:
		var o := ArenaOpponentData.new()
		o.opponent_name = str(names[i])
		o.rank_points = maxi(0, current_points + int(defs[i]["dpts"]))
		var target_cp := int(maxi(100, player_cp) * float(defs[i]["cpm"]))
		var heroes := _random_five()
		var lv := _level_for_cp(heroes, target_cp)
		o.combat_power = formation_cp_for_list(heroes, lv)
		for s in 5:
			o.formation[SLOTS[s]] = {"hero_data": heroes[s], "level": lv}
		generated_opponents.append(o)
	return generated_opponents

func use_ticket() -> bool:
	refresh_tickets()
	if free_tickets <= 0:
		return false
	free_tickets -= 1
	PlayerProfile.arena_tickets = free_tickets
	tickets_updated.emit(free_tickets)
	return true

func add_ticket() -> void:
	refresh_tickets()
	free_tickets += 1
	PlayerProfile.arena_tickets = free_tickets
	tickets_updated.emit(free_tickets)

func preview_delta(opponent: ArenaOpponentData) -> int:
	if opponent == null:
		return 25
	return clampi(int((opponent.rank_points - current_points) * 0.2) + 25, 15, 45)

func process_battle_result(is_victory: bool, opponent: ArenaOpponentData) -> int:
	var delta := -12
	if is_victory:
		delta = preview_delta(opponent)
	current_points = maxi(0, current_points + delta)
	PlayerProfile.arena_points = current_points
	QuestEvents.arena_battle_completed.emit(is_victory)
	points_updated.emit(current_points, get_league_name())
	return delta

func _random_five() -> Array:
	var ids := PlayerProfile.HERO_REGISTRY.keys()
	ids.shuffle()
	var out: Array = []
	for i in mini(5, ids.size()):
		var h := load(str(PlayerProfile.HERO_REGISTRY[str(ids[i])])) as HeroData
		if h != null:
			out.append(h)
	while out.size() < 5 and not out.is_empty():
		out.append(out[out.size() - 1])
	return out

func _level_for_cp(heroes: Array, target_cp: int) -> int:
	var lv := 1
	while lv < 240 and formation_cp_for_list(heroes, lv) < target_cp:
		lv += 2
	while lv > 1 and formation_cp_for_list(heroes, lv - 1) >= target_cp:
		lv -= 1
	return lv
