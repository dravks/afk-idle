extends Node
## Sahne akisi + bolum yukleme + kayit birlestirme (autoload, en sonda hazir
## olur; tum autoload'lar ayaktayken kaydi dagitir).

const STAGE_FILES: Array[String] = [
	"res://data/stages/stage_1_1.tres",
	"res://data/stages/stage_1_2.tres",
	"res://data/stages/stage_1_3.tres",
]
const LOBBY_SCENE := "res://scenes/ui/LobbyUI.tscn"
const FORMATION_SCENE := "res://scenes/ui/FormationUI.tscn"
const BATTLE_SCENE := "res://scenes/combat/BattleScene.tscn"
const CRYSTAL_SCENE := "res://scenes/ui/ResonatingCrystalUI.tscn"
const TAVERN_SCENE := "res://scenes/ui/TavernUI.tscn"
const SHOP_SCENE := "res://scenes/ui/ShopUI.tscn"
const TEMPLE_SCENE := "res://scenes/ui/TempleUI.tscn"
const MAP_SCENE := "res://scenes/ui/LabyrinthMapUI.tscn"
const ARENA_LOBBY_SCENE := "res://scenes/ui/ArenaLobbyUI.tscn"
const BOSS_SCENE := "res://scenes/combat/BossBattleScene.tscn"
const BOSS_LOBBY_SCENE := "res://scenes/ui/BossLobbyUI.tscn"
const TOWER_LOBBY_SCENE := "res://scenes/ui/TowerLobbyUI.tscn"
const QUEST_SCENE := "res://scenes/ui/QuestUI.tscn"
const TALENT_SCENE := "res://scenes/ui/CommanderTalentUI.tscn"
const SETTINGS_SCENE := "res://scenes/ui/SettingsUI.tscn"

var saver: SaveManager
var campaign: CampaignManager
var quests: QuestManager
var _last_victory := false
var _result_ui: BattleResultUI
var _last_drop_text := ""
## Labirent kipi: acikken savas kampanya yerine kosu verisiyle kurulur.
var labyrinth_mode := false
var pending_labyrinth_index := 0
## Arena kipi: acikken dusmanlar rakip diziliminden gelir, sonuc puan isler.
var arena_mode := false
var pending_arena_opponent: ArenaOpponentData
## Dizilim ekrani baglami: true ise savunma duzenlenir (savas butonu gizli,
## geri donus arena lobisine). Gidisten once kurulur (sahne tasiyamaz).
var formation_defense_mode := false
var arena: ArenaManager
var commander_prog: CommanderProgression
var tower: TowerManager
## Kule kipi: acikken dusmanlar kat verisinden gelir, sonuc kata isler.
var tower_mode := false
var _last_manager: CombatManager

func _ready() -> void:
	saver = SaveManager.new()
	add_child(saver)
	campaign = CampaignManager.new()
	add_child(campaign)
	quests = QuestManager.new()
	add_child(quests)
	arena = ArenaManager.new()
	add_child(arena)
	commander_prog = CommanderProgression.new()
	add_child(commander_prog)
	tower = TowerManager.new()
	add_child(tower)
	if saver.has_save():
		var data := saver.load_game()
		PlayerProfile.apply_save_data(data)
		AFKManager.apply_save_data(data)
		ResonatingCrystalManager.apply_save_data(data, PlayerProfile.owned_heroes)
		quests.apply_save_data(data)
		commander_prog.apply_save_data(data)
		AudioManager.set_bus_volume("Master", 0.0 if PlayerProfile.muted else 1.0)
	arena.sync_from_profile()
	tower.current_floor = maxi(1, PlayerProfile.tower_floor)
	# Seviye tek kaynagi kristal: kayitta olmayan kahraman sv1'den baslar.
	for h in PlayerProfile.owned_heroes:
		if not ResonatingCrystalManager.hero_levels.has(h.id):
			ResonatingCrystalManager.add_hero(h, 1)

func stage_count() -> int:
	return STAGE_FILES.size()

func get_stage(index: int) -> StageData:
	if index >= 1 and index <= STAGE_FILES.size():
		var st := load(STAGE_FILES[index - 1]) as StageData
		if st != null:
			return st
	return campaign.get_stage_data(maxi(1, index))

func get_current_stage() -> StageData:
	return get_stage(PlayerProfile.current_stage_index)

func go_lobby() -> void:
	get_tree().change_scene_to_file(LOBBY_SCENE)

func go_formation() -> void:
	get_tree().change_scene_to_file(FORMATION_SCENE)

func go_battle() -> void:
	labyrinth_mode = false
	arena_mode = false
	tower_mode = false
	pending_arena_opponent = null
	get_tree().change_scene_to_file(BATTLE_SCENE)

func go_map() -> void:
	get_tree().change_scene_to_file(MAP_SCENE)

## Haritadan labirent savasina: dusmanlar kosudan, canlar tasinir.
## (go_battle cagrilmaz: o kampanya kipine sifirlar.)
func start_labyrinth_battle(node_index: int) -> void:
	pending_labyrinth_index = node_index
	pending_arena_opponent = null
	labyrinth_mode = true
	arena_mode = false
	tower_mode = false
	get_tree().change_scene_to_file(BATTLE_SCENE)

## Arena savasina: rakip kilitlenir, kip acilir (tekrar ayni rakibe doner).
func start_arena_battle(opponent: ArenaOpponentData) -> void:
	pending_arena_opponent = opponent
	pending_labyrinth_index = 0
	arena_mode = true
	labyrinth_mode = false
	tower_mode = false
	get_tree().change_scene_to_file(BATTLE_SCENE)

func go_tower() -> void:
	get_tree().change_scene_to_file(TOWER_LOBBY_SCENE)

## Kule savasina: mevcut kat (zaferde process_victory artirir).
func start_tower_battle() -> void:
	pending_arena_opponent = null
	pending_labyrinth_index = 0
	tower_mode = true
	arena_mode = false
	labyrinth_mode = false
	get_tree().change_scene_to_file(BATTLE_SCENE)

func next_tower_battle() -> void:
	start_tower_battle()

## Ayni kipi bastan baslatir (kampanya/labirent tekrari duzeltir:
## eskiden retry hep kampanyaya dusuyordu). Arenada bilet ister.
func retry_battle() -> void:
	if arena_mode:
		if int(PlayerProfile.arena_tickets) > 0:
			PlayerProfile.arena_tickets -= 1
			arena.free_tickets = maxi(0, int(PlayerProfile.arena_tickets))
			save_all()
			get_tree().change_scene_to_file(BATTLE_SCENE)
		else:
			go_arena_lobby()
		return
	if labyrinth_mode:
		get_tree().change_scene_to_file(BATTLE_SCENE)
		return
	if tower_mode:
		get_tree().change_scene_to_file(BATTLE_SCENE)
		return
	go_battle()

func go_crystal() -> void:
	get_tree().change_scene_to_file(CRYSTAL_SCENE)

func go_tavern() -> void:
	get_tree().change_scene_to_file(TAVERN_SCENE)

func go_shop() -> void:
	get_tree().change_scene_to_file(SHOP_SCENE)

func go_temple() -> void:
	get_tree().change_scene_to_file(TEMPLE_SCENE)

func go_boss() -> void:
	get_tree().change_scene_to_file(BOSS_SCENE)

func go_boss_lobby() -> void:
	get_tree().change_scene_to_file(BOSS_LOBBY_SCENE)

func go_quests() -> void:
	get_tree().change_scene_to_file(QUEST_SCENE)

func go_commander() -> void:
	get_tree().change_scene_to_file(TALENT_SCENE)

func go_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)

func go_arena_lobby() -> void:
	get_tree().change_scene_to_file(ARENA_LOBBY_SCENE)

## Tum dilimleri tek dosyada birlestirir. Dukkan dilimi ShopUI'dan acikca
## verilir (dukkan yoneticisi sahneye bagli yasar, autoload degil).
func save_all(shop: ShopManager = null) -> void:
	var data := PlayerProfile.get_save_data()
	var afk := AFKManager.get_save_data()
	for key in afk.keys():
		if str(key) == "gold":
			continue
		data[key] = afk[key]
	var cry := ResonatingCrystalManager.get_save_data()
	for key in cry.keys():
		data[key] = cry[key]
	var run := LabyrinthRun.get_save_data()
	for key in run.keys():
		data[key] = run[key]
	var qst := quests.get_save_data()
	for key in qst.keys():
		data[key] = qst[key]
	var cmd := commander_prog.get_save_data()
	for key in cmd.keys():
		data[key] = cmd[key]
	if shop != null:
		var shop_data := shop.get_save_data()
		for key in shop_data.keys():
			data[key] = shop_data[key]
	saver.save_game(data)

## Savas sahnesi _ready'den cagrilir: dizilim + dusman + baglanti + baslat.
func setup_battle(grid: BattleGrid, manager: CombatManager, result_ui: BattleResultUI) -> void:
	_result_ui = result_ui
	_last_manager = manager
	grid.clear_units()
	_spawn_formation(grid)
	if tower_mode:
		_spawn_tower_enemies(grid)
		manager.relic_manager = null
		manager.battle_stage_index = 0
	elif arena_mode:
		_spawn_arena_enemies(grid)
		manager.relic_manager = null
		manager.battle_stage_index = 0
	elif labyrinth_mode:
		_spawn_labyrinth_enemies(grid)
		manager.relic_manager = LabyrinthRun.relics
		manager.battle_stage_index = -1
	else:
		_spawn_stage_enemies(grid)
		manager.relic_manager = null
		manager.battle_stage_index = PlayerProfile.current_stage_index
	result_ui.retry_requested.connect(retry_battle)
	result_ui.next_requested.connect(_on_next_pressed)
	result_ui.lobby_requested.connect(go_lobby)
	manager.battle_ended.connect(_on_battle_ended)
	manager.battle_ended.connect(result_ui.display_result)
	manager.start_battle()
	# Birimler start_battle'da toplanir; canlar ondan sonra uygulanir.
	if labyrinth_mode:
		LabyrinthRun.apply_states_to_spawned_units(manager.player_units)

func _spawn_formation(grid: BattleGrid) -> void:
	spawn_player_formation(grid)

## Dizilimi kurup birimleri dondurur (boss sahnesi de kullanir).
func spawn_player_formation(grid: BattleGrid) -> Array[Unit]:
	var out: Array[Unit] = []
	var f := PlayerProfile.current_formation
	for args in [
		[f.get("FRONT_TOP"), true, 0], [f.get("FRONT_BOT"), true, 1],
		[f.get("BACK_TOP"), false, 0], [f.get("BACK_MID"), false, 1],
		[f.get("BACK_BOT"), false, 2]]:
		var u := _spawn_slot(grid, args[0] as HeroData, bool(args[1]), int(args[2]))
		if u != null:
			out.append(u)
	return out

## Dizilimdeki kahramanlarin efektif seviyeleri (boss seviyesi icin).
func formation_hero_levels() -> Array[int]:
	var out: Array[int] = []
	for key in PlayerProfile.SLOT_KEYS:
		var h := PlayerProfile.current_formation.get(key) as HeroData
		if h != null:
			out.append(ResonatingCrystalManager.get_effective_level(h.id))
	return out

func _spawn_slot(grid: BattleGrid, hero: HeroData, frontline: bool, index: int) -> Unit:
	if hero == null:
		return null
	# Efektif seviye: kristal yuvasi + barajlar dahil (tek kaynak kristal).
	var lv := ResonatingCrystalManager.get_effective_level(hero.id)
	var unit := grid.spawn_hero(hero, lv, Unit.Team.PLAYER, frontline, index)
	_apply_gear_to_unit(unit, hero.id)
	return unit

## Profildeki kusakli esyalari savas-anlik bilesene isle (test edilebilir).
func _apply_gear_to_unit(unit: Unit, hero_id: String) -> void:
	if unit == null or unit.equipment_component == null:
		return
	var worn: Dictionary = PlayerProfile.gear_map_for(hero_id)
	for key in worn.keys():
		var g := worn[key] as EquipmentData
		if g != null:
			unit.equipment_component.equip_item(g)

func _spawn_stage_enemies(grid: BattleGrid) -> void:
	var st := get_current_stage()
	if st == null:
		return
	var lv := st.enemy_team_level
	_spawn_enemy(grid, st.enemy_front_top, true, 0, lv)
	_spawn_enemy(grid, st.enemy_front_bot, true, 1, lv)
	_spawn_enemy(grid, st.enemy_back_top, false, 0, lv)
	_spawn_enemy(grid, st.enemy_back_mid, false, 1, lv)
	_spawn_enemy(grid, st.enemy_back_bot, false, 2, lv)

func _spawn_arena_enemies(grid: BattleGrid) -> void:
	var opp: ArenaOpponentData = pending_arena_opponent
	if opp == null:
		return
	var f: Dictionary = opp.formation
	_spawn_foe(grid, f.get("FRONT_TOP"), true, 0)
	_spawn_foe(grid, f.get("FRONT_BOT"), true, 1)
	_spawn_foe(grid, f.get("BACK_TOP"), false, 0)
	_spawn_foe(grid, f.get("BACK_MID"), false, 1)
	_spawn_foe(grid, f.get("BACK_BOT"), false, 2)

func _spawn_tower_enemies(grid: BattleGrid) -> void:
	var st := tower.get_floor_stage_data(tower.current_floor)
	_spawn_foe(grid, {"hero_data": st.enemy_front_top, "level": st.enemy_team_level}, true, 0)
	_spawn_foe(grid, {"hero_data": st.enemy_front_bot, "level": st.enemy_team_level}, true, 1)
	_spawn_foe(grid, {"hero_data": st.enemy_back_top, "level": st.enemy_team_level}, false, 0)
	_spawn_foe(grid, {"hero_data": st.enemy_back_mid, "level": st.enemy_team_level}, false, 1)
	_spawn_foe(grid, {"hero_data": st.enemy_back_bot, "level": st.enemy_team_level}, false, 2)

func _spawn_foe(grid: BattleGrid, entry, frontline: bool, index: int) -> void:
	if entry == null:
		return
	var d: Dictionary = entry
	var h := d.get("hero_data") as HeroData
	if h == null:
		return
	grid.spawn_hero(h, maxi(1, int(d.get("level", 1))), Unit.Team.ENEMY, frontline, index)

func _spawn_labyrinth_enemies(grid: BattleGrid) -> void:
	var comp: Array = LabyrinthRun.get_node_enemies(
		LabyrinthRun.current_floor, pending_labyrinth_index)
	var front_i := 0
	var back_i := 0
	for entry in comp:
		var d: Dictionary = entry
		var h := d.get("hero") as HeroData
		var lv := int(d.get("level", 1))
		if h == null:
			continue
		# On sira dolar, sonra arka sira (3 kisi kapasiteli duzen).
		if front_i < 2:
			grid.spawn_hero(h, lv, Unit.Team.ENEMY, true, front_i)
			front_i += 1
		else:
			grid.spawn_hero(h, lv, Unit.Team.ENEMY, false, mini(back_i, 2))
			back_i += 1

func _spawn_enemy(grid: BattleGrid, hero: HeroData, frontline: bool, index: int, level: int) -> void:
	if hero != null:
		grid.spawn_hero(hero, level, Unit.Team.ENEMY, frontline, index)

func _on_battle_ended(is_victory: bool, _tracker: CombatTracker) -> void:
	_last_victory = is_victory
	# Kule: odul + kat ilerleme; yenilgide otomatik durur (sahne sayaci okur).
	if tower_mode:
		if is_victory:
			tower.process_victory(PlayerProfile)
			commander_prog.add_exp(30)
		else:
			tower.set_auto_climb_active(false)
		save_all()
		return
	# Arena: puan isle, mod dugumlerinden bagimsiz kapat.
	if arena_mode:
		if pending_arena_opponent != null:
			arena.process_battle_result(is_victory, pending_arena_opponent)
		save_all()
		return
	# Labirent: canlari yaz, dugumu kapat, kampanya odulu/ilerlemesi YOK.
	if labyrinth_mode:
		if _last_manager != null and is_instance_valid(_last_manager):
			LabyrinthRun.save_battle_end_states(_last_manager.player_units)
		LabyrinthRun.complete_node(pending_labyrinth_index)
		if is_victory:
			QuestEvents.labyrinth_battle_won.emit()
			commander_prog.add_exp(30)
		save_all()
		return
	if not is_victory:
		return
	commander_prog.add_exp(30)
	var idx := PlayerProfile.current_stage_index
	var st := get_stage(idx)
	if st == null:
		return
	# Zafer ganimeti: bolumle olceklenen 1 esya her zaman duser.
	var drop := PlayerProfile.make_gear(idx % 4, 5.0 + float(idx) * 2.0)
	_last_drop_text = "+%s dustu!" % drop.item_name
	if _result_ui != null and is_instance_valid(_result_ui):
		_result_ui.set_reward_line(_last_drop_text)
	if not (idx in PlayerProfile.cleared_stages):
		PlayerProfile.cleared_stages.append(idx)
		PlayerProfile.gold += st.first_clear_gold
		PlayerProfile.diamonds += st.first_clear_diamonds
	save_all()

func _on_next_pressed() -> void:
	# Kulede Next her zaman kule lobisine doner (otomatik zincir sahnededir).
	if tower_mode:
		go_tower()
		return
	# Arena zaferi/yenilgisi: arena lobisine don (kampanya ilerlemez).
	if arena_mode:
		go_arena_lobby()
		return
	# Labirent zaferi: once kalinti secimi, sonra harita. Yenilgi: harita.
	if labyrinth_mode:
		if _last_victory:
			_show_relic_reward()
		else:
			go_map()
		return
	# Kampanya sonsuz (1-4+ dinamik uretilir): zaferde sinir yok.
	if _last_victory:
		PlayerProfile.current_stage_index += 1
		save_all()
		go_battle()
	else:
		go_lobby()

func _show_relic_reward() -> void:
	var ui := RelicRewardUI.new()
	get_tree().current_scene.add_child(ui)
	ui.setup(LabyrinthRun.relics.roll_choices(3), _on_relic_picked)

func _on_relic_picked(relic: RelicData) -> void:
	LabyrinthRun.relics.add_relic(relic)
	save_all()
	go_map()
