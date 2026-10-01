extends Control
class_name ArenaLobbyUI
## Asenkron PvP lobisi: lig + bilet + 3 rakip karti + savunma + yenile.
## Bilet yoksa 100 elmaslik alim popup'i acar. Yonetici Flow cocugudur.

var league_label: Label
var tickets_label: Label
var defense_label: Label
var cards_box: VBoxContainer
var refresh_button: Button
var defense_button: Button
var back_button: Button

var ticket_popup: CenterContainer

var _arena: ArenaManager

func _ready() -> void:
	_arena = GameFlowManager.arena
	_build()
	_arena.points_updated.connect(_on_arena_signal)
	_arena.tickets_updated.connect(_on_arena_signal)
	_arena.sync_from_profile()
	if _arena.generated_opponents.is_empty():
		_regenerate()
	refresh()

func refresh() -> void:
	league_label.text = "%s - %d PUAN" % [_arena.get_league_name(), _arena.current_points]
	tickets_label.text = "Kalan Bilet: %d/2" % _arena.free_tickets
	defense_label.text = "Savunma: %d/5" % PlayerProfile.defense_count()
	_rebuild_cards()

func _player_cp() -> int:
	return ArenaManager.formation_cp(PlayerProfile.current_formation)

func _regenerate() -> void:
	_arena.generate_opponents(_player_cp())

func _on_refresh() -> void:
	_regenerate()
	refresh()

func _on_defense() -> void:
	if PlayerProfile.defense_count() < 1:
		for key in PlayerProfile.SLOT_KEYS:
			var h := PlayerProfile.current_formation.get(key) as HeroData
			if h != null:
				PlayerProfile.assign_defense(key, h.id)
		GameFlowManager.save_all()
	GameFlowManager.formation_defense_mode = true
	GameFlowManager.go_formation()

func _on_challenge(opp: ArenaOpponentData) -> void:
	if not _arena.use_ticket():
		_show_ticket_popup()
		return
	GameFlowManager.save_all()
	GameFlowManager.start_arena_battle(opp)

func _on_buy_ticket() -> void:
	if PlayerProfile.diamonds < 100:
		return
	PlayerProfile.diamonds -= 100
	_arena.add_ticket()
	GameFlowManager.save_all()
	_hide_ticket_popup()
	refresh()

func _on_back() -> void:
	GameFlowManager.go_lobby()

func _on_arena_signal(_a = null, _b = null) -> void:
	refresh()

func _rebuild_cards() -> void:
	for c in cards_box.get_children():
		c.queue_free()
	var titles := ["KOLAY", "DENGELİ", "ZORLU"]
	for i in _arena.generated_opponents.size():
		cards_box.add_child(_card(_arena.generated_opponents[i], titles[mini(i, 2)]))

func _card(opp: ArenaOpponentData, difficulty: String) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(8)
	sb.set_corner_radius_all(8)
	sb.border_color = Color("#3a2f52")
	sb.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var n := _lbl("%s (%s)" % [opp.opponent_name, difficulty], 15)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(n)
	var c := _lbl("Güç: %s" % _fmt(opp.combat_power), 12, Color("#9a8fb8"))
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(c)
	var g := _lbl("+%d Puan" % _arena.preview_delta(opp), 12, Color("#ffd966"))
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(g)
	var b := Button.new()
	b.text = "SAVAŞ"
	b.custom_minimum_size = Vector2(96, 52)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): _on_challenge(opp))
	h.add_child(b)
	return p

func _show_ticket_popup() -> void:
	_hide_ticket_popup()
	ticket_popup = CenterContainer.new()
	ticket_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ticket_popup)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(16)
	sb.set_corner_radius_all(8)
	sb.border_color = Color("#ffd966")
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	ticket_popup.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	v.add_child(_lbl("Biletin yok!", 17, Color("#ffd966")))
	v.add_child(_lbl("100 elmasa 1 bilet al?", 13))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var buy := Button.new()
	buy.text = "AL (100💎)"
	buy.focus_mode = Control.FOCUS_NONE
	buy.disabled = PlayerProfile.diamonds < 100
	buy.pressed.connect(_on_buy_ticket)
	row.add_child(buy)
	var cancel := Button.new()
	cancel.text = "Vazgeç"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.pressed.connect(_hide_ticket_popup)
	row.add_child(cancel)

func _hide_ticket_popup() -> void:
	if ticket_popup != null and is_instance_valid(ticket_popup):
		ticket_popup.queue_free()
	ticket_popup = null

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
	bg.color = Color("#141021")
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
	league_label = _lbl("BRONZ LİGİ", 18, Color("#ffd966"))
	league_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(league_label)
	tickets_label = _lbl("", 13, Color("#8fd3ff"))
	top.add_child(tickets_label)
	defense_label = _lbl("", 12, Color("#9a8fb8"))
	v.add_child(defense_label)
	cards_box = VBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 8)
	v.add_child(cards_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	refresh_button = Button.new()
	refresh_button.text = "Yenile"
	refresh_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refresh_button.focus_mode = Control.FOCUS_NONE
	refresh_button.pressed.connect(_on_refresh)
	row.add_child(refresh_button)
	defense_button = Button.new()
	defense_button.text = "Savunma Takımını Ayarla"
	defense_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defense_button.focus_mode = Control.FOCUS_NONE
	defense_button.pressed.connect(_on_defense)
	row.add_child(defense_button)
