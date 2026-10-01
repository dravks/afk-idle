extends Resource
class_name CommanderSpellData
## Komutan buyusu tanimi. Hasar = base_power * damage_mult (buyu gucu,
## komutanin ATK'si yok). Destek etkisi applied_buff ile (kalkan/HoT),
## alan iyilestirme bolgesi de ayni buff verisinden okunur.

@export var id: String = ""
@export var spell_name: String = ""
@export var icon: Texture2D
@export var mana_cost: int = 40
@export var cooldown: float = 8.0
@export var aoe_radius: float = 120.0  # 0 ise tek hedefli
@export var target_type: String = "AREA_ENEMY"  # AREA_ENEMY / SINGLE_ALLY / AREA_ALLY
@export var base_power: float = 200.0
@export var damage_mult: float = 1.0
@export var damage_type: GlobalEnums.DamageType = GlobalEnums.DamageType.MAGICAL
@export var applied_buff: BuffData = null
