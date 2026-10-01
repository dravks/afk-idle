extends CanvasLayer
class_name BattleResultUI
## Mac sonu popup: VICTORY/DEFEAT + Damage Meters + Tekrar/Sonraki.
## Butonlar SADECE sinyal yayar (retry_requested / next_requested); sahneyi
## yeniden kurmak savas sahnesinin isidir (Prompt 7 sonrasi baglanacak).

signal retry_requested
signal next_requested
signal lobby_requested

const ROLE_NAMES := {
	0: "TANK", 1: "WARRIOR", 2: "RANGER", 3: "MAGE", 4: "SUPPORT",
}
const COL_DEALT := Color("#d65a4f")
const COL_TAKEN := Color("#8fa3b8")
const COL_HEAL := Color("#3ec65a")

var title_label: Label
var reward_label: Label
var countdown_label: Label
var stats_list: VBoxContainer
var retry_button: Button
var next_button: Button
var lobby_button: Button

var _root: Control

func _ready() -> void:
	_build()
	visible = false

func display_result(is_victory: bool, tracker: CombatTracker) -> void:
	_rebuild_rows(tracker)
	title_label.text = "VICTORY" if is_victory else "DEFEAT"
	title_label.add_theme_color_override(
		"font_color", Color("#ffd966") if is_victory else Color("#ff5a5a"))
	# Lobi donusu yenilgide anlamli (zaferde Sonraki var).
	lobby_button.visible = not is_victory
	visible = true
	_root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 0.3)

func hide_result() -> void:
	visible = false
	countdown_label.visible = false
	countdown_label.text = ""

## Zafer ganimeti satiri (bos metin gizler).
func set_reward_line(text: String) -> void:
	reward_label.text = text
	reward_label.visible = not text.is_empty()

## Otomatik tirmanis geri sayimi (kule). Her gosterimde sifirlanir.
func show_countdown(text: String) -> void:
	countdown_label.text = text
	countdown_label.visible = not text.is_empty()

func _rebuild_rows(tracker: CombatTracker) -> void:
	for c in stats_list.get_children():
		c.queue_free()
	_add_team_block("TAKIMIN", tracker.get_team_stats(Unit.Team.PLAYER))
	_add_team_block("DUSMAN", tracker.get_team_stats(Unit.Team.ENEMY))

func _add_team_block(header: String, rows: Array[Dictionary]) -> void:
	var h := Label.new()
	h.text = header
	h.add_theme_font_size_override("font_size", 14)
	h.add_theme_color_override("font_color", Color("#9a8fb8"))
	stats_list.add_child(h)
	var max_dealt := 1.0
	var max_taken := 1.0
	var max_heal := 1.0
	for r in rows:
		max_dealt = maxf(max_dealt, float(r["damage_dealt"]))
		max_taken = maxf(max_taken, float(r["damage_taken"]))
		max_heal = maxf(max_heal, float(r["healing_done"]))
	for r in rows:
		stats_list.add_child(_hero_row(r, max_dealt, max_taken, max_heal))

func _hero_row(r: Dictionary, max_dealt: float, max_taken: float, max_heal: float) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var name_l := Label.new()
	name_l.text = "%s · %s" % [str(r["name"]), str(ROLE_NAMES.get(int(r["role"]), "?"))]
	name_l.add_theme_font_size_override("font_size", 13)
	v.add_child(name_l)
	v.add_child(_meter("Hasar", float(r["damage_dealt"]), max_dealt, COL_DEALT))
	v.add_child(_meter("Alinan", float(r["damage_taken"]), max_taken, COL_TAKEN))
	v.add_child(_meter("Iyilesme", float(r["healing_done"]), max_heal, COL_HEAL))
	return v

func _meter(caption: String, value: float, maximum: float, col: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var l := Label.new()
	l.text = caption
	l.custom_minimum_size = Vector2(64, 0)
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color("#9a8fb8"))
	h.add_child(l)
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = maxf(1.0, maximum)
	b.value = clampf(value, 0.0, maxf(1.0, maximum))
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 10)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	b.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#1a1424")
	b.add_theme_stylebox_override("background", bg)
	h.add_child(b)
	var v := Label.new()
	v.text = str(int(value))
	v.add_theme_font_size_override("font_size", 11)
	h.add_child(v)
	return h

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(14)
	sb.set_corner_radius_all(8)
	sb.border_color = Color("#ffd966")
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(400, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	title_label = Label.new()
	title_label.text = "VICTORY"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	v.add_child(title_label)
	reward_label = Label.new()
	reward_label.text = ""
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 14)
	reward_label.add_theme_color_override("font_color", Color("#8fd3ff"))
	reward_label.visible = false
	v.add_child(reward_label)
	countdown_label = Label.new()
	countdown_label.text = ""
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 14)
	countdown_label.add_theme_color_override("font_color", Color("#ffd966"))
	countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	countdown_label.visible = false
	v.add_child(countdown_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	stats_list = VBoxContainer.new()
	stats_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_list.add_theme_constant_override("separation", 8)
	scroll.add_child(stats_list)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(btns)
	retry_button = Button.new()
	retry_button.text = "Tekrar Oyna"
	retry_button.custom_minimum_size = Vector2(0, 44)
	retry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry_button.focus_mode = Control.FOCUS_NONE
	retry_button.pressed.connect(func(): AudioManager.play_sfx("btn_click"); retry_requested.emit())
	btns.add_child(retry_button)
	next_button = Button.new()
	next_button.text = "Sonraki Seviye"
	next_button.custom_minimum_size = Vector2(0, 44)
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.pressed.connect(func(): AudioManager.play_sfx("btn_click"); next_requested.emit())
	btns.add_child(next_button)
	lobby_button = Button.new()
	lobby_button.text = "Lobi"
	lobby_button.custom_minimum_size = Vector2(0, 44)
	lobby_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lobby_button.focus_mode = Control.FOCUS_NONE
	lobby_button.pressed.connect(func(): AudioManager.play_sfx("btn_click"); lobby_requested.emit())
	btns.add_child(lobby_button)
