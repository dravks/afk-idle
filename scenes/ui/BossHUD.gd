extends CanvasLayer
class_name BossHUD
## Boss savasi ust arayuzu: kirmizi can bari + buyuk skor + ofke uyarisi.

var manager: BossCombatManager
var boss: BossUnit

var hp_bar: ProgressBar
var score_label: Label
var warn_label: Label

var _blink_tween: Tween

func _ready() -> void:
	_build()

func setup(m: BossCombatManager, b: BossUnit) -> void:
	manager = m
	boss = b
	if manager != null:
		manager.boss_damage_updated.connect(_on_damage)
		manager.boss_enrage_warning.connect(_on_warning)
	refresh()

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if boss != null and is_instance_valid(boss) and boss.stats_component != null:
		var st := boss.stats_component
		hp_bar.max_value = 100.0
		hp_bar.value = clampf(st.current_hp / maxf(1.0, st.max_hp) * 100.0, 0.0, 100.0)
	if manager != null:
		score_label.text = "%s DMG" % BossCombatManager.format_damage(manager.total_boss_damage_dealt)

func _on_damage(total: float) -> void:
	score_label.text = "%s DMG" % BossCombatManager.format_damage(total)

func _on_warning() -> void:
	warn_label.visible = true
	if _blink_tween != null and _blink_tween.is_valid():
		_blink_tween.kill()
	warn_label.modulate.a = 1.0
	_blink_tween = create_tween()
	for i in 4:
		_blink_tween.tween_property(warn_label, "modulate:a", 0.2, 0.25)
		_blink_tween.tween_property(warn_label, "modulate:a", 1.0, 0.25)
	_blink_tween.tween_callback(func(): warn_label.visible = false)

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
	sb.border_color = Color("#72231f")
	sb.border_width_bottom = 2
	top.add_theme_stylebox_override("panel", sb)
	root.add_child(top)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(v)
	hp_bar = ProgressBar.new()
	hp_bar.min_value = 0.0
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(0, 16)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#d63a2f")
	hp_bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#1a1424")
	hp_bar.add_theme_stylebox_override("background", bg)
	v.add_child(hp_bar)
	score_label = Label.new()
	score_label.text = "0 DMG"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color("#ffd966"))
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(score_label)
	warn_label = Label.new()
	warn_label.text = "DİKKAT: BOSS ULTIMATE GELİYOR - KALKAN KULLAN!"
	warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_label.add_theme_font_size_override("font_size", 15)
	warn_label.add_theme_color_override("font_color", Color("#ff5a5a"))
	warn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warn_label.visible = false
	v.add_child(warn_label)
