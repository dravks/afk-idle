extends Node
class_name CombatManager
## Savasi hakemi: sure, hiz, zafer/yenilgi, istatistik toplama.
## Kullanim sozlesmesi: birimler uretilir uretilmez AYNI karede start_battle()
## cagrilir (baglantilar savas oncesi kurulur, erken hasar kacmaz).

enum BattleState { PRE_BATTLE, IN_PROGRESS, VICTORY, DEFEAT }

const MATCH_TIME := 90.0

signal battle_started
signal battle_ended(is_victory: bool, stats: CombatTracker)
signal time_updated(seconds_remaining: float)

var current_state: BattleState = BattleState.PRE_BATTLE
var match_time_remaining: float = MATCH_TIME
var tracker: CombatTracker = CombatTracker.new()
var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
## Komutan buyuleri koprusu (BattleScene atar; bossa da ayni sahne).
var commander_manager: CommanderManager
## Labirent kalintilari koprusu (sadece labirent savasinda dolar).
var relic_manager: RelicManager
## Kampanya bolum indeksi (Flow atar). Labirentte -1: kampanya sayilmaz.
var battle_stage_index: int = 0

func start_battle() -> void:
	# Kayit defteri SIFIRLANMAZ, degerler sifirlanir: baglanti tekligi
	# (register) cift start'ta korunur, olen birimler purge ile atilir.
	tracker.purge_invalid()
	for key in tracker.stats.keys():
		tracker.stats[key] = {"damage_dealt": 0.0, "damage_taken": 0.0, "healing_done": 0.0}
	player_units.clear()
	enemy_units.clear()
	match_time_remaining = MATCH_TIME
	Engine.time_scale = 1.0
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not is_instance_valid(u):
			continue
		if u.stats_component == null or u.stats_component.is_dead:
			continue
		u.set_frozen(false)
		if u.team == Unit.Team.PLAYER:
			player_units.append(u)
		else:
			enemy_units.append(u)
		if tracker.register(u):
			u.stats_component.damaged.connect(_on_unit_damaged.bind(u))
			u.stats_component.healed.connect(_on_unit_healed.bind(u))
			u.stats_component.died.connect(_on_unit_died.bind(u))
	if relic_manager != null:
		relic_manager.apply_combat_start_effects(player_units, commander_manager)
	_apply_aura_synergy()
	_deploy_assassins()
	current_state = BattleState.IN_PROGRESS
	if commander_manager != null:
		commander_manager.set_process(true)
	battle_started.emit()

## Suikastcilar yurumez: en zayif arka hat dusmaninin arkasina isinlanir ve kilitlenir.
func _deploy_assassins() -> void:
	for u in player_units + enemy_units:
		if not is_instance_valid(u):
			continue
		if u.hero_data == null or not u.hero_data.is_assassin_jumper:
			continue
		var target := _assassin_target(u)
		if target == null:
			continue
		var dir := signf(target.global_position.x - u.global_position.x)
		if dir == 0.0:
			dir = 1.0 if u.team == Unit.Team.PLAYER else -1.0
		u.global_position = target.global_position + Vector2(40.0 * dir, 0)
		u.targeting_component.current_target = target
		u.animated.flip_h = target.global_position.x < u.global_position.x
		var shade := ColorRect.new()
		shade.color = Color(0, 0, 0, 0.5)
		shade.size = Vector2(36, 12)
		shade.position = u.position + Vector2(-18, 28)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		u.get_parent().add_child(shade)
		var tw := u.create_tween()
		tw.tween_property(shade, "modulate:a", 0.0, 0.4)
		tw.tween_callback(shade.queue_free)

## En zayif arka hat dusmani (can yuzdesi en dusuk; arka = kendi tarafinin ucu).
func _assassin_target(assassin: Unit) -> Unit:
	var foes: Array[Unit] = []
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or u == assassin or u.team == assassin.team:
			continue
		if u.stats_component == null or u.stats_component.is_dead:
			continue
		foes.append(u)
	if foes.is_empty():
		return null
	var edge := -INF
	if assassin.team == Unit.Team.PLAYER:
		for u in foes:
			edge = maxf(edge, u.global_position.x)
	else:
		edge = INF
		for u in foes:
			edge = minf(edge, u.global_position.x)
	var best: Unit = null
	var best_hp := INF
	for u in foes:
		var d := absf(u.global_position.x - edge)
		if d > 60.0:
			continue
		var pct := u.stats_component.current_hp / maxf(1.0, u.stats_component.max_hp)
		if pct < best_hp:
			best_hp = pct
			best = u
	if best != null:
		return best
	for u in foes:
		var pct := u.stats_component.current_hp / maxf(1.0, u.stats_component.max_hp)
		if pct < best_hp:
			best_hp = pct
			best = u
	return best

func _process(delta: float) -> void:
	if current_state != BattleState.IN_PROGRESS:
		return
	match_time_remaining -= delta
	time_updated.emit(match_time_remaining)
	if match_time_remaining <= 0.0:
		end_battle(false)

## Fraksiyon aurasi: dizilime gore oyuncu statlarina carpan + kritik.
func _apply_aura_synergy() -> void:
	var heroes: Array[HeroData] = []
	for u in player_units:
		if is_instance_valid(u) and u.hero_data != null:
			heroes.append(u.hero_data)
	if heroes.is_empty():
		return
	var syn := FactionSynergyCalculator.calculate_synergy(heroes)
	for u in player_units:
		if not is_instance_valid(u) or u.stats_component == null:
			continue
		var st := u.stats_component
		st.max_hp *= float(syn["hp_mult"])
		st.current_hp = st.max_hp
		st.atk *= float(syn["atk_mult"])
		st.def *= float(syn["def_mult"])
		u.crit_bonus = float(syn["crit_add"])
		st.hp_changed.emit(st.current_hp, st.max_hp)

func _on_unit_damaged(amount: float, attacker: Unit, defender: Unit) -> void:
	tracker.record_damage_dealt(attacker, amount)
	tracker.record_damage_taken(defender, amount)

func _on_unit_healed(amount: float, healer: Unit, _target: Unit) -> void:
	tracker.record_healing_done(healer, amount)

func _on_unit_died(dead: Unit) -> void:
	# Oldurme odulu: sadece DUSMAN olumu komutana mana verir.
	if dead != null and is_instance_valid(dead) and dead.team == Unit.Team.ENEMY \
			and commander_manager != null:
		commander_manager.add_mana(CommanderManager.KILL_MANA)
	if current_state != BattleState.IN_PROGRESS:
		return
	var players_alive := false
	for u in player_units:
		if is_instance_valid(u) and not u.stats_component.is_dead:
			players_alive = true
			break
	var enemies_alive := false
	for u in enemy_units:
		if is_instance_valid(u) and not u.stats_component.is_dead:
			enemies_alive = true
			break
	if not players_alive:
		end_battle(false)  # karsilikli kiyimda yenilgi oncelikli
	elif not enemies_alive:
		end_battle(true)

func end_battle(is_victory: bool) -> void:
	if current_state == BattleState.VICTORY or current_state == BattleState.DEFEAT:
		return
	current_state = BattleState.VICTORY if is_victory else BattleState.DEFEAT
	Engine.time_scale = 1.0
	AudioManager.play_sfx("victory" if is_victory else "defeat")
	if commander_manager != null:
		commander_manager.set_process(false)
	for u in player_units + enemy_units:
		if is_instance_valid(u):
			(u as Unit).set_frozen(true)
	for node in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(node):
			node.set_physics_process(false)
	if is_victory and battle_stage_index > 0:
		QuestEvents.campaign_won.emit(battle_stage_index)
	battle_ended.emit(is_victory, tracker)

func toggle_battle_speed() -> float:
	Engine.time_scale = 2.0 if Engine.time_scale < 2.0 else 1.0
	return Engine.time_scale

## Takim cani orani 0..1 (HUD barlari). Birim yoksa 0.
func get_team_hp_ratio(team: Unit.Team) -> float:
	var cur := 0.0
	var max := 0.0
	var units := player_units if team == Unit.Team.PLAYER else enemy_units
	for u in units:
		if not is_instance_valid(u) or u.stats_component == null:
			continue
		cur += u.stats_component.current_hp
		max += u.stats_component.max_hp
	if max <= 0.0:
		return 0.0
	return clampf(cur / max, 0.0, 1.0)
