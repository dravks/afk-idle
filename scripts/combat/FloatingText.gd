extends Marker2D
class_name FloatingText
## Bas ustunde ucusan hasar sayisi. `FloatingText.spawn(ebeveyn, konum, sonuc)`
## ile uretilir; 1 saniyede 50px yukselip solar, sonra kendini temizler.

const SCENE: PackedScene = preload("res://scenes/combat/FloatingText.tscn")

const BASE_SIZE := 18
const CRIT_SCALE := 1.4
const RISE_PX := 50.0
const LIFE := 1.0
const FADE_TAIL := 0.4

const COL_NORMAL := Color("#ffffff")
const COL_ADVANTAGE := Color("#ffb02e")
const COL_CRIT := Color("#ff4b4b")

@onready var label: Label = $Label

static func spawn(parent: Node, at: Vector2, result: DamageResult) -> FloatingText:
	var ft := SCENE.instantiate() as FloatingText
	parent.add_child(ft)
	ft.position = at
	ft.setup(result)
	return ft

## Serbest metin (ulti bandi, iyilesme): renk/boyut cagiran secer.
static func spawn_custom(parent: Node, at: Vector2, text: String, col: Color, size: int) -> FloatingText:
	var ft := SCENE.instantiate() as FloatingText
	parent.add_child(ft)
	ft.position = at
	ft.setup_custom(text, col, size)
	return ft

func setup(result: DamageResult) -> void:
	var col := COL_NORMAL
	var size := BASE_SIZE
	if result.is_advantage:
		col = COL_ADVANTAGE
	if result.is_crit:
		col = COL_CRIT
		size = int(float(BASE_SIZE) * CRIT_SCALE)
	setup_custom(str(int(result.amount)), col, size)

func setup_custom(text: String, col: Color, size: int) -> void:
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", col)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", position.y - RISE_PX, LIFE)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, FADE_TAIL).set_delay(LIFE - FADE_TAIL)
	tw.chain().tween_callback(queue_free)
