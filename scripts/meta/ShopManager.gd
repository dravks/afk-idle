extends Node
class_name ShopManager
## Gunluk dukkan: 4 slot, altin/elmasla Toz/EXP/parsonen. Satilan slot gun
## sonuna kadar "tukendi" kalir (tarih kayda yazilir).
## Parsonen ozel urundur: alinca UCRETSIZ tekli cagirma yapar (envanter yok).

signal bought(slot_index: int, label: String)

const KIND_DUST := "dust"
const KIND_EXP := "exp"
const KIND_SCROLL := "scroll"

var slots: Array[Dictionary] = []
var last_refresh_date: String = ""

func _ready() -> void:
	_build_slots()

func _build_slots() -> void:
	slots = [
		{"kind": KIND_DUST, "amount": 50, "cost_gold": 50000, "cost_diamond": 0, "is_sold": false, "label": "50 Toz"},
		{"kind": KIND_DUST, "amount": 100, "cost_gold": 100000, "cost_diamond": 0, "is_sold": false, "label": "100 Toz"},
		{"kind": KIND_EXP, "amount": 200, "cost_gold": 20000, "cost_diamond": 0, "is_sold": false, "label": "200 EXP"},
		{"kind": KIND_SCROLL, "amount": 1, "cost_gold": 0, "cost_diamond": 300, "is_sold": false, "label": "Cagirma Parsomeni"},
	]

## Gun degistiysa slotlari tazele. UI acilisinda + alimda cagrilir.
func refresh_if_new_day() -> void:
	var today := _today_key()
	if last_refresh_date != today:
		last_refresh_date = today
		for s in slots:
			s["is_sold"] = false

func buy_item(slot_index: int, profile) -> bool:
	refresh_if_new_day()
	if profile == null or slot_index < 0 or slot_index >= slots.size():
		return false
	var s: Dictionary = slots[slot_index]
	if bool(s["is_sold"]):
		return false
	var cg := int(s["cost_gold"])
	var cd := int(s["cost_diamond"])
	if int(profile.gold) < cg or int(profile.diamonds) < cd:
		return false
	profile.gold -= cg
	profile.diamonds -= cd
	match str(s["kind"]):
		KIND_DUST:
			AFKManager.dust += int(s["amount"])
		KIND_EXP:
			AFKManager.hero_exp += int(s["amount"])
		KIND_SCROLL:
			var tavern := TavernManager.new()
			add_child(tavern)
			var pulled := tavern.summon_single(profile, true)
			tavern.queue_free()
			if pulled == null:
				profile.gold += cg
				profile.diamonds += cd
				return false
	s["is_sold"] = true
	bought.emit(slot_index, str(s["label"]))
	return true

func get_save_data() -> Dictionary:
	var sold: Array = []
	for s in slots:
		sold.append(bool(s["is_sold"]))
	return {"shop_sold": sold, "shop_date": last_refresh_date}

func apply_save_data(d: Dictionary) -> void:
	refresh_if_new_day()
	last_refresh_date = str(d.get("shop_date", last_refresh_date))
	var sold: Array = d.get("shop_sold", [])
	for i in mini(sold.size(), slots.size()):
		slots[i]["is_sold"] = bool(sold[i])
	# Kayitli gun baska gunse bugun tazelenir.
	refresh_if_new_day()

func _today_key() -> String:
	var dt := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(dt["year"]), int(dt["month"]), int(dt["day"])]
