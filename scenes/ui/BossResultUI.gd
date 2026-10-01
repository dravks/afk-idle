extends CanvasLayer
class_name BossResultUI
## Boss deneme sonucu: final skor + kademe kupasi + odul dokumu + lobiye donus.

signal lobby_requested

var title_label: Label
var score_label: Label
var tier_label: Label
var reward_label: Label
var best_label: Label
var lobby_button: Button

var _root: Control

const TIER_COLORS := {
	"": Color("#9a8fb8"), "bronze": Color("#c98a4b"), "silver": Color("#8fa3b8"),
	"gold": Color("#ffd966"), "diamond": Color("#c77dff"),
}
const TIER_CUPS := {
	"": "KATILIM", "bronze": "BRONZ KUPA", "silver": "GÜMÜŞ KUPA",
	"gold": "ALTIN KUPA", "diamond": "ELMAS KUPA",
}

func _ready() -> void:
	_build()
	visible = false

func display_result(final_damage: float, tier: String, rewards: Dictionary, best: float) -> void:
	score_label.text = "%s DMG" % BossCombatManager.format_damage(final_damage)
	tier_label.text = str(TIER_CUPS.get(tier, "?"))
	tier_label.add_theme_color_override("font_color", TIER_COLORS.get(tier, Color.WHITE))
	reward_label.text = _reward_text(rewards)
	best_label.text = "En iyi: %s DMG" % BossCombatManager.format_damage(best)
	visible = true
	_root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 0.3)

func _reward_text(rewards: Dictionary) -> String:
	if rewards.is_empty():
		return "Ödül yok — 100K barajını geçmelisin."
	var parts: Array = []
	if int(rewards.get("gold", 0)) > 0:
		parts.append("+%s Altın" % BossCombatManager.format_damage(float(rewards["gold"])))
	if int(rewards.get("dust", 0)) > 0:
		parts.append("+%d Toz" % int(rewards["dust"]))
	if int(rewards.get("exp", 0)) > 0:
		parts.append("+%s EXP" % BossCombatManager.format_damage(float(rewards["exp"])))
	if int(rewards.get("diamonds", 0)) > 0:
		parts.append("+%d Elmas" % int(rewards["diamonds"]))
	var gears: Array = rewards.get("gears", [])
	for g in gears:
		parts.append("+%s" % str(g))
	if str(rewards.get("summon", "")) != "":
		parts.append("Çağrı: %s!" % str(rewards["summon"]))
	return "\n".join(parts)

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#221a30")
	sb.set_content_margin_all(18)
	sb.set_corner_radius_all(10)
	sb.border_color = Color("#d63a2f")
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	title_label = Label.new()
	title_label.text = "BOSS SONUCU"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color("#ffd966"))
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(title_label)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(score_label)
	tier_label = Label.new()
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_size_override("font_size", 20)
	tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tier_label)
	reward_label = Label.new()
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 14)
	reward_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(reward_label)
	best_label = Label.new()
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_size_override("font_size", 12)
	best_label.add_theme_color_override("font_color", Color("#9a8fb8"))
	best_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(best_label)
	lobby_button = Button.new()
	lobby_button.text = "Lobiye Dön"
	lobby_button.custom_minimum_size = Vector2(0, 48)
	lobby_button.add_theme_font_size_override("font_size", 17)
	lobby_button.focus_mode = Control.FOCUS_NONE
	lobby_button.pressed.connect(func(): AudioManager.play_sfx("btn_click"); lobby_requested.emit())
	v.add_child(lobby_button)
