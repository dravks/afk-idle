extends Control
class_name SettingsUI
## Ayarlar ekrani: ses acma/kapama (kalici). Diger ayarlar buraya eklenir.

var mute_button: Button
var back_button: Button

func _ready() -> void:
	_build()
	refresh()

func refresh() -> void:
	mute_button.text = "SES: KAPALI" if PlayerProfile.muted else "SES: ACIK"

func _on_mute_pressed() -> void:
	AudioManager.play_sfx("btn_click")
	PlayerProfile.muted = not PlayerProfile.muted
	AudioManager.set_bus_volume("Master", 0.0 if PlayerProfile.muted else 1.0)
	GameFlowManager.save_all()
	refresh()

func _on_back_pressed() -> void:
	AudioManager.play_sfx("btn_click")
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
	bg.color = Color("#150f1f")
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
	back_button.text = "< Lobi"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(_on_back_pressed)
	top.add_child(back_button)
	var title := _lbl("AYARLAR", 22, Color("#ffd966"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(64, 0)
	top.add_child(spacer)
	v.add_child(_lbl("SES", 15, Color("#9a8fb8")))
	mute_button = Button.new()
	mute_button.custom_minimum_size = Vector2(0, 54)
	mute_button.add_theme_font_size_override("font_size", 18)
	mute_button.focus_mode = Control.FOCUS_NONE
	mute_button.pressed.connect(_on_mute_pressed)
	v.add_child(mute_button)
