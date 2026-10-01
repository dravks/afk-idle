extends Control
class_name TempleUI
## Kopya birlestirme: sol ana yuva, sag yem yuvasi, altta uygunlar listesi.
## Kendi AscensionManager cocugunu tasir.

var main_box: PanelContainer
var fodder_box: PanelContainer
var main_label: Label
var fodder_label: Label
var eligible_box: VBoxContainer
var ascend_button: Button
var back_button: Button
var info_label: Label

var _mgr: AscensionManager
var _main_id: String = ""
var _fodder_id: String = ""

func _ready() -> void:
	_mgr = AscensionManager.new()
	add_child(_mgr)
	_build()
	refresh()

func refresh() -> void:
	_paint_slot(main_box, main_label, _main_id, "ANA KAHRAMAN")
	_paint_slot(fodder_box, fodder_label, _fodder_id, "YEM KOPYA")
	_refresh_eligible()
	var ok := _mgr.can_ascend(_main_id, _fodder_id, PlayerProfile)
	ascend_button.disabled = not ok
	if _main_id.is_empty():
		info_label.text = "Soldan ana kahramani, sagdan yemi sec."
	elif ok:
		var t := _mgr.get_tier(PlayerProfile, _main_id)
		info_label.text = "%s -> %s (Maks Sv. %d)" % [
			AscensionManager.tier_name(t),
			AscensionManager.tier_name(t + 1),
			AscensionManager.get_max_level_for_tier(t + 1)]
	else:
		info_label.text = "Birlesme sarti: ayni kahramandan 2 kopya (yem dizilimde olmamali)."

func _on_roster_pick(hero_id: String) -> void:
	if _main_id.is_empty():
		_main_id = hero_id
	elif _fodder_id.is_empty() and hero_id == _main_id:
		_fodder_id = hero_id
	else:
		_fodder_id = hero_id
	refresh()

func _on_slot_clear(which: String) -> void:
	if which == "main":
		_main_id = ""
	else:
		_fodder_id = ""
	refresh()

func _on_ascend() -> void:
	if _mgr.ascend_hero(_main_id, _fodder_id, PlayerProfile):
		GameFlowManager.save_all()
		_main_id = ""
		_fodder_id = ""
		_flash()
	refresh()

func _on_back() -> void:
	GameFlowManager.go_lobby()

func _eligible_ids() -> Array[String]:
	var out: Array[String] = []
	var counts: Dictionary = {}
	for h in PlayerProfile.owned_heroes:
		var hd := h as HeroData
		if hd == null:
			continue
		counts[hd.id] = int(counts.get(hd.id, 0)) + 1
	for key in counts.keys():
		if int(counts[key]) >= 2 and _mgr.get_tier(PlayerProfile, str(key)) < AscensionManager.MAX_TIER:
			out.append(str(key))
	return out

func _paint_slot(box: PanelContainer, label: Label, hero_id: String, title: String) -> void:
	var h := PlayerProfile.get_hero(hero_id) if not hero_id.is_empty() else null
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1e3a2a") if h != null else Color("#221a30")
	sb.set_content_margin_all(8)
	sb.set_corner_radius_all(8)
	sb.border_color = Color("#ffd966") if h != null else Color("#3a2f52")
	sb.set_border_width_all(2)
	box.add_theme_stylebox_override("panel", sb)
	if h != null:
		var t := _mgr.get_tier(PlayerProfile, hero_id)
		label.text = "%s\n%s · %s" % [title, h.hero_name, AscensionManager.tier_name(t)]
	else:
		label.text = "%s\n(BOŞ)" % title

func _refresh_eligible() -> void:
	for c in eligible_box.get_children():
		c.queue_free()
	var ids := _eligible_ids()
	if ids.is_empty():
		var l := _lbl("Birlesebilir kopya yok (ayni kahramandan 2 kopya gerekir).", 12)
		eligible_box.add_child(l)
		return
	for hid in ids:
		var h := PlayerProfile.get_hero(hid)
		var b := Button.new()
		b.text = "%s x%d" % [h.hero_name if h != null else hid, _count(hid)]
		b.focus_mode = Control.FOCUS_NONE
		var id := hid
		b.pressed.connect(func(): _on_roster_pick(id))
		eligible_box.add_child(b)

func _count(hero_id: String) -> int:
	var n := 0
	for h in PlayerProfile.owned_heroes:
		var hd := h as HeroData
		if hd != null and hd.id == hero_id:
			n += 1
	return n

func _flash() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.5, 1.4, 1.0), 0.15)
	tw.tween_property(self, "modulate", Color.WHITE, 0.3)

func _lbl(text: String, size: int, col := Color("#e8e2f0")) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _slot_box(title: String, which: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(200, 110)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.gui_input.connect(_on_slot_gui.bind(which))
	var l := _lbl(title, 14)
	p.add_child(l)
	if which == "main":
		main_label = l
	else:
		fodder_label = l
	return p

func _on_slot_gui(event: InputEvent, which: String) -> void:
	var click: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	var touch: bool = (event is InputEventScreenTouch and event.pressed)
	if click or touch:
		_on_slot_clear(which)

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#150f1f")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(s, 14)
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	back_button = Button.new()
	back_button.text = "← Lobi"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(_on_back)
	top.add_child(back_button)
	var title := _lbl("TAPINAK", 20, Color("#ffd966"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	main_box = _slot_box("ANA", "main")
	row.add_child(main_box)
	fodder_box = _slot_box("YEM", "fodder")
	row.add_child(fodder_box)
	info_label = _lbl("", 12, Color("#8fd3ff"))
	v.add_child(info_label)
	ascend_button = Button.new()
	ascend_button.text = "KIDEM ATLA"
	ascend_button.custom_minimum_size = Vector2(0, 54)
	ascend_button.add_theme_font_size_override("font_size", 19)
	ascend_button.focus_mode = Control.FOCUS_NONE
	ascend_button.pressed.connect(_on_ascend)
	v.add_child(ascend_button)
	v.add_child(_lbl("UYGUN KAHRAMANLAR (dokun: sirayla ana + yem)", 12, Color("#9a8fb8")))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	eligible_box = VBoxContainer.new()
	eligible_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eligible_box.add_theme_constant_override("separation", 6)
	scroll.add_child(eligible_box)
