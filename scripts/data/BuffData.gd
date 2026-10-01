extends Resource
class_name BuffData
## Sureli / anlik etki tanimi.
## - tick_interval == 0: tek seferlik veya pasif stat etkisi (value_percentage/flat_value bir kez uygulanir).
## - tick_interval > 0: DOT/HOT; her periyotta flat_value uygulanir.

@export var id: String = ""
@export var buff_type: GlobalEnums.BuffType = GlobalEnums.BuffType.ATK_BUFF
@export var duration: float = 5.0
@export var tick_interval: float = 0.0
@export var value_percentage: float = 0.0  # orn: +0.20 = %20 ATK artisi
@export var flat_value: float = 0.0  # sabit kalkan / sabit DoT-HoT tik degeri

func is_over_time() -> bool:
	return buff_type == GlobalEnums.BuffType.DOT or buff_type == GlobalEnums.BuffType.HOT

func is_crowd_control() -> bool:
	return buff_type == GlobalEnums.BuffType.STUN
