extends RefCounted
class_name DamageResult
## Hasar verisini tasiyan transfer nesnesi. StatsComponent uretir;
## FloatingText ve savas logu tuketir.

var amount: float = 0.0
var is_crit: bool = false
var is_advantage: bool = false
var damage_type: GlobalEnums.DamageType = GlobalEnums.DamageType.PHYSICAL
