extends Control
class_name LobbyUI
## Ana lobi: bolum + cuzdan + AFK sandigi + savas girisi.
## AFK odulu PlayerProfile cuzdanina aktarilir (tek cuzdan disiplini).

var stage_label: Label
var wallet_label: Label
var battle_button: Button
var crystal_button: Button
var tavern_button: Button
var shop_button: Button
var temple_button: Button
var labyrinth_button: Button
var boss_button: Button
var quest_button: Button
var quest_badge: ColorRect
var arena_button: Button
var tower_button: Button
var commander_button: Button
var settings_button: Button
var chest: AFKChestUI

func _ready() -> void:
	_build()
	chest.setup(AFKManager)
	AFKManager.rewards_claimed.connect(_on_afk_claimed)
	AudioManager.play_bgm("lobby")
	refresh()

func _on_settings_pressed() -> void:
	GameFlowManager.go_settings()

func _on_nav_click() -> void:
	AudioManager.play_sfx("btn_click")

func refresh() -> void:
	var st := GameFlowManager.get_current_stage()
	stage_label.text = "Bölüm %s" % st.stage_id
	wallet_label.text = "%d Altin · %d Elmas" % [PlayerProfile.gold, PlayerProfile.diamonds]
	_update_badge()

func _on_afk_claimed(gold: int, _exp: int, _dust: int) -> void:
	PlayerProfile.gold += gold
	# Cuzdan tek: yonetici bakiyesi bosaltilir (exp/dust ilerideki sistemlere).
	AFKManager.gold = 0
	GameFlowManager.save_all()
	refresh()

func _on_battle_pressed() -> void:
	GameFlowManager.formation_defense_mode = false
	GameFlowManager.go_formation()

func _on_crystal_pressed() -> void:
	GameFlowManager.go_crystal()

func _on_tavern_pressed() -> void:
	GameFlowManager.go_tavern()

func _on_shop_pressed() -> void:
	GameFlowManager.go_shop()

func _on_temple_pressed() -> void:
	GameFlowManager.go_temple()

func _on_labyrinth_pressed() -> void:
	GameFlowManager.go_map()

func _on_boss_pressed() -> void:
	GameFlowManager.go_boss_lobby()

func _on_quest_pressed() -> void:
	GameFlowManager.go_quests()

func _on_arena_pressed() -> void:
	GameFlowManager.formation_defense_mode = false
	GameFlowManager.go_arena_lobby()

func _on_tower_pressed() -> void:
	GameFlowManager.go_tower()

func _on_commander_pressed() -> void:
	GameFlowManager.go_commander()

func _update_badge(_has: bool = false) -> void:
	if quest_badge != null and is_instance_valid(quest_badge):
		quest_badge.visible = GameFlowManager.quests.has_unclaimed_rewards()

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#150f1f")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	chest = AFKChestUI.new()
	add_child(chest)
	GameFlowManager.quests.has_unclaimed_rewards_changed.connect(_update_badge)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 40)
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(m)
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	m.add_child(top)
	var title := Label.new()
	title.text = "AFK IDLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#f2c14e"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(title)
	stage_label = Label.new()
	stage_label.text = "Bölüm 1-1"
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 22)
	stage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(stage_label)
	wallet_label = Label.new()
	wallet_label.text = ""
	wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet_label.add_theme_font_size_override("font_size", 15)
	wallet_label.add_theme_color_override("font_color", Color("#9a8fb8"))
	wallet_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(wallet_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)
	var bwrap := MarginContainer.new()
	bwrap.add_theme_constant_override("margin_left", 20)
	bwrap.add_theme_constant_override("margin_right", 20)
	v.add_child(bwrap)
	battle_button = Button.new()
	battle_button.text = "SAVAS"
	battle_button.custom_minimum_size = Vector2(0, 60)
	battle_button.add_theme_font_size_override("font_size", 22)
	battle_button.focus_mode = Control.FOCUS_NONE
	battle_button.pressed.connect(_on_battle_pressed)
	crystal_button = Button.new()
	crystal_button.text = "KRİSTAL"
	crystal_button.custom_minimum_size = Vector2(0, 48)
	crystal_button.add_theme_font_size_override("font_size", 17)
	crystal_button.focus_mode = Control.FOCUS_NONE
	crystal_button.pressed.connect(_on_crystal_pressed)
	var btnrow := VBoxContainer.new()
	btnrow.add_theme_constant_override("separation", 8)
	btnrow.add_child(battle_button)
	btnrow.add_child(crystal_button)
	tavern_button = Button.new()
	tavern_button.text = "TAVERNA"
	tavern_button.custom_minimum_size = Vector2(0, 48)
	tavern_button.add_theme_font_size_override("font_size", 17)
	tavern_button.focus_mode = Control.FOCUS_NONE
	tavern_button.pressed.connect(_on_tavern_pressed)
	btnrow.add_child(tavern_button)
	shop_button = Button.new()
	shop_button.text = "DÜKKAN"
	shop_button.custom_minimum_size = Vector2(0, 48)
	shop_button.add_theme_font_size_override("font_size", 17)
	shop_button.focus_mode = Control.FOCUS_NONE
	shop_button.pressed.connect(_on_shop_pressed)
	btnrow.add_child(shop_button)
	temple_button = Button.new()
	temple_button.text = "TAPINAK"
	temple_button.custom_minimum_size = Vector2(0, 48)
	temple_button.add_theme_font_size_override("font_size", 17)
	temple_button.focus_mode = Control.FOCUS_NONE
	temple_button.pressed.connect(_on_temple_pressed)
	btnrow.add_child(temple_button)
	labyrinth_button = Button.new()
	labyrinth_button.text = "LABİRENT"
	labyrinth_button.custom_minimum_size = Vector2(0, 48)
	labyrinth_button.add_theme_font_size_override("font_size", 17)
	labyrinth_button.focus_mode = Control.FOCUS_NONE
	labyrinth_button.pressed.connect(_on_labyrinth_pressed)
	btnrow.add_child(labyrinth_button)
	boss_button = Button.new()
	boss_button.text = "BOSS"
	boss_button.custom_minimum_size = Vector2(0, 48)
	boss_button.add_theme_font_size_override("font_size", 17)
	boss_button.focus_mode = Control.FOCUS_NONE
	boss_button.pressed.connect(_on_boss_pressed)
	btnrow.add_child(boss_button)
	quest_button = Button.new()
	quest_button.text = "GÖREV"
	quest_button.custom_minimum_size = Vector2(0, 48)
	quest_button.add_theme_font_size_override("font_size", 17)
	quest_button.focus_mode = Control.FOCUS_NONE
	quest_button.pressed.connect(_on_quest_pressed)
	btnrow.add_child(quest_button)
	quest_badge = ColorRect.new()
	quest_badge.color = Color("#ff3b30")
	quest_badge.custom_minimum_size = Vector2(12, 12)
	quest_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	quest_badge.position = Vector2(-16, 4)
	quest_badge.visible = false
	quest_button.add_child(quest_badge)
	arena_button = Button.new()
	arena_button.text = "ARENA"
	arena_button.custom_minimum_size = Vector2(0, 48)
	arena_button.add_theme_font_size_override("font_size", 17)
	arena_button.focus_mode = Control.FOCUS_NONE
	arena_button.pressed.connect(_on_arena_pressed)
	btnrow.add_child(arena_button)
	commander_button = Button.new()
	commander_button.text = "KOMUTAN"
	commander_button.custom_minimum_size = Vector2(0, 48)
	commander_button.add_theme_font_size_override("font_size", 17)
	commander_button.focus_mode = Control.FOCUS_NONE
	commander_button.pressed.connect(_on_commander_pressed)
	btnrow.add_child(commander_button)
	tower_button = Button.new()
	tower_button.text = "KULE"
	tower_button.custom_minimum_size = Vector2(0, 48)
	tower_button.add_theme_font_size_override("font_size", 17)
	tower_button.focus_mode = Control.FOCUS_NONE
	tower_button.pressed.connect(_on_tower_pressed)
	btnrow.add_child(tower_button)
	settings_button = Button.new()
	settings_button.text = "AYARLAR"
	settings_button.custom_minimum_size = Vector2(0, 48)
	settings_button.add_theme_font_size_override("font_size", 17)
	settings_button.focus_mode = Control.FOCUS_NONE
	settings_button.pressed.connect(_on_settings_pressed)
	btnrow.add_child(settings_button)
	var nav_buttons := [battle_button, crystal_button, tavern_button, shop_button, temple_button, labyrinth_button, boss_button, quest_button, arena_button, commander_button, tower_button, settings_button]
	var nav_icons := ["broadsword", "crystal-ball", "holy-grail", "coins", "crown", "", "dragon-head", "trophy", "crossed-swords", "sparkles", "skull-crossed-bones", ""]
	for i in nav_buttons.size():
		var nb := nav_buttons[i] as Button
		var ik := str(nav_icons[i])
		if nb != null and not ik.is_empty():
			nb.icon = IconLoader.get_icon(ik)
			nb.expand_icon = true
		nb.pressed.connect(_on_nav_click)
	bwrap.add_child(btnrow)
	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size = Vector2(0, 96)
	bottom_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bottom_pad)
