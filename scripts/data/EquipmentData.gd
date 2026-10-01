extends Resource
class_name EquipmentData
## Tek esya: yuvasi + 4 stat bonusu. Envanter/kusaknutsal veri; savas-anlik
## etkisi EquipmentComponent uzerinden stats_component'e islenir.

@export var uid: int = 0
@export var id: String = ""
@export var item_name: String = ""
@export var slot_type: GlobalEnums.EquipSlot = GlobalEnums.EquipSlot.WEAPON
@export var bonus_hp: float = 0.0
@export var bonus_atk: float = 0.0
@export var bonus_def: float = 0.0
@export var bonus_haste: float = 0.0

static func slot_name(slot: int) -> String:
	match slot:
		1:
			return "Zırh"
		2:
			return "Miğfer"
		3:
			return "Çizme"
	return "Silah"

func to_dict() -> Dictionary:
	return {
		"uid": uid, "id": id, "item_name": item_name, "slot_type": int(slot_type),
		"bonus_hp": bonus_hp, "bonus_atk": bonus_atk,
		"bonus_def": bonus_def, "bonus_haste": bonus_haste,
	}

static func from_dict(d: Dictionary) -> EquipmentData:
	var g := EquipmentData.new()
	g.uid = int(d.get("uid", 0))
	g.id = str(d.get("id", ""))
	g.item_name = str(d.get("item_name", ""))
	g.slot_type = clampi(int(d.get("slot_type", 0)), 0, 3) as GlobalEnums.EquipSlot
	g.bonus_hp = float(d.get("bonus_hp", 0.0))
	g.bonus_atk = float(d.get("bonus_atk", 0.0))
	g.bonus_def = float(d.get("bonus_def", 0.0))
	g.bonus_haste = float(d.get("bonus_haste", 0.0))
	return g
