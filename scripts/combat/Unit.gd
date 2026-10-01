extends CharacterBody2D
class_name Unit
## Sahadaki tek bir kahraman/dusman: gorsel + barlar + StatsComponent baglantisi.
## Savas karari (FSM/hedefleme) Prompt 3'te eklenecek; bu sinif su an kurulum
## ve gorsel geri bildirimden sorumlu.

enum Team { PLAYER, ENEMY }

const PLAYER_FILL := Color("#4f8fd6")
const PLAYER_FRAME := Color("#234a72")
const ENEMY_FILL := Color("#d65a4f")
const ENEMY_FRAME := Color("#72231f")

const PLAYER_LAYER := 2
const PLAYER_MASK := 4
const ENEMY_LAYER := 4
const ENEMY_MASK := 2

@export var team: Team = Team.PLAYER
@export var hero_data: HeroData
@export var level: int = 1

## Efektif saldiri menzili (setup_unit'ta HeroData.attack_range'den gelir).
## FSM durumlari menzil kararini bununla verir.
var attack_range: float = 120.0

## Can calma orani (kalinti). Savas basi sifir, kalintiyla dolar.
var lifesteal_pct: float = 0.0
## Aura kritik bonusu (toplamsal, 0..1 araliginda tutulur).
var crit_bonus: float = 0.0

func effective_crit() -> float:
	if hero_data == null:
		return clampf(crit_bonus, 0.0, 1.0)
	return clampf(float(hero_data.crit_chance) + crit_bonus, 0.0, 1.0)

## Aktif yetenek cooldown'lari: skill id -> kalan sure. 0 = hazir.
var skill_timers: Dictionary = {}

@onready var stats_component: StatsComponent = $StatsComponent
@onready var buff_component: BuffComponent = $BuffComponent
@onready var equipment_component: EquipmentComponent = $EquipmentComponent
@onready var targeting_component: TargetingComponent = $TargetingComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var hp_bar: ProgressBar = $HPBar
@onready var energy_bar: ProgressBar = $EnergyBar
@onready var facing: Node2D = $Facing
@onready var frame: Panel = $Facing/Frame
@onready var visual: ColorRect = $Facing/Visual
@onready var animated: AnimatedSprite2D = $Facing/Animated
@onready var label_name: Label = $NameLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _flash_tween: Tween

func _ready() -> void:
	add_to_group("units")
	stats_component.unit = self
	stats_component.buff_component = buff_component
	_style_bars()
	stats_component.hp_changed.connect(_on_hp_changed)
	stats_component.energy_changed.connect(_on_energy_changed)
	stats_component.died.connect(_on_died)
	if hero_data != null:
		setup_unit(hero_data, level, team)

func setup_unit(data: HeroData, lvl: int, unit_team: Team) -> void:
	hero_data = data
	level = maxi(1, lvl)
	team = unit_team
	attack_range = maxf(10.0, data.attack_range)
	skill_timers.clear()
	for s in data.active_skills:
		if s != null:
			skill_timers[s.id] = 0.0
	_setup_visual(data, unit_team)
	collision_layer = PLAYER_LAYER if unit_team == Team.PLAYER else ENEMY_LAYER
	collision_mask = PLAYER_MASK if unit_team == Team.PLAYER else ENEMY_MASK
	label_name.text = data.hero_name
	stats_component.initialize(data, level)

## Gorsel kurulum: .tres kareleri oncelikli, yoksa procedural uretim.
## Ikisi de olamaz diye bir durum yok (factory infallible) ama null
## gelirse renkli kutu yedegi gosterilir (crash-proof).
func _setup_visual(data: HeroData, unit_team: Team) -> void:
	var frames := HeroSpriteFactory.frames_of(data)
	var use_sprite := frames != null
	if use_sprite:
		animated.sprite_frames = frames
		animated.scale = Vector2(2, 2) * data.visual_scale
		if frames.has_animation("attack"):
			frames.set_animation_loop("attack", false)
	animated.visible = use_sprite
	frame.visible = not use_sprite
	visual.visible = not use_sprite
	facing.scale.x = 1.0
	if use_sprite:
		animated.flip_h = (unit_team == Team.ENEMY)
		animated.play("idle")
	else:
		visual.color = PLAYER_FILL if unit_team == Team.PLAYER else ENEMY_FILL
		var sb := StyleBoxFlat.new()
		sb.bg_color = PLAYER_FRAME if unit_team == Team.PLAYER else ENEMY_FRAME
		sb.set_corner_radius_all(3)
		frame.add_theme_stylebox_override("panel", sb)
		facing.scale.x = 1.0 if unit_team == Team.PLAYER else -1.0

## FSM durumlarindan cagrilir; karesi yoksa sessizce atlanir.
func play_animation(anim_name: String) -> void:
	if animated == null or not animated.visible:
		return
	var frames := animated.sprite_frames
	if frames == null or not frames.has_animation(anim_name):
		return
	if animated.animation == anim_name and animated.is_playing():
		return
	animated.play(anim_name)

func has_attack_anim() -> bool:
	return animated != null and animated.visible \
		and animated.sprite_frames != null \
		and animated.sprite_frames.has_animation("attack")

func _on_hp_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = 100.0
	hp_bar.value = clampf(current / maxf(1.0, maximum) * 100.0, 0.0, 100.0)

func _on_energy_changed(current: int, maximum: int) -> void:
	energy_bar.max_value = float(maxi(1, maximum))
	energy_bar.value = float(current)

func _physics_process(delta: float) -> void:
	# Aktif yetenek cooldown'lari burada tikler (StateMachine'den once calisir:
	# once ebeveyn, sonra cocuklar).
	if stats_component != null and not stats_component.is_dead:
		for key in skill_timers.keys():
			skill_timers[key] = maxf(0.0, float(skill_timers[key]) - delta)

## Cooldown'u dolmus ilk aktif yetenek (yoksa null).
func get_ready_active_skill() -> SkillData:
	if hero_data == null:
		return null
	for s in hero_data.active_skills:
		if s != null and float(skill_timers.get(s.id, 0.0)) <= 0.0:
			return s
	return null

func set_skill_on_cooldown(skill: SkillData) -> void:
	if skill != null:
		skill_timers[skill.id] = skill.cooldown

## Skill durumuna guvenli giris (Skill duguumu yoksa false).
func try_enter_skill(skill: SkillData) -> bool:
	if skill == null or state_machine == null:
		return false
	var st := state_machine.states.get("Skill") as SkillState
	if st == null:
		return false
	st.active_skill_data = skill
	state_machine.change_state("Skill")
	return true

## Savasi dondur/coz (CombatManager.end_battle/start_battle).
func set_frozen(frozen: bool) -> void:
	if frozen:
		velocity = Vector2.ZERO
	state_machine.set_physics_process(not frozen)
	state_machine.set_process(not frozen)
	set_physics_process(not frozen)
	buff_component.set_process(not frozen)

func _on_died() -> void:
	collision_layer = 0
	collision_mask = 0
	collision_shape.set_deferred("disabled", true)
	play_animation("death")
	if state_machine.current_state_name() != "Dead":
		state_machine.change_state("Dead")
	# Ceset olum karesinde kisa sure kalir, sonra solar.
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(_hide_corpse)

func _hide_corpse() -> void:
	visible = false
	modulate.a = 1.0

## Dirilis pasifi: olur gibi yere duser (hedef havuzundan cikar), 2sn sonra
## %50 canla kalkar (mac basi 1 kez; cagri StatsComponent'ten gelir).
func enter_resurrection() -> void:
	collision_layer = 0
	collision_mask = 0
	collision_shape.set_deferred("disabled", true)
	play_animation("death")
	if is_in_group("units"):
		remove_from_group("units")
	if state_machine.current_state_name() != "Dead":
		state_machine.change_state("Dead")
	await get_tree().create_timer(2.0).timeout
	if not is_instance_valid(self):
		return
	_revive_from_resurrection()

func _revive_from_resurrection() -> void:
	stats_component.current_hp = stats_component.max_hp * 0.5
	stats_component.hp_changed.emit(stats_component.current_hp, stats_component.max_hp)
	collision_layer = PLAYER_LAYER if team == Team.PLAYER else ENEMY_LAYER
	collision_mask = PLAYER_MASK if team == Team.PLAYER else ENEMY_MASK
	collision_shape.set_deferred("disabled", false)
	if not is_in_group("units"):
		add_to_group("units")
	visible = true
	modulate.a = 1.0
	if state_machine.current_state_name() != "Idle":
		state_machine.change_state("Idle")
	FloatingText.spawn_custom(get_parent(), position + Vector2(0, -80.0),
		"DİRİLDİ!", Color("#5fbf5f"), 20)

## Vurus ani pariltisi (spec zamanlamasi: 0.04 parlak + 0.06 donus).
## flash_hit ayni ise yarar (eski cagiranlar korunur).
func play_hit_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	visual.modulate = Color(2.0, 2.0, 2.0, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.06)

func flash_hit() -> void:
	play_hit_flash()

func _style_bars() -> void:
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color("#3ec65a")
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color("#1a1424")
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	var en_fill := StyleBoxFlat.new()
	en_fill.bg_color = Color("#4f8fd6")
	energy_bar.add_theme_stylebox_override("fill", en_fill)
	var en_bg := StyleBoxFlat.new()
	en_bg.bg_color = Color("#1a1424")
	energy_bar.add_theme_stylebox_override("background", en_bg)
