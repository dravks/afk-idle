extends Control
class_name BossLobbyUI
## Boss girisi: patron adi + bugunku rekor + Meydan Oku.

var title_label: Label
var best_label: Label
var challenge_button: Button
var back_button: Button

func _ready() -> void:
	_build()
	refresh()

func refresh() -> void:
	var dragon := load("res://data/bosses/dragon.tres") as BossData
	title_label.text = dragon.boss_title if dragon != null else "Kadim Ejderha"
	var today := BossCombatManager.today_key()
	if PlayerProfile.boss_best_date == today and int(PlayerProfile.boss_best_score) > 0:
		best_label.text = "Bugünkü en iyi: %s DMG" % BossCombatManager.format_damage(float(PlayerProfile.boss_best_score))
	else:
		best_label.text = "Bugün henüz denenmedi."

func _on_challenge() -> void:
	GameFlowManager.go_boss()

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
	bg.color = Color("#1c0f14")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(s, 20)
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
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	v.add_child(_lbl("DÜNYA BOSSU", 30, Color("#ff5a5a")))
	title_label = _lbl("", 18, Color("#ffd966"))
	v.add_child(title_label)
	var drake := TextureRect.new()
	drake.texture = IconLoader.get_icon("dragon-head")
	drake.custom_minimum_size = Vector2(96, 96)
	drake.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drake.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drake.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	drake.modulate = Color("#ff8a7a")
	v.add_child(drake)
	v.add_child(_lbl("90 saniyede olabildiğince hasar ver!\nHer 20 saniyede öfke saldırısı gelir — kalkanla karşıla.", 13, Color("#9a8fb8")))
	best_label = _lbl("", 15, Color("#8fd3ff"))
	v.add_child(best_label)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(grow)
	challenge_button = Button.new()
	challenge_button.text = "MEYDAN OKU"
	challenge_button.icon = IconLoader.get_icon("crossed-swords")
	challenge_button.expand_icon = true
	challenge_button.icon = IconLoader.get_icon("crossed-swords")
	challenge_button.expand_icon = true
	challenge_button.custom_minimum_size = Vector2(0, 60)
	challenge_button.add_theme_font_size_override("font_size", 22)
	challenge_button.focus_mode = Control.FOCUS_NONE
	challenge_button.pressed.connect(_on_challenge)
	v.add_child(challenge_button)
