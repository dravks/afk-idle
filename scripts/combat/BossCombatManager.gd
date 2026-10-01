extends Node
class_name BossCombatManager
## Dunya bossu hakemi: 90sn sure, 20sn ofke dongusu (2sn onceden uyarilir),
## kademe + odul dagitimi. Birimler FSM ile calisir; bu sinif gozlemler.

signal boss_damage_updated(total_damage: float)
signal boss_enrage_warning
signal boss_battle_ended(final_damage: float, tier_achieved: String, rewards: Dictionary)

const MATCH_TIME := 90.0
const WARN_BEFORE := 2.0

const TIER_LABELS := {
	"": "KATILIM", "bronze": "BRONZ", "silver": "GÜMÜŞ",
	"gold": "ALTIN", "diamond": "ELMAS",
}

var boss: BossUnit
var player_units: Array[Unit] = []
var commander: CommanderManager
var total_boss_damage_dealt: float = 0.0
var enrage_timer: float = 0.0
var match_timer: float = MATCH_TIME
var is_active: bool = false

var _warned := false
var _ended := false

static func format_damage(n: float) -> String:
	var s := str(maxi(0, int(n)))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

static func tier_for_damage(dmg: float) -> String:
	if dmg >= 3000000.0:
		return "diamond"
	elif dmg >= 1500000.0:
		return "gold"
	elif dmg >= 500000.0:
		return "silver"
	elif dmg >= 100000.0:
		return "bronze"
	return ""

static func today_key() -> String:
	var dt := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(dt["year"]), int(dt["month"]), int(dt["day"])]

func begin(boss_unit: BossUnit, players: Array[Unit], boss_commander: CommanderManager) -> void:
	boss = boss_unit
	player_units = players
	commander = boss_commander
	total_boss_damage_dealt = 0.0
	enrage_timer = 0.0
	match_timer = MATCH_TIME
	_warned = false
	_ended = false
	is_active = true

func _process(delta: float) -> void:
	if not is_active or _ended:
		return
	match_timer -= delta
	enrage_timer += delta
	if boss != null and is_instance_valid(boss):
		total_boss_damage_dealt = boss.total_damage_received
		boss_damage_updated.emit(total_boss_damage_dealt)
	var interval := _enrage_interval()
	if enrage_timer >= interval - WARN_BEFORE and not _warned:
		_warned = true
		boss_enrage_warning.emit()
	if enrage_timer >= interval:
		enrage_timer = 0.0
		_warned = false
		_execute_enrage()
	if match_timer <= 0.0 or _wipe():
		end_boss_battle()

func grant_tier_rewards(tier: String) -> Dictionary:
	var bundle := {"tier_name": str(TIER_LABELS.get(tier, "?"))}
	match tier:
		"bronze":
			bundle["gold"] = 20000
			bundle["dust"] = 100
			PlayerProfile.gold += 20000
			AFKManager.dust += 100
		"silver":
			bundle["exp"] = 2000
			AFKManager.hero_exp += 2000
			bundle["gears"] = [_drop_gear(30.0)]
		"gold":
			bundle["diamonds"] = 300
			PlayerProfile.diamonds += 300
			var tavern := TavernManager.new()
			add_child(tavern)
			var pulled := tavern.summon_single(PlayerProfile, true)
			tavern.queue_free()
			bundle["summon"] = pulled.hero_name if pulled != null else "-"
		"diamond":
			bundle["diamonds"] = 500
			PlayerProfile.diamonds += 500
			bundle["gears"] = [_drop_gear(80.0), _drop_gear(80.0)]
	return bundle

func end_boss_battle() -> void:
	if _ended:
		return
	_ended = true
	is_active = false
	Engine.time_scale = 1.0
	QuestEvents.boss_challenged.emit(total_boss_damage_dealt)
	if boss != null and is_instance_valid(boss):
		total_boss_damage_dealt = boss.total_damage_received
	var tier := tier_for_damage(total_boss_damage_dealt)
	var rewards := grant_tier_rewards(tier)
	var today := today_key()
	if today != PlayerProfile.boss_best_date or total_boss_damage_dealt > float(PlayerProfile.boss_best_score):
		PlayerProfile.boss_best_date = today
		PlayerProfile.boss_best_score = int(total_boss_damage_dealt)
	GameFlowManager.save_all()
	for u in player_units:
		if is_instance_valid(u):
			(u as Unit).set_frozen(true)
	if boss != null and is_instance_valid(boss):
		boss.set_frozen(true)
	if commander != null and is_instance_valid(commander):
		commander.set_process(false)
	boss_battle_ended.emit(total_boss_damage_dealt, tier, rewards)

func _enrage_interval() -> float:
	if boss != null and is_instance_valid(boss) and boss.hero_data is BossData:
		return maxf(5.0, (boss.hero_data as BossData).enrage_interval)
	return 20.0

func _execute_enrage() -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var skill: SkillData = null
	if boss.hero_data is BossData:
		skill = (boss.hero_data as BossData).enrage_skill
	if skill == null:
		return
	AudioManager.play_sfx("boss_roar")
	var ecam := CameraShake.find_camera(get_tree())
	if ecam != null:
		ecam.add_trauma(0.75)
	SkillExecutor.apply_skill(boss, skill, SkillExecutor.resolve_targets(boss, skill))

func _wipe() -> bool:
	for u in player_units:
		if is_instance_valid(u) and not (u as Unit).stats_component.is_dead:
			return false
	return true

func _drop_gear(power: float) -> String:
	var g := PlayerProfile.make_gear(randi() % 4, power)
	return g.item_name
