extends Node2D
class_name BattleGrid
## 5v5 formasyon sistemi: sol PLAYER (2 on + 3 arka), sag ENEMY (2 on + 3 arka).
## Referans alan 480x856 dikey (proje viewport). Slotlar sabit sozluk
## (Vector2 dizileri); tasiyici sahne duzenlenebilirligi yerine olculebilirlik
## ve headless test edilebilirlik tercih edildi.

const UNIT_SCENE: PackedScene = preload("res://scenes/combat/Unit.tscn")

const VIEW := Vector2(480.0, 856.0)

const PLAYER_BACK: Array[Vector2] = [
	Vector2(55, 300), Vector2(55, 428), Vector2(55, 556),
]
const PLAYER_FRONT: Array[Vector2] = [
	Vector2(150, 350), Vector2(150, 506),
]
const ENEMY_FRONT: Array[Vector2] = [
	Vector2(330, 350), Vector2(330, 506),
]
const ENEMY_BACK: Array[Vector2] = [
	Vector2(425, 300), Vector2(425, 428), Vector2(425, 556),
]

## Slot konumu. Arka hat index 0..2 (ust/orta/alt), on hat index 0..1 (ust/alt).
## Gecersiz index'te hata basip merkez dondurur (cokme yok).
func get_slot_position(team: Unit.Team, is_frontline: bool, index: int) -> Vector2:
	var slots: Array[Vector2]
	if team == Unit.Team.PLAYER:
		slots = PLAYER_BACK if not is_frontline else PLAYER_FRONT
	else:
		slots = ENEMY_BACK if not is_frontline else ENEMY_FRONT
	if index < 0 or index >= slots.size():
		push_error("BattleGrid: gecersiz slot index %d (hat boyutu %d)" % [index, slots.size()])
		return VIEW * 0.5
	return slots[index]

## Bir kahramani ilgili slota yerlestirir, kurar, sahneye ekler.
func spawn_hero(
	hero_data: HeroData,
	level: int,
	team: Unit.Team,
	is_frontline: bool,
	index: int
) -> Unit:
	var unit := UNIT_SCENE.instantiate() as Unit
	if unit == null:
		push_error("BattleGrid: Unit.tscn ornegi alinamadi")
		return null
	add_child(unit)
	unit.position = get_slot_position(team, is_frontline, index)
	unit.setup_unit(hero_data, level, team)
	return unit

## Tum birimleri temizler (yeni savas / test kurulumu).
func clear_units() -> void:
	for child in get_children():
		if child is Unit:
			child.queue_free()
