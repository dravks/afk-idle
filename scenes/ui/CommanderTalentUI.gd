extends Control
class_name CommanderTalentUI
## Komutan yetenek agaci: seviye/EXP/puan basi + kademeli kartlar.
## Kilit kurali: T2 icin T1, T3 icin T2 sarti (CommanderProgression).

var level_label: Label
var exp_bar: ProgressBar
var points_label: Label
var cards_box: VBoxContainer
var back_button: Button

func _ready() -> void:
	_build()
	var prog := _prog()
	if prog != null:
		prog.progressed.connect(refresh)
	refresh()

func refresh() -> void:
	var prog := _prog()
	if prog == null:
		return
	level_label.text = "Komutan Sv. %d" % prog.commander_level
	exp_bar.max_value = float(maxi(1, prog.exp_needed()))
	exp_bar.value = float(prog.current_exp)
	points_label.text = "Yetenek Puanı: %d" % prog.talent_points
	for c in cards_box.get_children():
		c.queue_free()
	for tid in CommanderProgression.TIER_ORDER:
		cards_box.add_child(_card(tid, prog))

func _card(talent_id: String, prog: CommanderProgression) -> Control:
	var def: Dictionary = CommanderProgression.TALENT_DEFS[talent_id]
	var owned := prog.has_talent(talent_id)
	var open := prog.can_unlock(talent_id)
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(8)
	sb.set_corner_radius_all(6)
	if owned:
		sb.border_color = Color("#ffd966")
		sb.set_border_width_all(2)
	elif open:
		sb.border_color = Color("#3ec65a")
		sb.set_border_width_all(2)
	else:
		sb.border_color = Color("#3a2f52")
		sb.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var t := _lbl("[%d] %s" % [int(def["tier"]), str(def["name"])], 15, Color("#ffd966") if owned else Color("#e8e2f0"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(t)
	var d := _lbl(str(def["desc"]), 12, Color("#9a8fb8"))
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(d)
	var b := Button.new()
	if owned:
		b.text = "AÇIK"
		b.disabled = true
	elif open:
		b.text = "1 PUAN VER"
		var tid := talent_id
		b.pressed.connect(func(): _on_unlock(tid))
	else:
		b.text = "KİLİTLİ"
		b.disabled = true
		b.tooltip_text = _lock_reason(talent_id, prog)
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(120, 48)
	h.add_child(b)
	return p

func _lock_reason(talent_id: String, prog: CommanderProgression) -> String:
	if prog.talent_points < 1:
		return "Puan yok (zaferlerle EXP kazan)"
	var tier := int((CommanderProgression.TALENT_DEFS[talent_id] as Dictionary)["tier"])
	if tier == 2:
		return "Önce 1. kademe yetenek aç"
	if tier == 3:
		return "Önce 2. kademe yetenek aç"
	return ""

func _on_unlock(talent_id: String) -> void:
	var prog := _prog()
	if prog == null:
		return
	if prog.unlock_talent(talent_id):
		AudioManager.play_sfx("btn_click")
		GameFlowManager.save_all()
	refresh()

func _on_back() -> void:
	AudioManager.play_sfx("btn_click")
	GameFlowManager.go_lobby()

func _prog() -> CommanderProgression:
	return GameFlowManager.commander_prog

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
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	back_button = Button.new()
	back_button.text = "< Lobi"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(_on_back)
	top.add_child(back_button)
	var title := _lbl("KOMUTAN", 20, Color("#ffd966"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	level_label = _lbl("", 16)
	v.add_child(level_label)
	exp_bar = ProgressBar.new()
	exp_bar.min_value = 0.0
	exp_bar.show_percentage = false
	exp_bar.custom_minimum_size = Vector2(0, 12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#8fd3ff")
	exp_bar.add_theme_stylebox_override("fill", fill)
	var ebg := StyleBoxFlat.new()
	ebg.bg_color = Color("#1a1424")
	exp_bar.add_theme_stylebox_override("background", ebg)
	v.add_child(exp_bar)
	points_label = _lbl("", 14, Color("#ffd966"))
	v.add_child(points_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	cards_box = VBoxContainer.new()
	cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_box.add_theme_constant_override("separation", 8)
	scroll.add_child(cards_box)
