extends Node
## AFK Sandigi: cevrimdisi pasif gelir. Unix zamaniyla gercek gecen sureyi
## olcer, 12 saat cap uygular. Cuzdan (gold/exp/dust) bu sinifta tutulur;
## ileride merkezi PlayerData gelirse devredilir.

signal rewards_claimed(gold: int, exp: int, dust: int)
signal afk_time_updated(accumulated_seconds: int)

const MAX_ACCUMULATION_SECONDS := 43200  # 12 saat
const QUICK_REWARD_MINUTES := 120  # hizli odul = 2 saatlik

var last_claim_timestamp: int = 0
var current_stage: int = 1
var gold: int = 0
var hero_exp: int = 0
var dust: int = 0

var _tick := 0.0

func _ready() -> void:
	if last_claim_timestamp <= 0:
		last_claim_timestamp = int(Time.get_unix_time_from_system())

func _process(delta: float) -> void:
	_tick += delta
	if _tick >= 1.0:
		_tick = 0.0
		afk_time_updated.emit(get_accumulated_seconds())

## Dakika basina uretim (kampanya bolumune gore olceklenir).
func get_rates_per_minute() -> Dictionary:
	return {
		"gold": 60 + current_stage * 15,
		"exp": 40 + current_stage * 10,
		"dust": 5 + current_stage * 2,
	}

func get_accumulated_seconds() -> int:
	var now := int(Time.get_unix_time_from_system())
	return clampi(now - last_claim_timestamp, 0, MAX_ACCUMULATION_SECONDS)

func calculate_pending_rewards() -> Dictionary:
	var minutes := float(get_accumulated_seconds()) / 60.0
	var rates := get_rates_per_minute()
	return {
		"gold": int(minutes * float(rates["gold"])),
		"exp": int(minutes * float(rates["exp"])),
		"dust": int(minutes * float(rates["dust"])),
	}

func claim_rewards() -> Dictionary:
	var r := calculate_pending_rewards()
	gold += int(r["gold"])
	hero_exp += int(r["exp"])
	dust += int(r["dust"])
	last_claim_timestamp = int(Time.get_unix_time_from_system())
	rewards_claimed.emit(int(r["gold"]), int(r["exp"]), int(r["dust"]))
	AudioManager.play_sfx("coins")
	QuestEvents.afk_claimed.emit()
	return r

## Aninda 120 dakikalik odul (birikmis sureyi etkilemez).
func claim_quick_rewards() -> Dictionary:
	var rates := get_rates_per_minute()
	var r := {
		"gold": QUICK_REWARD_MINUTES * int(rates["gold"]),
		"exp": QUICK_REWARD_MINUTES * int(rates["exp"]),
		"dust": QUICK_REWARD_MINUTES * int(rates["dust"]),
	}
	gold += int(r["gold"])
	hero_exp += int(r["exp"])
	dust += int(r["dust"])
	rewards_claimed.emit(int(r["gold"]), int(r["exp"]), int(r["dust"]))
	QuestEvents.afk_claimed.emit()
	return r

func get_save_data() -> Dictionary:
	return {
		"gold": gold,
		"hero_exp": hero_exp,
		"dust": dust,
		"last_claim_timestamp": last_claim_timestamp,
		"current_stage": current_stage,
	}

func apply_save_data(d: Dictionary) -> void:
	gold = int(d.get("gold", 0))
	hero_exp = int(d.get("hero_exp", 0))
	dust = int(d.get("dust", 0))
	last_claim_timestamp = int(d.get("last_claim_timestamp", 0))
	current_stage = maxi(1, int(d.get("current_stage", 1)))
	if last_claim_timestamp <= 0:
		last_claim_timestamp = int(Time.get_unix_time_from_system())
