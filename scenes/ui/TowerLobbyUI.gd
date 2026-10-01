extends Control
class_name TowerLobbyUI
## Kule girisi: kat bilgisi + dusman onizleme + guc + odul + otomatik + meydan okuma.

var floor_label: Label
var enemy_box: HBoxContainer
var cp_label: Label
var reward_label: Label
var auto_check: CheckButton
var challenge_button: Button
var back_button: Button
var info_label: Label

func _ready() -> void:
	_build()
	refresh()

func refresh() -> void:
	var tower: TowerManager = GameFlowManager.tower
	var f := tower.current_floor
	var st := tower.get_floor_stage_data(f)
	floor_label.text = "KRALIN KULESİ - KAT %d%s" % [f, " - ELİT MUHAFIZLAR" if tower.is_elite_floor(f) else ""]
	for c in enemy_box.get_children():
		c.queue_free()
	for h in [st.enemy_front_top, st.enemy_front_bot, st.enemy_back_top, st.enemy_back_mid, st.enemy_back_bot]:
		enemy_box.add_child(_foe_card(h as HeroData, st.enemy_team_level))
	cp_label.text = "Düşman Gücü: %s" % _fmt(tower.floor_cp_estimate(f))
	reward_label.text = _reward_text(f)
	auto_check.button_pressed = tower.is_auto_climb_active
	info_label.text = ""

func _foe_card(h: HeroData, level: int) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var por := TextureRect.new()
	por.texture = HeroSpriteFactory.portrait_of(h)
	por.custom_minimum_size = Vector2(56, 56)
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	v.add_child(por)
	var l := _lbl("Lv%d" % level, 11, Color("#9a8fb8"))
	v.add_child(l)
	var n := _lbl(h.hero_name if h != null else "?", 10)
	v.add_child(n)
	return v

func _reward_text(floor_num: int) -> String:
	var tower: TowerManager = GameFlowManager.tower
	var st := tower.get_floor_stage_data(floor_num)
	if floor_num in PlayerProfile.tower_cleared:
		return "Tekrar ödülü: %s Altın" % _fmt(int(float(st.first_clear_gold) * 0.2))
	var txt := "İlk geçiş: %s Altın" % _fmt(st.first_clear_gold)
	if tower.is_elite_floor(floor_num):
		txt += " · %d Elmas · Parşömen" % st.first_clear_diamonds
	return txt

func _on_challenge() -> void:
	if PlayerProfile.formation_count() < 1:
		info_label.text = "Önce dizilimden takım kur!"
		return
	AudioManager.play_sfx("btn_click")
	GameFlowManager.start_tower_battle()

func _on_auto_toggled(on: bool) -> void:
	GameFlowManager.tower.set_auto_climb_active(on)

func _on_back() -> void:
	AudioManager.play_sfx("btn_click")
	GameFlowManager.go_lobby()

func _fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (float(n) / 1000000.0)
	if n >= 1000:
		return "%.1fK" % (float(n) / 1000.0)
	return str(n)

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
	bg.color = Color("#141428")
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
	floor_label = _lbl("", 20, Color("#ffd966"))
	floor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(floor_label)
	v.add_child(_lbl("KARŞI TAKIM", 12, Color("#9a8fb8")))
	enemy_box = HBoxContainer.new()
	enemy_box.add_theme_constant_override("separation", 6)
	enemy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(enemy_box)
	cp_label = _lbl("", 13, Color("#ff9a9a"))
	v.add_child(cp_label)
	reward_label = _lbl("", 13, Color("#8fd3ff"))
	v.add_child(reward_label)
	info_label = _lbl("", 13, Color("#ff9a9a"))
	v.add_child(info_label)
	auto_check = CheckButton.new()
	auto_check.text = "Otomatik Tırmanış"
	auto_check.focus_mode = Control.FOCUS_NONE
	auto_check.toggled.connect(_on_auto_toggled)
	v.add_child(auto_check)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	challenge_button = Button.new()
	challenge_button.text = "MEYDAN OKU"
	challenge_button.custom_minimum_size = Vector2(0, 60)
	challenge_button.add_theme_font_size_override("font_size", 22)
	challenge_button.focus_mode = Control.FOCUS_NONE
	challenge_button.pressed.connect(_on_challenge)
	v.add_child(challenge_button)
