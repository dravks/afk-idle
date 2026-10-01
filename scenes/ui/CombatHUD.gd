extends CanvasLayer
class_name CombatHUD

signal auto_stop_requested
## Ust savas arayuzu: sure + hiz/duraklat + iki takim cani.
## `setup(manager)` ile baglanir; her kare manager'dan okur (sinyal yarisi yok).

var manager: CombatManager

var time_label: Label
var speed_button: Button
var pause_button: Button
var stop_button: Button
var player_team_hp_bar: ProgressBar
var enemy_team_hp_bar: ProgressBar

var _paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_refresh_time(CombatManager.MATCH_TIME)
	_refresh_bars(1.0, 1.0)

func setup(m: CombatManager) -> void:
	manager = m
	_sync_speed_text()

func _process(_delta: float) -> void:
	if manager == null:
		return
	_refresh_time(manager.match_time_remaining)
	_refresh_bars(
		manager.get_team_hp_ratio(Unit.Team.PLAYER),
		manager.get_team_hp_ratio(Unit.Team.ENEMY))

func _on_speed_pressed() -> void:
	if manager == null:
		return
	manager.toggle_battle_speed()
	_sync_speed_text()

func _on_pause_pressed() -> void:
	_paused = not _paused
	get_tree().paused = _paused
	pause_button.text = "▶" if _paused else "⏸"

func _sync_speed_text() -> void:
	speed_button.text = "2x" if Engine.time_scale >= 2.0 else "1x"

func _refresh_time(seconds_remaining: float) -> void:
	var s := maxi(0, int(seconds_remaining))
	time_label.text = "%02d:%02d" % [s / 60, s % 60]

func _refresh_bars(player_ratio: float, enemy_ratio: float) -> void:
	player_team_hp_bar.value = clampf(player_ratio, 0.0, 1.0) * 100.0
	enemy_team_hp_bar.value = clampf(enemy_ratio, 0.0, 1.0) * 100.0

func _bar(col: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 100.0
	b.value = 100.0
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 14)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	b.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#1a1424")
	b.add_theme_stylebox_override("background", bg)
	return b

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.set_content_margin_all(8)
	sb.border_color = Color("#3a2f52")
	sb.border_width_bottom = 2
	top.add_theme_stylebox_override("panel", sb)
	root.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(row)
	player_team_hp_bar = _bar(Color("#3ec65a"))
	row.add_child(player_team_hp_bar)
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 2)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mid)
	time_label = Label.new()
	time_label.text = "01:30"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 20)
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(time_label)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 4)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(btns)
	speed_button = Button.new()
	speed_button.text = "1x"
	speed_button.focus_mode = Control.FOCUS_NONE
	speed_button.pressed.connect(_on_speed_pressed)
	btns.add_child(speed_button)
	pause_button = Button.new()
	pause_button.text = "II"
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.pressed.connect(_on_pause_pressed)
	btns.add_child(pause_button)
	stop_button = Button.new()
	stop_button.text = "DURDUR"
	stop_button.focus_mode = Control.FOCUS_NONE
	stop_button.visible = false
	stop_button.pressed.connect(func(): auto_stop_requested.emit())
	btns.add_child(stop_button)
	enemy_team_hp_bar = _bar(Color("#d65a4f"))
	row.add_child(enemy_team_hp_bar)
