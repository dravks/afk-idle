extends Node
class_name TargetingComponent
## AFK tarzi kural tabanli hedefleme. "units" grubundan canli dusmanlari
## toplar; oluler ve ayni takim filtrelenir. Olu hedefler DeadState'te
## gruptan cikarildigi icin otomatik elenir.

var current_target: Unit = null

@onready var unit: Unit = get_parent() as Unit

func acquire_target(
	rule: GlobalEnums.TargetRule = GlobalEnums.TargetRule.NEAREST_ENEMY
) -> Unit:
	var enemies: Array[Unit] = []
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or u == unit:
			continue
		if u.team == unit.team:
			continue
		if u.stats_component == null or u.stats_component.is_dead:
			continue
		enemies.append(u)
	if enemies.is_empty():
		current_target = null
		return null
	# Varsayilan: en yakin (diger kurallar asagida ezer).
	var selected: Unit = enemies[0]
	var best_d := unit.global_position.distance_to(selected.global_position)
	for u in enemies:
		var d := unit.global_position.distance_to(u.global_position)
		if d < best_d:
			best_d = d
			selected = u
	match rule:
		GlobalEnums.TargetRule.LOWEST_HP_PERCENT:
			var best_p := _hp_percent(selected)
			for u in enemies:
				var p := _hp_percent(u)
				if p < best_p:
					best_p = p
					selected = u
		GlobalEnums.TargetRule.HIGHEST_ATK:
			var best_a := selected.stats_component.atk
			for u in enemies:
				if u.stats_component.atk > best_a:
					best_a = u.stats_component.atk
					selected = u
		GlobalEnums.TargetRule.RANDOM_ENEMY:
			selected = enemies[randi() % enemies.size()]
		_:
			pass
	current_target = selected
	return selected

func is_target_valid() -> bool:
	if current_target == null or not is_instance_valid(current_target):
		current_target = null
		return false
	if not current_target.is_in_group("units"):
		current_target = null
		return false
	if current_target.stats_component == null or current_target.stats_component.is_dead:
		current_target = null
		return false
	return true

func is_target_in_range(range_distance: float) -> bool:
	if not is_target_valid():
		return false
	return unit.global_position.distance_to(current_target.global_position) <= range_distance

func _hp_percent(u: Unit) -> float:
	return u.stats_component.current_hp / maxf(1.0, u.stats_component.max_hp)
