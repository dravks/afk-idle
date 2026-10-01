extends Control
class_name TavernUI
## Cagirma ekrani: 1x/10x butonlari + nadirlige gore parlayan sonuc popup'i.
## Kendi TavernManager cocugunu tasir; cuzdan PlayerProfile'dan okunur.

const TIER_COLORS := {
	0: Color("#3ec65a"),
	1: Color("#4f8fd6"),
	2: Color("#c77dff"),
}
const TIER_NAMES := {0: "SIRADAN", 1: "NADIR", 2: "ELIT"}

var wallet_label: Label
var single_button: Button
var ten_button: Button
var back_button: Button
var popup: CenterContainer
var popup_grid: GridContainer
var popup_title: Label

var _tavern: TavernManager

func _ready() -> void:
	_tavern = TavernManager.new()
	add_child(_tavern)
	_build()
	refresh()

func refresh() -> void:
	wallet_label.text = "%d Elmas" % PlayerProfile.diamonds
	single_button.text = "1x ÇAĞIR (%d Elmas)" % TavernManager.SINGLE_COST
	single_button.disabled = not _tavern.affordable(PlayerProfile, false)
	ten_button.text = "10x ÇAĞIR (%d Elmas)" % TavernManager.TEN_COST
	ten_button.disabled = not _tavern.affordable(PlayerProfile, true)

func _on_single() -> void:
	AudioManager.play_sfx("card_flip")
	var pulled := _tavern.summon_single(PlayerProfile)
	if pulled == null:
		return
	GameFlowManager.save_all()
	_show_results([pulled])
	refresh()

func _on_ten() -> void:
	AudioManager.play_sfx("card_flip")
	var pulled := _tavern.summon_ten(PlayerProfile)
	if pulled.is_empty():
		return
	GameFlowManager.save_all()
	_show_results(pulled)
	refresh()

func _show_results(heroes: Array) -> void:
	for c in popup_grid.get_children():
		c.queue_free()
	popup_title.text = "ÇAĞIRMA SONUCU (%d)" % heroes.size()
	var i := 0
	var has_elite := false
	for h in heroes:
		var hero := h as HeroData
		if hero == null:
			continue
		var tier := _tavern.get_tier(hero)
		if tier == 2:
			has_elite = true
		popup_grid.add_child(_card(hero, tier, i))
		i += 1
	if has_elite:
		AudioManager.play_sfx("elite_shine")
	popup.visible = true

func _card(hero: HeroData, tier: int, index: int) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(96, 84)
	var col: Color = TIER_COLORS.get(tier, Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(4)
	sb.set_corner_radius_all(6)
	sb.border_color = col
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var por := TextureRect.new()
	por.texture = HeroSpriteFactory.portrait_of(hero)
	por.custom_minimum_size = Vector2(56, 56)
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	v.add_child(por)
	var n := _lbl(hero.hero_name, 12)
	v.add_child(n)
	v.add_child(_lbl(str(TIER_NAMES.get(tier, "?")), 11, col))
	# Kademeli acilis parlamasi.
	p.scale = Vector2(0.5, 0.5)
	p.modulate.a = 0.0
	p.pivot_offset = Vector2(48, 42)
	var tw := create_tween()
	tw.tween_interval(0.06 * float(index))
	tw.tween_property(p, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(p, "modulate:a", 1.0, 0.18)
	return p

func _lbl(text: String, size: int, col := Color("#e8e2f0")) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _on_back() -> void:
	GameFlowManager.go_lobby()

func _on_popup_close() -> void:
	popup.visible = false

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
		margin.add_theme_constant_override(s, 16)
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
	var title := _lbl("TAVERNA", 22, Color("#ffd966"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	wallet_label = _lbl("", 15, Color("#8fd3ff"))
	top.add_child(wallet_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	v.add_child(_lbl("Elit %4.61  ·  Nadir %43.70  ·  Sıradan %51.69", 12, Color("#9a8fb8")))
	single_button = Button.new()
	single_button.custom_minimum_size = Vector2(0, 56)
	single_button.add_theme_font_size_override("font_size", 18)
	single_button.focus_mode = Control.FOCUS_NONE
	single_button.pressed.connect(_on_single)
	v.add_child(single_button)
	ten_button = Button.new()
	ten_button.custom_minimum_size = Vector2(0, 56)
	ten_button.add_theme_font_size_override("font_size", 18)
	ten_button.focus_mode = Control.FOCUS_NONE
	ten_button.pressed.connect(_on_ten)
	v.add_child(ten_button)
	popup = CenterContainer.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.visible = false
	add_child(popup)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(14)
	sb.set_corner_radius_all(10)
	sb.border_color = Color("#ffd966")
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	popup.add_child(panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 8)
	panel.add_child(pv)
	popup_title = _lbl("SONUÇ", 18, Color("#ffd966"))
	pv.add_child(popup_title)
	popup_grid = GridContainer.new()
	popup_grid.columns = 5
	popup_grid.add_theme_constant_override("h_separation", 6)
	popup_grid.add_theme_constant_override("v_separation", 6)
	pv.add_child(popup_grid)
	var close := Button.new()
	close.text = "Kapat"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_on_popup_close)
	pv.add_child(close)
