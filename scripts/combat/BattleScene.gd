extends Node2D
## Savas sahnesi: kadro (FormationUI) + bolum (StageData) GameFlowManager'dan
## gelir. Komutan buyuleri (Meteor / Kutsal Kalkan / Sifa Halesi) alt barda.
## F5 = lobi acilir; dogrudan bu sahne acilirsa mevcut bolum oynanir.

var grid: BattleGrid
var manager: CombatManager
var hud: CombatHUD
var result_ui: BattleResultUI
var commander: CommanderManager
var commander_hud: CommanderHUD

var _battle_time := 0.0
var _ended := false

func _ready() -> void:
	_build()
	hud.setup(manager)
	var overlay := UltimateOverlay.new()
	grid.add_child(overlay)  # perde savas canvas'inin icinde olmali
	commander.battle_root = grid
	for s in CommanderSpellbook.default_spells():
		commander.add_spell(s)
	GameFlowManager.commander_prog.apply_to_commander(commander)
	commander_hud.setup(commander)
	manager.commander_manager = commander
	manager.battle_ended.connect(_on_battle_ended)
	hud.auto_stop_requested.connect(_on_auto_stop)
	GameFlowManager.setup_battle(grid, manager, result_ui)
	AudioManager.play_bgm("battle")
	hud.stop_button.visible = GameFlowManager.tower_mode \
		and GameFlowManager.tower.is_auto_climb_active
	print("BattleScene: bolum %s savasi" % GameFlowManager.get_current_stage().stage_id)

func _process(delta: float) -> void:
	if not _ended and manager.current_state == CombatManager.BattleState.IN_PROGRESS:
		_battle_time += delta

func _build() -> void:
	var bg := ColorRect.new()
	# Kule elit katinda kirmizi atmosfer, normal kulede mor zemin.
	if GameFlowManager.tower_mode and GameFlowManager.tower.is_elite_floor(GameFlowManager.tower.current_floor):
		bg.color = Color("#2a0f14")
	elif GameFlowManager.tower_mode:
		bg.color = Color("#141428")
	else:
		bg.color = Color("#150f1f")
	bg.position = Vector2.ZERO
	bg.size = Vector2(480, 856)
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # tiklar arenaya (buyu hedefi) gecsin
	add_child(bg)
	var cam := CameraShake.new()
	cam.position = Vector2(480, 856) * 0.5
	cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	cam.add_to_group("battle_camera")
	add_child(cam)
	cam.make_current()
	grid = BattleGrid.new()
	add_child(grid)
	manager = CombatManager.new()
	add_child(manager)
	commander = CommanderManager.new()
	add_child(commander)
	hud = CombatHUD.new()
	add_child(hud)
	commander_hud = CommanderHUD.new()
	add_child(commander_hud)
	result_ui = BattleResultUI.new()
	add_child(result_ui)

func _on_battle_ended(is_victory: bool, _tracker: CombatTracker) -> void:
	_ended = true
	print("BattleScene: %s (%.1fs)" % ["VICTORY" if is_victory else "DEFEAT", _battle_time])
	# Otomatik tirmanis: zaferde 1.2sn geri sayim, sonra sonraki kat (sahne yeniden yuklenir).
	if is_victory and GameFlowManager.tower_mode and GameFlowManager.tower.is_auto_climb_active:
		result_ui.show_countdown("Sonraki Kat Yükleniyor...")
		_auto_advance()

func _on_auto_stop() -> void:
	GameFlowManager.tower.set_auto_climb_active(false)
	hud.stop_button.visible = false

func _auto_advance() -> void:
	await get_tree().create_timer(1.2).timeout
	if _ended and GameFlowManager.tower_mode \
			and GameFlowManager.tower.is_auto_climb_active \
			and get_tree().current_scene == self \
			and is_instance_valid(result_ui) and result_ui.visible:
		GameFlowManager.next_tower_battle()
