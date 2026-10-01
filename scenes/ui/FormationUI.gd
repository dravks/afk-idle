extends Control
class_name FormationUI
## Savas oncesi dizilim: 5 yuva (2 on + 3 arka) + kadro listesi.
## Mantik PlayerProfile'da (assign/remove/count); bu ekran sadece cizer.

var stage_label: Label
var aura_label: Label
var slot_boxes: Dictionary = {}
var roster_box: HBoxContainer
var battle_button: Button
var back_button: Button
var mode_button: Button

var _selected_slot: String = ""
var _detail_mode := false
var _detail: HeroDetailUI
## Savunma kipi: saldiri dizilimi yerine arena savunmasi duzenlenir,
## savas butonu gizlenir, geri donus arena lobisinedir.
var edit_defense := false

## Hedef sozluk (saldiri/savunma).
func _form() -> Dictionary:
	if edit_defense:
		return PlayerProfile.arena_defense_formation
	return PlayerProfile.current_formation

func _ready() -> void:
	edit_defense = GameFlowManager.formation_defense_mode
	_build()
	refresh()

func refresh() -> void:
	if edit_defense:
		stage_label.text = "SAVUNMA DİZİLİMİ (%d/5)" % PlayerProfile.defense_count()
	else:
		var st := GameFlowManager.get_current_stage()
		stage_label.text = "Bölüm %s — Takimini Diz" % st.stage_id
	_refresh_aura()
	_refresh_slots()
	_refresh_roster()
	if edit_defense:
		battle_button.visible = false
	else:
		battle_button.visible = true
		battle_button.disabled = PlayerProfile.formation_count() < 1
		battle_button.text = "SAVASA BASLA (%d/5)" % PlayerProfile.formation_count()

func _on_slot_pressed(slot: String) -> void:
	if edit_defense:
		var dh := PlayerProfile.arena_defense_formation.get(slot) as HeroData
		if dh != null:
			PlayerProfile.remove_defense(slot)
			_selected_slot = ""
		else:
			_selected_slot = "" if _selected_slot == slot else slot
		refresh()
		return
	var h := PlayerProfile.current_formation.get(slot) as HeroData
	if h != null:
		PlayerProfile.remove_from_slot(slot)  # dolu yuva bosalir
		_selected_slot = ""
	else:
		_selected_slot = "" if _selected_slot == slot else slot
	refresh()

func _on_roster_card(hero_id: String) -> void:
	if edit_defense:
		if _selected_slot != "" and PlayerProfile.arena_defense_formation.get(_selected_slot) == null:
			PlayerProfile.assign_defense(_selected_slot, hero_id)
			_selected_slot = ""
		else:
			for key in PlayerProfile.SLOT_KEYS:
				if PlayerProfile.arena_defense_formation.get(key) == null:
					PlayerProfile.assign_defense(key, hero_id)
					break
		GameFlowManager.save_all()
		refresh()
		return
	if LabyrinthRun.is_hero_dead(hero_id):
		return  # olu kahraman secilemez (pinar/sunak ister)
	if _detail_mode:
		_open_detail(hero_id)
		return
	if _selected_slot != "" and PlayerProfile.current_formation.get(_selected_slot) == null:
		PlayerProfile.assign_to_slot(_selected_slot, hero_id)
		_selected_slot = ""
	else:
		for key in PlayerProfile.SLOT_KEYS:
			if PlayerProfile.current_formation.get(key) == null:
				PlayerProfile.assign_to_slot(key, hero_id)
				break
	refresh()

func _on_battle_pressed() -> void:
	AudioManager.play_sfx("btn_click")
	if PlayerProfile.formation_count() < 1:
		return
	GameFlowManager.save_all()
	GameFlowManager.go_battle()

func _on_back_pressed() -> void:
	AudioManager.play_sfx("btn_click")
	if edit_defense:
		GameFlowManager.go_arena_lobby()
	else:
		GameFlowManager.go_lobby()

## Aktif sinerji rozeti (aura yoksa gizlenir).
func _refresh_aura() -> void:
	var heroes: Array[HeroData] = []
	for key in PlayerProfile.SLOT_KEYS:
		var h := _form().get(key) as HeroData
		if h != null:
			heroes.append(h)
	var syn := FactionSynergyCalculator.calculate_synergy(heroes)
	if str(syn["description"]) == "Sinerji yok":
		aura_label.visible = false
	else:
		aura_label.visible = true
		aura_label.text = str(syn["description"])

func _on_mode_pressed() -> void:
	AudioManager.play_sfx("btn_click")
	_detail_mode = not _detail_mode
	mode_button.text = "İNCELE: AÇIK" if _detail_mode else "İNCELE"
	refresh()

func _open_detail(hero_id: String) -> void:
	_close_detail()
	var h := PlayerProfile.get_hero(hero_id)
	if h == null:
		return
	_detail = HeroDetailUI.new()
	add_child(_detail)
	_detail.closed.connect(_close_detail)
	_detail.display_hero(h,
		int(ResonatingCrystalManager.hero_levels.get(hero_id, 1)),
		hero_id in ResonatingCrystalManager.crystal_slots)

func _close_detail() -> void:
	if _detail != null and is_instance_valid(_detail):
		_detail.queue_free()
	_detail = null
	refresh()

func _slot_panel(slot: String, title: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(140, 96)
	var h := _form().get(slot) as HeroData
	var sb := StyleBoxFlat.new()
	sb.set_content_margin_all(6)
	sb.set_corner_radius_all(6)
	if slot == _selected_slot:
		sb.bg_color = Color("#3a2f10")
		sb.border_color = Color("#ffd966")
		sb.set_border_width_all(2)
	elif h != null:
		sb.bg_color = Color("#1e3a2a")
		sb.border_color = Color("#3ec65a")
		sb.set_border_width_all(2)
	else:
		sb.bg_color = Color("#221a30")
		sb.border_color = Color("#3a2f52")
		sb.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.gui_input.connect(_on_slot_gui.bind(slot))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var t := _mk_label(title, 11, HORIZONTAL_ALIGNMENT_CENTER, Color("#9a8fb8"))
	v.add_child(t)
	var n := _mk_label(h.hero_name if h != null else "BOŞ", 15, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(n)
	if h != null:
		v.add_child(_mk_label(_role_name(h.role), 11, HORIZONTAL_ALIGNMENT_CENTER, Color("#8fd3ff")))
	slot_boxes[slot] = p
	return p

func _on_slot_gui(event: InputEvent, slot: String) -> void:
	var click: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	var touch: bool = (event is InputEventScreenTouch and event.pressed)
	if click or touch:
		_on_slot_pressed(slot)

func _refresh_slots() -> void:
	for c in slot_boxes.values():
		(c as Control).queue_free()
	slot_boxes.clear()
	var front: VBoxContainer = get_node("Margin/VBox/Slots/Front")
	var back: VBoxContainer = get_node("Margin/VBox/Slots/Back")
	for s in front.get_children() + back.get_children():
		s.queue_free()
	front.add_child(_slot_panel("FRONT_TOP", "ÖN · ÜST"))
	front.add_child(_slot_panel("FRONT_BOT", "ÖN · ALT"))
	back.add_child(_slot_panel("BACK_TOP", "ARKA · ÜST"))
	back.add_child(_slot_panel("BACK_MID", "ARKA · ORTA"))
	back.add_child(_slot_panel("BACK_BOT", "ARKA · ALT"))

func _refresh_roster() -> void:
	for c in roster_box.get_children():
		c.queue_free()
	for h in PlayerProfile.owned_heroes:
		var b := Button.new()
		var placed := PlayerProfile.is_defense_placed(h.id) if edit_defense else PlayerProfile.is_hero_placed(h.id)
		var mark := " •" if placed else ""
		var dead := LabyrinthRun.is_hero_dead(h.id)
		if dead:
			mark = " ÖLÜ"
		var lv := ResonatingCrystalManager.get_effective_level(h.id)
		b.text = "%s%s\n%s · Lv%d" % [h.hero_name, mark, _role_name(h.role), lv]
		b.disabled = dead
		b.custom_minimum_size = Vector2(110, 64)
		b.focus_mode = Control.FOCUS_NONE
		var hid := h.id
		b.icon = HeroSpriteFactory.portrait_of(h)
		b.expand_icon = true
		b.pressed.connect(func(): _on_roster_card(hid))
		roster_box.add_child(b)

func _role_name(role: GlobalEnums.Role) -> String:
	match role:
		GlobalEnums.Role.TANK:
			return "TANK"
		GlobalEnums.Role.WARRIOR:
			return "SAVAŞÇI"
		GlobalEnums.Role.RANGER:
			return "OKÇU"
		GlobalEnums.Role.MAGE:
			return "BÜYÜCÜ"
		GlobalEnums.Role.SUPPORT:
			return "DESTEK"
	return "?"

func _mk_label(text: String, size: int, align := HORIZONTAL_ALIGNMENT_LEFT, col := Color("#e8e2f0")) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
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
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(s, 14)
	add_child(margin)
	var v := VBoxContainer.new()
	v.name = "VBox"
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	back_button = Button.new()
	back_button.text = "← Lobi"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(_on_back_pressed)
	top.add_child(back_button)
	stage_label = _mk_label("Bölüm", 18, HORIZONTAL_ALIGNMENT_CENTER)
	stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stage_label)
	mode_button = Button.new()
	mode_button.text = "İNCELE"
	mode_button.focus_mode = Control.FOCUS_NONE
	mode_button.pressed.connect(_on_mode_pressed)
	top.add_child(mode_button)
	aura_label = _mk_label("", 13, HORIZONTAL_ALIGNMENT_CENTER, Color("#ffd966"))
	v.add_child(aura_label)
	var slots := HBoxContainer.new()
	slots.name = "Slots"
	slots.add_theme_constant_override("separation", 10)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(slots)
	var front := VBoxContainer.new()
	front.name = "Front"
	front.add_theme_constant_override("separation", 8)
	slots.add_child(front)
	var back := VBoxContainer.new()
	back.name = "Back"
	back.add_theme_constant_override("separation", 8)
	slots.add_child(back)
	v.add_child(_mk_label("KADRO (dokun: ilk boş yuvaya koy)", 12, HORIZONTAL_ALIGNMENT_LEFT, Color("#9a8fb8")))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 84)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	roster_box = HBoxContainer.new()
	roster_box.add_theme_constant_override("separation", 8)
	roster_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(roster_box)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	battle_button = Button.new()
	battle_button.text = "SAVASA BASLA"
	battle_button.icon = IconLoader.get_icon("broadsword")
	battle_button.expand_icon = true
	battle_button.custom_minimum_size = Vector2(0, 56)
	battle_button.add_theme_font_size_override("font_size", 20)
	battle_button.focus_mode = Control.FOCUS_NONE
	battle_button.pressed.connect(_on_battle_pressed)
	v.add_child(battle_button)
