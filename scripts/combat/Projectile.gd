extends Area2D
class_name Projectile
## Menzilli temel saldiri fuzesi. Hedefe ucar, carpinca hasari isletip
## sayi + parilti uretir. Hedef olurse/:none olursa havada soner.

var target: Unit
var attacker: Unit
var skill_data: SkillData
var speed: float = 800.0

const HIT_DISTANCE := 15.0

func _ready() -> void:
	add_to_group("projectiles")

func launch(
	from: Vector2,
	to_target: Unit,
	from_attacker: Unit,
	skill: SkillData
) -> void:
	global_position = from
	target = to_target
	attacker = from_attacker
	skill_data = skill

func _physics_process(delta: float) -> void:
	if attacker == null or not is_instance_valid(attacker):
		queue_free()
		return
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	if target.stats_component == null or target.stats_component.is_dead:
		queue_free()
		return
	global_position = global_position.move_toward(target.global_position, speed * delta)
	if global_position.distance_to(target.global_position) < HIT_DISTANCE:
		_impact()

func _impact() -> void:
	var dmg_type: GlobalEnums.DamageType = attacker.hero_data.damage_type
	if skill_data != null:
		dmg_type = skill_data.damage_type
	var res := target.stats_component.calculate_and_take_damage(
		attacker.stats_component.atk,
		attacker.hero_data.faction,
		attacker.effective_crit(),
		attacker.hero_data.crit_multiplier,
		dmg_type,
		attacker)
	FloatingText.spawn(target.get_parent(), target.position + Vector2(randf_range(-8.0, 8.0), -70.0), res)
	target.flash_hit()
	queue_free()
