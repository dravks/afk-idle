extends Control
class_name HeroDetailUI
## Kahraman gelistirme karti: portre + seviye + statlar + maliyet + buton.
## `display_hero` ile doldurulur; buton HeroProgression'a baglidir.
## Popup olarak da kullanilir (`closed` sinyali).

signal closed

var label_name: Label
var label_level: Label
var label_faction: Label
var label_tier: Label
var label_hp: Label
var label_atk: Label
var label_def: Label
var label_cost: Label
var label_note: Label
var btn_level_up: Button
var btn_equip_all: Button
var gear_box: HBoxContainer
var portrait_tex: TextureRect
var close_button: Button

var _hero: HeroData

func _ready() -> void:
	_build()

func display_hero(hero_data: HeroData, current_level: int, is_in_crystal: bool) -> void:
	_hero = hero_data
	if hero_data == null:
		return
	var lv := maxi(1, current_level)
	label_name.text = hero_data.hero_name
	label_level.text = "Sv. %d" % lv
	label_faction.text = _faction_name(hero_data.faction)
	portrait_tex.texture = HeroSpriteFactory.portrait_of(hero_data)
	var tier := int(PlayerProfile.hero_tiers.get(hero_data.id, 2))
	label_tier.text = "Kademe %s · Maks Sv. %d" % [
		AscensionManager.tier_name(tier), AscensionManager.get_max_level_for_tier(tier)]
	var st := hero_data.calculate_stats_at_level(lv)
	label_hp.text = "HP  %s" % _fmt(float(st["hp"]))
	label_atk.text = "ATK  %s" % _fmt(float(st["atk"]))
	label_def.text = "DEF  %s" % _fmt(float(st["def"]))
	if is_in_crystal:
		label_note.visible = true
		label_note.text = "Bu kahraman Yankı Kristali tarafından güçlendiriliyor — elle geliştirilemez."
		label_cost.text = ""
		btn_level_up.disabled = true
		return
	label_note.visible = false
	var cost := HeroProgression.get_level_cost(lv)
	var dust_txt := ("  ·  %d Toz" % int(cost["dust"])) if int(cost["dust"]) > 0 else ""
	label_cost.text = "%s Altın  ·  %s EXP%s" % [_fmt(float(cost["gold"])), _fmt(float(cost["exp"])), dust_txt]
	var ok := HeroProgression.can_level_up(hero_data.id, PlayerProfile, ResonatingCrystalManager)
	btn_level_up.disabled = not ok
	btn_level_up.text = "SEVİYE ATLA > %d" % (lv + 1)
	_refresh_gear(hero_data.id)

func _on_btn_level_up_pressed() -> void:
	if _hero == null:
		return
	if HeroProgression.level_up(_hero.id, PlayerProfile, ResonatingCrystalManager):
		GameFlowManager.save_all()
		var lv := int(ResonatingCrystalManager.hero_levels.get(_hero.id, 1))
		display_hero(_hero, lv, _hero.id in ResonatingCrystalManager.crystal_slots)
		_flash()

func _on_btn_equip_all_pressed() -> void:
	if _hero == null:
		return
	PlayerProfile.auto_equip(_hero.id)
	GameFlowManager.save_all()
	display_hero(_hero,
		int(ResonatingCrystalManager.hero_levels.get(_hero.id, 1)),
		_hero.id in ResonatingCrystalManager.crystal_slots)
	_flash()

func _refresh_gear(hero_id: String) -> void:
	for c in gear_box.get_children():
		c.queue_free()
	var worn: Dictionary = PlayerProfile.gear_map_for(hero_id)
	for slot in [0, 1, 2, 3]:
		var g := worn.get(slot) as EquipmentData
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(72, 56)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#1e3a2a") if g != null else Color("#1a1a22")
		sb.set_content_margin_all(3)
		sb.set_corner_radius_all(4)
		sb.border_color = Color("#3ec65a") if g != null else Color("#3a3a44")
		sb.set_border_width_all(1)
		cell.add_theme_stylebox_override("panel", sb)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 0)
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(cv)
		cv.add_child(_lbl(EquipmentData.slot_name(slot), 10, Color("#9a8fb8")))
		if g != null:
			cv.add_child(_lbl(g.item_name, 10))
		else:
			cv.add_child(_slot_icon(slot))
		gear_box.add_child(cell)

const SLOT_ICONS := ["broadsword", "breastplate", "visored-helm", "boots"]

func _slot_icon(slot: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = IconLoader.get_icon(SLOT_ICONS[clampi(slot, 0, 3)])
	t.custom_minimum_size = Vector2(28, 28)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	t.modulate = Color(0.55, 0.55, 0.6)
	return t

func _flash() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.4, 1.4, 1.2), 0.12)
	tw.tween_property(self, "modulate", Color.WHITE, 0.25)

func _faction_name(f: GlobalEnums.Faction) -> String:
	match f:
		GlobalEnums.Faction.LIGHTBEARER:
			return "LIGHTBEARER"
		GlobalEnums.Faction.MAULER:
			return "MAULER"
		GlobalEnums.Faction.WILDER:
			return "WILDER"
		GlobalEnums.Faction.GRAVEBORN:
			return "GRAVEBORN"
		GlobalEnums.Faction.CELESTIAL:
			return "CELESTIAL"
		GlobalEnums.Faction.HYPOGEAN:
			return "HYPOGEAN"
	return "DIMENSIONAL"

func _fmt(n: float) -> String:
	if n >= 1000000.0:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000.0:
		return "%.1fK" % (n / 1000.0)
	return str(int(n))

func _lbl(text: String, size: int, col := Color("#e8e2f0")) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(18)
	sb.set_corner_radius_all(10)
	sb.border_color = Color("#ffd966")
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(340, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var por := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color("#1a1424")
	psb.set_content_margin_all(4)
	psb.set_corner_radius_all(8)
	psb.border_color = Color("#ffd966")
	psb.set_border_width_all(2)
	por.add_theme_stylebox_override("panel", psb)
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(por)
	portrait_tex = TextureRect.new()
	portrait_tex.custom_minimum_size = Vector2(72, 72)
	portrait_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	por.add_child(portrait_tex)
	label_name = _lbl("?", 22, Color("#ffd966"))
	v.add_child(label_name)
	label_level = _lbl("Sv. 1", 16)
	v.add_child(label_level)
	label_faction = _lbl("", 12, Color("#9a8fb8"))
	v.add_child(label_faction)
	label_tier = _lbl("", 12, Color("#ffd966"))
	v.add_child(label_tier)
	label_hp = _lbl("", 14)
	v.add_child(label_hp)
	label_atk = _lbl("", 14)
	v.add_child(label_atk)
	label_def = _lbl("", 14)
	v.add_child(label_def)
	label_cost = _lbl("", 12, Color("#8fd3ff"))
	v.add_child(label_cost)
	label_note = _lbl("", 12, Color("#c9a0ff"))
	label_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(label_note)
	btn_level_up = Button.new()
	btn_level_up.text = "SEVİYE ATLA"
	btn_level_up.custom_minimum_size = Vector2(0, 50)
	btn_level_up.add_theme_font_size_override("font_size", 17)
	btn_level_up.focus_mode = Control.FOCUS_NONE
	btn_level_up.pressed.connect(_on_btn_level_up_pressed)
	v.add_child(btn_level_up)
	gear_box = HBoxContainer.new()
	gear_box.add_theme_constant_override("separation", 4)
	gear_box.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(gear_box)
	btn_equip_all = Button.new()
	btn_equip_all.text = "TÜMÜNÜ KUŞAN"
	btn_equip_all.focus_mode = Control.FOCUS_NONE
	btn_equip_all.pressed.connect(_on_btn_equip_all_pressed)
	v.add_child(btn_equip_all)
	close_button = Button.new()
	close_button.text = "Kapat"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func(): closed.emit())
	v.add_child(close_button)
