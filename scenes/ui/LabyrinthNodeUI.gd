extends Button
class_name LabyrinthNodeUI
## Harita dugme parcasi: baslik + durum rengi. Tiklama index ile yukari iletilir.

signal node_chosen(index: int)

var node_index: int = 0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 64)
	add_theme_font_size_override("font_size", 16)
	focus_mode = Control.FOCUS_NONE
	pressed.connect(func(): node_chosen.emit(node_index))

## state: "done" / "current" / "locked".
func setup(index: int, title: String, subtitle: String, state: String) -> void:
	node_index = index
	text = "%s\n%s" % [title, subtitle]
	disabled = state != "current"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(6)
	sb.set_corner_radius_all(8)
	if state == "done":
		sb.border_color = Color("#3ec65a")
		sb.set_border_width_all(2)
	elif state == "current":
		sb.border_color = Color("#ffd966")
		sb.set_border_width_all(3)
	else:
		sb.border_color = Color("#3a2f52")
		sb.set_border_width_all(1)
		modulate = Color(0.55, 0.55, 0.6)
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", sb)
	add_theme_stylebox_override("pressed", sb)
	add_theme_stylebox_override("disabled", sb)
