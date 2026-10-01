extends Node
class_name CampaignManager
## 1-4 sonrasi dinamik bolum uretimi. Ilk 3 bolum .tres'ten gelir
## (stage_1_N.tres varsa o); sonrasi formulle uretilir:
## seviye = 1 + index*1.5, oduller indeksle olceklenir, kadro deterministik
## donger (test edilebilirlik icin rastgelelik yok).

const POOL_FRONT: Array[String] = [
	"res://data/heroes/orc.tres",
	"res://data/heroes/goblin.tres",
	"res://data/heroes/hero_thorin.tres",
	"res://data/heroes/hero_skreg.tres",
	"res://data/heroes/hero_brutus.tres",
	"res://data/heroes/hero_eironn.tres",
]
const POOL_BACK: Array[String] = [
	"res://data/heroes/shaman.tres",
	"res://data/heroes/wolf.tres",
	"res://data/heroes/goblin.tres",
	"res://data/heroes/hero_shemira.tres",
	"res://data/heroes/hero_gwyneth.tres",
	"res://data/heroes/hero_saveas.tres",
	"res://data/heroes/hero_rowan.tres",
	"res://data/heroes/hero_tasi.tres",
	"res://data/heroes/hero_nemora.tres",
]

func get_stage_data(stage_index: int) -> StageData:
	var idx := maxi(1, stage_index)
	var path := "res://data/stages/stage_1_%d.tres" % idx
	if ResourceLoader.exists(path):
		var ready := load(path) as StageData
		if ready != null:
			return ready
	var st := StageData.new()
	st.stage_id = "1-%d" % idx
	st.stage_number = idx
	st.enemy_team_level = int(1.0 + float(idx) * 1.5)
	st.enemy_front_top = _pick(POOL_FRONT, idx + 0)
	st.enemy_front_bot = _pick(POOL_FRONT, idx + 1)
	st.enemy_back_top = _pick(POOL_BACK, idx + 0)
	st.enemy_back_mid = _pick(POOL_BACK, idx + 1)
	st.enemy_back_bot = _pick(POOL_BACK, idx + 2)
	st.first_clear_gold = 400 + idx * 250
	st.first_clear_diamonds = 80 + idx * 30
	return st

func _pick(pool: Array[String], salt: int) -> HeroData:
	if pool.is_empty():
		return null
	return load(pool[salt % pool.size()]) as HeroData
