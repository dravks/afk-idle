extends Node
class_name UltimateOverlay
## Ulti sinematik perdesi. Savas kokune (BattleGrid) cocuk olarak eklenir;
## `UltimateOverlay.active` uzerinden erisilir (autoload yok).
##
## NOT: Spec CanvasLayer diyordu; CanvasLayer'da caster'in z_index'i perdeyi
## delemezdi (katman tum canvas'in ustunde kalir, caster alta gomulurdu).
## Bu yuzden perde savas canvas'inin ICINDE (z 90), caster z 100 ile onde.

static var active: UltimateOverlay

const DIM_Z := 90
const CASTER_Z := 100
const DIM_COLOR := Color(0, 0, 0, 0.65)

var _dim: ColorRect
var _caster: Unit
var _orig_z: int = 0
var _tween: Tween

func _ready() -> void:
	active = self
	_dim = ColorRect.new()
	_dim.color = DIM_COLOR
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.z_index = DIM_Z
	_dim.visible = false
	_dim.modulate.a = 0.0
	add_child(_dim)

func _exit_tree() -> void:
	if active == self:
		active = null

## Odaklanma sinematigi: perde acilir, caster one cikar + buyur, sure sonu
## perde solar ve caster eski haline doner. Overlay yoksa hicbir sey olmaz
## (UltimateState efekti yine de isletir).
func play_cinematic_focus(caster: Unit, duration: float = 0.6) -> void:
	if caster == null or not is_instance_valid(caster):
		return
	_restore_caster()
	_kill_tween()
	_caster = caster
	_dim.size = get_viewport().get_visible_rect().size
	_dim.position = Vector2.ZERO
	_dim.visible = true
	_orig_z = caster.z_index
	caster.z_index = CASTER_Z
	caster.flash_hit()
	caster.visual.pivot_offset = caster.visual.size * 0.5
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_dim, "modulate:a", DIM_COLOR.a, 0.15)
	_tween.tween_property(caster.visual, "scale", Vector2(1.1, 1.1), 0.2)
	_tween.chain().tween_interval(duration)
	_tween.chain().tween_property(_dim, "modulate:a", 0.0, 0.25)
	_tween.chain().tween_callback(_finish)

## Prompt 6 (CombatManager) ve testler icin durum sorgusu.
func is_focus_active() -> bool:
	return _dim != null and _dim.visible

func _finish() -> void:
	_restore_caster()
	if _dim != null:
		_dim.visible = false

func _restore_caster() -> void:
	if _caster != null and is_instance_valid(_caster):
		_caster.z_index = _orig_z
		_caster.visual.scale = Vector2.ONE
	_caster = null

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
