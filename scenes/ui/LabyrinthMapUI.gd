extends Control
class_name LabyrinthMapUI
## Labirent haritasi: 5 dugumluk dogrusal yol (yesil = biten, altin = siradaki).
## Savas dugumu Flow uzerinden savasi acar; pinar/sunak yerinde cozulur.

var title_label: Label
var relic_label: Label
var info_label: Label
var nodes_box: VBoxContainer
var back_button: Button

func _ready() -> void:
	_build()
	refresh()

func refresh() -> void:
	title_label.text = "LABİRENT — Kat %d" % LabyrinthRun.current_floor
	relic_label.text = "Kalıntı: %d" % LabyrinthRun.relics.active_relics.size()
	for c in nodes_box.get_children():
		c.queue_free()
	for i in LabyrinthRun.NODES_PER_FLOOR:
		nodes_box.add_child(_node_button(i))

func _node_button(index: int) -> Control:
	var b := LabyrinthNodeUI.new()
	var t := LabyrinthRun.node_type(LabyrinthRun.current_floor, index)
	var state := "locked"
	if index in LabyrinthRun.completed_nodes:
		state = "done"
	elif index == LabyrinthRun.current_node_index:
		state = "current"
	b.setup(index, LabyrinthRun.node_label(LabyrinthRun.current_floor, index),
		_node_subtitle(t, state), state)
	b.node_chosen.connect(_on_node_chosen)
	return b

func _node_subtitle(t: int, state: String) -> String:
	if state == "done":
		return "Tamamlandı!"
	if state != "current":
		return "Kilitli"
	match t:
		LabyrinthRunManager.LabyrinthNodeType.BATTLE_NORMAL:
			return "Savaş — dokun: başla"
		LabyrinthRunManager.LabyrinthNodeType.BATTLE_ELITE:
			return "Elit savaş — dokun: başla"
		LabyrinthRunManager.LabyrinthNodeType.FOUNTAIN:
			return "Pınar — dokun: %50 iyileş"
		LabyrinthRunManager.LabyrinthNodeType.RESURRECTION:
			return "Sunak — dokun: dirilt"
	return "BOSS — dokun: başla"

func _on_node_chosen(index: int) -> void:
	if index != LabyrinthRun.current_node_index:
		return
	var t := LabyrinthRun.node_type(LabyrinthRun.current_floor, index)
	match t:
		LabyrinthRunManager.LabyrinthNodeType.FOUNTAIN:
			LabyrinthRun.use_fountain()
			GameFlowManager.save_all()
			info_label.text = "Pınar tüm takımı iyileştirdi!"
			refresh()
		LabyrinthRunManager.LabyrinthNodeType.RESURRECTION:
			var hid := LabyrinthRun.use_resurrection()
			GameFlowManager.save_all()
			if hid.is_empty():
				info_label.text = "Diriltilecek ölü yok."
			else:
				var h := PlayerProfile.get_hero(hid)
				info_label.text = "%s dirildi!" % (h.hero_name if h != null else hid)
			refresh()
		_:
			if PlayerProfile.formation_count() < 1:
				info_label.text = "Önce dizilimden takım kur!"
				return
			GameFlowManager.start_labyrinth_battle(index)

func _on_back() -> void:
	GameFlowManager.go_lobby()

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
	bg.color = Color("#120d1c")
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
	title_label = _lbl("LABİRENT", 20, Color("#c9a0ff"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_label)
	relic_label = _lbl("", 13, Color("#ffd966"))
	top.add_child(relic_label)
	info_label = _lbl("", 13, Color("#8fd3ff"))
	v.add_child(info_label)
	nodes_box = VBoxContainer.new()
	nodes_box.add_theme_constant_override("separation", 8)
	v.add_child(nodes_box)
