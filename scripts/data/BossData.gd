extends HeroData
class_name BossData
## Dev patron verisi: kitle kontrol direnci + zamanli ofke yetenegi.
## Savas davranisi BossUnit (olumsuz fazlar) + BossCombatManager (ofke dongusu).

@export var boss_title: String = "Kadim Ejderha"
@export var is_immune_to_cc: bool = true
@export var enrage_interval: float = 20.0
@export var enrage_skill: SkillData
