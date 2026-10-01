extends Resource
class_name HeroData
## Kahraman tanimi: kimlik + fraksiyon/rol + taban statlar + yetenek seti.
## Seviye buyumesi calculate_stats_at_level ile hesaplanir (ustal singly
## kaynak: denge ayari tek formulle tum kahramanlara yansir).

@export var id: String = ""
@export var hero_name: String = ""
@export var faction: GlobalEnums.Faction = GlobalEnums.Faction.LIGHTBEARER
@export var role: GlobalEnums.Role = GlobalEnums.Role.WARRIOR
@export var damage_type: GlobalEnums.DamageType = GlobalEnums.DamageType.PHYSICAL

@export var base_hp: float = 500.0
@export var base_atk: float = 50.0
@export var base_def: float = 10.0
@export var base_haste: float = 100.0  # saldiri + hareket hizi yuzdesi
@export var crit_chance: float = 0.1
@export var crit_multiplier: float = 1.5
@export var attack_range: float = 120.0  # melee ~120, ranged ~500

@export var basic_attack: SkillData
@export var active_skills: Array[SkillData] = []
@export var ultimate_skill: SkillData
## Gorseller: .tres'te verilmisse onlar kullanilir; yoksa HeroSpriteFactory
## rol/fraksiyona gore procedural uretir (hicbir durumda crash yok).
@export var portrait: Texture2D
@export var sprite_frames: SpriteFrames
@export var visual_scale: Vector2 = Vector2(1, 1)
## Ozel mekanikler (varsayilan kapali; yeni kahramanlar acar):
## suikastci arka hatta isinlanir, olumsuzz ilk olumu atlatir, dirilen 1 kez kalkar.
@export var is_assassin_jumper: bool = false
@export var has_death_defiance: bool = false
@export var has_resurrection: bool = false

# Seviye buyume egrisi (tek yerden tuning): HP/ATK %7, DEF %4 bilesik.
const HP_ATK_GROWTH := 1.07
const DEF_GROWTH := 1.04

## Verilen seviyedeki HP/ATK/DEF degerleri. Haste/kritik/menzil seviyeyle degismez.
func calculate_stats_at_level(level: int) -> Dictionary:
	var lv := maxi(1, level)
	var hp_mult := pow(HP_ATK_GROWTH, float(lv - 1))
	var def_mult := pow(DEF_GROWTH, float(lv - 1))
	return {
		"hp": base_hp * hp_mult,
		"atk": base_atk * hp_mult,
		"def": base_def * def_mult,
	}
