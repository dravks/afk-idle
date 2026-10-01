extends Unit
class_name BossUnit
## Olumsuz patron: cani bitince olmez, tam canla yeni faza gecer; tum alinan
## hasar sayaca islenir (hasar rekoru modu). Hedef havuzunda kalir.

var total_damage_received: float = 0.0
var phase: int = 1
var boss_title: String = ""

func _ready() -> void:
	add_to_group("boss")
	scale = Vector2(2.0, 2.0)
	super._ready()
	var boss_data := hero_data as BossData
	if boss_data != null:
		boss_title = boss_data.boss_title
	stats_component.damaged.connect(_on_boss_damaged)

func _on_boss_damaged(amount: float, _attacker: Unit) -> void:
	total_damage_received += amount

## setup_unit hero_data'yi baglar; baslik ancak BURADA okunabilir
## (_ready aninda data henuz atanmamistir).
func setup_unit(data: HeroData, lvl: int, unit_team: Team) -> void:
	super.setup_unit(data, lvl, unit_team)
	var boss_data := data as BossData
	if boss_data != null:
		boss_title = boss_data.boss_title

func is_immune_to_cc() -> bool:
	var boss_data := hero_data as BossData
	if boss_data == null:
		return false
	return boss_data.is_immune_to_cc

## Olum kapisi EZILIR: gizlenme/Dead yok; faz yenile, sayac korunur.
func _on_died() -> void:
	phase += 1
	stats_component.is_dead = false
	stats_component.current_hp = stats_component.max_hp
	stats_component.hp_changed.emit(stats_component.current_hp, stats_component.max_hp)
	flash_hit()
