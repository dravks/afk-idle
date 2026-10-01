extends Control
class_name QuestUI
## Gorev penceresi: GUNLUK / BASARIM sekmeleri, puan bari + 5 sandik,
## satir basina ilerleme + AL butonu. Veriler Flow cocugu QuestManager'dan.

var points_bar: ProgressBar
var points_label: Label
var chest_row: HBoxContainer
var list_box: VBoxContainer
var tab_daily_button: Button
var tab_ach_button: Button
var back_button: Button

var _tab_daily := true
var _chest_buttons: Dictionary = {}

func _ready() -> void:
	_build()
	var qm := _qm()
	if qm != null:
		qm.quest_progress_updated.connect(refresh)
		qm.daily_points_changed.connect(_on_points)
	refresh()

func refresh() -> void:
	var qm := _qm()
	if qm == null:
		return
	points_bar.max_value = 100.0
	points_bar.value = float(qm.daily_points)
	points_label.text = "Puan: %d / 100" % qm.daily_points
	_refresh_chests(qm)
	_refresh_list(qm)

func _on_points(_points: int) -> void:
	refresh()

func _on_tab(daily: bool) -> void:
	_tab_daily = daily
	refresh()

func _on_claim(quest_id: String) -> void:
	var qm := _qm()
	if qm == null:
		return
	if qm.claim_quest(quest_id, PlayerProfile):
		GameFlowManager.save_all()
	refresh()

func _on_chest(milestone: int) -> void:
	var qm := _qm()
	if qm == null:
		return
	if qm.claim_milestone_chest(milestone, PlayerProfile):
		GameFlowManager.save_all()
	refresh()

func _on_back() -> void:
	GameFlowManager.go_lobby()

func _qm() -> QuestManager:
	return GameFlowManager.quests

func _refresh_chests(qm: QuestManager) -> void:
	for c in chest_row.get_children():
		c.queue_free()
	_chest_buttons.clear()
	for m in QuestManager.MILESTONES:
		var mi: int = int(m)
		var b := Button.new()
		b.text = str(mi)
		b.custom_minimum_size = Vector2(56, 44)
		b.focus_mode = Control.FOCUS_NONE
		var claimed: bool = mi in qm.claimed_milestones
		var open: bool = qm.daily_points >= mi
		if claimed:
			b.text = "OK"
			b.disabled = true
			b.modulate = Color(0.5, 0.5, 0.55)
		elif open:
			b.modulate = Color(1.3, 1.1, 0.6)
			b.pressed.connect(func(): _on_chest(mi))
		else:
			b.disabled = true
			b.modulate = Color(0.55, 0.55, 0.6)
		chest_row.add_child(b)
		_chest_buttons[mi] = b

func _refresh_list(qm: QuestManager) -> void:
	for c in list_box.get_children():
		c.queue_free()
	var rows: Array[QuestData] = qm.daily_quests if _tab_daily else qm.achievements
	for q in rows:
		list_box.add_child(_row(q))

func _row(q: QuestData) -> Control:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(8)
	sb.set_corner_radius_all(6)
	sb.border_color = Color("#3ec65a") if (q.is_complete() and not q.is_claimed) else Color("#3a2f52")
	sb.set_border_width_all(2 if (q.is_complete() and not q.is_claimed) else 1)
	card.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	card.add_child(h)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var t := _lbl(q.title, 14)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(t)
	var p := _lbl("%s  ·  %s" % [q.progress_text(), _reward_text(q)], 11, Color("#9a8fb8"))
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(p)
	var b := Button.new()
	if q.is_claimed:
		b.text = "OK"
		b.disabled = true
	elif q.is_complete():
		b.text = "AL"
		var qid := q.id
		b.pressed.connect(func(): _on_claim(qid))
	else:
		b.text = q.progress_text()
		b.disabled = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(76, 44)
	h.add_child(b)
	return card

func _reward_text(q: QuestData) -> String:
	if q.quest_type == QuestData.QuestType.DAILY:
		return "+%d puan" % q.reward_points
	var parts: Array = []
	if q.reward_diamonds > 0:
		parts.append("+%d elmas" % q.reward_diamonds)
	if q.reward_scrolls > 0:
		parts.append("+%d parşömen" % q.reward_scrolls)
	return " · ".join(parts)

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
	back_button.text = "← Lobi"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(_on_back)
	top.add_child(back_button)
	tab_daily_button = Button.new()
	tab_daily_button.text = "GÜNLÜK"
	tab_daily_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_daily_button.focus_mode = Control.FOCUS_NONE
	tab_daily_button.pressed.connect(func(): _on_tab(true))
	top.add_child(tab_daily_button)
	tab_ach_button = Button.new()
	tab_ach_button.text = "BAŞARIM"
	tab_ach_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_ach_button.focus_mode = Control.FOCUS_NONE
	tab_ach_button.pressed.connect(func(): _on_tab(false))
	top.add_child(tab_ach_button)
	points_label = _lbl("Puan: 0 / 100", 15, Color("#ffd966"))
	v.add_child(points_label)
	points_bar = ProgressBar.new()
	points_bar.min_value = 0.0
	points_bar.max_value = 100.0
	points_bar.value = 0.0
	points_bar.show_percentage = false
	points_bar.custom_minimum_size = Vector2(0, 14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#ffd966")
	points_bar.add_theme_stylebox_override("fill", fill)
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = Color("#1a1424")
	points_bar.add_theme_stylebox_override("background", pbg)
	v.add_child(points_bar)
	chest_row = HBoxContainer.new()
	chest_row.add_theme_constant_override("separation", 6)
	chest_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(chest_row)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 6)
	scroll.add_child(list_box)
