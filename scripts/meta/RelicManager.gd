extends Node
class_name RelicManager
## Kosu boyu kalinti cantasi. Havuz .tres'lerden kurulur; savas basi
## etkiler CombatManager uzerinden enjekte edilir.

signal relics_changed

const RELIC_FILES: Array[String] = [
	"res://data/relics/relic_battle_paint.tres",
	"res://data/relics/relic_fang.tres",
	"res://data/relics/relic_drum.tres",
	"res://data/relics/relic_tome.tres",
	"res://data/relics/relic_vial.tres",
]
const COMMANDER_DMG_BONUS := 0.30

var pool: Array[RelicData] = []
var active_relics: Array[RelicData] = []

func _ready() -> void:
	for path in RELIC_FILES:
		var r := load(path) as RelicData
		if r != null:
			pool.append(r)
		else:
			push_error("RelicManager: kalinti yuklenemedi: %s" % path)

func add_relic(relic: RelicData) -> void:
	if relic == null:
		return
	active_relics.append(relic)
	relics_changed.emit()

func clear_run_relics() -> void:
	active_relics.clear()
	relics_changed.emit()

## Birbirinden farkli n kalinti (havuz kucukse tumu).
func roll_choices(count: int) -> Array[RelicData]:
	var out: Array[RelicData] = []
	var bag := pool.duplicate()
	bag.shuffle()
	for i in mini(count, bag.size()):
		out.append(bag[i])
	return out

func apply_combat_start_effects(player_units: Array[Unit], commander_mgr: CommanderManager) -> void:
	for relic in active_relics:
		if relic == null:
			continue
		match relic.effect_type:
			RelicData.RelicEffectType.STAT_BOOST:
				for u in player_units:
					if _ok(u):
						u.stats_component.atk *= 1.0 + relic.effect_value
						u.stats_component.def *= 1.0 + relic.effect_value
			RelicData.RelicEffectType.LIFE_STEAL:
				for u in player_units:
					if _ok(u):
						u.lifesteal_pct = maxf(u.lifesteal_pct, relic.effect_value)
			RelicData.RelicEffectType.START_ENERGY:
				for u in player_units:
					if _ok(u):
						u.stats_component.add_energy(int(relic.effect_value))
			RelicData.RelicEffectType.COMMANDER_BOOST:
				if commander_mgr != null:
					commander_mgr.mana_regen_rate *= 1.0 + relic.effect_value
					commander_mgr.spell_power_mult = 1.0 + COMMANDER_DMG_BONUS
			RelicData.RelicEffectType.POISON_START:
				_poison_enemies(relic.effect_value)

func _poison_enemies(max_hp_fraction: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or u.team != Unit.Team.ENEMY:
			continue
		if u.stats_component == null or u.stats_component.is_dead or u.buff_component == null:
			continue
		var dot := BuffData.new()
		dot.id = "relic_poison"
		dot.buff_type = GlobalEnums.BuffType.DOT
		dot.duration = 5.0
		dot.tick_interval = 1.0
		dot.flat_value = u.stats_component.max_hp * max_hp_fraction
		u.buff_component.apply_buff(dot, null)

func _ok(u: Unit) -> bool:
	return u != null and is_instance_valid(u) and u.stats_component != null \
		and not u.stats_component.is_dead

func get_save_data() -> Dictionary:
	var ids: Array = []
	for r in active_relics:
		if r != null:
			ids.append(r.id)
	return {"relic_ids": ids}

func apply_save_data(d: Dictionary) -> void:
	active_relics.clear()
	for rid in d.get("relic_ids", []):
		var found := _by_id(str(rid))
		if found != null:
			active_relics.append(found)

func _by_id(relic_id: String) -> RelicData:
	for r in pool:
		if r.id == relic_id:
			return r
	return null
