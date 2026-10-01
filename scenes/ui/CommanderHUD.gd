extends Control
class_name CommanderHUD
## Komutan arayuzu: alt bar (mana + 3 buyu) + fareyi takip eden hedef halkasi.
## Savas alanina tiklaninca secili buyu tiklanan noktaya atilir.

var commander: CommanderManager

var mana_bar: ProgressBar
var mana_label: Label
var spell_container: HBoxContainer
var reticle: Panel

var _selected: CommanderSpellData
var _buttons: Dictionary = {}

func _ready() -> void:
	_build()

func setup(m: CommanderManager) -> void:
	commander = m
	_rebuild_buttons()
	refresh()

func _process(_delta: float) -> void:
	if commander == null:
		return
	refresh()
	_fit_reticle()

func _fit_reticle() -> void:
	if not reticle.visible:
		return
	var r := 60.0
	if _selected != null:
		r = maxf(30.0, _selected.aoe_radius)
	reticle.size = Vector2(r * 2.0, r * 2.0)
	reticle.position = get_global_mouse_position() - reticle.size * 0.5

func refresh() -> void:
	if commander == null:
		return
	mana_bar.max_value = commander.max_mana
	mana_bar.value = commander.current_mana
	mana_label.text = "Mana: %d / %d" % [int(commander.current_mana), int(commander.max_mana)]
	for id in _buttons.keys():
		var b := _buttons[id] as Button
		var s := _spell_by_id(str(id))
		if b == null or s == null:
			continue
		var cd := commander.get_cooldown(s)
		var ok := commander.can_cast_spell(s)
		if cd > 0.0:
			b.text = "%s\n%ds" % [s.spell_name, int(ceil(cd))]
		else:
			b.text = "%s\n%d mana" % [s.spell_name, s.mana_cost]
		b.disabled = not ok
		b.modulate = Color(1, 1, 1) if ok or cd > 0.0 else Color(0.55, 0.55, 0.6)
		if _selected != null and _selected.id == s.id and ok:
			b.modulate = Color(1.3, 1.2, 0.8)

func select_spell(spell: CommanderSpellData) -> void:
	if spell != null and commander != null and commander.can_cast_spell(spell):
		_selected = spell
		reticle.visible = true
		_fit_reticle()
	else:
		_selected = null
		reticle.visible = false
	refresh()

func _on_spell_button(spell: CommanderSpellData) -> void:
	if _selected != null and spell != null and _selected.id == spell.id:
		select_spell(null)  # ayni buton: vazgec
	else:
		select_spell(spell)

func _unhandled_input(event: InputEvent) -> void:
	if _selected == null or commander == null:
		return
	var click: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	var touch: bool = (event is InputEventScreenTouch and event.pressed)
	if not (click or touch):
		return
	var pos := get_global_mouse_position()
	if event is InputEventScreenTouch:
		pos = (event as InputEventScreenTouch).position
	commander.cast_spell_at_position(_selected, pos)
	select_spell(null)
	get_viewport().set_input_as_handled()

func _spell_by_id(spell_id: String) -> CommanderSpellData:
	if commander == null:
		return null
	for s in commander.active_spells:
		if s.id == spell_id:
			return s
	return null

func _rebuild_buttons() -> void:
	for c in spell_container.get_children():
		c.queue_free()
	_buttons.clear()
	if commander == null:
		return
	for s in commander.active_spells:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 52)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 14)
		b.focus_mode = Control.FOCUS_NONE
		b.icon = s.icon
		b.expand_icon = true
		var spell := s
		b.pressed.connect(func(): _on_spell_button(spell))
		spell_container.add_child(b)
		_buttons[s.id] = b

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.6)
	sb.set_content_margin_all(8)
	sb.border_color = Color("#2a4a72")
	sb.border_width_top = 2
	bar.add_theme_stylebox_override("panel", sb)
	add_child(bar)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(v)
	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 8)
	mrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(mrow)
	mana_bar = ProgressBar.new()
	mana_bar.min_value = 0.0
	mana_bar.max_value = 100.0
	mana_bar.value = 20.0
	mana_bar.show_percentage = false
	mana_bar.custom_minimum_size = Vector2(0, 14)
	mana_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mana_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#3f8cff")
	mana_bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#101a2a")
	mana_bar.add_theme_stylebox_override("background", bg)
	mrow.add_child(mana_bar)
	mana_label = Label.new()
	mana_label.text = "Mana: 20 / 100"
	mana_label.add_theme_font_size_override("font_size", 13)
	mana_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mrow.add_child(mana_label)
	spell_container = HBoxContainer.new()
	spell_container.add_theme_constant_override("separation", 6)
	spell_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spell_container)
	# Hedef halkasi (secili buyunun alanini gosterir).
	reticle = Panel.new()
	var rsb := StyleBoxFlat.new()
	rsb.bg_color = Color(0.2, 0.5, 1.0, 0.12)
	rsb.border_color = Color("#8fd3ff")
	rsb.set_border_width_all(2)
	rsb.set_corner_radius_all(200)
	reticle.add_theme_stylebox_override("panel", rsb)
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle.visible = false
	reticle.z_index = 95
	add_child(reticle)
