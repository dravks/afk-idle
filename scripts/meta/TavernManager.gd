extends Node
class_name TavernManager
## Gacha motoru: elmasla kahraman cagirma. Havuz .tres'lerden kurulur,
## nadirlik id listeleriyle belirlenir (HeroData'da rarite alani yok).
## Cekilen kahraman profile + kristale (sv1) islenir.

signal summoned(heroes: Array)

const SINGLE_COST := 300
const TEN_COST := 2700

const POOL_ELITE: Array[String] = [
	"res://data/heroes/mage.tres",
	"res://data/heroes/shaman.tres",
	"res://data/heroes/hero_lucius.tres",
	"res://data/heroes/hero_shemira.tres",
	"res://data/heroes/hero_brutus.tres",
	"res://data/heroes/hero_eironn.tres",
]
const POOL_RARE: Array[String] = [
	"res://data/heroes/guard.tres",
	"res://data/heroes/striker.tres",
	"res://data/heroes/cleric.tres",
	"res://data/heroes/orc.tres",
	"res://data/heroes/hero_gwyneth.tres",
	"res://data/heroes/hero_rowan.tres",
	"res://data/heroes/hero_silvina.tres",
	"res://data/heroes/hero_thorin.tres",
	"res://data/heroes/hero_tasi.tres",
	"res://data/heroes/hero_nemora.tres",
	"res://data/heroes/hero_saveas.tres",
	"res://data/heroes/hero_skreg.tres",
]
const POOL_COMMON: Array[String] = [
	"res://data/heroes/footman.tres",
	"res://data/heroes/goblin.tres",
	"res://data/heroes/wolf.tres",
]

const P_ELITE := 0.0461
const P_RARE := 0.4831  # 0.0461 + 0.4370

var hero_pool: Array[HeroData] = []

func _ready() -> void:
	for path in POOL_ELITE + POOL_RARE + POOL_COMMON:
		var h := load(path) as HeroData
		if h != null:
			hero_pool.append(h)

## 0 = siradan, 1 = nadir, 2 = elit (UI parlamasi icin).
func get_tier(hero: HeroData) -> int:
	if hero == null:
		return 0
	for path in POOL_ELITE:
		if path.ends_with(hero.id + ".tres"):
			return 2
	for path in POOL_RARE:
		if path.ends_with(hero.id + ".tres"):
			return 1
	return 0

func affordable(profile, ten: bool) -> bool:
	if profile == null:
		return false
	return int(profile.diamonds) >= (TEN_COST if ten else SINGLE_COST)

func summon_single(profile, free: bool = false) -> HeroData:
	if profile == null or hero_pool.is_empty():
		return null
	if not free:
		if int(profile.diamonds) < SINGLE_COST:
			return null
		profile.diamonds -= SINGLE_COST
	var pulled := _roll()
	_register(pulled, profile)
	summoned.emit([pulled])
	QuestEvents.summon_performed.emit(1)
	return pulled

func summon_ten(profile) -> Array[HeroData]:
	var out: Array[HeroData] = []
	if profile == null or hero_pool.is_empty():
		return out
	if int(profile.diamonds) < TEN_COST:
		return out
	profile.diamonds -= TEN_COST
	for i in 10:
		var pulled := _roll()
		_register(pulled, profile)
		out.append(pulled)
	summoned.emit(out)
	QuestEvents.summon_performed.emit(10)
	return out

func _roll() -> HeroData:
	var r := randf()
	var path: String
	if r < P_ELITE:
		path = POOL_ELITE[randi() % POOL_ELITE.size()]
	elif r < P_RARE:
		path = POOL_RARE[randi() % POOL_RARE.size()]
	else:
		path = POOL_COMMON[randi() % POOL_COMMON.size()]
	return load(path) as HeroData

func _register(pulled: HeroData, profile) -> void:
	if pulled == null:
		return
	profile.owned_heroes.append(pulled)
	# Yeni id ilk kez geliyorsa kademesi zar nadirliginden yazilir; mevcut
	# kademe ASLA dusurulmez (baslangic kadrosu ELITE kalir).
	if not profile.hero_tiers.has(pulled.id):
		profile.hero_tiers[pulled.id] = get_tier(pulled)
	if not ResonatingCrystalManager.hero_levels.has(pulled.id):
		ResonatingCrystalManager.add_hero(pulled, 1)
