extends Control
class_name ResonatingCrystalUI
## Yanki Kristali ekrani: ustte pentagram + kristal seviyesi, altta 10 yuva.
## Bos yuva "+" -> uygun kahraman secici; dolu yuva dokununca cikar.

var pentagram_container: HBoxContainer
var label_crystal_level: Label
var slots_grid: GridContainer
var back_button: Button

var _picker: CenterContainer

func _ready() -> void:
	_build()
	ResonatingCrystalManager.crystal_level_updated.connect(_on_mgr_changed)
	ResonatingCrystalManager.hero_placed_in_slot.connect(_on_mgr_changed)
	ResonatingCrystalManager.hero_removed_from_slot.connect(_on_mgr_changed)
	refresh_ui()

func refresh_ui() -> void:
	label_crystal_level.text = "Kristal Seviyesi: Lv. %d" % ResonatingCrystalManager.crystal_level
	_refresh_pentagram()
	_refresh_slots()

func _on_mgr_changed(_a = null, _b = null) -> void:
	refresh_ui()

func _on_empty_slot_clicked(_slot_index: int) -> void:
	_open_picker()

func _on_filled_slot_clicked(hero_id: String) -> void:
	ResonatingCrystalManager.remove_hero_from_slot(hero_id)
	GameFlowManager.save_all()
	refresh_ui()

func _on_picker_pick(hero_id: String) -> void:
	if ResonatingCrystalManager.place_hero_in_slot(hero_id):
		GameFlowManager.save_all()
	_close_picker()
	refresh_ui()

func _refresh_pentagram() -> void:
	for c in pentagram_container.get_children():
		c.queue_free()
	for hid in ResonatingCrystalManager.pentagram_ids():
		var lv := int(ResonatingCrystalManager.hero_levels.get(hid, 1))
		var h := PlayerProfile.get_hero(hid)
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(80, 64)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#2a1f3d")
		sb.set_content_margin_all(4)
		sb.set_corner_radius_all(6)
		sb.border_color = Color("#ffd966")
		sb.set_border_width_all(1)
		p.add_theme_stylebox_override("panel", sb)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(v)
		var n := _lbl(h.hero_name if h != null else hid, 11)
		v.add_child(n)
		v.add_child(_lbl("Lv. %d" % lv, 13, Color("#ffd966")))
		pentagram_container.add_child(p)

func _refresh_slots() -> void:
	for c in slots_grid.get_children():
		c.queue_free()
	var slots: Array = ResonatingCrystalManager.crystal_slots
	for i in ResonatingCrystalManager.MAX_SLOTS:
		if i < slots.size():
			slots_grid.add_child(_filled_cell(str(slots[i])))
		else:
			var b := Button.new()
			b.text = "+"
			b.custom_minimum_size = Vector2(80, 64)
			b.add_theme_font_size_override("font_size", 24)
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(_on_empty_slot_clicked.bind(i))
			slots_grid.add_child(b)

func _filled_cell(hero_id: String) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(80, 64)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#241a38")
	sb.set_content_margin_all(4)
	sb.set_corner_radius_all(6)
	sb.border_color = Color("#a45fd6")
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.gui_input.connect(_on_cell_gui.bind(hero_id))
	var h := PlayerProfile.get_hero(hero_id)
	var lv := ResonatingCrystalManager.get_effective_level(hero_id)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	v.add_child(_lbl(h.hero_name if h != null else hero_id, 11))
	v.add_child(_lbl("Lv. %d" % lv, 13, Color("#c9a0ff")))
	return p

func _on_cell_gui(event: InputEvent, hero_id: String) -> void:
	var click: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	var touch: bool = (event is InputEventScreenTouch and event.pressed)
	if click or touch:
		_on_filled_slot_clicked(hero_id)

func _open_picker() -> void:
	_close_picker()
	_picker = CenterContainer.new()
	_picker.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_picker)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(14)
	sb.set_corner_radius_all(8)
	sb.border_color = Color("#a45fd6")
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(320, 0)
	_picker.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	v.add_child(_lbl("KAHROMAN SEC", 16, Color("#ffd966")))
	var penta := ResonatingCrystalManager.pentagram_ids()
	var any := false
	for h in PlayerProfile.owned_heroes:
		if h.id in ResonatingCrystalManager.crystal_slots:
			continue
		if h.id in penta:
			continue
		any = true
		var b := Button.new()
		var lv := int(ResonatingCrystalManager.hero_levels.get(h.id, 1))
		b.text = "%s (Lv. %d -> %d)" % [h.hero_name, lv, ResonatingCrystalManager.crystal_level]
		b.focus_mode = Control.FOCUS_NONE
		var hid := h.id
		b.pressed.connect(func(): _on_picker_pick(hid))
		v.add_child(b)
	if not any:
		v.add_child(_lbl("Uygun kahraman yok", 12, Color("#9a8fb8")))
	var close := Button.new()
	close.text = "Kapat"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_close_picker)
	v.add_child(close)

func _close_picker() -> void:
	if _picker != null and is_instance_valid(_picker):
		_picker.queue_free()
	_picker = null

func _lbl(text: String, size: int, col := Color("#e8e2f0")) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _on_back_pressed() -> void:
	GameFlowManager.go_lobby()

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
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	back_button = Button.new()
	back_button.text = "← Lobi"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(_on_back_pressed)
	top.add_child(back_button)
	var title := _lbl("YANKI KRISTALI", 20, Color("#c9a0ff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	label_crystal_level = _lbl("Kristal Seviyesi: Lv. 1", 18, Color("#ffd966"))
	v.add_child(label_crystal_level)
	v.add_child(_lbl("PENTAGRAM (en yuksek 5)", 12, Color("#9a8fb8")))
	pentagram_container = HBoxContainer.new()
	pentagram_container.add_theme_constant_override("separation", 6)
	pentagram_container.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(pentagram_container)
	v.add_child(_lbl("YUVALAR (dokun: cikar)", 12, Color("#9a8fb8")))
	slots_grid = GridContainer.new()
	slots_grid.columns = 5
	slots_grid.add_theme_constant_override("h_separation", 6)
	slots_grid.add_theme_constant_override("v_separation", 6)
	v.add_child(slots_grid)
