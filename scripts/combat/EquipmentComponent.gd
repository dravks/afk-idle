extends Node
class_name EquipmentComponent
## Savas-anlik esya tasiyici: 4 slot. Bonuslar stats_component'e dogrudan
## islenir (kusak degisimi savas disinda profile tarafindan yonetilir).

@onready var unit: Unit = get_parent() as Unit

var equipped_gear: Dictionary = {0: null, 1: null, 2: null, 3: null}

## Tak: eskisini dondurur (yoksa null). Bonuslar aninda statlara gecer.
func equip_item(gear: EquipmentData) -> EquipmentData:
	if gear == null or unit == null or unit.stats_component == null:
		return gear
	var slot := int(gear.slot_type)
	var old := equipped_gear.get(slot) as EquipmentData
	if old != null:
		_apply(old, -1.0)
	equipped_gear[slot] = gear
	_apply(gear, 1.0)
	return old

func unequip_slot(slot: int) -> EquipmentData:
	var old := equipped_gear.get(slot) as EquipmentData
	if old != null:
		_apply(old, -1.0)
		equipped_gear[slot] = null
	return old

func get_total_bonus_stats() -> Dictionary:
	var t := {"hp": 0.0, "atk": 0.0, "def": 0.0, "haste": 0.0}
	for key in equipped_gear.keys():
		var g := equipped_gear[key] as EquipmentData
		if g == null:
			continue
		t["hp"] = float(t["hp"]) + g.bonus_hp
		t["atk"] = float(t["atk"]) + g.bonus_atk
		t["def"] = float(t["def"]) + g.bonus_def
		t["haste"] = float(t["haste"]) + g.bonus_haste
	return t

func _apply(gear: EquipmentData, sign: float) -> void:
	var st := unit.stats_component
	st.max_hp = maxf(1.0, st.max_hp + sign * gear.bonus_hp)
	if sign > 0.0:
		st.current_hp = minf(st.max_hp, st.current_hp + gear.bonus_hp)
	else:
		st.current_hp = minf(st.current_hp, st.max_hp)
	st.atk = maxf(0.0, st.atk + sign * gear.bonus_atk)
	st.def = maxf(0.0, st.def + sign * gear.bonus_def)
	st.haste = maxf(1.0, st.haste + sign * gear.bonus_haste)
	st.hp_changed.emit(st.current_hp, st.max_hp)
