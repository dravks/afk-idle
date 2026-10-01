extends CanvasLayer
class_name RelicRewardUI
## 3 kartlik kalinti secimi (zorunlu secim). `setup` ile kurulur; secim
## disariya bildirilip kendini kapatir (ekleme Flow tarafinda).

const RARITY_COLORS := {
	0: Color("#3ec65a"),
	1: Color("#4f8fd6"),
	2: Color("#c77dff"),
}
const RARITY_NAMES := {0: "SIRADAN", 1: "NADIR", 2: "DESTANSI"}
const RELIC_ICONS := {
	"relic_battle_paint": "sparkles", "relic_fang": "daggers",
	"relic_drum": "power-lightning", "relic_tome": "open-book",
	"relic_vial": "potion-ball",
}

var _on_pick: Callable
var choices_shown: Array = []

func setup(choices: Array, on_pick: Callable) -> void:
	_on_pick = on_pick
	choices_shown = choices.duplicate()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(14)
	sb.set_corner_radius_all(10)
	sb.border_color = Color("#ffd966")
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var h := Label.new()
	h.text = "KALINTI SEÇ (1/3)"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 20)
	h.add_theme_color_override("font_color", Color("#ffd966"))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for c in choices:
		var r := c as RelicData
		if r != null:
			row.add_child(_card(r))

func _card(relic: RelicData) -> Control:
	var col: Color = RARITY_COLORS.get(int(relic.rarity), Color.WHITE)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(130, 170)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1a1424")
	sb.set_content_margin_all(6)
	sb.set_corner_radius_all(8)
	sb.border_color = col
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.gui_input.connect(_on_card_gui.bind(relic))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var n := _lbl(relic.relic_name, 13, col)
	v.add_child(n)
	v.add_child(_lbl(str(RARITY_NAMES.get(int(relic.rarity), "?")), 10, col))
	var ricon := TextureRect.new()
	ricon.texture = IconLoader.get_icon(str(RELIC_ICONS.get(relic.id, "sparkles")))
	ricon.custom_minimum_size = Vector2(44, 44)
	ricon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ricon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ricon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ricon)
	var d := _lbl(relic.description, 11)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	return p

func _on_card_gui(event: InputEvent, relic: RelicData) -> void:
	var click: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	var touch: bool = (event is InputEventScreenTouch and event.pressed)
	if click or touch:
		_pick(relic)

func _pick(relic: RelicData) -> void:
	if _on_pick.is_valid():
		_on_pick.call(relic)
	queue_free()

func _lbl(text: String, size: int, col := Color("#e8e2f0")) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
