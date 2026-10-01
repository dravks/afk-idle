extends Node2D
## Dunya bossu deneme sahnesi: dizilim + ejderha + komutan + skor/kademe.
## Bagimsiz kip: kampanya/labirent durumuna dokunmaz (can tasmasi yok).

const BOSS_UNIT_SCENE: PackedScene = preload("res://scenes/combat/BossUnit.tscn")
const BOSS_DATA_PATH := "res://data/bosses/dragon.tres"
const BOSS_SPAWN := Vector2(350, 428)

var grid: BattleGrid
var boss_manager: BossCombatManager
var boss_hud: BossHUD
var result_ui: BossResultUI
var commander: CommanderManager
var commander_hud: CommanderHUD
var boss: BossUnit

var _ended := false

func _ready() -> void:
	_build()
	hud_setup()
	var overlay := UltimateOverlay.new()
	grid.add_child(overlay)
	commander.battle_root = grid
	for s in CommanderSpellbook.default_spells():
		commander.add_spell(s)
	GameFlowManager.commander_prog.apply_to_commander(commander)
	commander_hud.setup(commander)
	var players := GameFlowManager.spawn_player_formation(grid)
	boss = _spawn_boss()
	boss_manager.begin(boss, players, commander)
	boss_manager.boss_battle_ended.connect(_on_battle_ended)
	AudioManager.play_bgm("battle")
	print("BossBattleScene: %s (sv%d)" % [boss.boss_title, boss.level])

func hud_setup() -> void:
	boss_hud.setup(boss_manager, boss)

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#1c0f14")
	bg.position = Vector2.ZERO
	bg.size = Vector2(480, 856)
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var cam := CameraShake.new()
	cam.position = Vector2(480, 856) * 0.5
	cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	cam.add_to_group("battle_camera")
	add_child(cam)
	cam.make_current()
	grid = BattleGrid.new()
	add_child(grid)
	boss_manager = BossCombatManager.new()
	add_child(boss_manager)
	commander = CommanderManager.new()
	add_child(commander)
	boss_hud = BossHUD.new()
	add_child(boss_hud)
	commander_hud = CommanderHUD.new()
	add_child(commander_hud)
	result_ui = BossResultUI.new()
	add_child(result_ui)
	result_ui.lobby_requested.connect(GameFlowManager.go_lobby)

func _spawn_boss() -> BossUnit:
	var data := load(BOSS_DATA_PATH) as BossData
	var b := BOSS_UNIT_SCENE.instantiate() as BossUnit
	grid.add_child(b)
	b.position = BOSS_SPAWN
	b.setup_unit(data, _boss_level(), Unit.Team.ENEMY)
	return b

## Patron seviyesi = dizilimin ortalama efektif seviyesi (en az 1).
func _boss_level() -> int:
	var total := 0
	var n := 0
	for h in GameFlowManager.formation_hero_levels():
		total += h
		n += 1
	return maxi(1, int(round(float(total) / float(maxi(1, n)))))

func _on_battle_ended(final_damage: float, tier: String, rewards: Dictionary) -> void:
	_ended = true
	var best := float(PlayerProfile.boss_best_score)
	result_ui.display_result(final_damage, tier, rewards, best)
	print("BossBattleScene: %s (%s)" % [
		BossCombatManager.format_damage(final_damage), tier])
