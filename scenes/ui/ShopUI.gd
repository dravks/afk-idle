extends Control
class_name ShopUI
## Gunluk dukkan: 4 slot kart + cuzdan + geri bildirim. Kendi ShopManager
## cocugunu tasir; alimlar save_all ile kalici olur.

var wallet_label: Label
var info_label: Label
var back_button: Button
var slot_rows: Array = []

var _shop: ShopManager

func _ready() -> void:
	_shop = ShopManager.new()
	add_child(_shop)
	var saved: Dictionary = {}
	if GameFlowManager.saver.has_save():
		saved = GameFlowManager.saver.load_game()
	_shop.apply_save_data(saved)
	_build()
	refresh()

func refresh() -> void:
	wallet_label.text = "%d Altın  ·  %d Elmas" % [PlayerProfile.gold, PlayerProfile.diamonds]
	_rebuild_slots()

func _on_buy(index: int) -> void:
	AudioManager.play_sfx("btn_click")
	if _shop.buy_item(index, PlayerProfile):
		info_label.text = "Satın alındı!"
		GameFlowManager.save_all(_shop)
	else:
		info_label.text = "Yetersiz kaynak ya da tükendi."
	refresh()

func _on_back() -> void:
	AudioManager.play_sfx("btn_click")
	GameFlowManager.go_lobby()

func _rebuild_slots() -> void:
	for c in slot_rows:
		(c as Control).queue_free()
	slot_rows.clear()
	var list: VBoxContainer = get_node("Margin/VBox/List")
	for i in _shop.slots.size():
		var s: Dictionary = _shop.slots[i]
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#221a30")
		sb.set_content_margin_all(8)
		sb.set_corner_radius_all(6)
		sb.border_color = Color("#3a2f52")
		sb.set_border_width_all(1)
		card.add_theme_stylebox_override("panel", sb)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		card.add_child(h)
		var kind_icon := TextureRect.new()
		var kind := str(s["kind"])
		kind_icon.texture = IconLoader.get_icon("sparkles" if kind == "dust" else ("star-swirl" if kind == "exp" else "envelope"))
		kind_icon.custom_minimum_size = Vector2(40, 40)
		kind_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		kind_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(kind_icon)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(info)
		var n := _lbl(str(s["label"]), 16)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(n)
		var cost := _lbl(_cost_text(s), 12, Color("#8fd3ff"))
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(cost)
		var b := Button.new()
		if bool(s["is_sold"]):
			b.text = "TÜKENDİ"
			b.disabled = true
		else:
			b.text = "AL"
			var idx := i
			b.pressed.connect(func(): _on_buy(idx))
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(110, 48)
		h.add_child(b)
		list.add_child(card)
		slot_rows.append(card)

func _cost_text(s: Dictionary) -> String:
	var parts: Array = []
	if int(s["cost_gold"]) > 0:
		parts.append("%d Altın" % int(s["cost_gold"]))
	if int(s["cost_diamond"]) > 0:
		parts.append("%d Elmas" % int(s["cost_diamond"]))
	return " · ".join(parts)

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
	v.add_child(top)
	back_button = Button.new()
	back_button.text = "← Lobi"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(_on_back)
	top.add_child(back_button)
	var title := _lbl("DÜKKAN", 20, Color("#ffd966"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	wallet_label = _lbl("", 14, Color("#8fd3ff"))
	top.add_child(wallet_label)
	info_label = _lbl("Günlük stoklar gece yenilenir.", 12, Color("#9a8fb8"))
	v.add_child(info_label)
	var list := VBoxContainer.new()
	list.name = "List"
	list.add_theme_constant_override("separation", 8)
	v.add_child(list)
