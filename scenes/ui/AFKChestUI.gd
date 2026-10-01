extends Control
class_name AFKChestUI
## AFK Sandigi arayuzu: tiklanabilir sandik + birikme suresi + odul popup'i.
## `setup(manager)` ile baglanir; sure her karede manager'dan okunur.

const CAP_TEXT := "12:00:00"

# Autoload singleton oldugu icin tipsiz tutulur (class_name + autoload ayni
# isimde olamaz; AFKManager'a ismiyle erisilir).
var manager

var chest_button: Button
var timer_label: Label
var popup: CenterContainer
var reward_label: Label
var claim_button: Button

func _ready() -> void:
	_build()
	popup.visible = false

func setup(m) -> void:
	manager = m
	manager.rewards_claimed.connect(_on_claimed)
	_refresh()

func _process(_delta: float) -> void:
	if manager == null:
		return
	_refresh_timer()

func _on_chest_pressed() -> void:
	if manager == null:
		return
	var r: Dictionary = manager.calculate_pending_rewards()
	reward_label.text = "+%d Altin\n+%d EXP\n+%d Toz" % [int(r["gold"]), int(r["exp"]), int(r["dust"])]
	popup.visible = true

func _on_claim_pressed() -> void:
	if manager == null:
		return
	manager.claim_rewards()
	popup.visible = false

func _on_claimed(_gold: int, _exp: int, _dust: int) -> void:
	_refresh()

func _refresh() -> void:
	_refresh_timer()

func _refresh_timer() -> void:
	if manager == null or timer_label == null:
		return
	timer_label.text = "%s / %s" % [format_hms(manager.get_accumulated_seconds()), CAP_TEXT]

static func format_hms(total_seconds: int) -> String:
	var s := maxi(0, total_seconds)
	return "%02d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.set_content_margin_all(8)
	sb.border_color = Color("#3a2f52")
	sb.border_width_top = 2
	bottom.add_theme_stylebox_override("panel", sb)
	add_child(bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(row)
	chest_button = Button.new()
	chest_button.text = "SANDIK"
	chest_button.icon = IconLoader.get_icon("chest")
	chest_button.expand_icon = true
	chest_button.custom_minimum_size = Vector2(120, 48)
	chest_button.add_theme_font_size_override("font_size", 18)
	chest_button.focus_mode = Control.FOCUS_NONE
	chest_button.pressed.connect(_on_chest_pressed)
	row.add_child(chest_button)
	timer_label = Label.new()
	timer_label.text = "00:00:00 / 12:00:00"
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(timer_label)
	# Odul popup'i.
	popup = CenterContainer.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(popup)
	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color("#221a30")
	psb.set_content_margin_all(20)
	psb.set_corner_radius_all(10)
	psb.border_color = Color("#ffd966")
	psb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", psb)
	popup.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var h := Label.new()
	h.text = "AFK ODULLERI"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 20)
	h.add_theme_color_override("font_color", Color("#ffd966"))
	v.add_child(h)
	reward_label = Label.new()
	reward_label.text = "+0 Altin"
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 16)
	v.add_child(reward_label)
	claim_button = Button.new()
	claim_button.text = "TOPLA"
	claim_button.custom_minimum_size = Vector2(200, 48)
	claim_button.add_theme_font_size_override("font_size", 16)
	claim_button.focus_mode = Control.FOCUS_NONE
	claim_button.pressed.connect(_on_claim_pressed)
	v.add_child(claim_button)
