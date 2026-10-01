extends State
class_name AttackState
## Saldiri dongusu: haste bazli ritim (1.2sn taban), vurusta yakin dovus
## dogrudan hasar + sayi + parilti, menzilli ise Projectile firlatir.
## Not: spec'teki `can_deal_damage` bayragi mantikta kullanilmadigi icin
## yazilmadi (olu degisken birakilmaz).

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/Projectile.tscn")
const RANGED_THRESHOLD := 200.0
const BASE_INTERVAL := 1.2

var attack_timer: float = 0.0
var _lunge_tween: Tween

func enter() -> void:
	unit.velocity = Vector2.ZERO
	attack_timer = 0.0
	unit.play_animation("idle")

func exit() -> void:
	if _lunge_tween != null and _lunge_tween.is_valid():
		_lunge_tween.kill()

func physics_update(delta: float) -> void:
	var targeting := unit.targeting_component
	if not targeting.is_target_valid():
		state_machine.change_state("Idle")
		return
	# 1) Ultimate her seyi bozar.
	if unit.stats_component.current_energy >= unit.stats_component.max_energy:
		state_machine.change_state("Ultimate")
		return
	# 2) Cooldown'u dolmus aktif yetenek.
	var ready := unit.get_ready_active_skill()
	if ready != null and targeting.is_target_in_range(maxf(unit.attack_range, ready.range)):
		if unit.try_enter_skill(ready):
			return
	# 3) Temel saldiri.
	if not targeting.is_target_in_range(unit.attack_range):
		state_machine.change_state("Move")
		return
	var interval := BASE_INTERVAL / (unit.stats_component.haste / 100.0)
	attack_timer += delta
	if attack_timer >= interval:
		attack_timer = 0.0
		execute_basic_attack()

func execute_basic_attack() -> void:
	var target := unit.targeting_component.current_target
	if target == null or not is_instance_valid(target):
		return
	_lunge(target)
	unit.play_animation("attack")
	var basic := unit.hero_data.basic_attack
	if basic != null:
		unit.stats_component.add_energy(basic.energy_generated)
	# Hasar vurus karesinde/bitiminde duser (animasyon bitimi beklenir).
	# Kare yoksa veya durum degistiyse hemen islet (yumusak dusus, kilit yok).
	if not unit.has_attack_anim():
		_deal_damage(target)
		return
	await unit.animated.animation_finished
	if state_machine.current_state != self:
		return
	if not unit.targeting_component.is_target_valid():
		return
	_deal_damage(unit.targeting_component.current_target)

func _deal_damage(target: Unit) -> void:
	if target == null or not is_instance_valid(target):
		return
	if unit.hero_data.attack_range > RANGED_THRESHOLD:
		var p := PROJECTILE_SCENE.instantiate() as Projectile
		unit.get_parent().add_child(p)
		p.launch(unit.global_position, target, unit, unit.hero_data.basic_attack)
	else:
		var res := target.stats_component.calculate_and_take_damage(
			unit.stats_component.atk,
			unit.hero_data.faction,
			unit.effective_crit(),
			unit.hero_data.crit_multiplier,
			unit.hero_data.damage_type,
			unit)
		FloatingText.spawn(
			target.get_parent(),
			target.position + Vector2(randf_range(-8.0, 8.0), -70.0),
			res)
		target.flash_hit()

## Vurup geri cekilme mikro animasyonu (hedef hareket ederse exit'te iptal).
func _lunge(target: Unit) -> void:
	if _lunge_tween != null and _lunge_tween.is_valid():
		_lunge_tween.kill()
	var dir := (target.global_position - unit.global_position).normalized()
	var start := unit.position
	_lunge_tween = create_tween()
	_lunge_tween.tween_property(unit, "position", start + dir * 12.0, 0.07)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_lunge_tween.tween_property(unit, "position", start, 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
