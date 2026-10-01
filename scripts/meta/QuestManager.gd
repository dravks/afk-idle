extends Node
class_name QuestManager
## Gunluk gorevler (0-100 puan, 5 sandik) + kalici basarimlar.
## QuestEvents dinler; oduller profile islenir. Gun donumunde gunlukler
## sifirlanir, basarimlar kalir. Kayit dilimi Flow.save_all ile birlesir.

signal quest_progress_updated
signal daily_points_changed(points: int)
signal has_unclaimed_rewards_changed(has_unclaimed: bool)

const MILESTONES := [20, 40, 60, 80, 100]

# id, baslik, aciklama, hedef, puan
const DAILIES := [
	["dq_campaign", "Kampanya Savaşı Kazan", "2 kez kazan", 2, 20],
	["dq_levelup", "Kahraman Geliştir", "3 kez seviye atla", 3, 15],
	["dq_afk", "AFK Sandığı Topla", "1 kez topla", 1, 10],
	["dq_summon", "Tavern Çekilişi", "3 çağrı yap", 3, 15],
	["dq_boss", "Boss'a Meydan Oku", "1 deneme", 1, 20],
	["dq_labyrinth", "Labirent Savaşı Kazan", "2 kez kazan", 2, 20],
	["dq_arena", "Arena'da Savaş", "2 kez savaş", 2, 15],
	["dq_tower", "Kule Katı Geç", "2 kat geç", 2, 15],
]
# id, baslik, aciklama, hedef, elmas, parsonen
const ACHIEVEMENTS := [
	["ac_campaign10", "Kampanya Fatihi", "10 kampanya zaferi", 10, 100, 0],
	["ac_levelup25", "Usta Eğitmen", "25 seviye atlat", 25, 100, 0],
	["ac_boss1m", "Ejderha Avcısı", "Boss'a toplam 1M hasar", 1000000, 150, 0],
	["ac_summon50", "Koleksiyoncu", "50 çağrı yap", 50, 0, 1],
	["ac_labyrinth5", "Labirent Kaşifi", "5 labirent zaferi", 5, 150, 0],
]

var daily_points: int = 0
var claimed_milestones: Array[int] = []
var daily_quests: Array[QuestData] = []
var achievements: Array[QuestData] = []

var _last_date := ""
var _has_unclaimed := false

func _ready() -> void:
	_build_catalog()
	_last_date = BossCombatManager.today_key()
	QuestEvents.afk_claimed.connect(_on_afk_claimed)
	QuestEvents.boss_challenged.connect(_on_boss_challenged)
	QuestEvents.hero_leveled_up.connect(_on_hero_leveled_up)
	QuestEvents.summon_performed.connect(_on_summon_performed)
	QuestEvents.campaign_won.connect(_on_campaign_won)
	QuestEvents.labyrinth_battle_won.connect(_on_labyrinth_battle_won)
	QuestEvents.arena_battle_completed.connect(_on_arena_battle_completed)
	QuestEvents.tower_floor_cleared.connect(_on_tower_floor_cleared)

func find_quest(quest_id: String) -> QuestData:
	for q in daily_quests + achievements:
		if q.id == quest_id:
			return q
	return null

func claim_quest(quest_id: String, profile) -> bool:
	var q := find_quest(quest_id)
	if q == null or q.is_claimed or not q.is_complete():
		return false
	q.is_claimed = true
	if q.quest_type == QuestData.QuestType.DAILY:
		daily_points += q.reward_points
		daily_points_changed.emit(daily_points)
	elif profile != null:
		profile.diamonds += q.reward_diamonds
		for i in q.reward_scrolls:
			_free_summon(profile)
	quest_progress_updated.emit()
	check_unclaimed_status()
	return true

func claim_milestone_chest(milestone_points: int, profile) -> bool:
	if not (milestone_points in MILESTONES):
		return false
	if milestone_points in claimed_milestones:
		return false
	if daily_points < milestone_points or profile == null:
		return false
	match milestone_points:
		20:
			profile.gold += 50000
		40:
			AFKManager.dust += 100
		60:
			AFKManager.hero_exp += 100
		80:
			profile.diamonds += 100
		100:
			_free_summon(profile)
	claimed_milestones.append(milestone_points)
	daily_points_changed.emit(daily_points)
	check_unclaimed_status()
	return true

func has_unclaimed_rewards() -> bool:
	for q in daily_quests + achievements:
		if not q.is_claimed and q.is_complete():
			return true
	for m in MILESTONES:
		if not (m in claimed_milestones) and daily_points >= m:
			return true
	return false

func check_unclaimed_status() -> void:
	var now := has_unclaimed_rewards()
	if now != _has_unclaimed:
		_has_unclaimed = now
		has_unclaimed_rewards_changed.emit(now)

func get_save_data() -> Dictionary:
	var dq: Dictionary = {}
	for q in daily_quests:
		dq[q.id] = [q.current_amount, q.is_claimed]
	var ac: Dictionary = {}
	for q in achievements:
		ac[q.id] = [q.current_amount, q.is_claimed]
	return {
		"quest_date": _last_date,
		"quest_points": daily_points,
		"quest_milestones": claimed_milestones.duplicate(),
		"quest_daily": dq,
		"quest_ach": ac,
	}

func apply_save_data(d: Dictionary) -> void:
	_restore(daily_quests, d.get("quest_daily", {}))
	_restore(achievements, d.get("quest_ach", {}))
	daily_points = int(d.get("quest_points", 0))
	claimed_milestones.clear()
	for m in d.get("quest_milestones", []):
		claimed_milestones.append(int(m))
	_last_date = str(d.get("quest_date", ""))
	# Gun donduyse gunlukler sifirlanir; basarimlar kalir.
	if _last_date != BossCombatManager.today_key():
		_reset_dailies()
	check_unclaimed_status()

func _restore(list: Array[QuestData], saved: Dictionary) -> void:
	for q in list:
		if saved.has(q.id):
			var pair: Array = saved[q.id]
			if pair.size() >= 2:
				q.current_amount = int(pair[0])
				q.is_claimed = bool(pair[1])

func _reset_dailies() -> void:
	for q in daily_quests:
		q.current_amount = 0
		q.is_claimed = false
	daily_points = 0
	claimed_milestones.clear()
	_last_date = BossCombatManager.today_key()
	daily_points_changed.emit(daily_points)

func _bump(quest_id: String, amount: int) -> void:
	if _last_date != BossCombatManager.today_key():
		_reset_dailies()
	var q := find_quest(quest_id)
	if q == null:
		return
	if q.quest_type == QuestData.QuestType.ACHIEVEMENT and q.is_claimed:
		return
	q.current_amount += amount
	quest_progress_updated.emit()
	check_unclaimed_status()

func _free_summon(profile) -> void:
	var tavern := TavernManager.new()
	add_child(tavern)
	tavern.summon_single(profile, true)
	tavern.queue_free()

func _build_catalog() -> void:
	daily_quests.clear()
	for row in DAILIES:
		var q := QuestData.new()
		q.id = str(row[0])
		q.title = str(row[1])
		q.description = str(row[2])
		q.quest_type = QuestData.QuestType.DAILY
		q.target_amount = int(row[3])
		q.reward_points = int(row[4])
		daily_quests.append(q)
	achievements.clear()
	for row in ACHIEVEMENTS:
		var q := QuestData.new()
		q.id = str(row[0])
		q.title = str(row[1])
		q.description = str(row[2])
		q.quest_type = QuestData.QuestType.ACHIEVEMENT
		q.target_amount = int(row[3])
		q.reward_diamonds = int(row[4])
		q.reward_scrolls = int(row[5])
		achievements.append(q)

func _on_afk_claimed() -> void:
	_bump("dq_afk", 1)

func _on_boss_challenged(damage: float) -> void:
	_bump("dq_boss", 1)
	_bump("ac_boss1m", int(damage))

func _on_hero_leveled_up() -> void:
	_bump("dq_levelup", 1)
	_bump("ac_levelup25", 1)

func _on_summon_performed(count: int) -> void:
	_bump("dq_summon", count)
	_bump("ac_summon50", count)

func _on_campaign_won(_stage_index: int) -> void:
	_bump("dq_campaign", 1)
	_bump("ac_campaign10", 1)

func _on_labyrinth_battle_won() -> void:
	_bump("dq_labyrinth", 1)
	_bump("ac_labyrinth5", 1)

func _on_arena_battle_completed(_is_victory: bool) -> void:
	_bump("dq_arena", 1)

func _on_tower_floor_cleared(_floor_number: int) -> void:
	_bump("dq_tower", 1)
