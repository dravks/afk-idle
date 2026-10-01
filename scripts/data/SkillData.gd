extends Resource
class_name SkillData
## Yetenek tanimi. Hasar = ATK * damage_multiplier (Prompt 4'te fraksiyon
## carpani ve DEF ile birlesir). Iyilesme SkillData disinda, kullanan
## sistem (StateMachine) tarafindan hedef max HP uzerinden hesaplanir.

@export var id: String = ""
@export var skill_name: String = ""
@export var skill_type: GlobalEnums.SkillType = GlobalEnums.SkillType.ACTIVE_SKILL
@export var target_rule: GlobalEnums.TargetRule = GlobalEnums.TargetRule.NEAREST_ENEMY
@export var damage_type: GlobalEnums.DamageType = GlobalEnums.DamageType.PHYSICAL
@export var damage_multiplier: float = 1.0  # ATK yuzdesi (1.5 = %150)
@export var cooldown: float = 0.0  # sadece ACTIVE_SKILL icin
@export var energy_cost: int = 0  # sadece ULTIMATE icin (varsayilan 1000)
@export var energy_generated: int = 100  # kullanimda uretilen enerji
@export var range: float = 120.0  # etkili menzil (hedef disindaysa kullanilmaz)
@export var aoe_radius: float = 0.0  # 0 = tek hedef
@export var applied_buffs: Array[BuffData] = []

func is_ultimate() -> bool:
	return skill_type == GlobalEnums.SkillType.ULTIMATE

func is_basic_attack() -> bool:
	return skill_type == GlobalEnums.SkillType.BASIC_ATTACK

func is_multi_target() -> bool:
	return aoe_radius > 0.0 \
		or target_rule == GlobalEnums.TargetRule.ALL_ENEMIES \
		or target_rule == GlobalEnums.TargetRule.ALL_ALLIES
